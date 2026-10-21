---------------------------------------------------------------------
-- PROMPT SANDY APARTMENTS — Proximity loader (client)
-- Ładowanie/zwalnianie IPL apartamentów wg odległości od gracza
-- (strategia "proximity_ipl") albo oparcie o auto-stream
-- (strategia "auto_stream_only") + zarządzanie entity setami
-- wnętrz (furnished / shell_only).
--
-- Plik przepisany z zapisu dekompilatora
-- na czytelny kod — zachowane wszystkie nazwy eventów, eksporty,
-- progi i kolejność wątków; patrz ANALIZA.md, rozdz. 13.
--
-- Świadome odstępstwa od dosłownego zapisu (brak zmiany zachowania):
--   * W setupEntitySetsForIpl usunięty duplikat wywołania
--     IsInteriorEntitySetActive (wynik drugiego odczytu nie był
--     nigdzie używany — artifact dekompilacji).
--   * pointInPolygon: dekompilacja testuje krawędzie w odwrotnej
--     kolejności indeksów (punkty[i], punkty[i-1]) — to ten sam
--     zbiór krawędzi; przepisane na (punkty[i], punkty[i+1]).
---------------------------------------------------------------------

local loadedIPLs = {}      -- [nazwa IPL] = true (załadowane przez nas)
local entitySetTracking = {}  -- [nazwa IPL] = { interiorId, sets }
local staticTracking = {}     -- [nazwa statycznego] = { interiorId, sets }

local interiorMode = Config.InteriorMode
local maxConcurrentInteriors = Config.MaxConcurrentInteriors or 6
local strategy = Config.Strategy or "auto_stream_only"

if strategy ~= "auto_stream_only" and strategy ~= "proximity_ipl" then
    print(("^1[SANDY APTS]^7 Unknown Config.Strategy '%s' — falling back to auto_stream_only"):format(tostring(strategy)))
    strategy = "auto_stream_only"
end

local function logDebug(...)
    if Config.Debug then
        print(...)
    end
end

-- ── Geometria ──────────────────────────────────────────────────────

local function distance3D(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

-- Strefa wykluczenia "ściana": zwraca true, gdy punkt (x,y) leży po
-- stronie dodatniej przekątnej prostej przez ExclusionWallPoint1/2
-- (iloczyn wektorowy < 0).
local function isExcludedByWall(x, y)
    if not Config.ExclusionZoneEnabled then
        return false
    end

    local p1 = Config.ExclusionWallPoint1
    local p2 = Config.ExclusionWallPoint2
    local cross = (p2.x - p1.x) * (y - p1.y) - (p2.y - p1.y) * (x - p1.x)
    return cross < 0
end

-- Punkt (x,y) leży na odcinku (x1,y1)-(x2,y2)?
local function pointOnSegment(x, y, x1, y1, x2, y2)
    -- Współliniowość: iloczyn wektorowy ~ 0
    local cross = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)
    if math.abs(cross) > 1.0e-4 then
        return false
    end
    -- Po właściwej stronie początku odcinka
    local dot = (x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)
    if dot < 0 then
        return false
    end
    -- Wewnątrz długości odcinka
    return dot <= (x2 - x1) ^ 2 + (y2 - y1) ^ 2
end

-- Punkt wewnątrz wielokąta (metoda promieni — ray casting)
local function pointInPolygon(x, y, points)
    local inside = false
    local count = #points

    for i = 1, count do
        local current = points[i]
        local nextPoint = points[i % count + 1]

        -- Punkt dokładnie na krawędzi = wewnątrz
        if pointOnSegment(x, y, current.x, current.y, nextPoint.x, nextPoint.y) then
            return true
        end

        -- Krawędź przecina promień poziomy w prawo?
        if (y < current.y) ~= (y < nextPoint.y) then
            inside = not inside
        end
    end

    return inside
end

-- Strefa wykluczenia "box": wielokąt ExclusionBoxPoints
local function isExcludedByBox(x, y)
    if not Config.ExclusionBoxEnabled then
        return false
    end

    local points = Config.ExclusionBoxPoints
    if not (points and #points >= 3) then
        return false
    end

    return pointInPolygon(x, y, points)
end

-- ── Harmonogram sprawdzania (im dalej, tym rzadziej) ─────────────

local function getCheckInterval(x, y, z)
    local distanceFromCenter = distance3D(
        x, y, z,
        Config.ApartmentCenter.x, Config.ApartmentCenter.y, Config.ApartmentCenter.z)

    -- Sprawdzane po kolei; pierwszy pasujący próg wygrywa
    for _, entry in ipairs(Config.CheckScaling) do
        if distanceFromCenter >= entry.distance then
            return entry.interval
        end
    end

    return Config.CheckInterval
end

-- ── Entity sets (furnished / shell_only) ──────────────────────────

local function getInteriorIdAt(x, y, z)
    local interior = GetInteriorAtCoords(x, y, z)
    if interior == 0 then
        return nil
    end
    return interior
end

-- Konfiguracja entity setów dla wnętrza przy danym IPL:
-- sprawdza dostępność, przełącza na tryb z Config.InteriorMode,
-- odświeża interior i zapamiętuje śledzenie.
local function setupEntitySetsForIpl(iplName, x, y, z)
    Citizen.Wait(100)

    local interiorId = getInteriorIdAt(x, y, z)
    if not interiorId then
        logDebug("^3[ENTITYSET]^7 Warning: Could not find interior for '" .. iplName .. "'")
        return false
    end

    if not IsInteriorEntitySetActive(interiorId, Config.EntitySetFurniture) then
        ActivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
        Citizen.Wait(50)
        if not IsInteriorEntitySetActive(interiorId, Config.EntitySetFurniture) then
            if interiorMode == "furnished" then
                logDebug(("^1[ENTITYSET]^7 Skipping '%s' - interior %d doesn't have '%s' entity set"):format(
                    iplName, interiorId, Config.EntitySetFurniture))
                return false
            end
        end
    end

    DeactivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
    Citizen.Wait(0)

    local activeSets = {}
    if interiorMode == "furnished" then
        ActivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
        table.insert(activeSets, Config.EntitySetFurniture)
        logDebug(("^2[ENTITYSET]^7 Activated '%s' for: %s (interior: %d)"):format(
            Config.EntitySetFurniture, iplName, interiorId))
    else
        table.insert(activeSets, "shell_only")
        logDebug("^3[ENTITYSET]^7 Shell only mode for: " .. iplName)
    end

    RefreshInterior(interiorId)
    entitySetTracking[iplName] = { interiorId = interiorId, sets = activeSets }
    return true
end

-- To samo dla wnętrz "statycznych" (Config.StaticInteriors)
local function setupEntitySetsForStatic(staticDef)
    local interiorId = getInteriorIdAt(staticDef.x, staticDef.y, staticDef.z)
    if not interiorId then
        logDebug("^3[ENTITYSET]^7 Warning: Could not find static interior '" .. staticDef.name .. "'")
        return false
    end

    ActivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
    Citizen.Wait(50)
    if not IsInteriorEntitySetActive(interiorId, Config.EntitySetFurniture) then
        if interiorMode == "furnished" then
            logDebug(("^1[ENTITYSET]^7 Skipping static '%s' - interior %d doesn't have '%s' entity set"):format(
                staticDef.name, interiorId, Config.EntitySetFurniture))
            return false
        end
    end

    DeactivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
    Citizen.Wait(0)

    local activeSets = {}
    if interiorMode == "furnished" then
        ActivateInteriorEntitySet(interiorId, Config.EntitySetFurniture)
        table.insert(activeSets, Config.EntitySetFurniture)
        logDebug(("^2[ENTITYSET]^7 Activated '%s' for static: %s (interior: %d)"):format(
            Config.EntitySetFurniture, staticDef.name, interiorId))
    else
        table.insert(activeSets, "shell_only")
        logDebug("^3[ENTITYSET]^7 Shell only mode for static: " .. staticDef.name)
    end

    RefreshInterior(interiorId)
    staticTracking[staticDef.name] = { interiorId = interiorId, sets = activeSets }
    return true
end

local function clearIplTracking(iplName)
    if entitySetTracking[iplName] then
        logDebug("^1[ENTITYSET]^7 Cleared tracking for: " .. iplName)
        entitySetTracking[iplName] = nil
    end
end

-- ── Ładowanie / zrzucanie IPL ─────────────────────────────────────

local function loadIpl(iplName)
    if not loadedIPLs[iplName] then
        RequestIpl(iplName)
        loadedIPLs[iplName] = true
        logDebug("^2[PROXIMITY]^7 Loaded: " .. iplName)
    end
end

local function unloadIpl(iplName)
    if loadedIPLs[iplName] then
        clearIplTracking(iplName)
        RemoveIpl(iplName)
        loadedIPLs[iplName] = nil
        logDebug("^1[PROXIMITY]^7 Unloaded: " .. iplName)
    end
end

-- Gwarantuje, że IPL jest załadowany (+ konfiguracja entity sets)
local function ensureIplLoaded(iplDef)
    if not loadedIPLs[iplDef.name] then
        loadIpl(iplDef.name)
        CreateThread(function()
            setupEntitySetsForIpl(iplDef.name, iplDef.x, iplDef.y, iplDef.z)
        end)
    end
end

-- Gwarantuje, że IPL nie jest załadowane (zrzucamy też auto-stream)
local function ensureIplUnloaded(iplDef)
    if loadedIPLs[iplDef.name] then
        unloadIpl(iplDef.name)
    elseif IsIplActive(iplDef.name) then
        RemoveIpl(iplDef.name)
    end
end

-- ── Logika bliskości ──────────────────────────────────────────────

local function isWithinProximity(iplDef, playerCoords)
    local maxDistance = iplDef.proximityDistance or Config.ProximityDistance
    local maxZDifference = iplDef.zThreshold or Config.ProximityZThreshold

    local distance = distance3D(
        playerCoords.x, playerCoords.y, playerCoords.z,
        iplDef.x, iplDef.y, iplDef.z)
    local zDifference = math.abs(playerCoords.z - iplDef.z)

    return maxDistance >= distance and maxZDifference >= zDifference
end

-- Dodatkowe IPL z configa (AdditionalProximityIPLs)
local function handleAdditionalIPLs(playerCoords, forceUnload)
    if not Config.AdditionalProximityIPLs then
        return
    end

    for _, entry in ipairs(Config.AdditionalProximityIPLs) do
        if not entry.name then
            logDebug("^1[PROXIMITY]^7 Skipping additional IPL entry with missing name")
        elseif forceUnload then
            unloadIpl(entry.name)
        else
            local hasCoords = entry.x and entry.y and entry.z
            if not hasCoords then
                logDebug(("^1[PROXIMITY]^7 Skipping additional IPL '%s' (missing coordinates)"):format(entry.name))
                unloadIpl(entry.name)
            elseif isWithinProximity(entry, playerCoords) then
                loadIpl(entry.name)
            else
                unloadIpl(entry.name)
            end
        end
    end
end

-- Główna aktualizacja: zbliżone IPL wg odległości (max
-- MaxConcurrentInteriors najbliższych), reszta zrzucana
local function updateProximity(playerCoords)
    -- Strefy wykluczenia: zrzucić wszystko i wyjść
    if isExcludedByWall(playerCoords.x, playerCoords.y)
        or isExcludedByBox(playerCoords.x, playerCoords.y) then
        for _, iplDef in ipairs(Config.IplLocations) do
            ensureIplUnloaded(iplDef)
        end
        handleAdditionalIPLs(playerCoords, true)
        return
    end

    local nearby = {}
    for _, iplDef in ipairs(Config.IplLocations) do
        local distance = distance3D(
            playerCoords.x, playerCoords.y, playerCoords.z,
            iplDef.x, iplDef.y, iplDef.z)
        local zDifference = math.abs(playerCoords.z - iplDef.z)

        if distance <= Config.ProximityDistance and zDifference <= Config.ProximityZThreshold then
            nearby[#nearby + 1] = { ipl = iplDef, distance = distance }
        else
            ensureIplUnloaded(iplDef)
        end
    end

    -- Najbliższe najpierw
    table.sort(nearby, function(a, b)
        return a.distance < b.distance
    end)

    for i, entry in ipairs(nearby) do
        if i <= maxConcurrentInteriors then
            ensureIplLoaded(entry.ipl)
        else
            ensureIplUnloaded(entry.ipl)
        end
    end

    handleAdditionalIPLs(playerCoords, false)
end

-- ── Wątki ─────────────────────────────────────────────────────────

-- Przy starcie (tylko proximity_ipl): zrzucenie ewentualnych
-- auto-streamowanych IPL, żeby loader miał czyste pole
CreateThread(function()
    if strategy ~= "proximity_ipl" then
        return
    end

    for _, iplDef in ipairs(Config.IplLocations) do
        RemoveIpl(iplDef.name)
    end

    if Config.AdditionalProximityIPLs then
        for _, entry in ipairs(Config.AdditionalProximityIPLs) do
            if entry.name then
                RemoveIpl(entry.name)
            end
        end
    end

    logDebug(("^5[ANTI-AUTOSTREAM]^7 Removed all %d apartment IPLs at startup"):format(#Config.IplLocations))
end)

-- Główna pętla bliskości (interwał rośnie z odległością)
CreateThread(function()
    if strategy ~= "proximity_ipl" then
        return
    end

    if not Config.ProximityEnabled then
        logDebug("^3[PROXIMITY]^7 Proximity loading is DISABLED (ProximityEnabled=false)")
        return
    end

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local interval = getCheckInterval(playerCoords.x, playerCoords.y, playerCoords.z)
        updateProximity(playerCoords)
        Wait(interval)
    end
end)

-- Sprzątacz auto-streamu: co 10 s zrzucamy IPL, które nie są
-- załadowane przez nas, a engine i tak podstreamował
CreateThread(function()
    if strategy ~= "proximity_ipl" then
        return
    end

    Wait(5000)
    while true do
        for _, iplDef in ipairs(Config.IplLocations) do
            if not loadedIPLs[iplDef.name] and IsIplActive(iplDef.name) then
                RemoveIpl(iplDef.name)
                logDebug("^5[SWEEP]^7 Removed auto-streamed: " .. iplDef.name)
            end
        end
        Wait(10000)
    end
end)

-- Inicjalizacja wnętrz statycznych (5 prób, interwał 1 s)
CreateThread(function()
    Wait(3000)
    logDebug("^5[ENTITYSET]^7 Initializing static interiors...")

    for _, staticDef in ipairs(Config.StaticInteriors) do
        local attempts = 0
        local ok = false
        while attempts < 5 and not ok do
            ok = setupEntitySetsForStatic(staticDef)
            if not ok then
                attempts = attempts + 1
                Wait(1000)
            end
        end
        if not ok then
            logDebug("^1[ENTITYSET]^7 Failed to initialize: " .. staticDef.name)
        end
    end

    logDebug("^5[ENTITYSET]^7 Static interior initialization complete!")
end)

-- ── Eksporty ──────────────────────────────────────────────────────

exports.GetInteriorMode = function()
    return interiorMode
end

exports.SetInteriorMode = function(mode)
    if mode ~= "shell_only" and mode ~= "furnished" then
        return false
    end

    interiorMode = mode
    logDebug("^5[PROXIMITY]^7 Interior mode changed to: " .. interiorMode)

    -- Przebuduj entity sety załadowanych IPL
    for iplName in pairs(loadedIPLs) do
        for _, iplDef in ipairs(Config.IplLocations) do
            if iplDef.name == iplName then
                CreateThread(function()
                    setupEntitySetsForIpl(iplDef.name, iplDef.x, iplDef.y, iplDef.z)
                end)
                break
            end
        end
    end

    -- Przebuduj entity sety wnętrz statycznych
    for _, staticDef in ipairs(Config.StaticInteriors) do
        CreateThread(function()
            setupEntitySetsForStatic(staticDef)
        end)
    end

    return true
end

exports.GetLoadedIPLsCount = function()
    local count = 0
    for _ in pairs(loadedIPLs) do
        count = count + 1
    end
    return count
end

exports.IsIPLLoaded = function(iplName)
    return loadedIPLs[iplName] == true
end

exports.GetStrategy = function()
    return strategy
end

-- Baner startowy
CreateThread(function()
    Wait(3000)
    logDebug(("^5[SANDY APTS]^7 Strategy: ^2%s^7"):format(strategy))

    if strategy == "proximity_ipl" then
        if Config.ProximityEnabled then
            logDebug(("^5  proximity:^7 ^2ENABLED^7 | dist=%s | interval=%ss | maxConcurrent=%s"):format(
                Config.ProximityDistance, Config.CheckInterval / 1000, maxConcurrentInteriors))
        else
            logDebug("^5  proximity:^7 ^1DISABLED (ProximityEnabled=false)")
        end
    end

    logDebug("^5  interior mode:^7 " .. interiorMode)
    logDebug("^5  static interiors:^7 " .. #Config.StaticInteriors)
end)

---------------------------------------------------------------------
-- PROMPT SANDY APARTMENTS — Building manager (client)
-- Automatyczne ukrywanie/przywracanie modeli budynków apartamentów
-- w zależności od bliskości (strefa target) i obecności we wnętrzu
-- (MLO) — patrz Config (config.lua).
--
-- Plik przepisany z zapisu dekompilatora
-- na czytelny kod — zachowane wszystkie współrzędne, promienie,
-- progi i kolejność wątków; patrz ANALIZA.md, rozdz. 13.
--
-- Świadome odstępstwa od dosłownego zapisu (brak zmiany zachowania):
--   * Usunięta funkcja isPlayerInAnyKnownInterior i jej martwe
--     wywołanie w wątku 1 s — wynik NIGDY nie był odczytywany
--     (czysta natywna, bez skutków ubocznych). Jeśli ktoś chce
--     ją wykorzystać (np. rozszerzenie warunku ukrywania), wzór:
--     GetInteriorFromEntity(PlayerPedId()) + GetInteriorAtCoords
--     dla ALL_TARGET_COORDS.
---------------------------------------------------------------------

local function logDebug(...)
    if Config.Debug then
        print(...)
    end
end

-- ── Zbiory budynków ────────────────────────────────────────────────
-- Każdy zbiór:
--   targetCoords   — punkt odniesienia bliskości (promień 50 m)
--   interiorCoords — punkty sprawdzane, czy gracz stoi WE WNĘTRZU
--                    (GetInteriorAtCoords -> ten sam interior co ped)
--   models         — ukrywane/odtwarzane modele (CreateModelHide)
--   hidden/nearTarget — stan runtime
local BUILDING_SETS = {
    [1] = {
        targetCoords = vector3(1590.52673, 3634.08862, 42.6931839),
        interiorCoords = {
            vector3(1590.52673, 3634.08862, 42.6931839),
            vector3(1590.53076, 3634.08154, 36.19072),
            vector3(1599.24329, 3618.98145, 42.6912956),
            vector3(1599.24329, 3618.98145, 36.191),
            vector3(1570.31067, 3623.349, 42.6931839),
            vector3(1570.28943, 3623.386, 36.19072)
        },
        models = {
            { name = "sm_cs4_apa_build01", coords = vector3(1596.20239, 3613.691, 44.3552437) },
            { name = "sm_cs4_apa_build01_windows", coords = vector3(1596.19788, 3613.09229, 46.9639778) }
        },
        hidden = false,
        nearTarget = false
    },
    [2] = {
        targetCoords = vector3(1629.8584, 3540.04663, 43.583374),
        interiorCoords = {
            vector3(1644.82935, 3539.47437, 42.664875),
            vector3(1644.82935, 3539.47437, 36.1650543),
            vector3(1653.57581, 3524.38525, 42.6656151),
            vector3(1653.57581, 3524.38525, 36.1693077),
            vector3(1634.14856, 3512.22681, 42.6656151),
            vector3(1634.16614, 3512.19653, 36.17069)
        },
        models = {
            { name = "sm_cs4_apa_build02", coords = vector3(1638.59241, 3539.52, 44.2963257) },
            { name = "sm_cs4_apa_build02_deta", coords = vector3(1622.81873, 3544.061, 45.6375923) },
            { name = "sm_cs4_apa_build02_windows", coords = vector3(1638.08618, 3539.81128, 46.9058952) }
        },
        hidden = false,
        nearTarget = false
    },
    [3] = {
        targetCoords = vector3(1414.19861, 3541.53174, 43.44409),
        interiorCoords = {
            vector3(1421.58618, 3568.96216, 42.52607),
            vector3(1421.58459, 3568.96973, 36.02586),
            vector3(1399.0022, 3565.22046, 42.52607),
            vector3(1398.99341, 3565.26367, 36.02772),
            vector3(1399.00159, 3565.22314, 42.52607),
            vector3(1402.23767, 3549.243, 42.52607),
            vector3(1402.2373, 3549.24561, 36.02772),
            vector3(1429.21619, 3531.25928, 42.52418),
            vector3(1429.21619, 3531.25928, 36.0),
            vector3(1425.04163, 3551.87427, 42.52418),
            vector3(1425.042, 3551.87158, 36.03373)
        },
        models = {
            { name = "sm_cs4_apa_build01ist", coords = vector3(1420.33289, 3547.79736, 44.18813) },
            { name = "sm_cs4_apa_build01ist_windows", coords = vector3(1420.145, 3547.24, 46.7969475) }
        },
        hidden = false,
        nearTarget = false
    }
}

local TARGET_RADIUS = 50.0    -- promień "w strefie target"
local HIDE_RADIUS = 50.0      -- promień CreateModelHide/RemoveModelHide
local HIDE_Z_THRESHOLD = 46.0 -- wyżej niż to Z nie chowamy (np. dachy)

-- Punkty referencyjne wnętrz (patrz usunięta funkcja w nagłówku)
local ALL_TARGET_COORDS = {
    vector3(1592.25439, 3605.72656, 43.6112061),
    vector3(1629.8584, 3540.04663, 43.583374),
    vector3(1414.19861, 3541.53174, 43.44409)
}

-- Odległość 3D <= maxDistance?
local function isWithinDistance(fromCoords, toCoords, maxDistance)
    return maxDistance >= #(fromCoords - toCoords)
end

-- Czy ped gracza jest w którymś z wnętrz opisanych punktami coordsList
local function isPlayerInInterior(coordsList)
    local playerInterior = GetInteriorFromEntity(PlayerPedId())
    if playerInterior == 0 then
        return false
    end

    for _, coords in ipairs(coordsList) do
        local interiorAtPoint = GetInteriorAtCoords(coords.x, coords.y, coords.z)
        if playerInterior == interiorAtPoint and interiorAtPoint ~= 0 then
            return true
        end
    end

    return false
end

local function hideModels(models)
    for _, model in ipairs(models) do
        logDebug("^1[MODEL HIDE]^7 Hiding: " .. model.name)
        CreateModelHide(model.coords.x, model.coords.y, model.coords.z,
            HIDE_RADIUS, GetHashKey(model.name), true)
    end
end

local function showModels(models)
    for _, model in ipairs(models) do
        logDebug("^2[MODEL SHOW]^7 Showing: " .. model.name)
        RemoveModelHide(model.coords.x, model.coords.y, model.coords.z,
            HIDE_RADIUS, GetHashKey(model.name), false)
    end
end

-- Wątek 1 (5 s): śledzenie bliskości stref target + odzyskiwanie
-- budynków po wyjściu ze strefy
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for setId, buildingSet in ipairs(BUILDING_SETS) do
            local wasNear = buildingSet.nearTarget
            buildingSet.nearTarget = isWithinDistance(playerCoords, buildingSet.targetCoords, TARGET_RADIUS)

            if wasNear ~= buildingSet.nearTarget then
                if buildingSet.nearTarget then
                    logDebug(("^2[PROXIMITY]^7 Set %d - ENTERED target area"):format(setId))
                else
                    logDebug(("^1[PROXIMITY]^7 Set %d - LEFT target area"):format(setId))
                end
            end

            -- Był blisko, teraz nie jest -> przywróć budynki
            if wasNear and not buildingSet.nearTarget and buildingSet.hidden then
                showModels(buildingSet.models)
                buildingSet.hidden = false
                logDebug(("^2[BUILDING]^7 Set %d - RESTORING buildings (left area)"):format(setId))
            end
        end

        Wait(5000)
    end
end)

-- Wątek 2 (1 s): ukrywanie budynków, gdy gracz jest w strefie
-- target i WEWNĄTRZ budynku (chyba że wyżej niż HIDE_Z_THRESHOLD),
-- oraz przywracanie, gdy powinien być widoczny
CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local zTooHigh = playerCoords.z > HIDE_Z_THRESHOLD

        for setId, buildingSet in ipairs(BUILDING_SETS) do
            if buildingSet.nearTarget then
                local shouldHide = isPlayerInInterior(buildingSet.interiorCoords) and not zTooHigh

                if shouldHide then
                    if not buildingSet.hidden then
                        hideModels(buildingSet.models)
                        buildingSet.hidden = true
                        logDebug(("^1[BUILDING]^7 Set %d - HIDING buildings"):format(setId))
                    end
                elseif buildingSet.hidden then
                    showModels(buildingSet.models)
                    buildingSet.hidden = false
                    logDebug(("^2[BUILDING]^7 Set %d - SHOWING buildings"):format(setId))
                end
            end
        end

        Wait(1000)
    end
end)

-- Baner startowy
CreateThread(function()
    Wait(3000)
    logDebug("^5[BUILDING MANAGER]^7 Automatic interior-based building hide system started!")
    logDebug("^5[BUILDING MANAGER]^7 Monitoring " .. #BUILDING_SETS .. " building sets")
end)

print("[NEOX POLY] ^2Script loading...^7")

if not NeoxConfig then
    print("[NEOX POLY] ^1ERROR: NeoxConfig not found!^7")
    return
end

if not NeoxConfig.PolyIpls then
    print("[NEOX POLY] ^1ERROR: NeoxConfig.PolyIpls not found!^7")
    return
end

local SEPARATOR = "^3========================================^7"

local polyEntries = NeoxConfig.PolyIpls.entries or {}
local notifyPolyChanges = NeoxConfig.PolyIpls.enableNotifications and NeoxConfig.Notify and NeoxConfig.Notify.debug
local vizDebugEnabled = NeoxConfig.PolyIpls.debug or false

local interiorIds = {}
local interiorStates = {}
local zoneEnteredFlags = {}

print(string.format(
    "[NEOX POLY] ^2Config loaded OK | Entries: %d | Debug: %s | VizDebug: %s^7",
    #polyEntries, tostring(notifyPolyChanges), tostring(vizDebugEnabled)
))

function NeoxPolyNotify(message)
    local notifyConfig = NeoxConfig.Notify or { mode = "none" }
    local text = (notifyConfig.prefix and notifyConfig.prefix .. " " or "") .. message

    if notifyConfig.mode == "chat" then
        TriggerEvent("chat:addMessage", { args = { text } })
    elseif notifyConfig.mode == "feed" then
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

function IsNotifyDebugEnabled()
    return NeoxConfig.Notify and NeoxConfig.Notify.debug
end

-- Ray casting: counts how many polygon edges a ray from (x, y) crosses.
function IsPointInPolygon(x, y, polygon)
    local cornerCount = #polygon
    local inside = false
    local previousIndex = cornerCount

    for currentIndex = 1, cornerCount do
        local currentX = polygon[currentIndex].x
        local currentY = polygon[currentIndex].y
        local previousX = polygon[previousIndex].x
        local previousY = polygon[previousIndex].y

        if (y < currentY) ~= (y < previousY) then
            local crossingX = (previousX - currentX) * (y - currentY) / (previousY - currentY) + currentX
            if x < crossingX then
                inside = not inside
            end
        end

        previousIndex = currentIndex
    end

    return inside
end

function IsInsidePolyZone(entry, coords)
    if entry.minZ and coords.z < entry.minZ then
        return false
    end

    if entry.maxZ and coords.z > entry.maxZ then
        return false
    end

    return IsPointInPolygon(coords.x, coords.y, entry.zone)
end

function IsInteriorAlreadyResolved(interiorId)
    for index = 1, #polyEntries do
        if interiorIds[index] == interiorId then
            return true
        end
    end

    return false
end

function ResolvePolyInteriors()
    local allResolved = true

    for index = 1, #polyEntries do
        if not interiorIds[index] then
            local entry = polyEntries[index]
            local pos = entry.pos
            local interiorId = 0

            if entry.interiorId and entry.interiorId ~= 0 then
                interiorId = entry.interiorId

                if IsValidInterior(interiorId) then
                    print(string.format("[NEOX POLY] ^2[RESOLVE] %s → Manual ID: %d^7", entry.name, interiorId))
                else
                    interiorId = 0
                end
            end

            if interiorId == 0 and entry.name then
                interiorId = GetInteriorAtCoordsWithTypehash(pos.x, pos.y, pos.z, GetHashKey(entry.name))

                if interiorId ~= 0 and IsValidInterior(interiorId) then
                    print(string.format("[NEOX POLY] ^2[RESOLVE] %s → TypeHash ID: %d^7", entry.name, interiorId))
                end
            end

            if interiorId == 0 then
                interiorId = GetInteriorAtCoords(pos.x, pos.y, pos.z)

                if interiorId ~= 0 and IsValidInterior(interiorId) then
                    if IsInteriorAlreadyResolved(interiorId) then
                        interiorId = 0
                    else
                        print(string.format(
                            "[NEOX POLY] ^3[RESOLVE] %s → Fallback ID: %d (verify with /polyinfo)^7",
                            entry.name, interiorId
                        ))
                    end
                end
            end

            if interiorId ~= 0 then
                interiorIds[index] = interiorId
                interiorStates[index] = "enabled"
                zoneEnteredFlags[index] = false
            else
                allResolved = false
            end
        end
    end

    return allResolved
end

function IsPlayerInsideInterior(interiorId)
    local currentInterior = GetInteriorFromEntity(PlayerPedId())
    return currentInterior ~= 0 and currentInterior == interiorId
end

function EnablePolyInterior(index, interiorId, name)
    if interiorStates[index] == "enabled" then
        return
    end

    DisableInterior(interiorId, false)
    CapInterior(interiorId, false)

    if not IsInteriorReady(interiorId) then
        LoadInterior(interiorId)
    end

    RefreshInterior(interiorId)
    interiorStates[index] = "enabled"

    if notifyPolyChanges then
        NeoxPolyNotify(string.format("[POLY ENABLE] %s", name))
    end

    if IsNotifyDebugEnabled() then
        print(string.format("[NEOX POLY] ^2[ENABLE] %s (ID: %d)^7", name, interiorId))
    end
end

function DisablePolyInterior(index, interiorId, name)
    if interiorStates[index] == "disabled" then
        return
    end

    DisableInterior(interiorId, true)
    CapInterior(interiorId, true)
    interiorStates[index] = "disabled"

    if notifyPolyChanges then
        NeoxPolyNotify(string.format("[POLY DISABLE] %s", name))
    end

    if IsNotifyDebugEnabled() then
        print(string.format("[NEOX POLY] ^1[DISABLE] %s (ID: %d)^7", name, interiorId))
    end
end

function UpdatePolyInterior(index, interiorId, entry, playerCoords)
    if IsInsidePolyZone(entry, playerCoords) then
        zoneEnteredFlags[index] = true
        EnablePolyInterior(index, interiorId, entry.name)
        return
    end

    zoneEnteredFlags[index] = false

    if IsPlayerInsideInterior(interiorId) then
        if notifyPolyChanges then
            NeoxPolyNotify(string.format("[POLY GUARD] Inside %s", entry.name))
        end
    else
        DisablePolyInterior(index, interiorId, entry.name)
    end
end

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ResolvePolyInteriors()
    end
end)

CreateThread(function()
    ResolvePolyInteriors()

    local allInteriorsResolved = false

    while true do
        if not allInteriorsResolved then
            allInteriorsResolved = ResolvePolyInteriors()
        end

        local playerCoords = GetEntityCoords(PlayerPedId())

        for index = 1, #polyEntries do
            local interiorId = interiorIds[index]

            if interiorId then
                UpdatePolyInterior(index, interiorId, polyEntries[index], playerCoords)
            end
        end

        Wait(NeoxConfig.IPL_POLL_INTERVAL or 1000)
    end
end)

RegisterCommand("polyinfo", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerInterior = GetInteriorFromEntity(playerPed)

    print(SEPARATOR)
    print("^3  NEOX POLY MANAGER — STATUS^7")
    print(SEPARATOR)
    print(string.format("[Player] Coords: %.3f, %.3f, %.3f", playerCoords.x, playerCoords.y, playerCoords.z))
    print(string.format("[Player] Interior: %d", playerInterior))
    print("")

    for index = 1, #polyEntries do
        local entry = polyEntries[index]
        local interiorId = interiorIds[index] or 0
        local state = interiorStates[index] or "not resolved"
        local isInsideZone = IsInsidePolyZone(entry, playerCoords)
        local isPhysicallyInside = interiorId ~= 0 and IsPlayerInsideInterior(interiorId)

        print(string.format("[%d] %s", index, entry.name))
        print(string.format("     ID: %d | State: %s", interiorId, state))
        print(string.format(
            "     Zone: %s | Physically inside: %s",
            isInsideZone and "^2INSIDE^7" or "^1OUTSIDE^7",
            isPhysicallyInside and "^2YES^7" or "no"
        ))
        print(string.format(
            "     Z filter → min: %s | max: %s | current: %.2f",
            entry.minZ and tostring(entry.minZ) or "none",
            entry.maxZ and tostring(entry.maxZ) or "none",
            playerCoords.z
        ))
        print("")
    end

    print(SEPARATOR)
end, false)

RegisterCommand("showzone", function(source, args)
    local index = tonumber(args[1])

    if not index or not polyEntries[index] then
        print("^1[NEOX POLY] /showzone <index>  — Valid indices: 1 to " .. #polyEntries .. "^7")
        return
    end

    local entry = polyEntries[index]

    print(SEPARATOR)
    print(string.format("[NEOX POLY] Zone corners for [%d] %s", index, entry.name))
    print(SEPARATOR)

    for cornerIndex, corner in ipairs(entry.zone) do
        print(string.format("  [%d] X: %.4f  Y: %.4f", cornerIndex, corner.x, corner.y))
    end

    print(string.format(
        "  Z filter: min=%s  max=%s",
        entry.minZ and tostring(entry.minZ) or "none",
        entry.maxZ and tostring(entry.maxZ) or "none"
    ))
    print(SEPARATOR)
end, false)

function GetPolyZoneCenter(zone)
    local sumX, sumY = 0.0, 0.0

    for _, corner in ipairs(zone) do
        sumX = sumX + corner.x
        sumY = sumY + corner.y
    end

    return sumX / #zone, sumY / #zone
end

function DrawPolyZoneLabel(text, x, y, z, red, green, blue)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetTextScale(0.0, 0.35)
    SetTextColour(red, green, blue, 255)
    SetTextOutline()
    SetTextCentre(true)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function DrawPolyZoneDebug(index, entry, playerCoords)
    local zone = entry.zone
    local cornerCount = #zone
    local baseZ = entry.pos.z
    local bottomZ = entry.minZ or (baseZ - 0.5)
    local topZ = entry.maxZ or (baseZ + 3.0)
    local hasZFilter = entry.minZ or entry.maxZ

    local isInside = IsInsidePolyZone(entry, playerCoords)
    local red = isInside and 0 or 220
    local green = isInside and 220 or 0
    local blue = 0

    for cornerIndex = 1, cornerCount do
        local corner = zone[cornerIndex]
        local nextCorner = zone[(cornerIndex % cornerCount) + 1]

        DrawLine(corner.x, corner.y, bottomZ, nextCorner.x, nextCorner.y, bottomZ, red, green, blue, 220)

        if hasZFilter then
            DrawLine(corner.x, corner.y, topZ, nextCorner.x, nextCorner.y, topZ, red, green, blue, 220)
            DrawLine(corner.x, corner.y, bottomZ, corner.x, corner.y, topZ, red, green, blue, 130)
        end

        DrawMarker(
            28, corner.x, corner.y, bottomZ,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.6, 0.6, 0.15,
            red, green, blue, 180,
            false, false, 2, false, nil, nil, false
        )
    end

    local centerX, centerY = GetPolyZoneCenter(zone)
    DrawPolyZoneLabel(string.format("[%d] %s", index, entry.name), centerX, centerY, topZ + 1.5, red, green, blue)
end

if vizDebugEnabled then
    CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())

            for index = 1, #polyEntries do
                DrawPolyZoneDebug(index, polyEntries[index], playerCoords)
            end

            Wait(0)
        end
    end)
end

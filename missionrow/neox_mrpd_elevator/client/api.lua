--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — ELEVATOR PUBLIC API (client)
-- =========================================================
-- Access rules and the exports other resources drive the elevators
-- with. Runtime state itself lives in client/runtime.lua.
-- =========================================================

-- shaftId -> { allowed = bool, floors = { [stopId] = true } or nil }
local jobAccess = {}

-- shaftId -> { [stopId] = true } for floors locked at runtime
local lockedFloors = {}

-- shaftId -> true while the call button is locked out
local lockedCalls = {}

function ElevatorFloorLocks(shaftId)
    local locks = lockedFloors[shaftId]
    if not locks then
        locks = {}
        lockedFloors[shaftId] = locks
    end
    return locks
end

-- ---------------------------------------------------------
-- Access checks (used by runtime.lua and panels.lua)
-- ---------------------------------------------------------
function CanInteractWithElevator(shaftId)
    if Config.Interaction.disabled then return false end
    if lockedCalls[shaftId] then return false end

    local access = jobAccess[shaftId]
    if access and access.allowed == false then return false end

    return true
end

function CanUseStop(shaftId, stopId)
    if ElevatorFloorLocks(shaftId)[stopId] then return false end

    local access = jobAccess[shaftId]
    if not access then return true end
    if access.allowed == false then return false end

    -- An explicit floor list is a whitelist.
    if access.floors then
        return access.floors[stopId] == true
    end

    return true
end

-- Which shaft the player is currently riding in, if any.
function GetOccupiedShaftId()
    for shaftId in pairs(Config.Shafts) do
        local runtime = GetShaftRuntime(shaftId)
        if runtime and runtime.isInCabin then
            return shaftId
        end
    end

    return nil
end

-- ---------------------------------------------------------
-- Exports
-- ---------------------------------------------------------
-- data = { job = false to deny entirely, floors = { stopId, ... } }
-- Passing nil clears the rule for that shaft.
exports('SetJobAccess', function(shaftId, data)
    if data == nil then
        jobAccess[shaftId] = nil
        return
    end

    local floors = nil
    if type(data.floors) == 'table' then
        floors = {}
        for _, stopId in ipairs(data.floors) do
            floors[stopId] = true
        end
    end

    jobAccess[shaftId] = {
        allowed = data.job ~= false,
        floors  = floors,
    }
end)

exports('CanPlayerAccessFloor', function(shaftId, stopId)
    return CanUseStop(shaftId, stopId)
end)

exports('SetPlayerAccessFloor', function(shaftId, stopId, allowed)
    ElevatorFloorLocks(shaftId)[stopId] = (allowed == false) or nil
end)

-- Omit shaftId to toggle every shaft at once, which also clears any
-- per-shaft call locks.
exports('SetElevatorInteractionEnabled', function(enabled, shaftId)
    if shaftId == nil then
        Config.Interaction.disabled = (enabled == false)
        lockedCalls = {}
    else
        lockedCalls[shaftId] = (enabled == false) or nil
    end
end)

exports('IsElevatorInteractionEnabled', function(shaftId)
    return CanInteractWithElevator(shaftId)
end)

exports('LockElevatorCall', function(shaftId)
    if shaftId then
        lockedCalls[shaftId] = true
    end
end)

exports('UnlockElevatorCall', function(shaftId)
    if shaftId then
        lockedCalls[shaftId] = nil
    end
end)

exports('LockFloor', function(shaftId, stopId)
    ElevatorFloorLocks(shaftId)[stopId] = true
end)

exports('UnlockFloor', function(shaftId, stopId)
    ElevatorFloorLocks(shaftId)[stopId] = nil
end)

exports('IsInElevator', function(shaftId)
    local runtime = GetShaftRuntime(shaftId)
    return (runtime and runtime.isInCabin) == true
end)

exports('IsInAnyElevator', function()
    return GetOccupiedShaftId() ~= nil
end)

exports('GetElevatorCurrentFloor', function(shaftId)
    return ReadShaftState(shaftId, 'stop', nil)
end)

exports('OpenElevatorKeypad', function()
    local shaftId = GetOccupiedShaftId()
    if not (shaftId and CanInteractWithElevator(shaftId)) then return end

    local runtime = GetShaftRuntime(shaftId)
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return end

    EnterPanelView(shaftId)
end)

-- Calls whichever cabin has the stop nearest the player.
exports('CallElevator', function()
    local coords = GetEntityCoords(PlayerPedId())
    local nearestShaft, nearestStop, nearestDist = nil, nil, nil

    for shaftId, shaft in pairs(Config.Shafts) do
        for stopId, stop in pairs(shaft.stops or {}) do
            if stop.position then
                local dist = #(coords - stop.position)
                if not nearestDist or nearestDist > dist then
                    nearestDist = dist
                    nearestStop = stopId
                    nearestShaft = shaftId
                end
            end
        end
    end

    if not nearestShaft then return end

    RequestCabinAtStop(nearestShaft, nearestStop)
end)

-- ---------------------------------------------------------
-- Occupancy reporting
-- ---------------------------------------------------------
-- The server needs to know which cabin a player is in so it can keep the
-- shaft alive for them; only transitions are sent.
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(500)
    end

    local lastShaftId = nil

    while true do
        Wait(250)

        local shaftId = GetOccupiedShaftId()
        if shaftId ~= lastShaftId then
            lastShaftId = shaftId
            TriggerServerEvent(Neox.Event('occupancy'), shaftId)
        end
    end
end)

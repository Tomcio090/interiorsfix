--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — ELEVATOR (server) [FiveVault]
-- =========================================================
-- The server is the authority on where every cabin is and what it is
-- doing. Clients only interpolate between the stops it publishes.
--
-- Published per shaft through GlobalState (keys from Neox.StateKey):
--   phase    Neox.Phase.IDLE | CLOSING | TRAVELLING | OPENING | OPEN
--   stop     the stop id the cabin is parked at
--   trip     { id, from, to, start, duration } while travelling, else nil
--   pending  array of queued stop ids, so the panels can light buttons
--
-- `trip.start` is a server GetGameTimer() value, which is the same clock
-- the clock/clock:reply exchange lets clients line themselves up with.
--
-- This resource is standalone: it has its own Config and Neox and does
-- not share neox_mrpd_scripts' bridges.
-- =========================================================

-- shaftId -> runtime
local shafts = {}

-- src -> shaftId the player reported riding in
local occupants = {}

-- shaftId -> src holding the in-cabin panel
local panelOwners = {}

local throttles = {}

-- ---------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------
function ElevatorThrottle(src, key, windowMs)
    local bucket = throttles[src]
    if not bucket then
        bucket = {}
        throttles[src] = bucket
    end

    local now = GetGameTimer()
    if bucket[key] and now < bucket[key] then return true end

    bucket[key] = now + (windowMs or 250)
    return false
end

function ElevatorPublish(shaftId, key, value)
    GlobalState[Neox.StateKey(shaftId, key)] = value
end

-- The queue table is mutated in place, so a fresh copy is published every
-- time to be sure the change actually replicates.
function ElevatorPublishPending(shaftId)
    local copy = {}

    for index, stopId in ipairs(shafts[shaftId].pending) do
        copy[index] = stopId
    end

    ElevatorPublish(shaftId, 'pending', copy)
end

function ElevatorSetPhase(shaftId, phase)
    local shaft = shafts[shaftId]
    if shaft.phase == phase then return end

    shaft.phase = phase
    ElevatorPublish(shaftId, 'phase', phase)
end

-- Doors sit open while idle, so the resting phase is IDLE rather than OPEN.
function ElevatorDoorTiming()
    local timing = Config.Timing or {}

    return
        Neox.Seconds(timing.doorClose, 2.0),
        Neox.Seconds(timing.doorOpen, 2.0),
        Neox.Seconds(timing.doorHold, 2.0)
end

-- Stop 1 exists on both shipped shafts; otherwise take the lowest id.
function ElevatorStartStop(shaft)
    if shaft.stops and shaft.stops[1] then return 1 end

    local lowest = nil
    for stopId in pairs(shaft.stops or {}) do
        if type(stopId) == 'number' and (lowest == nil or stopId < lowest) then
            lowest = stopId
        end
    end

    return lowest or 1
end

-- ---------------------------------------------------------
-- Scheduling
-- ---------------------------------------------------------
-- A request is queued once; pressing the same button again is ignored,
-- and the destination stays in `pending` until the cabin arrives so the
-- panel keeps its button lit.
function ElevatorQueue(shaftId, stopId)
    local shaft = shafts[shaftId]
    if not shaft then return false end

    if not Neox.GetStop(shaftId, stopId) then return false end

    for _, queued in ipairs(shaft.pending) do
        if queued == stopId then return false end
    end

    -- Already parked here with the doors open.
    if shaft.stop == stopId and shaft.phase == Neox.Phase.IDLE and #shaft.pending == 0 then
        return false
    end

    shaft.pending[#shaft.pending + 1] = stopId
    ElevatorPublishPending(shaftId)

    return true
end

function ElevatorServe(shaftId, target)
    local shaft = shafts[shaftId]
    local closeMs, openMs, holdMs = ElevatorDoorTiming()

    if target ~= shaft.stop then
        ElevatorSetPhase(shaftId, Neox.Phase.CLOSING)
        Wait(closeMs)

        local duration = Neox.GetTripDuration(shaftId, shaft.stop, target)

        shaft.tripId = shaft.tripId + 1

        local trip = {
            id       = shaft.tripId,
            from     = shaft.stop,
            to       = target,
            start    = GetGameTimer(),
            duration = duration,
        }

        ElevatorPublish(shaftId, 'trip', trip)
        ElevatorSetPhase(shaftId, Neox.Phase.TRAVELLING)

        -- Also pushed directly so a client with no synced clock yet can
        -- still latch the trip (LatchTrip's `force` path).
        TriggerClientEvent(Neox.Event('trip'), -1,
            shaftId, trip.id, trip.from, trip.to, trip.start, trip.duration)

        Wait(duration)

        shaft.stop = target
        ElevatorPublish(shaftId, 'stop', target)
        ElevatorPublish(shaftId, 'trip', nil)
    end

    ElevatorSetPhase(shaftId, Neox.Phase.OPENING)
    Wait(openMs)

    ElevatorSetPhase(shaftId, Neox.Phase.OPEN)
    Wait(holdMs)

    ElevatorSetPhase(shaftId, Neox.Phase.IDLE)
end

function ElevatorRun(shaftId)
    local shaft = shafts[shaftId]

    while true do
        local target = shaft.pending[1]

        if target == nil then
            Wait(250)
        else
            ElevatorServe(shaftId, target)

            -- Only drop it once served, so the button stays lit en route.
            for index, queued in ipairs(shaft.pending) do
                if queued == target then
                    table.remove(shaft.pending, index)
                    break
                end
            end

            ElevatorPublishPending(shaftId)
        end
    end
end

-- ---------------------------------------------------------
-- Boot
-- ---------------------------------------------------------
CreateThread(function()
    for shaftId, shaft in pairs(Config.Shafts or {}) do
        local startStop = ElevatorStartStop(shaft)

        shafts[shaftId] = {
            stop    = startStop,
            phase   = Neox.Phase.IDLE,
            pending = {},
            tripId  = 0,
        }

        ElevatorPublish(shaftId, 'stop', startStop)
        ElevatorPublish(shaftId, 'phase', Neox.Phase.IDLE)
        ElevatorPublish(shaftId, 'trip', nil)
        ElevatorPublish(shaftId, 'pending', {})

        CreateThread(function()
            ElevatorRun(shaftId)
        end)
    end

    local count = 0
    for _ in pairs(shafts) do count = count + 1 end

    print('^5[FiveVault]^7 neox_mrpd_elevator initialized - https://fivevault.net | discord.gg/fivevault')
    print(('^2[%s]^7 server ready - %d shaft(s) ^5[FiveVault]^7'):format(Neox.Resource, count))
end)

-- ---------------------------------------------------------
-- Clock sync
-- ---------------------------------------------------------
-- Echo the client's own timestamp back with ours, so it can work out the
-- round trip and the offset by itself.
RegisterNetEvent(Neox.Event('clock'), function(sentAt)
    local src = source
    if type(sentAt) ~= 'number' then return end

    TriggerClientEvent(Neox.Event('clock:reply'), src, sentAt, GetGameTimer())
end)

-- ---------------------------------------------------------
-- Requests
-- ---------------------------------------------------------
RegisterNetEvent(Neox.Event('request'), function(shaftId, stopId)
    local src = source
    if ElevatorThrottle(src, 'request', 400) then return end
    
    if type(shaftId) ~= 'string' or not shafts[shaftId] then return end
    if type(stopId) ~= 'number' then return end

    ElevatorQueue(shaftId, stopId)
end)

RegisterNetEvent(Neox.Event('occupancy'), function(shaftId)
    local src = source

    if shaftId == nil then
        occupants[src] = nil
        return
    end

    if type(shaftId) ~= 'string' or not shafts[shaftId] then return end

    occupants[src] = shaftId
end)

RegisterNetEvent(Neox.Event('panel:claim'), function(shaftId)
    local src = source
    if type(shaftId) ~= 'string' or not shafts[shaftId] then return end

    local owner = panelOwners[shaftId]
    if owner and owner ~= src and GetPlayerName(owner) then return end

    -- One panel per player.
    for key, holder in pairs(panelOwners) do
        if holder == src and key ~= shaftId then
            panelOwners[key] = nil
        end
    end

    panelOwners[shaftId] = src
end)

RegisterNetEvent(Neox.Event('panel:release'), function(shaftId)
    local src = source
    if type(shaftId) ~= 'string' then return end

    if panelOwners[shaftId] == src then
        panelOwners[shaftId] = nil
    end
end)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source

    occupants[src] = nil
    throttles[src] = nil

    for shaftId, holder in pairs(panelOwners) do
        if holder == src then
            panelOwners[shaftId] = nil
        end
    end
end)

-- Leaving stale state bags behind would make a restarted resource think
-- a cabin was mid-trip.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= Neox.Resource then return end

    for shaftId in pairs(shafts) do
        ElevatorPublish(shaftId, 'trip', nil)
        ElevatorPublish(shaftId, 'pending', {})
        ElevatorPublish(shaftId, 'phase', Neox.Phase.IDLE)
    end
end)

-- ---------------------------------------------------------
-- Admin
-- ---------------------------------------------------------
RegisterCommand('elevator_status', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'neox.mrpd.admin') then return end

    for shaftId, shaft in pairs(shafts) do
        local queued = {}
        for _, stopId in ipairs(shaft.pending) do
            queued[#queued + 1] = tostring(stopId)
        end

        print(('[%s] %s: stop=%s phase=%s pending=[%s] panel=%s'):format(
            Neox.Resource,
            shaftId,
            tostring(shaft.stop),
            tostring(shaft.phase),
            table.concat(queued, ', '),
            tostring(panelOwners[shaftId] or 'none')
        ))
    end
end, false)

RegisterCommand('elevator_send', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'neox.mrpd.admin') then return end

    local shaftId = args[1]
    local stopId = tonumber(args[2])

    if not shaftId or not stopId or not shafts[shaftId] then
        print(('[%s] usage: elevator_send <shaftId> <stopId>'):format(Neox.Resource))
        return
    end

    if ElevatorQueue(shaftId, stopId) then
        print(('[%s] %s queued for stop %d'):format(Neox.Resource, shaftId, stopId))
    end
end, false)

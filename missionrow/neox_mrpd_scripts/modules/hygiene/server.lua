--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — HYGIENE (server)
-- =========================================================
-- Owns which showers, toilets and sinks are occupied so two players
-- cannot claim the same fixture, and relays the particle effects so
-- everyone nearby sees running water.
--
-- Occupancy is deliberately not persisted: a restart should leave every
-- fixture free.
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

local cfg = NeoxMRPD.Config.Hygiene

-- fixture index -> src currently using it
local showerUse, toiletUse, sinkUse = {}, {}, {}

-- Shared shape so the three fixture kinds do not repeat themselves.
local FIXTURES = {
    shower = { state = showerUse, list = 'Showers', event = 'neox_shower:updateShowerState' },
    toilet = { state = toiletUse, list = 'Toilets', event = 'neox_shower:updateToiletState' },
    sink   = { state = sinkUse,   list = 'Sinks',   event = 'neox_shower:updateSinkState' },
}

-- The client only ever needs to know "busy or not", so the src values are
-- flattened to booleans before they go out.
function HygieneOccupancy(state)
    local out = {}
    for index, owner in pairs(state) do
        out[index] = owner ~= nil
    end
    return out
end

function HygieneBroadcast(kind, index)
    local fixture = FIXTURES[kind]
    TriggerClientEvent(fixture.event, -1, index, fixture.state[index] ~= nil)
end

function HygieneSetUse(src, kind, index, inUse)
    local fixture = FIXTURES[kind]
    if not fixture then return end

    if type(index) ~= 'number' or index % 1 ~= 0 then return end
    if not (cfg[fixture.list] and cfg[fixture.list][index]) then return end

    local owner = fixture.state[index]

    if inUse then
        -- Already taken by somebody still connected.
        if owner and owner ~= src and GetPlayerName(owner) then return end
        fixture.state[index] = src
    else
        -- Only the occupant may free it.
        if owner and owner ~= src then return end
        fixture.state[index] = nil
    end

    HygieneBroadcast(kind, index)
end

RegisterNetEvent('neox_shower:requestStates', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'hygiene:states', 1000) then return end

    TriggerClientEvent('neox_shower:receiveStates', src,
        HygieneOccupancy(showerUse),
        HygieneOccupancy(toiletUse),
        HygieneOccupancy(sinkUse))
end)

RegisterNetEvent('neox_shower:setShowerUse', function(index, inUse)
    HygieneSetUse(source, 'shower', index, inUse)
end)

RegisterNetEvent('neox_shower:setToiletUse', function(index, inUse)
    HygieneSetUse(source, 'toilet', index, inUse)
end)

RegisterNetEvent('neox_shower:setSinkUse', function(index, inUse)
    HygieneSetUse(source, 'sink', index, inUse)
end)

-- ---------------------------------------------------------
-- Effect relays
-- ---------------------------------------------------------
-- Each client decides for itself whether it is close enough to draw the
-- effect (see Hyg.resolveSyncPed), so these go to everyone but the
-- player who caused them.
function HygienePedCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

RegisterNetEvent('neox_shower:syncShower', function(showerPos, heading)
    local src = source
    if NeoxMRPD.Throttle(src, 'hygiene:shower', 500) then return end
    if type(heading) ~= 'number' or not showerPos then return end

    -- Args are (showerPos, heading, originPos, serverId): the particle
    -- origin and the distance-check point are the same spot here.
    TriggerClientEvent('neox_shower:syncShowerEffect', -1, showerPos, heading, showerPos, src)
end)

RegisterNetEvent('neox_shower:stopShower', function()
    local src = source
    TriggerClientEvent('neox_shower:stopShowerEffect', -1, src)
end)

RegisterNetEvent('neox_shower:syncWash', function(waterPos)
    local src = source
    if NeoxMRPD.Throttle(src, 'hygiene:wash', 500) then return end
    if not waterPos then return end

    TriggerClientEvent('neox_shower:syncWashFx', -1, waterPos, src)
end)

-- Toilet effects are positioned from the ped, because the client only
-- reports the gender.
RegisterNetEvent('neox_shower:syncPoop', function(gender)
    local src = source
    if NeoxMRPD.Throttle(src, 'hygiene:poop', 500) then return end

    local coords = HygienePedCoords(src)
    if not coords then return end

    TriggerClientEvent('neox_shower:syncPoopFx', -1, coords, src, gender)
end)

RegisterNetEvent('neox_shower:syncPee', function(gender)
    local src = source
    if NeoxMRPD.Throttle(src, 'hygiene:pee', 500) then return end

    local coords = HygienePedCoords(src)
    if not coords then return end

    TriggerClientEvent('neox_shower:syncPeeFx', -1, coords, src, gender)
end)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
-- A fixture held by someone who crashed out would stay busy forever.
AddEventHandler('playerDropped', function()
    local src = source

    for kind, fixture in pairs(FIXTURES) do
        for index, owner in pairs(fixture.state) do
            if owner == src then
                fixture.state[index] = nil
                HygieneBroadcast(kind, index)
            end
        end
    end

    TriggerClientEvent('neox_shower:stopShowerEffect', -1, src)
end)

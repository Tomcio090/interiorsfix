-- =========================================================
-- NEOX MRPD — ELEVATOR PANEL TEXTURES (client)
-- =========================================================
-- Drives the floor-number display, direction arrows and lit call
-- buttons on the cabin props by swapping streamed textures.
--
-- Two shafts can share a texture slot (same txd + base texture). Each
-- tick every nearby shaft states what it wants that slot to show, and
-- the shaft closest to the player wins it.
-- =========================================================

Panel = Panel or {}

-- 'txd/base' -> { texture = <currently applied replacement, or nil> }
local appliedTextures = {}

-- txd -> { deadline, warned } for dictionaries still streaming in
local txdRequests = {}

-- dedupe key -> true, so a given warning is only raised once
local warnedOnce = {}

local conflictWarned = false

-- How long to sleep when no shaft is close enough to matter.
local IDLE_INTERVAL = 1000

function Panel.slotKey(txd, base)
    return txd .. '/' .. base
end

function Panel.enabled()
    return Config.Panels ~= nil
end

function Panel.shaftTextures(shaftId)
    local shaft = Neox.GetShaft(shaftId)
    return (shaft and shaft.textures) or nil
end

-- Entry-level txd wins, then the shaft's, then the global default.
function Panel.resolveTxd(shaftId, entry)
    local textures = Panel.shaftTextures(shaftId)

    if entry and entry.txd then return entry.txd end
    if textures and textures.txd then return textures.txd end

    return Config.Panels.txd
end

-- NOTE: `message` is deliberately unused -- the original only records that
-- the condition was hit and never prints. Kept as-is so the signature and
-- the dedupe behaviour match.
function Panel.debugWarn(key, message)
    if not (Config.Debug.enabled and not warnedOnce[key]) then return end
    warnedOnce[key] = true
end

-- ---------------------------------------------------------
-- Reading shaft state
-- ---------------------------------------------------------
-- Which entry of Config.Panels.numbers a stop maps to.
function Panel.stopNumberKey(shaft, stopId, stop)
    local numbers = shaft.textures and shaft.textures.numbers

    if numbers and numbers[stopId] ~= nil then
        return tostring(numbers[stopId])
    end

    if stop and stop.key ~= nil then
        return tostring(stop.key)
    end

    return tostring(stopId)
end

-- The floor the display should be showing right now: measured off the
-- cabin prop when it exists, otherwise taken from the state bag.
function Panel.currentNumberKey(shaftId)
    local shaft = Neox.GetShaft(shaftId)
    if not (shaft and shaft.stops) then return nil end

    local runtime = GetShaftRuntime and GetShaftRuntime(shaftId)
    local entity = runtime and runtime.entity

    if not (entity and DoesEntityExist(entity)) then
        local stopId = ReadShaftState(shaftId, 'stop', 1)
        local stop = shaft.stops[stopId]
        return (stop and Panel.stopNumberKey(shaft, stopId, stop)) or nil
    end

    local cabinZ = GetEntityCoords(entity).z
    local nearestId, nearestStop, nearestDelta = nil, nil, nil

    for stopId, stop in pairs(shaft.stops) do
        if stop.position then
            local delta = math.abs(stop.position.z - cabinZ)
            if not nearestDelta or nearestDelta > delta then
                nearestDelta = delta
                nearestStop = stop
                nearestId = stopId
            end
        end
    end

    if not nearestStop then return nil end

    return Panel.stopNumberKey(shaft, nearestId, nearestStop)
end

-- 'up' / 'down' while travelling, nil otherwise.
function Panel.travelDirection(shaftId)
    local phase = ReadShaftState(shaftId, 'phase', Neox.Phase.IDLE)
    if phase ~= Neox.Phase.TRAVELLING then return nil end

    local trip = ReadShaftState(shaftId, 'trip', nil)
    if type(trip) ~= 'table' then return nil end

    local fromPos = Neox.GetStopPosition(shaftId, trip.from)
    local toPos = Neox.GetStopPosition(shaftId, trip.to)
    if not fromPos or not toPos then return nil end

    if toPos.z > fromPos.z then return 'up' end
    if toPos.z < fromPos.z then return 'down' end

    return nil
end

-- Set of stop ids with a call queued, for lighting their buttons.
function Panel.pendingStops(shaftId)
    local pending = {}
    local queued = ReadShaftState(shaftId, 'pending', nil)

    if type(queued) == 'table' then
        for _, stopId in ipairs(queued) do
            pending[stopId] = true
        end
    end

    return pending
end

-- ---------------------------------------------------------
-- Building this tick's texture list
-- ---------------------------------------------------------
-- Appends { txd, base, texture } entries to `out`. A nil texture means
-- "show the unlit base".
function Panel.collectSlots(shaftId, out)
    local shaft = Neox.GetShaft(shaftId)
    if not shaft then return end

    local textures = shaft.textures or {}

    if textures.number then
        out[#out + 1] = {
            txd     = Panel.resolveTxd(shaftId, textures),
            base    = textures.number,
            texture = Config.Panels.numbers[Panel.currentNumberKey(shaftId) or ''],
        }
    end

    if textures.arrows ~= false then
        local direction = Panel.travelDirection(shaftId)

        for _, side in ipairs({ 'up', 'down' }) do
            local arrow = (textures.arrows and textures.arrows[side])
                or Config.Panels.arrows[side]

            if arrow and arrow.base then
                out[#out + 1] = {
                    txd     = Panel.resolveTxd(shaftId, arrow),
                    base    = arrow.base,
                    texture = (direction == side and arrow.lit) or nil,
                }
            end
        end
    end

    if textures.buttons ~= false then
        local pending = Panel.pendingStops(shaftId)

        for stopId, stop in pairs(shaft.stops or {}) do
            local key = tostring(stop.key or stopId)
            local button = (textures.buttons and textures.buttons[key])
                or Config.Panels.buttons[key]

            if button and button.base then
                out[#out + 1] = {
                    txd     = Panel.resolveTxd(shaftId, button),
                    base    = button.base,
                    texture = (pending[stopId] and button.lit) or nil,
                }
            else
                Panel.debugWarn('button:' .. key,
                    ("no cabin button texture for stop key '%s' - see Config.Panels.buttons")
                        :format(key))
            end
        end
    end
end

-- Distance to the closest thing belonging to this shaft: any of its
-- stops, or the cabin prop itself.
function Panel.shaftDistance(shaftId, coords)
    local shaft = Neox.GetShaft(shaftId)
    if not shaft then return nil end

    local nearest = nil

    for _, stop in pairs(shaft.stops or {}) do
        if stop.position then
            local dist = #(coords - stop.position)
            if not nearest or nearest > dist then nearest = dist end
        end
    end

    local runtime = GetShaftRuntime and GetShaftRuntime(shaftId)

    if runtime and runtime.entity and DoesEntityExist(runtime.entity) then
        local dist = #(coords - GetEntityCoords(runtime.entity))
        if not nearest or nearest > dist then nearest = dist end
    end

    return nearest
end

-- ---------------------------------------------------------
-- Applying textures
-- ---------------------------------------------------------
-- Re-requests the dict every tick until it lands; `warned` is recorded
-- after a 10s grace, matching the original (which also never printed).
function Panel.ensureTxdLoaded(txd)
    if HasStreamedTextureDictLoaded(txd) then return true end

    local request = txdRequests[txd]

    if not request then
        txdRequests[txd] = {
            deadline = GetGameTimer() + 10000,
            warned   = false,
        }
        RequestStreamedTextureDict(txd, false)
        return false
    end

    RequestStreamedTextureDict(txd, false)

    if not request.warned and GetGameTimer() > request.deadline then
        request.warned = true
    end

    return false
end

function Panel.applyTexture(slot, txd, base, texture)
    local applied = appliedTextures[slot]
    if applied and applied.texture == texture then return end

    RemoveReplaceTexture(txd, base)

    if texture and texture ~= base then
        AddReplaceTexture(txd, base, txd, texture)
    end

    appliedTextures[slot] = { texture = texture }
end

function Panel.clearTexture(slot)
    local txd, base = slot:match('^(.-)/(.+)$')

    if txd and base then
        RemoveReplaceTexture(txd, base)
    end

    appliedTextures[slot] = nil
end

-- Records that two shafts fought over a slot. Like debugWarn above, the
-- original never printed; only the one-shot flag is kept.
function Panel.warnOnConflicts(slots)
    if conflictWarned or not Config.Debug.enabled then return end

    for _, slot in pairs(slots) do
        if #slot.claimants > 1 then
            conflictWarned = true
            table.sort(slot.claimants)
        end
    end
end

function Panel.anyShaftNearby()
    for shaftId in pairs(Config.Shafts) do
        local runtime = GetShaftRuntime and GetShaftRuntime(shaftId)
        if runtime and runtime.isNearby then return true end
    end

    return false
end

-- ---------------------------------------------------------
-- Update loop
-- ---------------------------------------------------------
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(500)
    end

    local active = false

    while true do
        Wait(active and (Config.Panels.updateInterval or 100) or IDLE_INTERVAL)

        if Panel.enabled() then
            active = Panel.anyShaftNearby()
        end

        if not active then
            for slot in pairs(appliedTextures) do
                Panel.clearTexture(slot)
            end
        else
            local coords = GetEntityCoords(PlayerPedId())
            local slots = {}

            for shaftId, shaft in pairs(Config.Shafts) do
                local dist = Panel.shaftDistance(shaftId, coords)

                if dist and dist <= (shaft.range or 25.0) then
                    local entries = {}
                    Panel.collectSlots(shaftId, entries)

                    for _, entry in ipairs(entries) do
                        if entry.txd and entry.base then
                            local key = Panel.slotKey(entry.txd, entry.base)
                            local slot = slots[key]

                            if not slot then
                                slot = { txd = entry.txd, base = entry.base, claimants = {} }
                                slots[key] = slot
                            end

                            slot.claimants[#slot.claimants + 1] = shaftId

                            if not slot.owner or dist < slot.ownerDistance then
                                slot.texture = entry.texture
                                slot.ownerDistance = dist
                                slot.owner = shaftId
                            end
                        end
                    end
                end
            end

            Panel.warnOnConflicts(slots)

            for key, slot in pairs(slots) do
                if Panel.ensureTxdLoaded(slot.txd) then
                    Panel.applyTexture(key, slot.txd, slot.base, slot.texture)
                end
            end

            -- Release any slot no shaft claimed this tick.
            for slot in pairs(appliedTextures) do
                if not slots[slot] then
                    Panel.clearTexture(slot)
                end
            end
        end
    end
end)

-- ---------------------------------------------------------
-- Debug helper: force the number display to a given key
-- ---------------------------------------------------------
function PreviewStopNumber(shaftId, key)
    if not Panel.enabled() then
        return false, 'Config.Panels is disabled'
    end

    local textures = Panel.shaftTextures(shaftId)
    if not (textures and textures.number) then
        return false, 'this shaft has no textures.number in config.lua'
    end

    local txd = Panel.resolveTxd(shaftId, textures)

    if not Panel.ensureTxdLoaded(txd) then
        return false, ("texture dictionary '%s' is not loaded yet"):format(txd)
    end

    local texture = Config.Panels.numbers[tostring(key)]
    if not texture then
        return false, ("no texture mapped to key '%s'"):format(tostring(key))
    end

    Panel.applyTexture(Panel.slotKey(txd, textures.number), txd, textures.number, texture)

    return true, texture
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= Neox.Resource then return end

    for slot in pairs(appliedTextures) do
        Panel.clearTexture(slot)
    end

    appliedTextures = {}
end)

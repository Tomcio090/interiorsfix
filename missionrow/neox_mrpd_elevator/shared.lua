--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — ELEVATOR SHARED CORE
-- =========================================================
-- Turns the authored Config.Shafts data into its runtime form and
-- exposes the lookups and timing maths both sides need.
-- =========================================================

Neox = Neox or {}
Neox.Resource = GetCurrentResourceName()

Config = Config or {}
Config.Debug = Config.Debug or {}

Neox.Phase = {
    IDLE       = 'idle',
    CLOSING    = 'closing',
    TRAVELLING = 'travelling',
    OPENING    = 'opening',
    OPEN       = 'open',
}

function Neox.Event(name)
    return Neox.Resource .. ':' .. name
end

-- ---------------------------------------------------------
-- State bag keys
-- ---------------------------------------------------------
-- Keys are reused every tick, so they are built once and cached.
local stateKeyCache = {}

function Neox.StateKey(shaftId, key)
    local shaftKeys = stateKeyCache[shaftId]
    if not shaftKeys then
        shaftKeys = {}
        stateKeyCache[shaftId] = shaftKeys
    end

    local cached = shaftKeys[key]
    if not cached then
        cached = Neox.Resource .. ':' .. shaftId .. ':' .. key
        shaftKeys[key] = cached
    end

    return cached
end

-- ---------------------------------------------------------
-- Compiling the authored config
-- ---------------------------------------------------------
-- Config offsets are cabin-relative; this puts them in world space.
function Neox.RotateOffset(origin, headingDeg, offset)
    local radians = math.rad(headingDeg or 0.0)
    local sinH, cosH = math.sin(radians), math.cos(radians)

    return vector3(
        origin.x + offset.x * cosH - offset.y * sinH,
        origin.y + offset.x * sinH + offset.y * cosH,
        origin.z + offset.z
    )
end

-- Fills in a stop's derived fields. `stop` is the authored
-- { z, label, key, number } tuple and is edited in place.
function Neox.CompileStop(shaft, stopId, stop)
    stop.z = stop.z or stop[1]
    stop.label = stop.label or stop[2] or ('Stop ' .. tostring(stopId))
    stop.key = tostring(stop.key or stop[3] or stopId)
    stop.number = tostring(stop.number or stop[4] or stop.key)

    local at = shaft.cabin.at
    local heading = at.w or 0.0

    -- The cabin only moves vertically, so a stop sits above the shaft base.
    local base = vector3(at.x, at.y, stop.z)
    stop.position = vector3(at.x, at.y, stop.z)

    local plan = shaft.plan or {}

    if not stop.call and plan.call then
        local point = Neox.RotateOffset(base, heading, plan.call)
        stop.call = vector4(point.x, point.y, point.z, (plan.call.w or 0.0) + heading)
    end

    if not stop.doors and plan.landing then
        stop.doors = {}

        for _, side in ipairs({ 'left', 'right' }) do
            local door = plan.landing[side]
            if door then
                stop.doors[side] = {
                    position = Neox.RotateOffset(base, heading, door),
                    rotation = vector3(0.0, 0.0, (door.w or 0.0) + heading),
                }
            end
        end
    end
end

function Neox.Compile()
    for _, shaft in pairs(Config.Shafts or {}) do
        local at = shaft.cabin.at
        local plan = shaft.plan or {}

        shaft.cabin.position = vector3(at.x, at.y, at.z)
        shaft.cabin.rotation = vector3(0.0, 0.0, at.w or 0.0)

        shaft.range = shaft.range or 25.0
        shaft.callRadius = shaft.callRadius or plan.callRadius or 1.5

        shaft.doors = {
            model = plan.doorModel,
            slide = plan.slide or 0.6,
            cabin = {},
        }

        local cabinDoors = plan.cabinDoors or {}

        if cabinDoors.left then
            shaft.doors.cabin.left = vector3(cabinDoors.left.x, cabinDoors.left.y, cabinDoors.left.z)
            shaft.doors.cabin.leftRot = vector3(0.0, 0.0, cabinDoors.left.w or 0.0)
        end

        if cabinDoors.right then
            shaft.doors.cabin.right = vector3(cabinDoors.right.x, cabinDoors.right.y, cabinDoors.right.z)
            shaft.doors.cabin.rightRot = vector3(0.0, 0.0, cabinDoors.right.w or 180.0)
        end

        shaft.panel = shaft.panel or {}

        -- No explicit panel anchor: use the centre of the button cluster.
        if not shaft.panel.offset and shaft.panel.buttons then
            local sum = vector3(0.0, 0.0, 0.0)
            local count = 0

            for _, buttonOffset in pairs(shaft.panel.buttons) do
                sum = sum + buttonOffset
                count = count + 1
            end

            if count > 0 then
                shaft.panel.offset = sum / count
            end
        end

        shaft.textures = shaft.textures or {}
        shaft.textures.numbers = shaft.textures.numbers or {}

        for stopId, stop in pairs(shaft.stops or {}) do
            Neox.CompileStop(shaft, stopId, stop)

            if shaft.textures.numbers[stopId] == nil then
                shaft.textures.numbers[stopId] = stop.number
            end
        end
    end
end

Neox.Compile()

-- ---------------------------------------------------------
-- Lookups
-- ---------------------------------------------------------
function Neox.GetShaft(shaftId)
    return (Config.Shafts and Config.Shafts[shaftId]) or nil
end

function Neox.GetStop(shaftId, stopId)
    local shaft = Neox.GetShaft(shaftId)
    return (shaft and shaft.stops and shaft.stops[stopId]) or nil
end

-- Accepts a stop id, a vector3 or any table with x/y/z.
function Neox.GetStopPosition(shaftId, target)
    if not target then return nil end

    if type(target) == 'vector3' then
        return target
    end

    if type(target) == 'table' and target.x and target.y and target.z then
        return vector3(target.x + 0.0, target.y + 0.0, target.z + 0.0)
    end

    local stop = Neox.GetStop(shaftId, target)
    return (stop and stop.position) or nil
end

-- ---------------------------------------------------------
-- Timing
-- ---------------------------------------------------------
-- Smoothstep, unless Config.Timing.easing is explicitly false.
function Neox.EaseMoveProgress(progress)
    if not progress or progress <= 0.0 then return 0.0 end
    if progress >= 1.0 then return 1.0 end

    if Config.Timing and Config.Timing.easing == false then
        return progress
    end

    return progress * progress * (3.0 - 2.0 * progress)
end

-- Trip length in ms. Prefers a real speed (m/s); otherwise charges a flat
-- Timing.perStop per floor, falling back to a distance estimate when the
-- endpoints are not plain stop ids.
function Neox.GetTripDuration(shaftId, fromStop, toStop)
    local shaft = Neox.GetShaft(shaftId)
    local timing = Config.Timing or {}

    local fromPos = Neox.GetStopPosition(shaftId, fromStop)
    local toPos = Neox.GetStopPosition(shaftId, toStop)

    if fromPos and toPos then
        local travel = math.abs(toPos.z - fromPos.z)
        local speed = (shaft and shaft.speed) or timing.speed

        if not speed or speed <= 0.0 then
            local perStop = timing.perStop or 4.0

            if type(fromStop) == 'number' and type(toStop) == 'number' then
                local floors = math.max(1, math.abs(toStop - fromStop))
                return math.floor(floors * perStop * 1000)
            end

            local derivedSpeed = 4.2 / perStop
            return math.max(500, math.floor(travel / derivedSpeed * 1000))
        end

        return math.max(500, math.floor(travel / speed * 1000))
    end

    -- Nothing to measure: count floors instead.
    local fromFloor = (type(fromStop) == 'number' and fromStop) or 1
    local floors = math.max(1, math.abs((toStop or 1) - fromFloor))

    return math.floor(floors * (timing.perStop or 4.0) * 1000)
end

-- Seconds (or `fallback` seconds) as a non-negative whole number of ms.
function Neox.Seconds(seconds, fallback)
    return math.floor(math.max(0, (seconds or fallback or 0) * 1000))
end

-- =========================================================
-- NEOX MRPD — SERVER CORE
-- =========================================================
-- Loads first, so every module server can rely on:
--
--   NeoxMRPD.ReadData(name, default)      data/<name> as a table
--   NeoxMRPD.WriteData(name, value)       write it back now
--   NeoxMRPD.QueueWrite(name, value)      write it back soon (coalesced)
--   NeoxMRPD.Allowed(src, moduleName)     access gate + refusal notify
--   NeoxMRPD.Throttle(src, key, ms)       per-player rate limit
--   NeoxMRPD.NewClaims(label)             single-occupant lock helper
--
-- Nothing here talks to a database: scores, presets and bookmarks live
-- in this resource's own data/ folder as JSON, matching the dataFile
-- helper that shared/core.lua already exposes.
-- =========================================================

-- ---------------------------------------------------------
-- JSON persistence
-- ---------------------------------------------------------
function NeoxMRPD.ReadData(name, default)
    local raw = LoadResourceFile(NeoxMRPD.resource, NeoxMRPD.dataFile(name))
    if not raw or raw == '' then return default end

    local ok, value = pcall(json.decode, raw)
    if not ok or type(value) ~= 'table' then
        print(('^3[neox_mrpd_scripts] data/%s is unreadable — starting from empty.^7'):format(name))
        return default
    end

    return value
end

function NeoxMRPD.WriteData(name, value)
    local ok, raw = pcall(json.encode, value)
    if not ok then
        print(('^1[neox_mrpd_scripts] could not encode data/%s^7'):format(name))
        return false
    end

    return SaveResourceFile(NeoxMRPD.resource, NeoxMRPD.dataFile(name), raw, -1)
end

-- Scores and presets change in bursts, so writes are coalesced into one
-- flush per second rather than hitting the disk on every event.
local pendingWrites = {}
local writerRunning = false

function NeoxMRPD.QueueWrite(name, value)
    pendingWrites[name] = value

    if writerRunning then return end
    writerRunning = true

    CreateThread(function()
        while true do
            Wait(1000)

            local batch = pendingWrites
            pendingWrites = {}

            local wrote = false
            for name, value in pairs(batch) do
                NeoxMRPD.WriteData(name, value)
                wrote = true
            end

            if not wrote and next(pendingWrites) == nil then
                writerRunning = false
                return
            end
        end
    end)
end

-- Anything still queued must reach disk before the resource goes away.
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for name, value in pairs(pendingWrites) do
        NeoxMRPD.WriteData(name, value)
    end

    pendingWrites = {}
end)

-- ---------------------------------------------------------
-- Access
-- ---------------------------------------------------------
-- Returns true when src may use that module. On refusal the player is
-- told once, so a module handler can simply bail out.
function NeoxMRPD.Allowed(src, moduleName)
    if not src or src <= 0 then return false end

    if Bridge.HasAccess(src, NeoxMRPD.accessOf(moduleName)) then
        return true
    end

    local moduleConfig = NeoxMRPD.configOf(moduleName)
    local locale = moduleConfig and moduleConfig.Locale

    Notify.toPlayer(src, (locale and locale.no_access) or 'You are not allowed to use this.', 'error')
    return false
end

-- ---------------------------------------------------------
-- Rate limiting
-- ---------------------------------------------------------
-- Net events are client-driven, so every handler that does real work
-- goes through this. Returns true when the call should be dropped.
local throttles = {}

function NeoxMRPD.Throttle(src, key, windowMs)
    local bucket = throttles[src]
    if not bucket then
        bucket = {}
        throttles[src] = bucket
    end

    local now = GetGameTimer()
    local readyAt = bucket[key]

    if readyAt and now < readyAt then
        return true
    end

    bucket[key] = now + (windowMs or 250)
    return false
end

-- ---------------------------------------------------------
-- Single-occupant locks
-- ---------------------------------------------------------
-- CCTV monitors, projectors and the kill house all follow the same
-- shape: one player at a time, released on disconnect.
function NeoxMRPD.NewClaims(label)
    local claims = {
        label  = label,
        owners = {},
    }

    function claims.ownerOf(key)
        return claims.owners[key]
    end

    function claims.heldBy(src)
        for key, owner in pairs(claims.owners) do
            if owner == src then return key end
        end
        return nil
    end

    -- Re-claiming something you already hold succeeds.
    function claims.claim(key, src)
        local owner = claims.owners[key]
        if owner and owner ~= src and GetPlayerName(owner) then
            return false, owner
        end

        claims.owners[key] = src
        return true
    end

    function claims.release(key, src)
        if src and claims.owners[key] ~= src then return false end
        claims.owners[key] = nil
        return true
    end

    function claims.releaseAll(src)
        local released = {}

        for key, owner in pairs(claims.owners) do
            if owner == src then
                claims.owners[key] = nil
                released[#released + 1] = key
            end
        end

        return released
    end

    return claims
end

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
-- Modules add their own handlers; this one only drops the throttle
-- bucket so it cannot grow for the life of the server.
AddEventHandler('playerDropped', function()
    throttles[source] = nil
end)

-- ---------------------------------------------------------
-- Startup diagnostics
-- ---------------------------------------------------------
CreateThread(function()
    Bridge.await(10000)

    local enabled = {}
    for moduleName, isEnabled in pairs(Config.Modules or {}) do
        if isEnabled then
            enabled[#enabled + 1] = moduleName
        end
    end
    table.sort(enabled)

    print(('^2[neox_mrpd_scripts]^7 server ready — framework: %s | modules: %s'):format(
        Bridge.type or Config.Framework,
        #enabled > 0 and table.concat(enabled, ', ') or 'none'
    ))
end)

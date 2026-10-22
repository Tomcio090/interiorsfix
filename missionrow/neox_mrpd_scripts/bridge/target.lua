--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — TARGET BRIDGE  (OPEN FILE — edit freely)
-- =========================================================
-- One API over qb-target / ox_target / qtarget / bt-target.
-- Every module registers its interaction points here, so adding
-- another target resource means editing this file only.
--
-- Driven by config/config.lua:
--   Config.Target.system    'auto' | false | 'ox_target'
--                           | 'qb-target' | 'qtarget' | 'bt-target'
--   Config.Target.distance  default option reach
--   Config.Target.debug     draw zone outlines (nil = follow Config.Debug)
--   Config.InteractionType  'drawtext' forces key prompts everywhere
--
-- A module may still override the system for itself, e.g.
--   Config.Range.Target = { system = false }
--
-- API
--   Target.system(override, interaction)     resolved name or nil
--   Target.enabled(override, interaction)    boolean
--   Target.addSphere(name, coords, r, opts, override, interaction)
--   Target.addBox(name, coords, size, heading, opts, override, interaction)
--   Target.addModel(name, model, opts, distance, override, interaction)
--   Target.remove(name)  /  Target.removeAll(prefix)
--
-- opts is a list of { icon, label, distance, action, canInteract,
-- item, job }. `action` is mapped to whatever key the active target
-- resource expects.
-- =========================================================

Target = Target or {}

local registered = {}   -- name -> { system, kind, handle }
local SUPPORTED = { ox_target = true, ['qb-target'] = true, qtarget = true, ['bt-target'] = true }

local function resourceUp(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

-- ---------------------------------------------------------
-- Which target resource is in play
-- ---------------------------------------------------------
local resolved

local function normalise(value)
    if value == false or value == nil or value == 'none' or value == '' then return nil end
    return string.lower(tostring(value))
end

-- Config.InteractionType = 'drawtext' switches the whole pack (or one
-- module) to key prompts regardless of what is installed. Every module
-- already falls back to [E] when targeting is unavailable, so turning
-- targeting off here is all it takes.
local function promptsForced(interaction)
    local want = interaction
    if want == nil then want = Config.InteractionType end
    return want == 'drawtext'
end

-- override: a module-level value. nil falls through to Config.Target.system.
function Target.system(override, interaction)
    if promptsForced(interaction) then return nil end

    -- Explicit module override wins, including an explicit `false`.
    if override ~= nil and override ~= 'auto' then
        local s = normalise(override)
        if s and not SUPPORTED[s] then
            print(('[neox_mrpd_scripts] Unknown target system "%s" — ignoring.'):format(s))
            return nil
        end
        return s
    end

    -- A positive result is cached; a negative one is not, because a target
    -- resource may simply not have started yet when the first module asks.
    if resolved then return resolved end

    local want = (Config.Target and Config.Target.system)
    if want == nil then want = 'auto' end

    if want ~= 'auto' then
        local s = normalise(want)
        if s and not SUPPORTED[s] then
            print(('[neox_mrpd_scripts] Unknown Config.Target.system "%s" — targeting disabled.'):format(s))
            return nil
        end
        resolved = s
        return s
    end

    if     resourceUp('ox_target')  then resolved = 'ox_target'
    elseif resourceUp('qb-target')  then resolved = 'qb-target'
    elseif resourceUp('qtarget')    then resolved = 'qtarget'
    elseif resourceUp('bt-target')  then resolved = 'bt-target'
    else                                 return nil
    end

    return resolved
end

function Target.enabled(override, interaction)
    local s = Target.system(override, interaction)
    if not s then return false end
    return GetResourceState(s) ~= 'missing'
end

local function debugZones()
    local d = Config.Target and Config.Target.debug
    if d == nil then return Config.Debug == true end
    return d == true
end

local function defaultDistance()
    return (Config.Target and Config.Target.distance) or 2.0
end

-- Resources report 'starting' before their exports exist; calling one
-- too early on a cold boot fails silently.
local function waitForResource(name, timeoutMs)
    if GetResourceState(name) == 'missing' then return false end
    local deadline = GetGameTimer() + (timeoutMs or 20000)
    while GetResourceState(name) ~= 'started' and GetGameTimer() < deadline do
        Wait(100)
    end
    return GetResourceState(name) == 'started'
end

-- ---------------------------------------------------------
-- Option normalisation
--   ox_target  wants onSelect / canInteract / name
--   qb family  wants action   / canInteract
-- ---------------------------------------------------------
local function toOx(name, opts)
    local out = {}
    for i, o in ipairs(opts) do
        out[i] = {
            name        = o.name or (name .. '_' .. i),
            icon        = o.icon,
            label       = o.label,
            distance    = o.distance or defaultDistance(),
            items       = o.item,
            groups      = o.job,
            canInteract = o.canInteract,
            onSelect    = o.action,
        }
    end
    return out
end

local function toQB(opts)
    local out = {}
    for i, o in ipairs(opts) do
        out[i] = {
            icon        = o.icon,
            label       = o.label,
            item        = o.item,
            job         = o.job,
            canInteract = o.canInteract,
            action      = o.action,
        }
    end
    return out
end

local function maxDistance(opts, fallback)
    local d = fallback or defaultDistance()
    for _, o in ipairs(opts) do
        if o.distance and o.distance > d then d = o.distance end
    end
    return d
end

local function warn(kind, name, system, err)
    print(('^3[neox_mrpd_scripts] could not create target %s "%s" on %s: %s^7')
        :format(kind, name, system, tostring(err)))
end

-- ---------------------------------------------------------
-- Target.addSphere
-- ---------------------------------------------------------
function Target.addSphere(name, coords, radius, opts, override, interaction)
    local s = Target.system(override, interaction)
    if not s or registered[name] then return false end
    if not waitForResource(s) then
        warn('sphere', name, s, 'resource never started')
        return false
    end

    radius = radius or 1.0

    if s == 'ox_target' then
        local ok, handle = pcall(function()
            return exports.ox_target:addSphereZone({
                name    = name,
                coords  = coords,
                radius  = radius,
                debug   = debugZones(),
                options = toOx(name, opts),
            })
        end)
        if not ok then warn('sphere', name, s, handle) return false end
        registered[name] = { system = s, kind = 'zone', handle = handle }
        return true
    end

    local ok, err = pcall(function()
        exports[s]:AddCircleZone(name, coords, radius, {
            name      = name,
            useZ      = true,
            debugPoly = debugZones(),
        }, {
            options  = toQB(opts),
            distance = maxDistance(opts, radius),
        })
    end)
    if not ok then warn('sphere', name, s, err) return false end
    registered[name] = { system = s, kind = 'zone', handle = name }
    return true
end

-- ---------------------------------------------------------
-- Target.addBox
-- ---------------------------------------------------------
function Target.addBox(name, coords, size, heading, opts, override, interaction)
    local s = Target.system(override, interaction)
    if not s or registered[name] then return false end
    if not waitForResource(s) then
        warn('box', name, s, 'resource never started')
        return false
    end

    size = size or vec3(1.5, 1.5, 2.0)
    heading = heading or 0.0

    if s == 'ox_target' then
        local ok, handle = pcall(function()
            return exports.ox_target:addBoxZone({
                name     = name,
                coords   = coords,
                size     = size,
                rotation = heading,
                debug    = debugZones(),
                options  = toOx(name, opts),
            })
        end)
        if not ok then warn('box', name, s, handle) return false end
        registered[name] = { system = s, kind = 'zone', handle = handle }
        return true
    end

    local ok, err = pcall(function()
        exports[s]:AddBoxZone(name, coords, size.x, size.y, {
            name      = name,
            heading   = heading,
            debugPoly = debugZones(),
            minZ      = coords.z - (size.z / 2),
            maxZ      = coords.z + (size.z / 2),
        }, {
            options  = toQB(opts),
            distance = maxDistance(opts),
        })
    end)
    if not ok then warn('box', name, s, err) return false end
    registered[name] = { system = s, kind = 'zone', handle = name }
    return true
end

-- ---------------------------------------------------------
-- Target.addModel — attaches to every prop of that model
-- ---------------------------------------------------------
function Target.addModel(name, model, opts, distance, override, interaction)
    local s = Target.system(override, interaction)
    if not s or registered[name] then return false end
    if not waitForResource(s) then
        warn('model', name, s, 'resource never started')
        return false
    end

    if s == 'ox_target' then
        local ok, err = pcall(function()
            exports.ox_target:addModel(model, toOx(name, opts))
        end)
        if not ok then warn('model', name, s, err) return false end
        registered[name] = { system = s, kind = 'model', handle = model }
        return true
    end

    local ok, err = pcall(function()
        exports[s]:AddTargetModel(model, {
            options  = toQB(opts),
            distance = distance or maxDistance(opts),
        })
    end)
    if not ok then warn('model', name, s, err) return false end
    registered[name] = { system = s, kind = 'model', handle = model }
    return true
end

-- ---------------------------------------------------------
-- Removal
-- ---------------------------------------------------------
function Target.remove(name)
    local entry = registered[name]
    if not entry then return end
    registered[name] = nil

    if GetResourceState(entry.system) == 'missing' then return end

    pcall(function()
        if entry.system == 'ox_target' then
            if entry.kind == 'model' then
                exports.ox_target:removeModel(entry.handle)
            else
                exports.ox_target:removeZone(entry.handle)
            end
        else
            if entry.kind == 'model' then
                exports[entry.system]:RemoveTargetModel(entry.handle)
            else
                exports[entry.system]:RemoveZone(entry.handle)
            end
        end
    end)
end

-- nil prefix removes everything this resource registered
function Target.removeAll(prefix)
    for name in pairs(registered) do
        if not prefix or name:sub(1, #prefix) == prefix then
            Target.remove(name)
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Target.removeAll()
    end
end)

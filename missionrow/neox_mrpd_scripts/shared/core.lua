-- =========================================================
-- NEOX MRPD — SHARED CORE
-- =========================================================
-- Builds the per-module config views, resolves locales and
-- exposes the small helpers every module relies on.
-- =========================================================

NeoxMRPD = NeoxMRPD or {}
NeoxMRPD.resource = GetCurrentResourceName()

-- Config table key -> module id used by Config.Modules / NeoxMRPD.enabled
local MODULES = {
    CCTV      = 'cctv',
    Hygiene   = 'hygiene',
    Killhouse = 'killhouse',
    Projector = 'projector',
    Range     = 'range',
    Archive   = 'archive',
}

NeoxMRPD.modules = MODULES

Config.Access = Config.Access or {}
Config.Admin  = Config.Admin  or {}
Config.Target = Config.Target or {}
Config.Notify = Config.Notify or {}
Config.TextUI = Config.TextUI or {}

-- Each Config.<Module> falls through to the global Config, so a module
-- file only declares what it overrides. Access and Target nest one level
-- deeper and need their own fallback; rawget/rawset keep those lookups
-- from being answered by the parent metatable we just installed.
for moduleKey in pairs(MODULES) do
    Config[moduleKey] = Config[moduleKey] or {}
    setmetatable(Config[moduleKey], { __index = Config })

    local access = rawget(Config[moduleKey], 'Access') or {}
    rawset(Config[moduleKey], 'Access', setmetatable(access, { __index = Config.Access }))

    local target = rawget(Config[moduleKey], 'Target')
    if target then
        rawset(Config[moduleKey], 'Target', setmetatable(target, { __index = Config.Target }))
    end
end

NeoxMRPD.Config = Config

-- ---------------------------------------------------------
-- Locales
-- ---------------------------------------------------------
local localeCache = {}

-- Returns that module's strings for `language`, with English filling any
-- gap. The result is cached per module+language pair.
function NeoxMRPD.locale(moduleName, language)
    if not language then
        language = Config.Language or 'en'
    end

    local cacheKey = moduleName .. '|' .. language
    local cached = localeCache[cacheKey]
    if cached then return cached end

    local fallback = (Locales and Locales.en and Locales.en[moduleName]) or {}
    local active = Locales and Locales[language] and Locales[language][moduleName]

    local resolved
    if not active or active == fallback then
        resolved = fallback
    else
        resolved = setmetatable({}, {
            __index = function(_, key)
                local value = active[key]
                if value ~= nil then return value end
                return fallback[key]
            end,
        })
    end

    localeCache[cacheKey] = resolved
    return resolved
end

for moduleKey, moduleName in pairs(MODULES) do
    Config[moduleKey].Locale = NeoxMRPD.locale(moduleName, Config[moduleKey].Language)
end

-- Config.ModuleInteraction = { cctv = 'drawtext', ... } overrides the
-- pack-wide Config.InteractionType for one module.
for moduleKey, moduleName in pairs(MODULES) do
    local override = (Config.ModuleInteraction or {})[moduleName]
    if override then
        rawset(Config[moduleKey], 'InteractionType', override)
    end
end

-- ---------------------------------------------------------
-- Performance defaults
-- ---------------------------------------------------------
-- An explicit value in the module's own config wins, then the shared
-- Config.Performance entry, then the hard default.
local performance = Config.Performance or {}

Config.Killhouse.DuiDistance    = rawget(Config.Killhouse, 'DuiDistance')    or performance.screenDistance or 30.0
Config.Range.DuiDistance        = rawget(Config.Range, 'DuiDistance')        or performance.screenDistance or 30.0
Config.Projector.RenderDistance = rawget(Config.Projector, 'RenderDistance') or performance.screenDistance or 30.0

Config.CCTV.Dui = rawget(Config.CCTV, 'Dui') or {}
Config.CCTV.Dui.width          = Config.CCTV.Dui.width          or performance.cctvDuiWidth  or 1280
Config.CCTV.Dui.height         = Config.CCTV.Dui.height         or performance.cctvDuiHeight or 720
Config.CCTV.Dui.renderDistance = Config.CCTV.Dui.renderDistance or performance.cctvDistance  or 12.0

-- ---------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------
-- Unlisted modules default to enabled.
function NeoxMRPD.enabled(moduleName)
    local modules = Config.Modules or {}
    if modules[moduleName] == nil then return true end
    return modules[moduleName] == true
end

function NeoxMRPD.configOf(moduleName)
    for moduleKey, name in pairs(MODULES) do
        if name == moduleName then return Config[moduleKey] end
    end
    return nil
end

function NeoxMRPD.accessOf(moduleName)
    local moduleConfig = NeoxMRPD.configOf(moduleName)
    return (moduleConfig and rawget(moduleConfig, 'Access')) or Config.Access
end

function NeoxMRPD.clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if maxValue < value then return maxValue end
    return value
end

function NeoxMRPD.formatTime(totalSeconds)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format('%02d:%02d', minutes, seconds)
end

function NeoxMRPD.dataFile(name)
    return 'data/' .. name
end

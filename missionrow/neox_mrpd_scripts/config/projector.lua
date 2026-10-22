--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — PROJECTOR MODULE CONFIGURATION
-- =========================================================
-- Only what this module needs to differ on. Framework, language,
-- target system, notifications, debug and the access defaults all
-- come from config/config.lua unless overridden here.
-- =========================================================

Config.Projector = {}

-- =========================================================
-- INTERACTION
-- =========================================================
Config.Projector.Interact = {
    -- Reach of the laptop target option / [E] prompt, in meters.
    distance = 0.8,
}

-- =========================================================
-- ACCESS
-- =========================================================
-- Inherits restrict / jobs / minGrade / standaloneAllowAll from
-- Config.Access. Grant the briefing room on its own with:
--   add_ace group.command neox.mrpd.projector allow
Config.Projector.Access = {
    aceFallback = 'neox.mrpd.projector',
}

-- =========================================================
-- PROJECTOR LOCATIONS
-- =========================================================
-- =========================================================
Config.Projector.Projectors = {
    [1] = {
        Laptop    = { coords = vector3(465.77, -983.21, 34.99) },
        Projector = { coords = vector3(465.77, -983.21, 34.99) },
    },
    [2] = {
        Laptop    = { coords = vector3(488.73, -988.19, 34.82) },
        Projector = { coords = vector3(484.62, -991.41, 34.82) },
    },
    [3] = {
        Laptop    = { coords = vector3(474.53, -987.28, 34.82) },
        Projector = { coords = vector3(474.81, -984.74, 34.82) },
    },
    [4] = {
        isStandalone = true,
        Projector    = { coords = vector3(445.54, -988.15, 34.82) },
    },
    [5] = {
        Laptop    = { coords = vector3(456.57, -987.22, 39.25) },
        Projector = { coords = vector3(453.83, -989.96, 39.25) },
    },
    [6] = {
        Laptop    = { coords = vector3(465.85, -992.96, 18.67) },
        Projector = { coords = vector3(464.81, -989.04, 18.67) },
    },
    [7] = {
        Laptop    = { coords = vector3(465.37, -1006.35, 18.67) },
        Projector = { coords = vector3(468.95, -1005.10, 18.67) },
    },
}

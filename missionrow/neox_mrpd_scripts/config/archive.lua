--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — DIGITAL ARCHIVE MODULE CONFIGURATION
-- =========================================================
-- Only what this module needs to differ on. Framework, language,
-- target system, notifications, debug and the access defaults all
-- come from config/config.lua unless overridden here.
-- =========================================================

Config.Archive = {}

-- =========================================================
-- COORDINATES & INTERACTION
-- =========================================================
Config.Archive.Coords = vector3(432.7629, -992.320, 30.710)
Config.Archive.InteractionDistance = 1.0

-- =========================================================
-- TARGET SETTINGS
-- =========================================================
Config.Archive.Target = {
    size = vec3(1.2, 1.2, 1.5),
    heading = 0.0,
    icon = 'fas fa-box-archive',
    distance = 2.0,
}

-- =========================================================
-- BLIP SETTINGS
-- =========================================================
Config.Archive.Blip = {
    enable = false,
    sprite = 57,
    color  = 3,
    scale  = 0.7,
}

-- =========================================================
-- PHOTO & ANIMATION
-- =========================================================
-- Photo file inside html/archive/ folder or direct URL
Config.Archive.OfficerPhoto = 'officer.png'

Config.Archive.Animation = {
    dict = 'anim@amb@casino@hangout@ped_male@stand@02b@idles',
    name = 'idle_a',
}

-- =========================================================
-- ACCESS
-- =========================================================
-- Inherits restrict / jobs / minGrade / standaloneAllowAll from
-- Config.Access.
Config.Archive.Access = {
    aceFallback = 'neox.mrpd.archive',
}

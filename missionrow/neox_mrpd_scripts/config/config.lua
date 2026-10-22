--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — MAIN CONFIGURATION
-- =========================================================
-- This is the only file most servers need to touch.
--
-- Everything here is the DEFAULT for all five modules. A module
-- table in config/*.lua may override any single key locally, and
-- anything it does not set is inherited from this file.
--
--   Config.Framework    = 'qb'          -- applies everywhere
--
-- The same inheritance applies one level deeper for Access:
-- Config.CCTV.Access falls back to Config.Access key by key.
-- =========================================================

Config = {}

-- =========================================================
-- LANGUAGE
-- =========================================================
-- Available: 'en', 'tr', 'de', 'fr', 'es', 'pt', 'nl', 'pl'
-- Missing keys fall back to English one by one, so a partial
-- translation never shows a blank string or a raw key name.
Config.Language = 'pl'

-- =========================================================
-- FRAMEWORK
-- =========================================================
-- 'auto'  detect what is running (qbx_core > qb-core > es_extended > vrp)
-- 'qb' | 'qbox' | 'esx' | 'vrp' | 'standalone'
--
-- Leave it on 'auto' unless you run more than one core at once.
Config.Framework = 'esx'

-- Name shown on the kill house / shooting range scoreboards.
--   'charname'  character first + last name (needs a framework)
--   'steam'     Steam / RockstarID name (works standalone)
Config.NameType = 'charname'

-- =========================================================
-- INTERACTION  (how the player triggers things)
-- =========================================================
-- 'auto'      third-eye wherever a target resource is available,
--             [E] / [G] proximity prompts everywhere else
-- 'target'    same as 'auto' — reads better when you have one installed
-- 'drawtext'  always use prompts, even if a target resource is running
--
-- Set this to 'drawtext' and the whole pack drops to key prompts, no
-- other change needed.
Config.InteractionType = 'target'

-- Per-module exceptions. Anything not listed here follows the value
-- above. Use the same three words.
Config.ModuleInteraction = {
    -- The booths sit ~1.2 m apart, tighter than a third-eye ray separates
    -- reliably, so the range ships on key prompts. Comment this out to let
    -- it follow Config.InteractionType like everything else.
    -- range = 'drawtext',
    -- cctv      = 'auto',
    -- hygiene   = 'drawtext',   -- stalls are close together too
    -- killhouse = 'auto',
    -- projector = 'auto',
    -- archive   = 'auto',
}

-- =========================================================
-- TARGET  (third-eye interaction)
-- =========================================================
Config.Target = {
    -- 'auto'   use whichever target resource is installed
    -- false    no targeting anywhere — GTA [E] prompts instead
    -- 'ox_target' | 'qb-target' | 'qtarget' | 'bt-target'
    system = 'ox_target',

    -- Default reach for a target option, in meters. Individual
    -- zones may still ask for less (the range booths do).
    distance = 2.0,

    -- Draw the zone outlines in game. Follows Config.Debug when nil.
    debug = nil,
}

-- =========================================================
-- NOTIFICATIONS
-- =========================================================
Config.Notify = {
    -- 'auto'   pick from what is installed, in this order:
    --          qbx_core -> qb-core -> ox_lib -> es_extended -> okokNotify
    -- 'native' always use the GTA notification feed (no dependency)
    -- 'qb' | 'qbox' | 'esx' | 'ox_lib' | 'okok' | 'custom'
    --
    -- 'custom' calls Notify.custom() in bridge/notify.lua — write
    -- your own three lines there and every module follows.
    system = 'ox_lib',

    -- Default lifetime in ms for a notification that does not ask
    -- for a specific one.
    duration = 3500,

    -- Identical text inside this window is dropped, so a prompt
    -- inside a loop cannot flood the feed. 0 disables it.
    antiSpam = 2000,
}

-- =========================================================
-- TEXT UI  (the "[E] to open" prompt)
-- =========================================================
Config.TextUI = {
    -- 'auto'   ox_lib if installed, otherwise the native help box
    -- 'native' GTA instructional help box (no dependency)
    -- 'ox_lib' | 'qb' | 'custom'
    system = 'ox_lib',

    -- ox_lib only: 'left-center' | 'right-center' | 'top-center'
    position = 'left-center',
}

-- =========================================================
-- ACCESS  (who may use the MRPD systems)
-- =========================================================
-- These are the defaults for every module. A module may override
-- any single key — see the Access block in config/cctv.lua.
Config.Access = {
    -- false: anyone may use every system.
    -- true:  the job / grade / ace rules below apply.
    restrict = false,

    -- Allowed job names (QBCore / Qbox / ESX).
    jobs = { 'police', 'sheriff' },

    -- Minimum job grade. 0 accepts every rank of an allowed job.
    -- Per-job minimums: minGrade = { police = 2, sheriff = 0 }
    minGrade = 0,

    -- Checked before the job rules and accepted on its own, so an
    -- ace grant works on servers with no framework at all.
    --   add_ace group.admin neox.mrpd allow
    aceFallback = 'neox.mrpd',

    -- What happens when no framework is detected and no ace matched.
    -- true lets everyone through, false locks the systems down.
    standaloneAllowAll = true,
}

-- =========================================================
-- ADMIN  (scoreboard resets and debug commands)
-- =========================================================
Config.Admin = {
    -- Framework groups treated as admin.
    groups = { 'admin', 'zarzad', 'god' },

    -- Ace fallback, checked when the framework has no answer.
    --   add_ace group.admin neox.mrpd.admin allow
    aceFallback = 'neox.mrpd.admin',

    -- The server console is always allowed.
}

-- =========================================================
-- PERFORMANCE
-- =========================================================
-- Every in-world screen in this pack is a DUI: a real browser
-- surface the game composites onto a prop. They are the single
-- biggest cost the resource has, and these are the dials.
Config.Performance = {
    -- How far away the wall screens wake up, in meters — kill house and
    -- range scoreboards, briefing projectors. Everything inside MRPD is
    -- within ~50 m of everything else, so a large value keeps every
    -- screen in the building alive at once even when you cannot see one.
    -- 30 m is roughly "this room and the corridor outside".
    screenDistance = 30.0,

    -- The CCTV monitor bank sits in a single room, so it wakes up much
    -- later than the wall screens. Keep this tight.
    cctvDistance = 12.0,

    -- Resolution of the CCTV monitor surface. The console is authored
    -- at 1600x900 and scales to fit, so a smaller surface costs less
    -- to composite without changing the layout. Raise it if you view
    -- the monitors on a 4K screen and want sharper text.
    cctvDuiWidth  = 1280,
    cctvDuiHeight = 720,

    -- How often a screen checks that its texture override survived the
    -- MLO streaming, and how often it re-applies regardless.
    texturePollMs    = 2000,
    textureRefreshMs = 30000,
}

-- =========================================================
-- MODULES
-- =========================================================
-- Turn any feature off completely. A disabled module registers no
-- threads, no targets, no events and no NUI, and costs nothing.
Config.Modules = {
    cctv      = true,   -- MRPD CCTV monitors + camera network
    hygiene   = true,   -- Showers, toilets, sinks
    killhouse = true,   -- Kill house CQB training
    projector = true,   -- Briefing room projector / laptop
    range     = true,   -- Shooting range + aim challenge
    archive   = true,   -- Personnel records & digital archive
}

-- =========================================================
-- DEBUG
-- =========================================================
-- Registers every module's calibration command and draws target
-- zone outlines. Turn this off on a live server.
Config.Debug = false

--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — SHOOTING RANGE MODULE CONFIGURATION
-- =========================================================
-- Only what this module needs to differ on. Framework, language,
-- target system, notifications, debug and the access defaults all
-- come from config/config.lua unless overridden here.
-- =========================================================

Config.Range = {}

-- =========================================================
-- ACCESS
-- =========================================================
-- Inherits restrict / jobs / minGrade / standaloneAllowAll from
-- Config.Access. Restrict the range to police with:
--   Config.Range.Access.restrict = true
Config.Range.Access = {
    aceFallback = 'neox.mrpd.range',
}

-- =========================================================
-- INTERACTION & TARGET
-- =========================================================
-- Both come from config/config.lua and nothing is repeated here:
--   Config.InteractionType          third-eye vs [E] prompts
--   Config.Target                   which target resource, reach, debug
--
-- The booths sit ~1.2 m apart, which is tighter than a third-eye ray
-- separates reliably. If that bothers you, force key prompts for this
-- module alone by uncommenting the range line in Config.ModuleInteraction
-- — no setting needs to move into this file.

Config.Range.MenuSystem = "cinematic" -- "cinematic", "qb-menu", "ox_lib", "esx_menu", or "none"

-- AimLab Challenge Duration (seconds) & Booth assignment
Config.Range.AimLab = {
    BoothId = 3,
    DurationSeconds = 30,
}

-- Target Appearance (Alpha / Opaklık Ayarı: 0-255, 255 = tam opak)
Config.Range.TargetAlpha = 250

-- Hit Marker (Bullet Hole) Settings
Config.Range.HitMarkerSettings = {
    EnableHitMarkers = true,  -- Set to true to enable red hit markers on target props, false to disable
    MarkerDurationMs = 25000, -- Duration before red hit markers fade & disappear (in milliseconds)
    MaxMarkersPerTarget = 30, -- Maximum active bullet hole markers per target prop
    MarkerSize = 0.025,       -- Size of red bullet hit markers (0.025 = ~2.5cm realistic bullet hole)
    EnableHitSound = false     -- Set to true to play sound when target is hit, false to disable hit sound
}

-- Weapon Settings
Config.Range.WeaponSettings = {
    UseOwnWeapon = false, -- If true, players use their own equipped weapon
    NoReload = true,      -- If true, weapons in the shooting range have infinite clip (no reload animation / clip never empties)
    GiveAsItem = false,   -- If false (recommended), gives weapon directly into hands (no item weight, no ammo loss on reload). If true, adds weapon & ammo items to inventory.
    GivenWeapons = {
        { name = "weapon_heavysniper", label = "Heavy Sniper", category = "Sniper" },
        { name = "weapon_carbinerifle", label = "Carbine Rifle", category = "Carbine" },
        { name = "weapon_smg", label = "SMG", category = "SMG" },
        { name = "weapon_pumpshotgun", label = "Pump Shotgun", category = "Shotgun" },
        { name = "weapon_pistol", label = "Pistol", category = "Pistol" }
    },
    GivenAmmo = 250
}

-- Zones & Booths
Config.Range.Zones = {
    WeaponZone = {
        coords = vector3(480.70, -1018.44, 18.67),
        radius = 1.5,
        interactPos = vector4(481.11, -1018.39, 18.67, 87.61)
    },
    LaptopZone = {
        coords = vector3(480.40, -1014.57, 18.67),
        radius = 1.5,
        interactPos = vector4(480.97, -1014.57, 18.67, 94.22)
    },
    CinematicCam = {
        coords = vector3(482.126, -1018.372, 19.360), 
        rot = vector3(-1.449, 0.000, 93.292),
        fov = 45.0
    },
    LaptopCam = {
        coords = vector3(480.532, -1014.596, 18.895),
        rot = vector3(-12.095, 0.000, 87.029),
        fov = 45.0
    },
    ExitZone = {
        coords = vector3(481.76, -1010.21, 18.67),
        radius = 2.5
    }
}

-- 6 Independent Booths (Booths 1 to 6)
Config.Range.Booths = {
    {
        id = 1,
        coords = vector3(483.93, -1014.02, 18.67),
        radius = 0.55,
        targetPos = vector3(497.1211, -1014.03, 20.50439),
        targetHeading = 0.0
    },
    {
        id = 2,
        coords = vector3(483.95, -1015.26, 18.67),
        radius = 0.55,
        targetPos = vector3(494.5854, -1015.242, 20.50439),
        targetHeading = 0.0
    },
    {
        id = 3,
        coords = vector3(483.85, -1016.52, 18.67),
        radius = 0.55,
        targetPos = vector3(496.1465, -1016.48, 20.50439),
        targetHeading = 0.0
    },
    {
        id = 4,
        coords = vector3(483.97, -1017.74, 18.67),
        radius = 0.55,
        targetPos = vector3(495.8154, -1017.715, 20.50439),
        targetHeading = 0.0
    },
    {
        id = 5,
        coords = vector3(483.92, -1019.0, 18.67),
        radius = 0.55,
        targetPos = vector3(497.9109, -1018.962, 20.50439),
        targetHeading = 0.0
    },
    {
        id = 6,
        coords = vector3(484.0, -1020.23, 18.67),
        radius = 0.55,
        targetPos = vector3(495.7692, -1020.196, 20.50439),
        targetHeading = 0.0
    }
}

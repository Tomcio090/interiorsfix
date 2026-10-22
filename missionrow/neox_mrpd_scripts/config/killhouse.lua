-- =========================================================
-- NEOX MRPD — KILL HOUSE MODULE CONFIGURATION
-- =========================================================
-- Only what this module needs to differ on. Framework, language,
-- target system, notifications, debug and the access defaults all
-- come from config/config.lua unless overridden here.
-- =========================================================

Config.Killhouse = {}

-- =========================================================
-- ACCESS
-- =========================================================
-- Inherits restrict / jobs / minGrade / standaloneAllowAll from
-- Config.Access. Restrict CQB training to police with:
--   Config.Killhouse.Access.restrict = true
Config.Killhouse.Access = {
    aceFallback = 'neox.mrpd.killhouse',
}

Config.Killhouse.MenuSystem = "cinematic" -- "cinematic", "qb-menu", "ox_lib", "esx_menu", or "none"

-- (Weapon Settings)
Config.Killhouse.WeaponSettings = {
    UseOwnWeapon = false, -- (If true, uses own weapon)
    NoReload = false,     -- If true, weapons in killhouse have infinite clip (no reload animation / clip never empties)
    GiveAsItem = false,   -- If false (recommended), gives weapon directly into hands. If true, adds weapon & ammo items to inventory.
    GivenWeapons = {
        { name = "weapon_pistol", label = "Pistol", category = "Pistol" },
        { name = "weapon_combatpistol", label = "Combat Pistol", category = "Pistol" },
        { name = "weapon_smg", label = "SMG", category = "SMG" },
        { name = "weapon_pumpshotgun", label = "Pump Shotgun", category = "Shotgun" },
        { name = "weapon_carbinerifle", label = "Carbine Rifle", category = "Carbine" },
        { name = "weapon_assaultrifle", label = "Assault Rifle", category = "Rifle" }
    },
    GivenAmmo = 250
}

--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — CLIENT BOOTSTRAP [FiveVault]
-- =========================================================
-- Validates the framework/language settings, prints the load banner
-- and undoes every world-level change the pack makes when it stops.
-- =========================================================

local VALID_FRAMEWORKS = {
    auto       = true,
    qb         = true,
    qbox       = true,
    esx        = true,
    vrp        = true,
    standalone = true,
}

CreateThread(function()
    if not VALID_FRAMEWORKS[Config.Framework] then
        print(('^1[neox_mrpd_scripts] Unknown Config.Framework "%s" — detecting instead.^7')
            :format(tostring(Config.Framework)))
        Config.Framework = 'auto'
    end

    Bridge.await(5000)

    if not Locales[Config.Language] then
        print(('^3[neox_mrpd_scripts] No locale file for "%s" — using English.^7')
            :format(tostring(Config.Language)))
    end

    local enabledModules = {}
    for moduleName, isEnabled in pairs(Config.Modules or {}) do
        if isEnabled then
            enabledModules[#enabledModules + 1] = moduleName
        end
    end
    table.sort(enabledModules)

    print('^5[FiveVault]^7 Loaded neox_mrpd_scripts - https://fivevault.net | discord.gg/fivevault')
    print(('^2[neox_mrpd_scripts]^7 loaded — framework: %s | language: %s | modules: %s ^5[FiveVault]^7'):format(
        Bridge.type or Config.Framework,
        Config.Language,
        #enabledModules > 0 and table.concat(enabledModules, ', ') or 'none'
    ))
end)

-- ---------------------------------------------------------
-- Shutdown cleanup
-- ---------------------------------------------------------
-- Replaced textures survive a resource stop, so every one the pack
-- installs has to be released by hand or the props keep the DUI image.
local REPLACED_TEXTURES = {
    { 'neox_mrpd_r13_monitors',                   'neox_mrpd_monitor_screen_02' },
    { 'neox_mrpd_det_01',                         'neox_mrpd_monitor_screen_02' },
    { 'neox_mrpd06_r08_shooting_range_screen1',   'neox_mrpd_scoreboard_screen_01' },
    { 'neox_mrpd06_r08_shooting_range_screen2',   'neox_mrpd_monitor_screen_07' },
    { 'neox_mrpd06_r09_kill_house_screen',        'neox_mrpd_monitor_screen_09' },
    { 'neox_mrpd06_r09_kill_house_screen_02',     'neox_mrpd_scoreboard_screen_02' },
}

-- Any of these screens may be showing any of the textures below, so the
-- whole grid gets released.
local SCREEN_PROPS = {
    'neox_mrpd_prop_proj_screen',
    'neox_mrpd_prop_proj_screen2',
    'neox_mrpd_prop_proj_screen3',
    'neox_mrpd_prop_proj_screen4',
    'neox_mrpd_prop_proj_screen5',
    'neox_mrpd_prop_proj_screen6',
    'neox_mrpd_prop_proj_screen7',
    'neox_mrpd04_r03_laptop_screen',
    'neox_mrpd04_r13_laptop_screen',
    'neox_mrpd04_r12_laptop_screen',
    'neox_mrpd05_r04_laptop_screen',
    'neox_mrpd06_r05_laptop_screen',
    'neox_mrpd06_r09_laptop_screen',
}

local SCREEN_TEXTURES = {
    'neox_mrpd_white_screen_01',
    'neox_mrpd_white_screen_02',
    'neox_mrpd_white_screen_03',
    'neox_mrpd_white_screen_04',
    'neox_mrpd_white_screen_05',
    'neox_mrpd_white_screen_06',
    'neox_mrpd_white_screen_07',
    'neox_mrpd_monitor_screen_03',
    'neox_mrpd_monitor_screen_04',
    'neox_mrpd_monitor_screen_05',
    'neox_mrpd_monitor_screen_06',
    'neox_mrpd_monitor_screen_07',
    'neox_mrpd_monitor_screen_08',
}

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    SetNuiFocus(false, false)
    ClearTimecycleModifier()
    ClearFocus()
    RenderScriptCams(false, false, 0, true, true)

    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, 0)

    for _, entry in ipairs(REPLACED_TEXTURES) do
        RemoveReplaceTexture(entry[1], entry[2])
    end

    for _, prop in ipairs(SCREEN_PROPS) do
        for _, texture in ipairs(SCREEN_TEXTURES) do
            RemoveReplaceTexture(prop, texture)
        end
    end
end)

-- =========================================================
-- NEOX MRPD — KILL HOUSE (client)
-- =========================================================
-- CQB training run: pick a weapon, enter the start zone, shoot the
-- hostile targets without hitting a civilian, leave via the end zone.
-- Two DUI screens show the live run and the scoreboard.
-- =========================================================

if not NeoxMRPD.enabled('killhouse') then
    -- The screens keep whatever texture was last pushed, so release them.
    RemoveReplaceTexture('neox_mrpd06_r09_kill_house_screen', 'neox_mrpd_monitor_screen_09')
    RemoveReplaceTexture('neox_mrpd06_r09_kill_house_screen_02', 'neox_mrpd_scoreboard_screen_02')
    return
end

KH = KH or {}

local cfg = NeoxMRPD.Config.Killhouse

-- ---------------------------------------------------------
-- Config defaults
-- ---------------------------------------------------------
cfg.TargetModel = cfg.TargetModel or GetHashKey('neox_mrpd_prop_kh_target_01')
cfg.CivilianModel = cfg.CivilianModel or GetHashKey('neox_mrpd_prop_kh_target_02')
cfg.TotalTargets = cfg.TotalTargets or 16

-- Above this height the player is out of the course.
cfg.MaxZ = cfg.MaxZ or 17.0

cfg.Zones = cfg.Zones or {
    WeaponZone = {
        coords      = vector3(472.9, -1013.2, 15.27),
        radius      = 1.5,
        interactPos = vector4(472.08, -1013.3, 15.27, 275.98),
    },
    CinematicCam = {
        coords = vector3(470.912, -1013.387, 15.882),
        rot    = vector3(-1.26, -0.0, -87.911),
        fov    = 45.0,
    },
    StartZone = {
        coords = vector3(468.6, -1020.05, 15.27),
        radius = 2.0,
    },
    EndZone = {
        coords = vector3(474.92, -1020.73, 15.27),
        radius = 2.0,
    },
}

function KH.text(key)
    return cfg.Locale[key] or key
end

-- Defined by the original but never called; kept so the helper surface
-- matches.
function KH.drawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(screenX, screenY)

    local factor = string.len(text) / 370
    DrawRect(screenX, screenY + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- ---------------------------------------------------------
-- DUI screens
-- ---------------------------------------------------------
local mainDui = nil
local scoreboardDui = nil
local screensActive = false

-- Every prop that may be showing one of the two screens.
local SCREEN_PROPS = {
    'neox_mrpd06_r09_kill_house_screen',
    'neox_mrpd_kill_house_screen',
    'neox_mrpd_kill_house_screen2',
    'neox_mrpd06_r09_kill_house_screen2',
}

local appliedScreens = {}

local TEXTURE_POLL_MS = (cfg.Performance and cfg.Performance.texturePollMs) or 2000
local TEXTURE_REFRESH_MS = (cfg.Performance and cfg.Performance.textureRefreshMs) or 30000

local lastTextureRefresh = 0

function KH.clearScreens()
    for _, prop in ipairs(SCREEN_PROPS) do
        RemoveReplaceTexture(prop, 'neox_mrpd_kill_house_screen')
        RemoveReplaceTexture(prop, 'neox_mrpd_kill_house_screen2')
        appliedScreens[prop] = nil
    end
end

function KH.applyScreen(prop)
    RemoveReplaceTexture(prop, 'neox_mrpd_kill_house_screen')
    RemoveReplaceTexture(prop, 'neox_mrpd_kill_house_screen2')

    AddReplaceTexture(prop, 'neox_mrpd_kill_house_screen', 'killhouse_txd', 'killhouse_txn')
    AddReplaceTexture(prop, 'neox_mrpd_kill_house_screen2', 'killhouse_sb_txd', 'killhouse_sb_txn')

    appliedScreens[prop] = true
end

function KH.refreshScreens()
    if not (mainDui and scoreboardDui) then return end

    for _, prop in ipairs(SCREEN_PROPS) do
        RequestStreamedTextureDict(prop, false)
        KH.applyScreen(prop)
    end
end

-- Creates both browsers and binds them to runtime textures. Each one gets
-- 15 seconds to come up.
function KH.ensureDuis()
    if mainDui and scoreboardDui then return end

    if not mainDui then
        local url = string.format('nui://%s/html/killhouse/dui.html', GetCurrentResourceName())
        mainDui = CreateDui(url, 1024, 512)

        local deadline = GetGameTimer() + 15000
        while not IsDuiAvailable(mainDui) and deadline > GetGameTimer() do
            Citizen.Wait(50)
        end

        if IsDuiAvailable(mainDui) then
            local txd = CreateRuntimeTxd('killhouse_txd')
            CreateRuntimeTextureFromDuiHandle(txd, 'killhouse_txn', GetDuiHandle(mainDui))
        else
            print('[neox_killhouse] WARNING: Killhouse Main DUI not ready in 15s')
        end
    end

    if not scoreboardDui then
        local url = string.format('nui://%s/html/killhouse/scoreboard.html', GetCurrentResourceName())
        scoreboardDui = CreateDui(url, 1024, 512)

        local deadline = GetGameTimer() + 15000
        while not IsDuiAvailable(scoreboardDui) and deadline > GetGameTimer() do
            Citizen.Wait(50)
        end

        if IsDuiAvailable(scoreboardDui) then
            local txd = CreateRuntimeTxd('killhouse_sb_txd')
            CreateRuntimeTextureFromDuiHandle(txd, 'killhouse_sb_txn', GetDuiHandle(scoreboardDui))
        else
            print('[neox_killhouse] WARNING: Killhouse Scoreboard DUI not ready in 15s')
        end
    end
end

-- Builds the screens while the player is near them and tears them down
-- again once they walk away.
Citizen.CreateThread(function()
    local zone = (cfg.Zones and cfg.Zones.WeaponZone and cfg.Zones.WeaponZone.coords)
        or vector3(471.64, -1013.2, 15.27)

    while true do
        local coords = GetEntityCoords(PlayerPedId())

        local heightDelta = math.abs(coords.z - zone.z)
        local flat = #(vector2(coords.x, coords.y) - vector2(zone.x, zone.y))

        if heightDelta <= 4.0 and 25.0 > flat then
            if not screensActive then
                KH.ensureDuis()
                screensActive = true
                KH.refreshScreens()
                TriggerServerEvent('neox_killhouse:server:RequestState')
            else
                -- Replaced textures get dropped on a streaming hitch, so
                -- they are reapplied periodically.
                local now = GetGameTimer()
                if now - lastTextureRefresh > TEXTURE_REFRESH_MS then
                    lastTextureRefresh = now
                    KH.refreshScreens()
                end
            end

            Citizen.Wait(TEXTURE_POLL_MS)
        else
            if screensActive then
                screensActive = false
                KH.clearScreens()
            end

            Citizen.Wait(1500)
        end
    end
end)

RegisterNUICallback('kh_duiReady', function(_, cb)
    TriggerServerEvent('neox_killhouse:server:RequestState')
    cb('ok')
end)

RegisterNUICallback('kh_sbReady', function(_, cb)
    TriggerServerEvent('neox_killhouse:server:RequestState')
    cb('ok')
end)

RegisterNetEvent('neox_killhouse:client:SyncScoreboard', function(data)
    if scoreboardDui and screensActive then
        SendDuiMessage(scoreboardDui, json.encode({
            type = 'UPDATE_SCOREBOARD',
            data = data,
        }))
    end
end)

RegisterNetEvent('neox_killhouse:client:SyncScreen', function(payload)
    if mainDui and screensActive then
        SendDuiMessage(mainDui, json.encode(payload))
    end
end)

-- ---------------------------------------------------------
-- Session state
-- ---------------------------------------------------------
local sessionActive = false
local sessionStartedAt = 0
local score = 0
local hitTargets = {}
local givenWeapon = nil
local leftStartZone = false

function KH.rotationToDirection(rotation)
    local radians = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z,
    }

    return {
        x = -math.sin(radians.z) * math.abs(math.cos(radians.x)),
        y = math.cos(radians.z) * math.abs(math.cos(radians.x)),
        z = math.sin(radians.x),
    }
end

-- Shoots a ray from the gameplay camera; returns the hit flag and entity.
function KH.raycastFromCamera(distance)
    local camRot = GetGameplayCamRot()
    local camCoords = GetGameplayCamCoord()
    local direction = KH.rotationToDirection(camRot)

    local target = {
        x = camCoords.x + direction.x * distance,
        y = camCoords.y + direction.y * distance,
        z = camCoords.z + direction.z * distance,
    }

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        target.x, target.y, target.z,
        -1, PlayerPedId(), 0)

    local _, hit, _, _, entity = GetShapeTestResult(ray)

    return hit, entity
end

function KH.formatTime(totalSeconds)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format('%02d:%02d', minutes, seconds)
end

-- Weapon hashes, grouped for the scoreboard category.
local WEAPON_UNARMED = -1569615261

local CATEGORY_BY_WEAPON_HASH = {
    [453432689]   = 'Pistol',  [1593441988]  = 'Pistol',
    [584646201]   = 'Pistol',  [-771403250]  = 'Pistol',
    [-1076751822] = 'Pistol',

    [736523883]   = 'SMG',     [324215364]   = 'SMG',
    [171789620]   = 'SMG',     [-270015777]  = 'SMG',

    [487013001]   = 'Shotgun', [2017895192]  = 'Shotgun',
    [-1654528753] = 'Shotgun',

    [-2084633992] = 'Carbine', [-1063057011] = 'Carbine',

    [-1074790547] = 'Rifle',   [2132975508]  = 'Rifle',
    [-1357824103] = 'Rifle',
}

local CATEGORY_BY_WEAPON_GROUP = {
    [416676503]   = 'Pistol',
    [-957766203]  = 'SMG',
    [1159398501]  = 'SMG',
    [860032945]   = 'Shotgun',
    [970310017]   = 'Rifle',
    [-1212426201] = 'Sniper',
    [-1609124186] = 'Heavy',
}

-- Name lookup first, then a few exact names, then a substring guess;
-- falls back to whatever the player is holding.
function KH.weaponCategory(weaponName)
    if weaponName then
        local name = string.lower(tostring(weaponName))

        for _, entry in ipairs(cfg.WeaponSettings.GivenWeapons) do
            if string.lower(entry.name) == name then
                return entry.category or entry.label or 'Pistol'
            end
        end

        if name == 'weapon_pistol' then
            return 'Pistol'
        elseif name == 'weapon_smg' then
            return 'SMG'
        elseif name == 'weapon_pumpshotgun' then
            return 'Shotgun'
        elseif name == 'weapon_carbinerifle' then
            return 'Carbine'
        end

        if string.find(name, 'pistol') then
            return 'Pistol'
        elseif string.find(name, 'smg') or string.find(name, 'pdw') then
            return 'SMG'
        elseif string.find(name, 'shotgun') then
            return 'Shotgun'
        elseif string.find(name, 'carbine') then
            return 'Carbine'
        elseif string.find(name, 'rifle') then
            return 'Rifle'
        end
    end

    local weapon = GetSelectedPedWeapon(PlayerPedId())

    if weapon and weapon ~= WEAPON_UNARMED then
        local byHash = CATEGORY_BY_WEAPON_HASH[weapon]
        if byHash then return byHash end

        local byGroup = CATEGORY_BY_WEAPON_GROUP[GetWeapontypeGroup(weapon)]
        if byGroup then return byGroup end
    end

    return 'Pistol'
end

-- reason is 'finished' | 'failed' | 'canceled' | 'troll'
function KH.endSession(reason)
    if not sessionActive then return end
    sessionActive = false

    local elapsed = math.floor((GetGameTimer() - sessionStartedAt) / 1000)

    NUI.send('killhouse', { type = 'HIDE_UI' })

    if reason == 'finished' then
        local category = KH.weaponCategory(givenWeapon)

        Notify.send(string.format(KH.text('training_finished'),
            KH.formatTime(elapsed), score, cfg.TotalTargets), 'success', 6000)

        TriggerServerEvent('neox_killhouse:server:SaveScore',
            score, KH.formatTime(elapsed), elapsed, category)

        TriggerServerEvent('neox_killhouse:server:StopSession',
            'finished', KH.formatTime(elapsed), score, cfg.TotalTargets)

    elseif reason == 'failed' then
        Notify.send(KH.text('training_failed'), 'error', 6000)
        TriggerServerEvent('neox_killhouse:server:StopSession', 'failed', 0, 0)

    elseif reason == 'canceled' then
        Notify.send(KH.text('training_canceled'), 'error', 6000)
        TriggerServerEvent('neox_killhouse:server:StopSession', 'canceled', 0, 0)

    elseif reason == 'troll' then
        Notify.send(KH.text('troll_warning'), 'error', 6000)
        TriggerServerEvent('neox_killhouse:server:StopSession', 'troll', 0, 0)
    end

    if givenWeapon then
        Bridge.RemoveWeapon(givenWeapon)
        givenWeapon = nil
    end
end

-- ---------------------------------------------------------
-- Starting a run
-- ---------------------------------------------------------
-- The server owns the single-operator lock, so the client asks and waits
-- for StartResponse. startPending stops the request repeating every frame.
local startPending = false

function KH.requestStart()
    if sessionActive or startPending then return end

    startPending = true
    TriggerServerEvent('neox_killhouse:server:RequestStart')

    SetTimeout(3000, function()
        startPending = false
    end)
end

function KH.beginSession()
    sessionActive = true
    leftStartZone = false
    score = 0
    hitTargets = {}
    sessionStartedAt = GetGameTimer()

    Notify.send(KH.text('training_started'), 'success', 4000)

    NUI.send('killhouse', {
        type         = 'SHOW_UI',
        totalTargets = cfg.TotalTargets,
        ui_time      = KH.text('ui_time'),
        ui_targets   = KH.text('ui_targets'),
    })

    -- Timer / score readout, pushed only when a value actually changed.
    Citizen.CreateThread(function()
        local lastSeconds, lastScore = -1, -1

        while sessionActive do
            Citizen.Wait(250)

            local seconds = math.floor((GetGameTimer() - sessionStartedAt) / 1000)

            if seconds ~= lastSeconds or score ~= lastScore then
                NUI.send('killhouse', {
                    type         = 'UPDATE_UI',
                    time         = KH.formatTime(seconds),
                    score        = score,
                    totalTargets = cfg.TotalTargets,
                })

                TriggerServerEvent('neox_killhouse:server:SyncUpdate',
                    KH.formatTime(seconds), score, cfg.TotalTargets)

                lastSeconds = seconds
                lastScore = score
            end
        end
    end)

    -- Hit detection. Each target only counts once.
    Citizen.CreateThread(function()
        while sessionActive do
            Citizen.Wait(0)

            if IsPedShooting(PlayerPedId()) then
                local hit, entity = KH.raycastFromCamera(100.0)

                if hit == 1 and entity ~= 0 and not hitTargets[entity] then
                    local model = GetEntityModel(entity)

                    if model == cfg.TargetModel then
                        hitTargets[entity] = true
                        score = score + 1
                        PlaySoundFrontend(-1, 'SHOOTING_RANGE_ROUND_OVER', 'HUD_AWARDS', 1)

                    elseif model == cfg.CivilianModel then
                        hitTargets[entity] = true
                        PlaySoundFrontend(-1, 'Bed', 'WastedSounds', 1)
                        KH.endSession('failed')
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('neox_killhouse:client:StartResponse', function(granted, reason)
    startPending = false

    if granted then
        KH.beginSession()
    elseif reason == 'no_access' then
        Notify.send(KH.text('no_access'), 'error', 5000)
    else
        Notify.send(KH.text('operator_inside'), 'error', 5000)
    end
end)

-- ---------------------------------------------------------
-- Weapon selection
-- ---------------------------------------------------------
function KH.giveWeapon(weapon)
    givenWeapon = weapon

    Bridge.GiveWeapon(weapon, cfg.WeaponSettings.GivenAmmo, {
        noReload   = cfg.WeaponSettings and cfg.WeaponSettings.NoReload == true,
        giveAsItem = cfg.WeaponSettings and cfg.WeaponSettings.GiveAsItem == true,
    })

    Notify.send(KH.text('weapon_given'), 'success', 3000)
end

RegisterNetEvent('neox_killhouse:client:SelectWeapon', function(request)
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then return end

    -- qb-menu hands the payload through as a table.
    local weapon = request
    if type(request) == 'table' and request.weapon then
        weapon = request.weapon
    end

    if givenWeapon and givenWeapon ~= weapon then
        Bridge.RemoveWeapon(givenWeapon)
    end

    KH.giveWeapon(weapon)
end)

local weaponCam = nil

function KH.closeWeaponCam()
    if not weaponCam then return end

    NUI.focus('killhouse', false, false)
    RenderScriptCams(false, true, 1000, true, true)
    SetCamActive(weaponCam, false)
    DestroyCam(weaponCam, true)
    weaponCam = nil

    SetEntityVisible(PlayerPedId(), true, 0)
end

RegisterNUICallback('kh_selectWeapon', function(data, cb)
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then
        KH.closeWeaponCam()
        cb('ok')
        return
    end

    local weapon = data.weapon
    local ped = PlayerPedId()
    local interact = cfg.Zones.WeaponZone.interactPos

    SetEntityCoordsNoOffset(ped, interact.x, interact.y, interact.z, false, false, false)
    SetEntityHeading(ped, interact.w)

    KH.closeWeaponCam()

    RequestAnimDict('amb@prop_human_atm@male@enter')
    while not HasAnimDictLoaded('amb@prop_human_atm@male@enter') do
        Citizen.Wait(10)
    end

    TaskPlayAnim(ped, 'amb@prop_human_atm@male@enter', 'enter',
        8.0, -8.0, 1500, 0, 0, false, false, false)
    Citizen.Wait(1000)

    if givenWeapon and givenWeapon ~= weapon then
        Bridge.RemoveWeapon(givenWeapon)
    end

    KH.giveWeapon(weapon)
    cb('ok')
end)

RegisterNUICallback('kh_closeWeapons', function(_, cb)
    KH.closeWeaponCam()
    cb('ok')
end)

-- Config.Killhouse.MenuSystem picks the front end.
function KH.openWeaponMenu()
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then return end

    local menu = cfg.MenuSystem

    if menu == 'cinematic' then
        if weaponCam then return end

        SetEntityVisible(PlayerPedId(), false, 0)

        local camera = cfg.Zones.CinematicCam
        weaponCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

        SetCamCoord(weaponCam, camera.coords.x, camera.coords.y, camera.coords.z)
        SetCamRot(weaponCam, camera.rot.x, camera.rot.y, camera.rot.z, 2)
        SetCamFov(weaponCam, camera.fov)
        SetCamActive(weaponCam, true)
        RenderScriptCams(true, true, 1000, true, true)

        NUI.focus('killhouse', true, true)
        NUI.send('killhouse', { type = 'SHOW_WEAPONS' })

    elseif menu == 'qb-menu' then
        local options = {
            {
                header = KH.text('menu_header'),
                isMenuHeader = true,
            },
        }

        for _, weapon in ipairs(cfg.WeaponSettings.GivenWeapons) do
            options[#options + 1] = {
                header = weapon.label,
                txt    = KH.text('menu_desc'),
                params = {
                    event = 'neox_killhouse:client:SelectWeapon',
                    args  = { weapon = weapon.name },
                },
            }
        end

        options[#options + 1] = {
            header = KH.text('menu_cancel'),
            txt    = KH.text('menu_cancel_desc'),
            params = { event = 'qb-menu:client:closeMenu' },
        }

        exports['qb-menu']:openMenu(options)

    elseif menu == 'ox_lib' then
        local options = {}

        for _, weapon in ipairs(cfg.WeaponSettings.GivenWeapons) do
            table.insert(options, {
                title       = weapon.label,
                description = KH.text('menu_desc'),
                onSelect    = function()
                    TriggerEvent('neox_killhouse:client:SelectWeapon', weapon.name)
                end,
            })
        end

        lib.registerContext({
            id      = 'killhouse_weapon_menu',
            title   = KH.text('menu_header'),
            options = options,
        })

        lib.showContext('killhouse_weapon_menu')

    -- 'none' / anything else: hand over the first configured weapon.
    elseif #cfg.WeaponSettings.GivenWeapons > 0 then
        TriggerEvent('neox_killhouse:client:SelectWeapon',
            cfg.WeaponSettings.GivenWeapons[1].name)
    end
end

-- ---------------------------------------------------------
-- Interaction
-- ---------------------------------------------------------
function KH.removeTargets()
    Target.removeAll('neox_mrpd_kh_')
end

function KH.setupTarget()
    if not Target.enabled(cfg.Target.system, cfg.InteractionType) then return end

    KH.removeTargets()

    if not cfg.Zones.WeaponZone then return end
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then return end

    Target.addBox('neox_mrpd_kh_weapon', cfg.Zones.WeaponZone.coords,
        vec3(1.6, 1.2, 2.0), 270.0, {
            {
                icon        = 'fas fa-gun',
                label       = KH.text('target_weapon_menu'),
                distance    = 2.0,
                action      = function() KH.openWeaponMenu() end,
                canInteract = function() return not sessionActive end,
            },
        }, cfg.Target.system, cfg.InteractionType)
end

function KH.refreshOnSpawn()
    Citizen.Wait(1000)
    KH.refreshScreens()
    TriggerServerEvent('neox_killhouse:server:RequestState')
    KH.setupTarget()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', KH.refreshOnSpawn)
RegisterNetEvent('esx:playerLoaded', KH.refreshOnSpawn)
AddEventHandler('playerSpawned', KH.refreshOnSpawn)

Citizen.CreateThread(function()
    Citizen.Wait(1500)
    KH.setupTarget()
end)

-- Prompts and zone transitions. Sleeps long while nothing is in reach.
Citizen.CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local zone = cfg.Zones.WeaponZone.coords

        local heightDelta = math.abs(coords.z - zone.z)
        local flat = #(vector2(coords.x, coords.y) - vector2(zone.x, zone.y))

        if heightDelta > 3.5 or flat > 30.0 then
            Citizen.Wait(1500)
        else
            local idle = true
            local targetOn = Target.enabled(cfg.Target.system, cfg.InteractionType)

            -- [E] weapon prompt, only when targeting is off.
            if not (cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon) then
                if not givenWeapon and not sessionActive and not targetOn then
                    if #(coords - cfg.Zones.WeaponZone.coords) < cfg.Zones.WeaponZone.radius then
                        idle = false
                        Notify.show(KH.text('press_e_weapon'))

                        if IsControlJustReleased(0, 38) then
                            KH.openWeaponMenu()
                        end
                    end
                end
            end

            if not sessionActive then
                if #(coords - cfg.Zones.StartZone.coords) < cfg.Zones.StartZone.radius then
                    idle = false

                    -- Armed either with their own weapon or an issued one.
                    local armed = (cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon)
                        or givenWeapon

                    if armed ~= nil then
                        KH.requestStart()
                    end
                end
            end

            if sessionActive then
                if #(coords - cfg.Zones.EndZone.coords) < cfg.Zones.EndZone.radius then
                    idle = false
                    KH.endSession('finished')
                end

                -- Walking back into the start zone aborts the run, but only
                -- once they have actually left it.
                local fromStart = #(coords - cfg.Zones.StartZone.coords)

                if fromStart > cfg.Zones.StartZone.radius + 1.5 then
                    leftStartZone = true
                elseif leftStartZone and fromStart < cfg.Zones.StartZone.radius then
                    idle = false
                    KH.endSession('canceled')
                end
            end

            Citizen.Wait(idle and 400 or 0)
        end
    end
end)

-- Watchdog: cancels a run if the player dies or leaves the course, and
-- confiscates an issued weapon carried out of bounds.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if sessionActive then
            local zone = cfg.Zones.WeaponZone.coords
            local flat = #(vector2(coords.x, coords.y) - vector2(zone.x, zone.y))

            if coords.z >= cfg.MaxZ or flat > 35.0 or IsEntityDead(ped) then
                KH.endSession('canceled')
            end

        elseif givenWeapon and coords.z >= cfg.MaxZ then
            Bridge.RemoveWeapon(givenWeapon)
            givenWeapon = nil
            Notify.send(KH.text('troll_warning'), 'error', 5000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if sessionActive then
        TriggerServerEvent('neox_killhouse:server:StopSession', 'canceled', 0, 0)
    end

    if givenWeapon then
        Bridge.RemoveWeapon(givenWeapon)
        givenWeapon = nil
    end

    KH.removeTargets()
    KH.clearScreens()

    if mainDui then
        DestroyDui(mainDui)
        mainDui = nil
    end

    if scoreboardDui then
        DestroyDui(scoreboardDui)
        scoreboardDui = nil
    end
end)

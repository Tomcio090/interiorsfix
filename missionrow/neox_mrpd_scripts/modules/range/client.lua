-- =========================================================
-- NEOX MRPD — SHOOTING RANGE (client)
-- =========================================================
-- Six booths with a movable target each, plus an "AimLab" timed
-- challenge on one booth where targets pop up one at a time. Two DUI
-- screens show the live run and the scoreboard; a laptop prop acts as
-- the control surface.
-- =========================================================

if not NeoxMRPD.enabled('range') then
    RemoveReplaceTexture('neox_mrpd06_r08_shooting_range_screen1', 'neox_mrpd_scoreboard_screen_01')
    RemoveReplaceTexture('neox_mrpd06_r08_shooting_range_screen2', 'neox_mrpd_monitor_screen_07')
    return
end

Range = Range or {}

local cfg = NeoxMRPD.Config.Range

-- ---------------------------------------------------------
-- Built-in defaults
-- ---------------------------------------------------------
local DEFAULT_DUI_SCREENS = {
    Scoreboard = {
        textureDict = 'neox_mrpd06_r08_shooting_range_screen1',
        textureName = 'neox_mrpd_shooting_range_screen1',
        duiWidth    = 1024,
        duiHeight   = 576,
    },
    Laptop = {
        textureDict = 'neox_mrpd06_r08_shooting_range_screen2',
        textureName = 'neox_mrpd_shooting_range_screen2',
        duiWidth    = 1024,
        duiHeight   = 576,
    },
}

-- ActiveRot faces the shooter, IdleRot turns the target edge-on.
local AIMLAB_DEFAULTS = {
    TargetModel     = GetHashKey('neox_mrpd_prop_target_03'),
    BoothId         = 4,
    BoothCoords     = vector3(483.97, -1017.74, 18.67),
    DurationSeconds = 20,
    ActiveRot       = vector3(0.0, 0.0, 0.0),
    IdleRot         = vector3(0.0, 90.0, 0.0),
    LaptopHitbox    = { width = 0.73, height = 0.85, x = 0.49, y = 0.55 },
    Targets = {
        { id = 1, pos = vector3(495.8154, -1020.193, 17.74447), heading = 0.0 },
        { id = 2, pos = vector3(495.8154, -1018.959, 17.74447), heading = 0.0 },
        { id = 3, pos = vector3(495.8154, -1017.709, 17.74447), heading = 0.0 },
        { id = 4, pos = vector3(495.8154, -1016.478, 17.74447), heading = 0.0 },
        { id = 5, pos = vector3(495.8154, -1015.24, 17.74447), heading = 0.0 },
        { id = 6, pos = vector3(495.8154, -1014.025, 17.74447), heading = 0.0 },
        { id = 7, pos = vector3(495.8154, -1012.791, 17.74447), heading = 0.0 },
    },
}

cfg.TargetModel = cfg.TargetModel or GetHashKey('neox_mrpd_prop_target_01')
cfg.DuiScreens = cfg.DuiScreens or DEFAULT_DUI_SCREENS

cfg.AimLab = cfg.AimLab or {}

for _, key in ipairs({
    'TargetModel', 'BoothId', 'BoothCoords', 'DurationSeconds',
    'ActiveRot', 'IdleRot', 'LaptopHitbox', 'Targets',
}) do
    cfg.AimLab[key] = cfg.AimLab[key] or AIMLAB_DEFAULTS[key]
end

cfg.TargetLimits = cfg.TargetLimits or {
    minX     = 486.0,
    maxX     = 499.0,
    moveStep = 0.15,
}

cfg.Controls = cfg.Controls or {
    MoveForward  = 172,
    MoveBackward = 173,
}

-- ---------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------
function Range.text(key)
    return cfg.Locale[key] or key
end

function Range.drawText3D(x, y, z, text)
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

function Range.clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if maxValue < value then return maxValue end
    return value
end

function Range.toHash(model)
    if type(model) == 'number' then return model end
    return GetHashKey(tostring(model))
end

function Range.formatTime(totalSeconds)
    totalSeconds = math.max(0, math.floor(tonumber(totalSeconds) or 0))

    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60

    return string.format('%02d:%02d', minutes, seconds)
end

function Range.aimLabDuration()
    return (cfg.AimLab and cfg.AimLab.DurationSeconds) or 60
end

-- ---------------------------------------------------------
-- State
-- ---------------------------------------------------------
local laptopDui = nil
local scoreboardDui = nil
local screensActive = false

local laptopViewActive = false
local laptopCam = nil

local weaponMenuActive = false
local weaponMenuCam = nil

local pendingAimLabMode = 'single'

local SCREEN_PROPS = {
    'neox_mrpd06_r08_shooting_range_screen1',
    'neox_mrpd06_r08_shooting_range_screen2',
    'neox_mrpd_shooting_range_screen',
    'neox_mrpd_shooting_range_screen1',
    'neox_mrpd_shooting_range_screen2',
}

local appliedScreens = {}

local TEXTURE_POLL_MS = (cfg.Performance and cfg.Performance.texturePollMs) or 2000
local TEXTURE_REFRESH_MS = (cfg.Performance and cfg.Performance.textureRefreshMs) or 30000
local lastTextureRefresh = 0

-- boothIndex -> prop handle / remembered position
local boothTargets = {}
local boothTargetPos = {}

-- aimlab target index -> prop handle / popped flag
local aimLabTargets = {}
local aimLabPopped = {}

local aimLabActive = false
local aimLabIsMine = false
local aimLabState = {
    active     = false,
    player     = nil,
    playerName = '',
    mode       = 'single',
    phase      = 'idle',
}
local aimLabMode = 'single'
local aimLabHits = 0
local aimLabShots = 0
local aimLabRunning = false
local aimLabCountdown = false

local givenWeapon = nil

local targetsSpawned = false
local spawningTargets = false

local inBooth = false
local currentBoothId = nil

-- boothId -> { { rel, spawnTime }, ... }
local hitMarkers = {}

-- ⚠ Accidental global in the original (no `local`). Only this file reads
-- it, but the name is preserved rather than localised in case anything
-- outside the pack depends on it. See the refactor notes.
aimlabStartTime = aimlabStartTime or 0

-- ---------------------------------------------------------
-- Screens
-- ---------------------------------------------------------
function Range.clearScreens()
    for _, prop in ipairs(SCREEN_PROPS) do
        RemoveReplaceTexture(prop, 'neox_mrpd_shooting_range_screen1')
        RemoveReplaceTexture(prop, 'neox_mrpd_shooting_range_screen2')
        appliedScreens[prop] = nil
    end
end

function Range.applyScreen(prop)
    RemoveReplaceTexture(prop, 'neox_mrpd_shooting_range_screen1')
    RemoveReplaceTexture(prop, 'neox_mrpd_shooting_range_screen2')

    AddReplaceTexture(prop, 'neox_mrpd_shooting_range_screen1',
        'shootingrange_sb_txd', 'shootingrange_sb_txn')
    AddReplaceTexture(prop, 'neox_mrpd_shooting_range_screen2',
        'shootingrange_txd', 'shootingrange_txn')

    appliedScreens[prop] = true
end

function Range.refreshScreens()
    if not (laptopDui and scoreboardDui) then return end

    for _, prop in ipairs(SCREEN_PROPS) do
        RequestStreamedTextureDict(prop, false)
        Range.applyScreen(prop)
    end
end

function Range.ensureDuis()
    if laptopDui and scoreboardDui then return end

    if not laptopDui then
        local url = string.format('nui://%s/html/range/dui.html', GetCurrentResourceName())
        laptopDui = CreateDui(url, 1024, 512)

        local deadline = GetGameTimer() + 15000
        while not IsDuiAvailable(laptopDui) and deadline > GetGameTimer() do
            Citizen.Wait(50)
        end

        if IsDuiAvailable(laptopDui) then
            local txd = CreateRuntimeTxd('shootingrange_txd')
            CreateRuntimeTextureFromDuiHandle(txd, 'shootingrange_txn', GetDuiHandle(laptopDui))
        else
            print('[neox_shootingrange] WARNING: Range Laptop DUI not ready in 15s')
        end
    end

    if not scoreboardDui then
        local url = string.format('nui://%s/html/range/scoreboard.html', GetCurrentResourceName())
        scoreboardDui = CreateDui(url, 1024, 512)

        local deadline = GetGameTimer() + 15000
        while not IsDuiAvailable(scoreboardDui) and deadline > GetGameTimer() do
            Citizen.Wait(50)
        end

        if IsDuiAvailable(scoreboardDui) then
            local txd = CreateRuntimeTxd('shootingrange_sb_txd')
            CreateRuntimeTextureFromDuiHandle(txd, 'shootingrange_sb_txn', GetDuiHandle(scoreboardDui))
        else
            print('[neox_shootingrange] WARNING: Range Scoreboard DUI not ready in 15s')
        end
    end
end

function Range.onDuiReady(_, cb)
    TriggerServerEvent('neox_shootingrange:server:RequestState')
    cb('ok')
end

RegisterNUICallback('rng_duiReady', Range.onDuiReady)
RegisterNUICallback('rng_sbReady', Range.onDuiReady)

RegisterNUICallback('rng_requestMyStats', function(_, cb)
    TriggerServerEvent('neox_shootingrange:server:RequestMyStats')
    cb('ok')
end)

RegisterNetEvent('neox_shootingrange:client:SyncScoreboard', function(data)
    if scoreboardDui and screensActive then
        SendDuiMessage(scoreboardDui, json.encode({
            type = 'UPDATE_SCOREBOARD',
            data = data,
        }))
    end
end)

RegisterNetEvent('neox_shootingrange:client:SyncScreen', function(payload)
    if laptopDui and screensActive then
        SendDuiMessage(laptopDui, json.encode(payload))
    end
end)

-- ---------------------------------------------------------
-- Targets
-- ---------------------------------------------------------
function Range.removeGivenWeapon(ped)
    ped = ped or PlayerPedId()

    if givenWeapon then
        Bridge.RemoveWeapon(givenWeapon)
        givenWeapon = nil
        Notify.send(Range.text('weapon_removed'), 'error', 3000)
    end
end

-- Eases a prop between two rotations; used to swivel aimlab targets.
function Range.animateRotation(entity, fromRot, toRot, durationMs)
    if not (entity and DoesEntityExist(entity)) then return end

    durationMs = durationMs or 220

    Citizen.CreateThread(function()
        local startedAt = GetGameTimer()

        while DoesEntityExist(entity) do
            local elapsed = GetGameTimer() - startedAt
            local progress = math.min(1.0, elapsed / durationMs)
            local eased = progress * (2 - progress)

            SetEntityRotation(entity,
                fromRot.x + (toRot.x - fromRot.x) * eased,
                fromRot.y + (toRot.y - fromRot.y) * eased,
                fromRot.z + (toRot.z - fromRot.z) * eased,
                2, true)

            if progress >= 1.0 then break end

            Citizen.Wait(10)
        end
    end)
end

function Range.setBoothTargetsVisible(visible)
    for _, entity in pairs(boothTargets) do
        if DoesEntityExist(entity) then
            SetEntityVisible(entity, visible, 0)
        end
    end
end

function Range.clearBoothTargets()
    for _, entity in pairs(boothTargets) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    boothTargets = {}
    boothTargetPos = {}
end

function Range.resetAimLabTargets()
    for _, entity in pairs(aimLabTargets) do
        if DoesEntityExist(entity) then
            SetEntityRotation(entity,
                cfg.AimLab.IdleRot.x, cfg.AimLab.IdleRot.y, cfg.AimLab.IdleRot.z, 2, true)
            SetEntityVisible(entity, true, 0)
        end
    end

    aimLabTargets = {}
    aimLabPopped = {}
end

-- Reuses a target prop already standing at this lane, deleting any
-- duplicates, and spawns one only when none is there.
function Range.acquireTarget(pool, model, spawnPos, laneY, center, heading)
    local matches = {}

    for _, entity in ipairs(pool) do
        if DoesEntityExist(entity) and GetEntityModel(entity) == model then
            local entityCoords = GetEntityCoords(entity)

            if #(entityCoords - center) <= 30.0
                and math.abs(entityCoords.y - laneY) <= 0.55
            then
                table.insert(matches, entity)
            end
        end
    end

    for index = 2, #matches do
        local duplicate = matches[index]
        SetEntityAsMissionEntity(duplicate, true, true)
        SetEntityVisible(duplicate, false, 0)
        SetEntityCoords(duplicate, 0.0, 0.0, -500.0, false, false, false, false)
        DeleteEntity(duplicate)
    end

    local entity = matches[1]

    if not (entity and DoesEntityExist(entity)) then
        RequestModel(model)

        local tries = 0
        while not HasModelLoaded(model) and tries < 50 do
            Citizen.Wait(10)
            tries = tries + 1
        end

        if HasModelLoaded(model) then
            entity = CreateObject(model,
                spawnPos.x + 0.0, laneY + 0.0, spawnPos.z + 0.0,
                false, false, false)

            if entity and entity ~= 0 and DoesEntityExist(entity) then
                SetEntityHeading(entity, (heading or 0.0) + 0.0)
                SetEntityAsMissionEntity(entity, true, true)
            end
        end
    end

    return entity
end

function Range.spawnTargets()
    if spawningTargets then return end
    spawningTargets = true

    local center = vector3(485.0, -1018.0, 18.67)
    local boothModel = Range.toHash(cfg.TargetModel)
    local aimLabModel = Range.toHash(cfg.AimLab.TargetModel)
    local pool = GetGamePool('CObject')

    for index, booth in ipairs(cfg.Booths) do
        local spawnPos = boothTargetPos[index] or booth.targetPos
        local laneY = booth.targetPos.y

        local entity = Range.acquireTarget(pool, boothModel, spawnPos, laneY,
            center, booth.targetHeading)

        if entity and DoesEntityExist(entity) then
            FreezeEntityPosition(entity, true)
            SetEntityLodDist(entity, 500)
            SetEntityVisible(entity, not aimLabActive, 0)

            if cfg.TargetAlpha then
                SetEntityAlpha(entity, cfg.TargetAlpha, false)
            end

            boothTargets[index] = entity
            boothTargetPos[index] = GetEntityCoords(entity)
        end
    end

    for index, target in ipairs(cfg.AimLab.Targets) do
        local entity = Range.acquireTarget(pool, aimLabModel, target.pos, target.pos.y,
            center, target.heading)

        if entity and DoesEntityExist(entity) then
            FreezeEntityPosition(entity, true)
            SetEntityLodDist(entity, 500)
            SetEntityVisible(entity, true, 0)

            if cfg.TargetAlpha then
                SetEntityAlpha(entity, cfg.TargetAlpha, false)
            end

            -- A target already popped up in a live run keeps its rotation.
            if not (aimLabActive and aimLabPopped[index]) then
                SetEntityRotation(entity,
                    cfg.AimLab.IdleRot.x, cfg.AimLab.IdleRot.y, cfg.AimLab.IdleRot.z, 2, true)
            end

            aimLabTargets[index] = entity
        end
    end

    spawningTargets = false
end

-- ---------------------------------------------------------
-- Ending an AimLab run
-- ---------------------------------------------------------
function Range.stopAimLab(notifyCancelled)
    aimLabRunning = false
    aimLabCountdown = false
    aimLabIsMine = false

    if cfg.WeaponSettings and cfg.WeaponSettings.NoReload then
        SetPedInfiniteAmmoClip(PlayerPedId(), false)
    end

    local timeText = Range.formatTime(Range.aimLabDuration())

    NUI.send('range', { type = 'HIDE_UI' })
    NUI.send('range', { type = 'HIDE_GTA_COUNTDOWN' })

    Range.removeGivenWeapon(PlayerPedId())

    for _, entity in pairs(aimLabTargets) do
        if DoesEntityExist(entity) then
            SetEntityRotation(entity,
                cfg.AimLab.IdleRot.x, cfg.AimLab.IdleRot.y, cfg.AimLab.IdleRot.z, 2, true)
        end
    end

    aimLabPopped = {}
    Range.setBoothTargetsVisible(true)

    TriggerServerEvent('neox_shootingrange:server:StopAimLab', timeText)

    NUI.send('range', { type = 'SYNC_IDLE', time = timeText })
    TriggerEvent('neox_shootingrange:client:SyncScreen', { type = 'SYNC_IDLE', time = timeText })

    if notifyCancelled then
        Notify.send(Range.text('aimlab_canceled'), 'error', 4000)
    end
end

-- ---------------------------------------------------------
-- Screen / target streaming
-- ---------------------------------------------------------
Citizen.CreateThread(function()
    local center = vector3(485.0, -1018.0, 18.67)

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local heightDelta = math.abs(coords.z - center.z)
        local flat = #(vector2(coords.x, coords.y) - vector2(center.x, center.y))

        if heightDelta <= 4.0 and 25.0 > flat then
            if not screensActive then
                Range.ensureDuis()
                screensActive = true
                Range.refreshScreens()
                TriggerServerEvent('neox_shootingrange:server:RequestState')
            else
                local now = GetGameTimer()
                if now - lastTextureRefresh > TEXTURE_REFRESH_MS then
                    lastTextureRefresh = now
                    Range.refreshScreens()
                end
            end

            if not targetsSpawned then
                Range.spawnTargets()
                targetsSpawned = true
            end

            -- Walking out of the range ends a claimed or running session.
            if aimLabRunning or (aimLabActive and aimLabIsMine) then
                if flat > 12.0 then
                    Range.stopAimLab(true)
                end
            end

            if givenWeapon and flat > 12.0 then
                Range.removeGivenWeapon(ped)
            end

            Citizen.Wait(TEXTURE_POLL_MS)
        else
            if targetsSpawned or screensActive then
                Range.clearBoothTargets()
                Range.resetAimLabTargets()
                targetsSpawned = false
                screensActive = false
                Range.clearScreens()
            end

            Citizen.Wait(1500)
        end
    end
end)

-- ---------------------------------------------------------
-- Target zones
-- ---------------------------------------------------------
function Range.removeTargets()
    Target.removeAll('neox_mrpd_range_')
end

function Range.setupTargets()
    if not Target.enabled(cfg.Target.system, cfg.InteractionType) then return end

    Range.removeTargets()

    if cfg.Zones.WeaponZone
        and not (cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon)
    then
        Target.addBox('neox_mrpd_range_weapon', cfg.Zones.WeaponZone.coords,
            vec3(1.6, 1.2, 2.0), 90.0, {
                {
                    icon        = 'fas fa-gun',
                    label       = Range.text('target_weapon_menu'),
                    distance    = 2.0,
                    action      = function()
                        if Range.openWeaponMenu then
                            Range.openWeaponMenu()
                        end
                    end,
                    -- ⚠ The decompiled expression was `not x or x`, a tautology,
                    -- so this is always true. openWeaponMenu does its own
                    -- aimlab check, so the option is still safe to show.
                    canInteract = function()
                        return not aimLabActive or aimLabActive
                    end,
                },
            }, cfg.Target.system, cfg.InteractionType)
    end

    if cfg.Zones.LaptopZone then
        Target.addBox('neox_mrpd_range_laptop', cfg.Zones.LaptopZone.coords,
            vec3(1.2, 1.2, 1.5), 90.0, {
                {
                    icon     = 'fas fa-laptop',
                    label    = Range.text('target_laptop'),
                    distance = 2.0,
                    action   = function()
                        if Range.openLaptop then
                            Range.openLaptop()
                        end
                    end,
                },
            }, cfg.Target.system, cfg.InteractionType)
    end

    for index, booth in ipairs(cfg.Booths) do
        local options = {
            {
                icon     = 'fas fa-crosshairs',
                label    = string.format(Range.text('target_booth'), index),
                distance = 2.0,
                action   = function()
                    TriggerServerEvent('neox_shootingrange:server:RequestBooth', booth.id)
                end,
                -- ⚠ `activeSession` is a global this resource never defines,
                -- and `not x and x` is always nil, so this option never
                -- appears while a target resource is active. Preserved
                -- verbatim -- see the refactor notes.
                canInteract = function()
                    return not activeSession and activeSession
                end,
            },
        }

        if index == (cfg.AimLab.BoothId or 4) then
            options[#options + 1] = {
                icon     = 'fas fa-bullseye',
                label    = Range.text('target_aimlab'),
                distance = 2.0,
                action   = function()
                    if Range.startAimLab then
                        Range.startAimLab()
                    end
                end,
                -- ⚠ Same artifact: the innermost test is `not x and x`,
                -- always nil, so this never appears either.
                canInteract = function()
                    if aimLabActive and aimLabIsMine then
                        return not aimLabCountdown and aimLabCountdown
                    end
                    return aimLabActive and aimLabIsMine
                end,
            }
        end

        Target.addBox('neox_mrpd_range_booth_' .. index, booth.coords,
            vec3(1.2, 1.2, 2.0), 0.0, options,
            cfg.Target.system, cfg.InteractionType)
    end
end

function Range.destroyDuis()
    Range.clearScreens()

    if laptopDui then
        DestroyDui(laptopDui)
        laptopDui = nil
    end

    if scoreboardDui then
        DestroyDui(scoreboardDui)
        scoreboardDui = nil
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Range.removeTargets()
    Range.setBoothTargetsVisible(true)
    Range.clearBoothTargets()
    Range.resetAimLabTargets()
    Range.destroyDuis()
end)

function Range.refreshOnSpawn()
    Citizen.Wait(1000)
    Range.refreshScreens()
    TriggerServerEvent('neox_shootingrange:server:RequestState')
    Range.setupTargets()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', Range.refreshOnSpawn)
RegisterNetEvent('esx:playerLoaded', Range.refreshOnSpawn)
AddEventHandler('playerSpawned', Range.refreshOnSpawn)

Citizen.CreateThread(function()
    Citizen.Wait(1500)
    Range.setupTargets()
end)

-- ---------------------------------------------------------
-- Target position sync
-- ---------------------------------------------------------
RegisterNetEvent('neox_shootingrange:client:SyncTargetPos', function(boothIndex, x)
    local entity = boothTargets[boothIndex]
    if not (entity and DoesEntityExist(entity)) then return end

    local coords = GetEntityCoords(entity)

    SetEntityCoordsNoOffset(entity, x, coords.y, coords.z, false, false, false)
    boothTargetPos[boothIndex] = vector3(x, coords.y, coords.z)
end)

RegisterNetEvent('neox_shootingrange:client:SyncAllTargetPositions', function(positions)
    if not positions then return end

    for boothIndex, x in pairs(positions) do
        local booth = cfg.Booths[boothIndex]

        if booth then
            local entity = boothTargets[boothIndex]
            local laneY = booth.targetPos.y
            local laneZ = booth.targetPos.z

            boothTargetPos[boothIndex] = vector3(x, laneY, laneZ)

            if entity and DoesEntityExist(entity) then
                SetEntityCoordsNoOffset(entity, x, laneY, laneZ, false, false, false)
            end
        end
    end
end)

RegisterNetEvent('neox_shootingrange:client:SyncAimLabState', function(state)
    aimLabState = state or {
        active     = false,
        player     = nil,
        playerName = '',
        mode       = 'single',
        phase      = 'idle',
    }

    aimLabActive = aimLabState.active
    aimLabMode = aimLabState.mode or 'single'

    if aimLabActive then
        Range.setBoothTargetsVisible(false)
        Range.spawnTargets()

        if aimLabState.player == GetPlayerServerId(PlayerId()) then
            aimLabIsMine = true

            local boothId = cfg.AimLab.BoothId or 4
            local boothCoords = (cfg.Booths[boothId] and cfg.Booths[boothId].coords)
                or cfg.AimLab.BoothCoords

            SetNewWaypoint(boothCoords.x, boothCoords.y)
            Notify.send(Range.text('aimlab_goto_booth'), 'primary', 6000)
        else
            aimLabIsMine = false

            NUI.send('range', { type = 'SYNC_AIMLAB_BUSY', player = aimLabState.playerName })
            TriggerEvent('neox_shootingrange:client:SyncScreen',
                { type = 'SYNC_AIMLAB_BUSY', player = aimLabState.playerName })
        end
    else
        aimLabIsMine = false
        aimLabRunning = false
        aimLabCountdown = false

        NUI.send('range', { type = 'HIDE_UI' })
        NUI.send('range', { type = 'HIDE_GTA_COUNTDOWN' })

        Range.setBoothTargetsVisible(true)

        -- Called twice in the original; spawnTargets is idempotent.
        Range.spawnTargets()
        Range.spawnTargets()

        NUI.send('range', { type = 'SYNC_IDLE' })
        TriggerEvent('neox_shootingrange:client:SyncScreen', { type = 'SYNC_IDLE' })
    end
end)

-- ---------------------------------------------------------
-- Laptop view
-- ---------------------------------------------------------
local LAPTOP_BLOCKED_CONTROLS = { 1, 2, 24, 25, 30, 31, 36, 44, 142, 106, 200, 177 }

function Range.closeLaptop()
    if not laptopViewActive then return end
    laptopViewActive = false

    ClearFocus()
    RenderScriptCams(false, true, 500, true, true)

    if laptopCam then
        DestroyCam(laptopCam, false)
        laptopCam = nil
    end

    FreezeEntityPosition(PlayerPedId(), false)
end

function Range.runLaptopLoop()
    local duiWidth = cfg.DuiScreens.Laptop.duiWidth
    local duiHeight = cfg.DuiScreens.Laptop.duiHeight

    while laptopViewActive do
        Citizen.Wait(0)

        DisablePlayerFiring(PlayerId(), true)

        for _, control in ipairs(LAPTOP_BLOCKED_CONTROLS) do
            DisableControlAction(0, control, true)
        end

        SetMouseCursorActiveThisFrame()
        SetMouseCursorSprite(1)

        local hitbox = cfg.AimLab.LaptopHitbox
            or { width = 0.73, height = 0.85, x = 0.49, y = 0.55 }

        local left = hitbox.x - hitbox.width / 2
        local top = hitbox.y - hitbox.height / 2

        local cursorX = GetDisabledControlNormal(0, 239)
        local cursorY = GetDisabledControlNormal(0, 240)

        if cfg.Debug then
            DrawRect(hitbox.x, hitbox.y, hitbox.width, hitbox.height, 255, 0, 0, 90)
            DrawRect(cursorX, cursorY, 0.008, 0.008, 102, 252, 241, 255)

            local duiX = math.floor(
                Range.clamp((cursorX - left) / hitbox.width, 0.0, 1.0) * duiWidth)
            local duiY = math.floor(
                Range.clamp((cursorY - top) / hitbox.height, 0.0, 1.0) * duiHeight)

            Range.drawText3D(
                cfg.Zones.LaptopZone.coords.x,
                cfg.Zones.LaptopZone.coords.y,
                cfg.Zones.LaptopZone.coords.z + 0.35,
                string.format(
                    'Cursor: (%.3f, %.3f) | DUI Mapped: (%d, %d) | Hitbox: (x=%.2f, y=%.2f, w=%.2f, h=%.2f)',
                    cursorX, cursorY, duiX, duiY,
                    hitbox.x, hitbox.y, hitbox.width, hitbox.height))
        end

        if laptopDui then
            local duiX = math.floor(
                Range.clamp((cursorX - left) / hitbox.width, 0.0, 1.0) * duiWidth)
            local duiY = math.floor(
                Range.clamp((cursorY - top) / hitbox.height, 0.0, 1.0) * duiHeight)

            SendDuiMouseMove(laptopDui, duiX, duiY)

            if IsDisabledControlJustPressed(0, 24) then
                SendDuiMouseDown(laptopDui, 'left')
            end

            if IsDisabledControlJustReleased(0, 24) then
                SendDuiMouseUp(laptopDui, 'left')
            end
        end

        if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
            Range.closeLaptop()
        end
    end
end

function Range.openLaptop()
    if laptopViewActive then return end
    laptopViewActive = true

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    if not aimLabActive then
        TriggerEvent('neox_shootingrange:client:SyncScreen', { type = 'SYNC_IDLE' })
    elseif not aimLabIsMine then
        TriggerEvent('neox_shootingrange:client:SyncScreen',
            { type = 'SYNC_AIMLAB_BUSY', player = aimLabState.playerName })
    end

    local camera = cfg.Zones.LaptopCam or {
        coords = vector3(480.532, -1014.596, 18.895),
        rot    = vector3(-12.095, 0.0, 87.029),
        fov    = 45.0,
    }

    laptopCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(laptopCam, camera.coords.x, camera.coords.y, camera.coords.z)
    SetCamRot(laptopCam, camera.rot.x, camera.rot.y, camera.rot.z, 2)
    SetCamFov(laptopCam, camera.fov)
    SetCamActive(laptopCam, true)
    RenderScriptCams(true, true, 800, true, true)

    Citizen.CreateThread(Range.runLaptopLoop)
end

-- ---------------------------------------------------------
-- Weapons
-- ---------------------------------------------------------
local CATEGORY_BY_WEAPON_GROUP = {
    [416676503]   = 'Pistol',
    [-957766203]  = 'SMG',
    [1159398501]  = 'SMG',
    [860032945]   = 'Shotgun',
    [970310017]   = 'Carbine',
    [-1212426201] = 'Sniper',
}

function Range.weaponCategory(weaponName)
    if weaponName then
        local name = string.lower(tostring(weaponName))

        if string.find(name, 'sniper') then
            return 'Sniper'
        elseif string.find(name, 'carbine')
            or string.find(name, 'ar')
            or string.find(name, 'rifle')
        then
            return 'Carbine'
        elseif string.find(name, 'smg') then
            return 'SMG'
        elseif string.find(name, 'shotgun') then
            return 'Shotgun'
        elseif string.find(name, 'pistol') then
            return 'Pistol'
        end
    end

    local group = GetWeapontypeGroup(GetSelectedPedWeapon(PlayerPedId()))
    return CATEGORY_BY_WEAPON_GROUP[group] or 'Pistol'
end

function Range.closeWeaponMenu()
    if weaponMenuCam then
        RenderScriptCams(false, true, 800, true, true)
        DestroyCam(weaponMenuCam, false)
        weaponMenuCam = nil
    end

    weaponMenuActive = false

    SetEntityVisible(PlayerPedId(), true, 0)
    NUI.focus('range', false, false)
    NUI.send('range', { type = 'HIDE_WEAPONS' })
end

-- Backing out of the weapon menu with a claimed-but-unstarted session and
-- no weapon in hand releases the session.
function Range.cancelWeaponSelect()
    Range.closeWeaponMenu()

    if aimLabActive and aimLabIsMine and not aimLabRunning and not givenWeapon then
        Range.stopAimLab(true)
    end
end

RegisterNUICallback('rng_closeWeapons', function(_, cb)
    Range.cancelWeaponSelect()
    cb('ok')
end)

RegisterNetEvent('neox_shootingrange:client:CancelWeaponSelect', Range.cancelWeaponSelect)

function Range.openWeaponMenu()
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then return end

    if aimLabActive and not aimLabIsMine then
        Notify.send(string.format(
            Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        return
    end

    local menu = cfg.MenuSystem

    if menu == 'cinematic' then
        SetEntityVisible(PlayerPedId(), false, 0)
        weaponMenuActive = true

        local camera = cfg.Zones.CinematicCam

        weaponMenuCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(weaponMenuCam, camera.coords.x, camera.coords.y, camera.coords.z)
        SetCamRot(weaponMenuCam, camera.rot.x, camera.rot.y, camera.rot.z, 2)
        SetCamFov(weaponMenuCam, camera.fov)
        SetCamActive(weaponMenuCam, true)
        RenderScriptCams(true, true, 1000, true, true)

        NUI.focus('range', true, true)
        NUI.send('range', { type = 'SHOW_WEAPONS' })

    elseif menu == 'qb-menu' then
        local options = {
            {
                header = Range.text('menu_header'),
                isMenuHeader = true,
            },
        }

        for _, weapon in ipairs(cfg.WeaponSettings.GivenWeapons) do
            options[#options + 1] = {
                header = weapon.label,
                txt    = Range.text('menu_desc'),
                params = {
                    event = 'neox_shootingrange:client:SelectWeapon',
                    args  = { weapon = weapon.name },
                },
            }
        end

        options[#options + 1] = {
            header = Range.text('menu_cancel'),
            txt    = Range.text('menu_cancel_desc'),
            params = { event = 'neox_shootingrange:client:CancelWeaponSelect' },
        }

        exports['qb-menu']:openMenu(options)

    elseif menu == 'ox_lib' then
        local options = {}

        for _, weapon in ipairs(cfg.WeaponSettings.GivenWeapons) do
            table.insert(options, {
                title       = weapon.label,
                description = Range.text('menu_desc'),
                onSelect    = function()
                    TriggerEvent('neox_shootingrange:client:SelectWeapon', weapon.name)
                end,
            })
        end

        lib.registerContext({
            id      = 'shootingrange_weapon_menu',
            title   = Range.text('menu_header'),
            options = options,
        })

        lib.showContext('shootingrange_weapon_menu')

    elseif #cfg.WeaponSettings.GivenWeapons > 0 then
        TriggerEvent('neox_shootingrange:client:SelectWeapon',
            cfg.WeaponSettings.GivenWeapons[1].name)
    end
end

function Range.giveWeapon(weapon)
    if givenWeapon and givenWeapon ~= weapon then
        Bridge.RemoveWeapon(givenWeapon)
    end

    givenWeapon = weapon

    Bridge.GiveWeapon(weapon, cfg.WeaponSettings.GivenAmmo, {
        noReload   = cfg.WeaponSettings and cfg.WeaponSettings.NoReload == true,
        giveAsItem = cfg.WeaponSettings and cfg.WeaponSettings.GiveAsItem == true,
    })
end

RegisterNUICallback('rng_selectWeapon', function(data, cb)
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then
        Range.closeWeaponMenu()
        cb('ok')
        return
    end

    if aimLabActive and not aimLabIsMine then
        Range.closeWeaponMenu()
        Notify.send(string.format(
            Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        cb('ok')
        return
    end

    local ped = PlayerPedId()
    Range.giveWeapon(data.weapon)

    if cfg.Zones.WeaponZone and cfg.Zones.WeaponZone.interactPos then
        local interact = cfg.Zones.WeaponZone.interactPos
        SetEntityCoordsNoOffset(ped, interact.x, interact.y, interact.z, false, false, false)
        SetEntityHeading(ped, interact.w)
    end

    Range.closeWeaponMenu()
    SetEntityVisible(ped, true, 0)

    RequestAnimDict('amb@prop_human_atm@male@enter')
    while not HasAnimDictLoaded('amb@prop_human_atm@male@enter') do
        Citizen.Wait(10)
    end

    TaskPlayAnim(ped, 'amb@prop_human_atm@male@enter', 'enter',
        8.0, -8.0, 1500, 0, 0, false, false, false)

    Notify.send(Range.text('weapon_given'), 'success', 3000)

    if aimLabActive and aimLabIsMine then
        Notify.send(Range.text('aimlab_goto_booth'), 'primary', 6000)
    end

    cb('ok')
end)

RegisterNetEvent('neox_shootingrange:client:SelectWeapon', function(request)
    if cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then return end

    if aimLabActive and not aimLabIsMine then
        Notify.send(string.format(
            Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        return
    end

    local weapon = request
    if type(request) == 'table' and request.weapon then
        weapon = request.weapon
    end

    local ped = PlayerPedId()
    Range.giveWeapon(weapon)

    SetEntityVisible(ped, true, 0)
    Notify.send(Range.text('weapon_given'), 'success', 3000)

    if aimLabActive and aimLabIsMine then
        Notify.send(Range.text('aimlab_goto_booth'), 'primary', 6000)
    end
end)

-- ---------------------------------------------------------
-- Claiming an AimLab session
-- ---------------------------------------------------------
-- The server replies on AimLabResponse; the handler is swapped in per
-- request so it closes over nothing stale.
local aimLabResponseHandler = nil

RegisterNetEvent('neox_shootingrange:client:AimLabResponse', function(granted, reason)
    if aimLabResponseHandler then
        aimLabResponseHandler(granted, reason)
    end
end)

function Range.requestAimLab(mode)
    mode = mode or pendingAimLabMode or 'single'

    local boothId = cfg.AimLab.BoothId or 4
    local boothCoords = (cfg.Booths[boothId] and cfg.Booths[boothId].coords)
        or cfg.AimLab.BoothCoords

    SetNewWaypoint(boothCoords.x, boothCoords.y)

    aimLabResponseHandler = function(granted, failReason)
        if not granted then
            if failReason == 'no_access' then
                Notify.send(Range.text('no_access'), 'error', 5000)
            elseif failReason == 'busy' then
                Notify.send(Range.text('range_busy_aimlab'), 'error', 5000)
            else
                Notify.send(string.format(
                    Range.text('aimlab_in_progress'), tostring(failReason)), 'error', 5000)
            end
            return
        end

        local ped = PlayerPedId()
        GetSelectedPedWeapon(ped)

        if givenWeapon ~= nil then
            Notify.send(Range.text('aimlab_goto_booth'), 'primary', 6000)

        elseif cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon then
            Notify.send(
                Range.text('equip_weapon_first') or Range.text('select_weapon_first'),
                'primary', 4000)
        else
            Notify.send(Range.text('select_weapon_first'), 'primary', 4000)
            Range.openWeaponMenu()
        end
    end

    TriggerServerEvent('neox_shootingrange:server:RequestAimLab', mode)
end

RegisterNUICallback('rng_clickStartAimLab', function(data, cb)
    pendingAimLabMode = data.mode or 'single'

    Range.closeLaptop()

    if aimLabActive then
        Notify.send(string.format(
            Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        cb('ok')
        return
    end

    Range.requestAimLab(pendingAimLabMode)
    cb('ok')
end)

-- ---------------------------------------------------------
-- Aiming / hit detection
-- ---------------------------------------------------------
function Range.rotationToDirection(rotation)
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

-- Returns hit, entityHit, endCoords, surfaceNormal.
function Range.raycastFromCamera(distance)
    local camRot = GetGameplayCamRot()
    local camCoords = GetGameplayCamCoord()
    local direction = Range.rotationToDirection(camRot)

    local target = {
        x = camCoords.x + direction.x * distance,
        y = camCoords.y + direction.y * distance,
        z = camCoords.z + direction.z * distance,
    }

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        target.x, target.y, target.z,
        -1, PlayerPedId(), 0)

    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)

    return hit, entityHit, endCoords, surfaceNormal
end

-- Bullet holes, drawn as small markers that fade out.
Citizen.CreateThread(function()
    while true do
        local idle = true
        local now = GetGameTimer()

        local lifetime = (cfg.HitMarkerSettings and cfg.HitMarkerSettings.MarkerDurationMs)
            or 25000

        if cfg.HitMarkerSettings and cfg.HitMarkerSettings.EnableHitMarkers then
            for boothIndex, markers in pairs(hitMarkers) do
                local entity = boothTargets[boothIndex]

                if entity and DoesEntityExist(entity) and markers and #markers > 0 then
                    idle = false

                    -- Walked backwards so removals do not skip entries.
                    for index = #markers, 1, -1 do
                        local marker = markers[index]
                        local age = now - marker.spawnTime

                        if lifetime <= age then
                            table.remove(markers, index)
                        else
                            local world = GetOffsetFromEntityInWorldCoords(entity,
                                marker.rel.x, marker.rel.y, marker.rel.z)

                            -- Fade over the last three seconds.
                            local alpha = 240
                            if lifetime - age < 3000 then
                                alpha = math.floor(240 * ((lifetime - age) / 3000))
                            end

                            if alpha > 0 then
                                local size = (cfg.HitMarkerSettings
                                    and cfg.HitMarkerSettings.MarkerSize) or 0.025

                                DrawMarker(28,
                                    world.x - 0.06, world.y, world.z,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    size, size, size,
                                    235, 25, 25, alpha,
                                    false, true, 2, false, nil, nil, false)
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(idle and 1000 or 0)
    end
end)

-- ---------------------------------------------------------
-- AimLab target pop-up
-- ---------------------------------------------------------
function Range.popAimLabTarget(index)
    local target = cfg.AimLab.Targets[index]
    local aimLabModel = Range.toHash(cfg.AimLab.TargetModel)
    local boothModel = Range.toHash(cfg.TargetModel)

    -- Clear any stray prop sitting on this lane.
    if target then
        for _, entity in ipairs(GetGamePool('CObject')) do
            if DoesEntityExist(entity) and entity ~= aimLabTargets[index] then
                local model = GetEntityModel(entity)

                if (model == aimLabModel or model == boothModel)
                    and #(GetEntityCoords(entity) - target.pos) <= 0.9
                then
                    SetEntityAsMissionEntity(entity, true, true)
                    SetEntityVisible(entity, false, 0)
                    SetEntityCoords(entity, 0.0, 0.0, -500.0, false, false, false, false)
                    DeleteEntity(entity)
                end
            end
        end
    end

    local entity = aimLabTargets[index]

    if entity and DoesEntityExist(entity) then
        aimLabPopped[index] = true
        SetEntityVisible(entity, true, 0)
        Range.animateRotation(entity, cfg.AimLab.IdleRot, cfg.AimLab.ActiveRot, 200)
        TriggerServerEvent('neox_shootingrange:server:SyncAimLabTargetPopup', index, true)
    end
end

function Range.hideAimLabTarget(index)
    local entity = aimLabTargets[index]

    if entity and DoesEntityExist(entity) then
        aimLabPopped[index] = nil
        Range.animateRotation(entity, cfg.AimLab.ActiveRot, cfg.AimLab.IdleRot, 180)
        TriggerServerEvent('neox_shootingrange:server:SyncAimLabTargetPopup', index, false)
    end
end

-- Spectators mirror the pop-ups driven by whoever is running.
RegisterNetEvent('neox_shootingrange:client:SyncAimLabTargetPopup', function(index, popped)
    if not (aimLabActive and not aimLabIsMine) then return end

    local entity = aimLabTargets[index]
    if not (entity and DoesEntityExist(entity)) then return end

    if popped then
        Range.animateRotation(entity, cfg.AimLab.IdleRot, cfg.AimLab.ActiveRot, 200)
    else
        Range.animateRotation(entity, cfg.AimLab.ActiveRot, cfg.AimLab.IdleRot, 180)
    end
end)

-- ---------------------------------------------------------
-- Running an AimLab session
-- ---------------------------------------------------------
function Range.startAimLab()
    if aimLabRunning or aimLabCountdown then return end

    aimLabCountdown = true
    aimLabHits = 0
    aimLabShots = 0
    aimLabPopped = {}

    TriggerServerEvent('neox_shootingrange:server:UpdateAimLabPhase', 'in_progress')
    Range.setBoothTargetsVisible(false)

    local modeLabel = (aimLabMode == 'burst' and '3-ROUND BURST') or 'SINGLE SHOT'

    local durationSeconds = Range.aimLabDuration()
    local timeText = Range.formatTime(durationSeconds)
    local durationMs = durationSeconds * 1000

    for count = 3, 1, -1 do
        NUI.send('range', { type = 'SHOW_GTA_COUNTDOWN', count = count, sub = 'GET READY' })
        NUI.send('range', { type = 'SHOW_UI', ui_time = 'TIME', ui_score = 'TARGETS' })
        NUI.send('range', { type = 'UPDATE_UI', time = timeText, score = 0 })
        NUI.send('range', { type = 'SYNC_COUNTDOWN', count = count })
        TriggerEvent('neox_shootingrange:client:SyncScreen',
            { type = 'SYNC_COUNTDOWN', count = count })

        PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', 1)
        Citizen.Wait(1000)
    end

    NUI.send('range', { type = 'SHOW_GTA_COUNTDOWN', text = 'START!', sub = modeLabel })
    PlaySoundFrontend(-1, 'GO', 'HUD_MINI_GAME_SOUNDSET', 1)
    Citizen.Wait(800)
    NUI.send('range', { type = 'HIDE_GTA_COUNTDOWN' })

    aimLabCountdown = false
    aimLabRunning = true
    aimlabStartTime = GetGameTimer()

    if cfg.WeaponSettings and cfg.WeaponSettings.NoReload then
        SetPedInfiniteAmmoClip(PlayerPedId(), true)
    end

    Range.popAimLabTarget(math.random(1, #cfg.AimLab.Targets))

    -- Fire-rate limiter: single shot blocks held triggers, burst allows
    -- three rounds then forces a 250ms pause.
    Citizen.CreateThread(function()
        local firedThisPress = false
        local burstCount = 0
        local burstLockUntil = 0

        while aimLabRunning do
            Citizen.Wait(0)

            local ped = PlayerPedId()
            local now = GetGameTimer()

            if aimLabMode == 'single' then
                if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) then
                    firedThisPress = false
                end

                if IsPedShooting(ped) then
                    firedThisPress = true
                end

                if firedThisPress then
                    if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) then
                        DisablePlayerFiring(ped, true)
                        DisableControlAction(0, 24, true)
                        DisableControlAction(0, 257, true)
                    else
                        firedThisPress = false
                    end
                end

            elseif aimLabMode == 'burst' then
                local pressed = IsControlJustPressed(0, 24)
                    or IsDisabledControlJustPressed(0, 24)

                if pressed and burstLockUntil < now then
                    burstCount = 0
                end

                if IsPedShooting(ped) then
                    burstCount = burstCount + 1
                    if burstCount >= 3 then
                        burstLockUntil = now + 250
                    end
                end

                if burstCount >= 3 or now <= burstLockUntil then
                    DisablePlayerFiring(ped, true)
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 257, true)

                    if not (IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24))
                        and now > burstLockUntil
                    then
                        burstCount = 0
                    end
                end
            end
        end
    end)

    -- Clock / score readout, and the end-of-run scoring.
    Citizen.CreateThread(function()
        while aimLabRunning do
            Citizen.Wait(200)

            local elapsed = GetGameTimer() - aimlabStartTime
            local remaining = math.max(0, durationMs - elapsed)
            local remainingText = Range.formatTime(math.ceil(remaining / 1000))

            NUI.send('range', {
                type  = 'UPDATE_UI',
                time  = remainingText,
                score = aimLabHits,
            })

            TriggerServerEvent('neox_shootingrange:server:SyncAimLabLiveStats',
                remainingText, aimLabHits)

            if remaining <= 0 then break end
        end

        if aimLabRunning then
            local category = Range.weaponCategory(givenWeapon)
            local misses = math.max(0, aimLabShots - aimLabHits)
            local modeName = (aimLabMode == 'burst' and 'Burst') or 'Single'

            PlaySoundFrontend(-1, 'ROUND_ENDING', 'HUD_AWARDS', 1)

            Notify.send(string.format(Range.text('aimlab_finished'),
                aimLabHits, category .. ' (' .. modeName .. ')'), 'success', 6000)

            TriggerServerEvent('neox_shootingrange:server:SaveScore',
                aimLabHits, timeText, durationSeconds, category, modeName)

            TriggerServerEvent('neox_shootingrange:server:SaveAimLabStats',
                aimLabHits, misses, aimLabShots, category .. ' (' .. modeName .. ')')

            Range.stopAimLab(false)
        end
    end)

    -- Hit detection: works out which popped target the shot went through.
    Citizen.CreateThread(function()
        local lastShotAt = 0

        while aimLabRunning do
            Citizen.Wait(0)

            local ped = PlayerPedId()

            if IsPedShooting(ped) then
                local now = GetGameTimer()

                if now - lastShotAt >= 30 then
                    lastShotAt = now
                    aimLabShots = aimLabShots + 1

                    local hitIndex = nil

                    local camRot = GetGameplayCamRot()
                    local camCoords = GetGameplayCamCoord()
                    local direction = Range.rotationToDirection(camRot)

                    local _, entityHit = Range.raycastFromCamera(150.0)

                    for index in pairs(aimLabPopped) do
                        local entity = aimLabTargets[index]

                        if entity and DoesEntityExist(entity) then
                            local entityCoords = GetEntityCoords(entity)

                            if entityHit == entity then
                                hitIndex = index
                                break
                            end

                            -- Fall back to projecting the aim ray onto the
                            -- target's X plane.
                            if math.abs(direction.x) > 0.001 then
                                local scale = (entityCoords.x - camCoords.x) / direction.x

                                if scale > 0 then
                                    local aimY = camCoords.y + scale * direction.y
                                    local aimZ = camCoords.z + scale * direction.z

                                    local offY = math.abs(aimY - entityCoords.y)
                                    local offZ = aimZ - entityCoords.z

                                    if offY <= 0.4 and offZ >= 0.2 and offZ <= 1.7 then
                                        hitIndex = index
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if hitIndex then
                        PlaySoundFrontend(-1, 'SHOOTING_RANGE_ROUND_OVER', 'HUD_AWARDS', 1)
                        aimLabHits = aimLabHits + 1

                        local elapsed = GetGameTimer() - aimlabStartTime
                        local remaining = math.max(0, durationMs - elapsed)
                        local remainingText = Range.formatTime(math.ceil(remaining / 1000))

                        NUI.send('range', {
                            type  = 'UPDATE_UI',
                            time  = remainingText,
                            score = aimLabHits,
                        })

                        TriggerServerEvent('neox_shootingrange:server:SyncAimLabLiveStats',
                            remainingText, aimLabHits)

                        Range.hideAimLabTarget(hitIndex)

                        -- Pop a different target next, if one is free.
                        local candidates = {}

                        for index = 1, #cfg.AimLab.Targets do
                            if not aimLabPopped[index] and index ~= hitIndex then
                                table.insert(candidates, index)
                            end
                        end

                        if #candidates > 0 then
                            Range.popAimLabTarget(candidates[math.random(1, #candidates)])
                        else
                            Range.popAimLabTarget(hitIndex)
                        end
                    end
                end
            end
        end
    end)
end

-- ---------------------------------------------------------
-- Booths
-- ---------------------------------------------------------
function Range.enterBooth(boothId, startX)
    if aimLabActive then
        Notify.send(string.format(
            Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        return
    end

    currentBoothId = boothId
    inBooth = true
    hitMarkers[boothId] = {}

    if cfg.WeaponSettings and cfg.WeaponSettings.NoReload then
        SetPedInfiniteAmmoClip(PlayerPedId(), true)
    end

    Notify.send(string.format(Range.text('booth_entered'), boothId), 'success', 5000)

    -- Target distance control.
    Citizen.CreateThread(function()
        local x = startX or cfg.Booths[boothId].targetPos.x

        while inBooth and currentBoothId == boothId do
            Citizen.Wait(0)

            Notify.show(Range.text('booth_controls'))

            local moved = false

            if IsControlPressed(0, cfg.Controls.MoveForward) then
                if x < cfg.TargetLimits.maxX then
                    x = x + cfg.TargetLimits.moveStep
                    moved = true
                end
            elseif IsControlPressed(0, cfg.Controls.MoveBackward) then
                if x > cfg.TargetLimits.minX then
                    x = x - cfg.TargetLimits.moveStep
                    moved = true
                end
            end

            if moved then
                TriggerServerEvent('neox_shootingrange:server:UpdateTargetPos', boothId, x)
                Citizen.Wait(30)
            end
        end
    end)

    -- Bullet holes on this booth's target.
    Citizen.CreateThread(function()
        local lastShotAt = 0

        while inBooth and currentBoothId == boothId do
            Citizen.Wait(0)

            local ped = PlayerPedId()

            if IsPedShooting(ped) then
                local now = GetGameTimer()

                if now - lastShotAt >= 30 then
                    lastShotAt = now

                    local entity = boothTargets[boothId]

                    if entity and DoesEntityExist(entity) then
                        local entityCoords = GetEntityCoords(entity)

                        local hit, _, endCoords = Range.raycastFromCamera(150.0)

                        local onTarget = false
                        local impact = nil

                        if hit == 1 and endCoords and #(endCoords - entityCoords) <= 2.5 then
                            onTarget = true
                            impact = endCoords
                        end

                        -- Nothing solid was hit: project the aim ray onto the
                        -- target's X plane instead.
                        if not onTarget then
                            local camRot = GetGameplayCamRot()
                            local camCoords = GetGameplayCamCoord()
                            local direction = Range.rotationToDirection(camRot)

                            if math.abs(direction.x) > 0.001 then
                                local scale = (entityCoords.x - camCoords.x) / direction.x

                                if scale > 0 then
                                    local aimY = camCoords.y + scale * direction.y
                                    local aimZ = camCoords.z + scale * direction.z

                                    if math.abs(aimY - entityCoords.y) <= 0.8
                                        and math.abs(aimZ - entityCoords.z) <= 1.0
                                    then
                                        onTarget = true
                                        impact = vector3(entityCoords.x, aimY, aimZ)
                                    end
                                end
                            end
                        end

                        if onTarget and impact then
                            if cfg.HitMarkerSettings and cfg.HitMarkerSettings.EnableHitMarkers then
                                local rel = GetOffsetFromEntityGivenWorldCoords(entity,
                                    impact.x, impact.y, impact.z)

                                hitMarkers[boothId] = hitMarkers[boothId] or {}

                                local maxMarkers = (cfg.HitMarkerSettings
                                    and cfg.HitMarkerSettings.MaxMarkersPerTarget) or 30

                                if maxMarkers <= #hitMarkers[boothId] then
                                    table.remove(hitMarkers[boothId], 1)
                                end

                                table.insert(hitMarkers[boothId], {
                                    rel       = rel,
                                    spawnTime = now,
                                })
                            end

                            if not (cfg.HitMarkerSettings
                                and cfg.HitMarkerSettings.EnableHitSound == false)
                            then
                                PlaySoundFrontend(-1, 'SHOOTING_RANGE_ROUND_OVER', 'HUD_AWARDS', 1)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function Range.leaveBooth()
    if not (inBooth and currentBoothId) then return end

    TriggerServerEvent('neox_shootingrange:server:LeaveBooth', currentBoothId)
    hitMarkers[currentBoothId] = {}

    if cfg.WeaponSettings and cfg.WeaponSettings.NoReload then
        SetPedInfiniteAmmoClip(PlayerPedId(), false)
    end

    Range.removeGivenWeapon(PlayerPedId())

    inBooth = false
    currentBoothId = nil
end

RegisterNetEvent('neox_shootingrange:client:BoothResponse',
    function(granted, boothId, startX, reason)
        if granted then
            Range.enterBooth(boothId, startX)

        elseif reason == 'no_access' then
            Notify.send(Range.text('no_access'), 'error', 4000)

        elseif reason == 'aimlab_in_progress' then
            Notify.send(string.format(
                Range.text('aimlab_in_progress'), aimLabState.playerName), 'error', 4000)
        else
            Notify.send(string.format(
                Range.text('booth_occupied'), boothId), 'error', 4000)
        end
    end)

-- ---------------------------------------------------------
-- Prompts and zone transitions
-- ---------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        -- The weapon menu and the laptop view own the screen while up.
        if weaponMenuActive or laptopViewActive then
            Citizen.Wait(250)
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local heightDelta = math.abs(coords.z - 18.67)
            local flat = #(coords - vector3(485.0, -1018.0, 18.67))

            -- Leaving the booth mid-run, or the range while merely claimed,
            -- ends the session.
            if aimLabRunning or (aimLabActive and aimLabIsMine) then
                local boothId = cfg.AimLab.BoothId or 4
                local booth = cfg.Booths[boothId] or { coords = cfg.AimLab.BoothCoords }
                local fromBooth = #(coords - booth.coords)

                if aimLabRunning or aimLabCountdown then
                    if fromBooth > 2.5 then
                        Range.stopAimLab(true)
                    end
                elseif flat > 12.0 then
                    Range.stopAimLab(true)
                end
            end

            if heightDelta > 3.5 or flat > 35.0 then
                Citizen.Wait(1500)

            elseif flat > 12.0 then
                Citizen.Wait(500)

            else
                local idle = true

                if cfg.Zones.ExitZone then
                    if #(coords - cfg.Zones.ExitZone.coords) <= cfg.Zones.ExitZone.radius then
                        if inBooth then
                            Range.leaveBooth()
                        end

                        if aimLabRunning or (aimLabActive and aimLabIsMine) then
                            Range.stopAimLab(true)
                        end

                        if givenWeapon then
                            Range.removeGivenWeapon(ped)
                        end
                    end
                end

                local targetOn = Target.enabled(cfg.Target.system, cfg.InteractionType)

                if not (cfg.WeaponSettings and cfg.WeaponSettings.UseOwnWeapon)
                    and cfg.Zones.WeaponZone
                then
                    if #(coords - cfg.Zones.WeaponZone.coords) <= cfg.Zones.WeaponZone.radius then
                        idle = false

                        if not targetOn then
                            if aimLabActive and not aimLabIsMine then
                                Notify.show(string.format(
                                    Range.text('aimlab_in_progress'), aimLabState.playerName))
                            else
                                Notify.show(Range.text('press_e_weapon'))

                                if IsControlJustPressed(0, 38) then
                                    Range.openWeaponMenu()
                                end
                            end
                        end
                    end
                end

                if cfg.Zones.LaptopZone then
                    if #(coords - cfg.Zones.LaptopZone.coords) <= cfg.Zones.LaptopZone.radius then
                        idle = false

                        if not targetOn then
                            Notify.show(Range.text('press_e_laptop'))

                            if IsControlJustPressed(0, 38) then
                                Range.openLaptop()
                            end
                        end
                    end
                end

                -- Marker showing where to stand for a claimed session.
                if aimLabActive and aimLabIsMine
                    and not aimLabRunning and not aimLabCountdown
                then
                    local boothId = cfg.AimLab.BoothId or 4
                    local booth = cfg.Booths[boothId] or { coords = cfg.AimLab.BoothCoords }
                    local fromBooth = #(coords - booth.coords)

                    idle = false

                    DrawMarker(1,
                        booth.coords.x, booth.coords.y, booth.coords.z - 0.95,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.2, 1.2, 0.8,
                        102, 252, 241, 150,
                        false, true, 2, false, nil, nil, false)

                    DrawMarker(20,
                        booth.coords.x, booth.coords.y, booth.coords.z + 0.3,
                        0.0, 0.0, 0.0, 0.0, 180.0, 0.0,
                        0.5, 0.5, 0.5,
                        255, 51, 102, 200,
                        true, true, 2, false, nil, nil, false)

                    if fromBooth <= 1.8 and not targetOn then
                        Notify.show(Range.text('press_e_aimlab'))

                        if IsControlJustPressed(0, 38) then
                            Range.startAimLab()
                        end
                    end
                end

                if not aimLabActive and not inBooth and not targetOn then
                    local nearest, nearestDist = nil, 999.0

                    for _, booth in ipairs(cfg.Booths) do
                        local dist = #(coords - booth.coords)
                        if dist <= booth.radius and nearestDist > dist then
                            nearestDist = dist
                            nearest = booth
                        end
                    end

                    if nearest then
                        idle = false
                        Notify.show(string.format(Range.text('press_e_booth'), nearest.id))

                        if IsControlJustPressed(0, 38) then
                            TriggerServerEvent('neox_shootingrange:server:RequestBooth', nearest.id)
                        end
                    end
                end

                -- Walking away from your own booth releases it.
                if inBooth and currentBoothId then
                    local booth = cfg.Booths[currentBoothId]

                    if #(coords - booth.coords) > 2.5 then
                        Range.leaveBooth()
                    end
                end

                Citizen.Wait(idle and 350 or 0)
            end
        end
    end
end)

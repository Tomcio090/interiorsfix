--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — CCTV (client)
-- =========================================================
-- The monitor wall is a DUI page replacing the screen texture on two
-- props. Walking up to a monitor swings a camera onto it and forwards
-- the mouse into the page; picking a camera there renders that camera's
-- viewpoint with a scanline filter.
--
-- Also hosts the in-game camera placement tool (startSetup).
-- =========================================================

if not NeoxMRPD.enabled('cctv') then
    RemoveReplaceTexture('neox_mrpd_r13_monitors', 'neox_mrpd_monitor_screen_02')
    RemoveReplaceTexture('neox_mrpd_det_01', 'neox_mrpd_monitor_screen_02')
    return
end

CCTV = CCTV or {}

local cfg = NeoxMRPD.Config.CCTV

-- ---------------------------------------------------------
-- Built-in monitor layout
-- ---------------------------------------------------------
-- Each monitor is a spot the player can stand at. camCoords/camRot frame
-- the screen; hitbox maps the screen area onto DUI coordinates.
local DEFAULT_MONITORS = {
    {
        coords       = vector3(487.71, -1005.11, 31.63),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(487.616, -1005.053, 31.001),
        camRot       = vector3(-1.323, 0.0, -89.968),
        camFov       = 48.0,
        hitbox       = { width = 0.76, height = 0.86, x = 0.495, y = 0.49 },
        textureDict  = 'neox_mrpd_r13_monitors',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(480.56, -1005.06, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(480.632, -1005.076, 31.01),
        camRot       = vector3(-1.701, -0.0, 89.007),
        camFov       = 50.0,
        hitbox       = { width = 0.85, height = 0.9, x = 0.518, y = 0.495 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(480.56, -1005.06, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(480.632, -1005.076, 31.01),
        camRot       = vector3(-1.701, -0.0, 89.007),
        camFov       = 50.0,
        hitbox       = { width = 0.85, height = 0.9, x = 0.53, y = 0.495 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(480.74, -1008.17, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(480.801, -1008.159, 31.026),
        camRot       = vector3(-3.339, -0.0, 135.396),
        camFov       = 50.0,
        hitbox       = { width = 0.82, height = 0.88, x = 0.52, y = 0.5 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(483.37, -1008.18, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(483.294, -1008.148, 31.006),
        camRot       = vector3(-1.197, -0.0, -135.303),
        camFov       = 50.0,
        hitbox       = { width = 0.82, height = 0.88, x = 0.52, y = 0.5 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(484.97, -1008.19, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(485.001, -1008.164, 31.008),
        camRot       = vector3(-1.26, -0.0, 135.401),
        camFov       = 50.0,
        hitbox       = { width = 0.85, height = 0.92, x = 0.5, y = 0.5 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(487.48, -1008.18, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(487.529, -1008.14, 31.008),
        camRot       = vector3(-1.449, 0.0, -136.584),
        camFov       = 50.0,
        hitbox       = { width = 0.81, height = 0.92, x = 0.505, y = 0.5 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
    {
        coords       = vector3(487.63, -1001.98, 31.0),
        heading      = 0.0,
        model        = 'neox_mrpd_r13_monitors',
        spawnProp    = false,
        targetRadius = 0.7,
        camCoords    = vector3(487.528, -1001.953, 31.013),
        camRot       = vector3(-2.142, -0.0, -44.365),
        camFov       = 50.0,
        hitbox       = { width = 0.81, height = 0.92, x = 0.495, y = 0.5 },
        textureDict  = 'neox_mrpd_det_01',
        textureName  = 'neox_mrpd_monitor_screen_02',
    },
}

cfg.Monitors = cfg.Monitors or DEFAULT_MONITORS

cfg.Interact = cfg.Interact or {}
cfg.Interact.distance     = cfg.Interact.distance or 2.2
cfg.Interact.camDistance  = cfg.Interact.camDistance or 1.0
cfg.Interact.camHeight    = cfg.Interact.camHeight or 0.35
cfg.Interact.camFov       = cfg.Interact.camFov or 37.0
cfg.Interact.hitboxHeight = cfg.Interact.hitboxHeight or 0.92

for index, monitor in ipairs(cfg.Monitors) do
    monitor.id = index
end

-- ---------------------------------------------------------
-- State
-- ---------------------------------------------------------
local TXD_NAME = 'neox_cctv_txd'
local TXN_NAME = 'neox_cctv_txn'

local dui = nil
local duiCreating = false

local viewing = false          -- standing at a monitor
local monitorCam = nil

local cameraActive = false     -- watching a camera feed through the monitor
local cameraCam = nil

local accessPending = false
local accessRequestedAt = 0
local pendingMonitor = nil

local ACCESS_TIMEOUT_MS = 3000
local claimedMonitorId = nil

local texturesApplied = false
local lastTexturePoll = 0
local lastTextureRefresh = 0

local TEXTURE_POLL_MS = (cfg.Performance and cfg.Performance.texturePollMs) or 2000
local TEXTURE_REFRESH_MS = (cfg.Performance and cfg.Performance.textureRefreshMs) or 30000

-- Rough centre of the monitor room, used for the cheap early-out.
local ROOM_CENTER = vector3(484.0, -1005.0, 31.0)
local RENDER_DISTANCE = (cfg.Dui and cfg.Dui.renderDistance) or 15.0

local SCREEN_PROPS = { 'neox_mrpd_r13_monitors', 'neox_mrpd_det_01' }

local registeredModels = {}

function CCTV.debug(format, ...)
    if cfg.Debug then
        print(('[neox_mrpd_cctv] ' .. format):format(...))
    end
end

function CCTV.monitorProp(monitor)
    if monitor.prop and DoesEntityExist(monitor.prop) then
        return monitor.prop
    end

    local model = (type(monitor.model) == 'number' and monitor.model)
        or GetHashKey(monitor.model)

    return GetClosestObjectOfType(
        monitor.coords.x, monitor.coords.y, monitor.coords.z,
        2.0, model, false, false, false)
end

-- ---------------------------------------------------------
-- DUI and screen textures
-- ---------------------------------------------------------
function CCTV.ensureDui()
    if dui or duiCreating then return end

    duiCreating = true

    local width = (cfg.Dui and cfg.Dui.width) or 1280
    local height = (cfg.Dui and cfg.Dui.height) or 720

    local url = ('nui://%s/html/cctv/index.html?mode=dui'):format(GetCurrentResourceName())
    local handle = CreateDui(url, width, height)

    local deadline = GetGameTimer() + 15000
    while not IsDuiAvailable(handle) and deadline > GetGameTimer() do
        Wait(50)
    end

    if not IsDuiAvailable(handle) then
        print('[neox_mrpd_cctv] WARNING: DUI not ready in 15 seconds! Check html files and fxmanifest.')
        duiCreating = false
        return
    end

    dui = handle

    local txd = CreateRuntimeTxd(TXD_NAME)
    CreateRuntimeTextureFromDuiHandle(txd, TXN_NAME, GetDuiHandle(dui))

    duiCreating = false
    CCTV.debug('CCTV DUI initialized (%dx%d)', width, height)
end

function CCTV.applyTextures(force)
    CCTV.ensureDui()
    if not dui then return end
    if texturesApplied and not force then return end

    for _, prop in ipairs(SCREEN_PROPS) do
        RequestStreamedTextureDict(prop, false)
        AddReplaceTexture(prop, 'neox_mrpd_monitor_screen_02', TXD_NAME, TXN_NAME)
    end

    texturesApplied = true
    lastTextureRefresh = GetGameTimer()
end

function CCTV.clearTextures()
    if not texturesApplied then return end

    for _, prop in ipairs(SCREEN_PROPS) do
        RemoveReplaceTexture(prop, 'neox_mrpd_monitor_screen_02')
    end

    texturesApplied = false
end

-- ---------------------------------------------------------
-- Leaving views
-- ---------------------------------------------------------
-- Drops the camera feed and hands the screen back to the monitor view.
function CCTV.closeCameraFeed()
    if not cameraActive then return end

    cameraActive = false
    ClearTimecycleModifier()

    if cameraCam then
        DestroyCam(cameraCam, false)
        cameraCam = nil
    end

    ClearFocus()
    NUI.send('cctv', { type = 'hideCCTVHud' })
    NUI.focus('cctv', true, false)

    if monitorCam then
        SetCamActive(monitorCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
end

function CCTV.exitView()
    if not viewing then return end
    viewing = false

    if claimedMonitorId then
        TriggerServerEvent('neox_mrpd_cctv:server:releaseAccess', claimedMonitorId)
        claimedMonitorId = nil
    end

    if cameraActive then
        cameraActive = false
        ClearTimecycleModifier()

        if cameraCam then
            DestroyCam(cameraCam, false)
            cameraCam = nil
        end
    end

    ClearFocus()
    NUI.send('cctv', { type = 'hideCCTVHud' })
    NUI.focus('cctv', false, false)
    RenderScriptCams(false, true, 400, true, true)

    if monitorCam then
        DestroyCam(monitorCam, false)
        monitorCam = nil
    end

    FreezeEntityPosition(PlayerPedId(), false)
end

-- ---------------------------------------------------------
-- Monitor view
-- ---------------------------------------------------------
local MONITOR_BLOCKED_CONTROLS = { 1, 2, 24, 25, 30, 31, 36, 44, 142, 106, 200, 177 }

-- Maps the mouse onto the monitor's hitbox and forwards it into the DUI.
function CCTV.runMonitorLoop(monitor)
    local duiWidth = (cfg.Dui and cfg.Dui.width) or 1280
    local duiHeight = (cfg.Dui and cfg.Dui.height) or 720

    local lastX, lastY = -1, -1

    while viewing do
        Wait(0)

        -- Skip input entirely while the on-screen keyboard is up.
        if UpdateOnscreenKeyboard() ~= 0 then
            DisablePlayerFiring(PlayerId(), true)

            for _, control in ipairs(MONITOR_BLOCKED_CONTROLS) do
                DisableControlAction(0, control, true)
            end

            SetMouseCursorActiveThisFrame()
            SetMouseCursorSprite(1)

            -- The cursor only drives the DUI from the monitor view, not
            -- while a camera feed is on screen.
            if dui and not cameraActive then
                local hitbox = monitor.hitbox

                local width   = (hitbox and hitbox.width) or 0.8
                local height  = (hitbox and hitbox.height) or 0.8
                local centerX = (hitbox and hitbox.x) or 0.5
                local centerY = (hitbox and hitbox.y) or 0.5

                if cfg.Debug then
                    DrawRect(centerX, centerY, width, height, 255, 0, 0, 80)
                end

                local cursorX = GetDisabledControlNormal(0, 239)
                local cursorY = GetDisabledControlNormal(0, 240)

                local left = centerX - width / 2
                local top = centerY - height / 2

                local duiX = math.floor(
                    NeoxMRPD.clamp((cursorX - left) / width, 0.0, 1.0) * duiWidth)
                local duiY = math.floor(
                    NeoxMRPD.clamp((cursorY - top) / height, 0.0, 1.0) * duiHeight)

                if duiX ~= lastX or duiY ~= lastY then
                    lastX, lastY = duiX, duiY
                    SendDuiMouseMove(dui, duiX, duiY)
                end

                if IsDisabledControlJustPressed(0, 24) then
                    SendDuiMouseDown(dui, 'left')
                end

                if IsDisabledControlJustReleased(0, 24) then
                    SendDuiMouseUp(dui, 'left')
                end

                if IsDisabledControlJustPressed(0, 25) then
                    SendDuiMouseDown(dui, 'right')
                end

                if IsDisabledControlJustReleased(0, 25) then
                    SendDuiMouseUp(dui, 'right')
                end

                if IsDisabledControlJustPressed(0, 241) then
                    SendDuiMouseWheel(dui, 120, 0)
                end

                if IsDisabledControlJustPressed(0, 242) then
                    SendDuiMouseWheel(dui, -120, 0)
                end
            end

            -- Escape backs out of a camera feed first, then the whole view.
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
                if cameraActive then
                    CCTV.closeCameraFeed()
                else
                    CCTV.exitView()
                end
            end
        end
    end
end

function CCTV.openMonitor(monitor)
    if viewing then return end
    viewing = true

    claimedMonitorId = monitor.id
    CCTV.applyTextures(true)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    monitorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    if monitor.camCoords and monitor.camRot then
        SetCamCoord(monitorCam, monitor.camCoords.x, monitor.camCoords.y, monitor.camCoords.z)
        SetCamRot(monitorCam, monitor.camRot.x, monitor.camRot.y, monitor.camRot.z, 2)
    else
        -- No authored camera: frame the monitor prop from the side the
        -- player is standing on.
        local prop = CCTV.monitorProp(monitor)
        local propCoords = (prop and prop ~= 0 and GetEntityCoords(prop)) or monitor.coords

        local lookAt = vector3(propCoords.x, propCoords.y,
            propCoords.z + (cfg.Interact.camHeight or 0.35))

        local forward
        if prop and prop ~= 0 then
            forward = GetEntityForwardVector(prop)
        else
            local radians = math.rad(monitor.heading or 0.0)
            forward = vector3(-math.sin(radians), math.cos(radians), 0.0)
        end

        forward = vector3(forward.x, forward.y, 0.0)

        local pedCoords = GetEntityCoords(ped)
        local toPlayer = vector3(pedCoords.x - propCoords.x, pedCoords.y - propCoords.y, 0.0)

        if forward.x * toPlayer.x + forward.y * toPlayer.y < 0.0 then
            forward = -forward
        end

        local reach = cfg.Interact.camDistance or 1.0

        local camPos = vector3(
            lookAt.x + forward.x * reach,
            lookAt.y + forward.y * reach,
            lookAt.z + 0.15
        )

        SetCamCoord(monitorCam, camPos.x, camPos.y, camPos.z)
        PointCamAtCoord(monitorCam, lookAt.x, lookAt.y, lookAt.z)
    end

    SetCamFov(monitorCam, monitor.camFov or cfg.Interact.camFov or 37.0)
    SetCamActive(monitorCam, true)
    RenderScriptCams(true, true, 400, true, true)

    NUI.focus('cctv', true, false)

    CreateThread(function()
        CCTV.runMonitorLoop(monitor)
    end)
end

function CCTV.requestAccess(monitor)
    if viewing then return end

    -- A reply that never arrives (server-side throttle, dropped event) must
    -- not latch the prompt shut for the rest of the session.
    if accessPending and GetGameTimer() - accessRequestedAt < ACCESS_TIMEOUT_MS then
        return
    end

    accessPending = true
    accessRequestedAt = GetGameTimer()
    pendingMonitor = monitor

    TriggerServerEvent('neox_mrpd_cctv:server:requestAccess', monitor.id)
end

RegisterNetEvent('neox_mrpd_cctv:client:requestOpen', function(monitorId)
    local found = nil

    for _, monitor in ipairs(cfg.Monitors) do
        if monitor.id == monitorId then
            found = monitor
            break
        end
    end

    if found then
        CCTV.requestAccess(found)
    end
end)

RegisterNetEvent('neox_mrpd_cctv:client:accessResult', function(monitorId, granted, reason)
    accessPending = false

    -- A reply for a monitor we are no longer asking about.
    if pendingMonitor and pendingMonitor.id ~= monitorId then
        pendingMonitor = nil
        return
    end

    if granted then
        if pendingMonitor then
            CCTV.openMonitor(pendingMonitor)
        end
    elseif reason == 'in_use' then
        Notify.send(cfg.Locale.in_use)
    else
        Notify.send(cfg.Locale.no_access)
    end

    pendingMonitor = nil
end)

-- ---------------------------------------------------------
-- Target zones
-- ---------------------------------------------------------
-- One model target covers every monitor sharing that prop, so the action
-- resolves which monitor was actually used by distance.
function CCTV.setupTargets()
    local system = cfg.Target.system
    if not Target.enabled(system, cfg.InteractionType) then return end

    for _, monitor in ipairs(cfg.Monitors) do
        local model = monitor.model

        if not registeredModels[model] then
            registeredModels[model] = true

            Target.addModel('neox_mrpd_cctv_' .. tostring(model), model, {
                {
                    icon     = 'fas fa-video',
                    label    = cfg.Locale.target_label,
                    distance = cfg.Interact.distance,
                    action   = function(data)
                        local origin = (type(data) == 'table' and data.position)
                            or GetEntityCoords(PlayerPedId())

                        local nearest, nearestDist = nil, 9999.0

                        for _, candidate in ipairs(cfg.Monitors) do
                            local dist = #(origin - candidate.coords)
                            if nearestDist > dist then
                                nearestDist = dist
                                nearest = candidate
                            end
                        end

                        if nearest then
                            CCTV.requestAccess(nearest)
                        end
                    end,
                },
            }, cfg.Interact.distance, system, cfg.InteractionType)
        end
    end
end

-- Streams the screens in and out, and draws the [E] prompt.
CreateThread(function()
    CCTV.setupTargets()

    while true do
        local coords = GetEntityCoords(PlayerPedId())

        local heightDelta = math.abs(coords.z - ROOM_CENTER.z)
        local flat = #(vector2(coords.x, coords.y)
            - vector2(ROOM_CENTER.x, ROOM_CENTER.y))

        local promptsAllowed = not Target.enabled(cfg.Target.system, cfg.InteractionType)

        if heightDelta > 3.5 or flat > RENDER_DISTANCE + 20.0 then
            if texturesApplied then CCTV.clearTextures() end
            if viewing then CCTV.exitView() end
            Wait(1500)

        elseif flat > RENDER_DISTANCE then
            if texturesApplied then CCTV.clearTextures() end
            if viewing then CCTV.exitView() end
            Wait(600)

        else
            local now = GetGameTimer()

            if not texturesApplied then
                lastTexturePoll = now
                CCTV.applyTextures(true)

            elseif now - lastTexturePoll > TEXTURE_POLL_MS then
                lastTexturePoll = now

                -- Replaced textures get dropped on a streaming hitch.
                if now - lastTextureRefresh > TEXTURE_REFRESH_MS then
                    CCTV.applyTextures(true)
                end
            end

            local nearest, nearestDist = nil, 9999.0

            for _, monitor in ipairs(cfg.Monitors) do
                local dist = #(coords - monitor.coords)
                if nearestDist > dist then
                    nearestDist = dist
                    nearest = monitor
                end
            end

            if promptsAllowed and nearest
                and nearestDist <= cfg.Interact.distance
                and not viewing
            then
                Notify.show(cfg.Locale.help_open)

                if IsControlJustReleased(0, 38) then
                    CCTV.requestAccess(nearest)
                end

                Wait(0)
            else
                Wait(300)
            end
        end
    end
end)

-- ---------------------------------------------------------
-- DUI messaging
-- ---------------------------------------------------------
function CCTV.sendToDui(payload)
    if dui then
        SendDuiMessage(dui, json.encode(payload))
    end
end

function CCTV.initPayload()
    return {
        type         = 'init',
        resource     = GetCurrentResourceName(),
        cameras      = cfg.Cameras,
        totalCameras = #cfg.Cameras,
        locale       = cfg.Locale.ui,
    }
end

RegisterNetEvent('neox_mrpd_cctv:client:addAlert', function(alert)
    CCTV.sendToDui({ type = 'addAlert', alert = alert })
end)

RegisterNetEvent('neox_mrpd_cctv:client:syncAlerts', function(alerts)
    CCTV.sendToDui({ type = 'syncAlerts', alerts = alerts })
end)

RegisterNetEvent('neox_mrpd_cctv:client:syncBookmarks', function(bookmarks)
    CCTV.sendToDui({ type = 'setBookmarks', bookmarks = bookmarks })
end)

RegisterNetEvent('neox_mrpd_cctv:client:syncCameras', function(cameras)
    if type(cameras) ~= 'table' then return end

    cfg.Cameras = cameras
    CCTV.sendToDui(CCTV.initPayload())
end)

RegisterNUICallback('cctv_uiReady', function(_, cb)
    cb({ ok = true })

    CCTV.debug('UI Ready callback received from NUI')

    if not dui then return end

    CCTV.sendToDui(CCTV.initPayload())

    TriggerServerEvent('neox_mrpd_cctv:server:requestCameras')
    TriggerServerEvent('neox_mrpd_cctv:server:requestBookmarks')
    TriggerServerEvent('neox_mrpd_cctv:server:requestAlerts')
end)

RegisterNUICallback('cctv_exitView', function(_, cb)
    cb({ ok = true })
    CCTV.exitView()
end)

RegisterNUICallback('cctv_reportIncident', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('neox_mrpd_cctv:server:reportIncident', data)
end)

RegisterNUICallback('cctv_toggleBookmark', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('neox_mrpd_cctv:server:toggleBookmark', data.camId)
end)

RegisterNUICallback('cctv_setSearchFocus', function(data, cb)
    cb({ ok = true })
    NUI.send('cctv', { type = 'setSearchFocus', focused = data.focused })
end)

RegisterNUICallback('cctv_nuiKeydown', function(data, cb)
    cb({ ok = true })

    CCTV.sendToDui({
        type  = 'forwardKeydown',
        key   = data.key,
        code  = data.code,
        ctrl  = data.ctrl,
        shift = data.shift,
        alt   = data.alt,
    })
end)

RegisterNUICallback('cctv_closeCCTV', function(_, cb)
    cb({ ok = true })

    if cameraActive then
        CCTV.closeCameraFeed()
    else
        CCTV.exitView()
    end
end)

-- Switches the view to a camera's own viewpoint.
function CCTV.openCameraFeed(camera)
    if not cameraActive then
        cameraActive = true
        SetTimecycleModifier('scanline_cam_cheap')
        SetTimecycleModifierStrength(1.0)
    end

    if cameraCam then
        DestroyCam(cameraCam, false)
    end

    cameraCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(cameraCam, camera.camCoords.x, camera.camCoords.y, camera.camCoords.z)
    SetCamRot(cameraCam,
        (camera.camRot and camera.camRot.x) or -15.0,
        (camera.camRot and camera.camRot.y) or 0.0,
        (camera.camRot and camera.camRot.z) or 0.0,
        2)
    SetCamFov(cameraCam, camera.camFov or 60.0)
    SetCamActive(cameraCam, true)
    RenderScriptCams(true, false, 0, true, true)

    -- Without this the world around the camera never streams in.
    SetFocusPosAndVel(camera.camCoords.x, camera.camCoords.y, camera.camCoords.z, 0.0, 0.0, 0.0)

    NUI.send('cctv', {
        type     = 'showCCTVHud',
        label    = camera.label,
        name     = camera.name,
        district = camera.district,
        locale   = cfg.Locale.ui,
    })

    NUI.focus('cctv', false, false)
end

RegisterNUICallback('cctv_uiAction', function(data, cb)
    cb({ ok = true })

    if data.action == 'openCam' then
        if not data.camId then return end

        local camera = nil

        for _, candidate in ipairs(cfg.Cameras) do
            if candidate.id == data.camId then
                camera = candidate
                break
            end
        end

        if camera and camera.camCoords then
            CCTV.openCameraFeed(camera)
        else
            Notify.send(cfg.Locale.cam_no_coords or '~r~Camera coordinates are not set!')
            print('[neox_mrpd_cctv] WARNING: Missing coords for camera ID ' .. tostring(data.camId))
        end

    elseif data.action == 'closeCam' then
        CCTV.closeCameraFeed()
    end
end)

-- ---------------------------------------------------------
-- Camera placement tool
-- ---------------------------------------------------------
local setupMode = false
local setupCam = nil

function CCTV.keyboardInput(prompt, default, maxLength)
    AddTextEntry('CCTV_INPUT_PROMPT', prompt or 'Enter Value')
    DisplayOnscreenKeyboard(1, 'CCTV_INPUT_PROMPT', '', default or '', '', '', '', maxLength or 32)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if GetOnscreenKeyboardResult() then
        return GetOnscreenKeyboardResult()
    end

    return nil
end

function CCTV.cancelSetup(ped)
    setupMode = false

    RenderScriptCams(false, true, 400, true, true)

    if setupCam then
        DestroyCam(setupCam, false)
        setupCam = nil
    end

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
end

-- Walks the operator through naming the camera, then saves it.
function CCTV.promptAndSaveCamera(camCoords, camRot, camFov)
    local cancelled = cfg.Locale.setup_cancelled or '~y~CCTV Camera setup cancelled.'

    local label = CCTV.keyboardInput(
        cfg.Locale.setup_prompt_label or 'Camera Label (e.g. MRPD CAM 05)',
        'MRPD CAM ', 32)

    if not label or label == '' then
        Notify.send(cancelled)
        return
    end

    local name = CCTV.keyboardInput(
        cfg.Locale.setup_prompt_name or 'Location Name (e.g. Main Hall)',
        'Main Hall', 48)

    if not name or name == '' then
        Notify.send(cancelled)
        return
    end

    local district = CCTV.keyboardInput(
        cfg.Locale.setup_prompt_district or 'District (e.g. MRPD)',
        'MRPD', 32)

    if not district or district == '' then
        district = 'General'
    end

    TriggerServerEvent('neox_mrpd_cctv:server:saveCustomCamera', {
        label     = label,
        name      = name,
        district  = district,
        camCoords = camCoords,
        camRot    = camRot,
        camFov    = camFov,
    })
end

RegisterNetEvent('neox_mrpd_cctv:client:startSetup', function()
    if setupMode or viewing or cameraActive then return end

    setupMode = true

    local ped = PlayerPedId()
    local startCoords = GetGameplayCamCoord()
    local startRot = GetGameplayCamRot(2)

    -- Mutated by the loop below.
    local fov = 60.0
    local moveSpeed = 0.4

    setupCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(setupCam, startCoords.x, startCoords.y, startCoords.z)
    SetCamRot(setupCam, startRot.x, startRot.y, startRot.z, 2)
    SetCamFov(setupCam, fov)
    SetCamActive(setupCam, true)
    RenderScriptCams(true, true, 400, true, true)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    Notify.send(cfg.Locale.setup_started or '~g~CCTV Camera Setup Mode Started.~w~')

    CreateThread(function()
        local pitch = startRot.x
        local yaw = startRot.z
        local position = startCoords

        while setupMode do
            Wait(0)

            DisableAllControlActions(0)
            EnableControlAction(0, 249, true)

            local lookX = GetDisabledControlNormal(0, 1)
            local lookY = GetDisabledControlNormal(0, 2)

            if math.abs(lookX) > 0.001 or math.abs(lookY) > 0.001 then
                yaw = (yaw - lookX * 8.0) % 360.0
                pitch = math.max(-85.0, math.min(85.0, pitch - lookY * 8.0))
                SetCamRot(setupCam, pitch, 0.0, yaw, 2)
            end

            local pitchRad = math.rad(pitch)
            local yawRad = math.rad(yaw)

            local forward = vector3(
                -math.sin(yawRad) * math.cos(pitchRad),
                math.cos(yawRad) * math.cos(pitchRad),
                math.sin(pitchRad)
            )

            local right = vector3(math.cos(yawRad), math.sin(yawRad), 0.0)

            local move = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, 32) then move = move + forward * moveSpeed end
            if IsDisabledControlPressed(0, 33) then move = move - forward * moveSpeed end
            if IsDisabledControlPressed(0, 34) then move = move - right * moveSpeed end
            if IsDisabledControlPressed(0, 35) then move = move + right * moveSpeed end
            if IsDisabledControlPressed(0, 22) then move = move + vector3(0.0, 0.0, moveSpeed) end
            if IsDisabledControlPressed(0, 21) then move = move - vector3(0.0, 0.0, moveSpeed) end

            if #move > 1.0E-4 then
                position = position + move
                SetCamCoord(setupCam, position.x, position.y, position.z)
            end

            if IsDisabledControlPressed(0, 44) then
                fov = math.max(20.0, fov - 0.4)
                SetCamFov(setupCam, fov)
            end

            if IsDisabledControlPressed(0, 38) then
                fov = math.min(100.0, fov + 0.4)
                SetCamFov(setupCam, fov)
            end

            if IsDisabledControlJustPressed(0, 241) then
                moveSpeed = math.min(3.0, moveSpeed + 0.05)
            end

            if IsDisabledControlJustPressed(0, 242) then
                moveSpeed = math.max(0.05, moveSpeed - 0.05)
            end

            DrawRect(0.5, 0.92, 0.7, 0.08, 0, 0, 0, 180)

            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.33, 0.33)
            SetTextColour(33, 230, 118, 255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(
                '~g~[W/A/S/D]~w~ Move  ~g~[SPACE/SHIFT]~w~ Up/Down  ~g~[MOUSE]~w~ Look  ~g~[Q/E]~w~ Zoom (FOV: '
                .. string.format('%.1f', fov)
                .. '°)  ~g~[SCROLL]~w~ Spd ('
                .. string.format('%.2f', moveSpeed)
                .. ')')
            DrawText(0.5, 0.89)

            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.33, 0.33)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(
                '~g~[ENTER]~w~ Confirm & Save   ~r~[BACKSPACE/ESC]~w~ Cancel   ~y~XYZ: ('
                .. string.format('%.2f, %.2f, %.2f', position.x, position.y, position.z)
                .. ')~w~')
            DrawText(0.5, 0.93)

            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
                CCTV.cancelSetup(ped)
                Notify.send(cfg.Locale.setup_cancelled or '~y~CCTV Camera setup cancelled.')
                break
            end

            if IsDisabledControlJustPressed(0, 18) or IsDisabledControlJustPressed(0, 201) then
                -- Captured before the camera is torn down.
                local savedCoords = position
                local savedRot = vector3(pitch, 0.0, yaw)
                local savedFov = fov

                CCTV.cancelSetup(ped)

                CreateThread(function()
                    CCTV.promptAndSaveCamera(savedCoords, savedRot, savedFov)
                end)

                break
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if setupMode then
        setupMode = false

        if setupCam then
            DestroyCam(setupCam, false)
            setupCam = nil
        end
    end

    if viewing then
        RenderScriptCams(false, false, 0, true, true)

        if monitorCam then
            DestroyCam(monitorCam, false)
        end

        FreezeEntityPosition(PlayerPedId(), false)
    end

    CCTV.clearTextures()

    if dui then
        DestroyDui(dui)
        dui = nil
    end
end)

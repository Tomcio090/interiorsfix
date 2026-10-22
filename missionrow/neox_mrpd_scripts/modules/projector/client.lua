-- =========================================================
-- NEOX MRPD — BRIEFING PROJECTOR (client)
-- =========================================================
-- Every projector is a screen prop fed by a DUI browser. Most also have
-- a laptop prop that acts as the control surface: opening it swings a
-- camera onto the laptop screen and forwards mouse/keyboard input into
-- that DUI. Standalone projectors are driven by the shared NUI page
-- instead.
-- =========================================================

-- Props the module replaces textures on, with the texture each one uses.
local RELEASE_ON_DISABLE = {
    { 'neox_mrpd_prop_proj_screen',   'neox_mrpd_white_screen_01' },
    { 'neox_mrpd_prop_proj_screen2',  'neox_mrpd_white_screen_02' },
    { 'neox_mrpd_prop_proj_screen3',  'neox_mrpd_white_screen_03' },
    { 'neox_mrpd_prop_proj_screen4',  'neox_mrpd_white_screen_04' },
    { 'neox_mrpd_prop_proj_screen5',  'neox_mrpd_white_screen_05' },
    { 'neox_mrpd_prop_proj_screen6',  'neox_mrpd_white_screen_06' },
    { 'neox_mrpd_prop_proj_screen7',  'neox_mrpd_white_screen_07' },
    { 'neox_mrpd04_r03_laptop_screen', 'neox_mrpd_monitor_screen_03' },
    { 'neox_mrpd04_r13_laptop_screen', 'neox_mrpd_monitor_screen_04' },
    { 'neox_mrpd04_r12_laptop_screen', 'neox_mrpd_monitor_screen_05' },
    { 'neox_mrpd05_r04_laptop_screen', 'neox_mrpd_monitor_screen_06' },
    { 'neox_mrpd06_r05_laptop_screen', 'neox_mrpd_monitor_screen_08' },
    { 'neox_mrpd06_r09_laptop_screen', 'neox_mrpd_monitor_screen_07' },
}

if not NeoxMRPD.enabled('projector') then
    -- Repeated seven times in the original; a replaced texture only needs
    -- releasing once, but the extra calls are harmless no-ops.
    for _ = 1, 7 do
        for _, entry in ipairs(RELEASE_ON_DISABLE) do
            RemoveReplaceTexture(entry[1], entry[2])
        end
    end
    return
end

Proj = Proj or {}

local cfg = NeoxMRPD.Config.Projector

-- ---------------------------------------------------------
-- Built-in projector layout
-- ---------------------------------------------------------
-- config/projector.lua only carries coordinates; everything below (prop
-- models, texture names, DUI sizes, laptop camera and hitbox) lives here
-- and is merged with the config per index.
local DEFAULT_PROJECTORS = {
    {
        Laptop = {
            coords      = vector3(465.77, -983.21, 34.99),
            heading     = 0.0,
            model       = 'neox_mrpd04_r03_laptop_screen',
            textureDict = 'neox_mrpd04_r03_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_03',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(465.868, -983.333, 35.313),
            camRot      = vector3(-18.016, -0.0, 30.575),
            camFov      = 40.0,
            hitbox      = { width = 0.87, height = 0.91, x = 0.51, y = 0.49 },
        },
        Projector = {
            coords      = vector3(465.77, -983.21, 34.99),
            model       = 'neox_mrpd_prop_proj_screen',
            textureDict = 'neox_mrpd_prop_proj_screen',
            textureName = 'neox_mrpd_white_screen_01',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
    {
        Laptop = {
            coords      = vector3(488.73, -988.19, 34.82),
            heading     = 0.0,
            model       = 'neox_mrpd04_r13_laptop_screen',
            textureDict = 'neox_mrpd04_r13_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_04',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(488.602, -988.166, 34.883),
            camRot      = vector3(-18.331, -0.0, -97.029),
            camFov      = 50.0,
            hitbox      = { width = 0.77, height = 0.82, x = 0.51, y = 0.49 },
        },
        Projector = {
            coords      = vector3(484.62, -991.41, 34.82),
            model       = 'neox_mrpd_prop_proj_screen3',
            textureDict = 'neox_mrpd_prop_proj_screen3',
            textureName = 'neox_mrpd_white_screen_03',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
    {
        Laptop = {
            coords      = vector3(474.53, -987.28, 34.82),
            heading     = 0.0,
            model       = 'neox_mrpd04_r12_laptop_screen',
            textureDict = 'neox_mrpd04_r12_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_05',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(474.415, -987.36, 34.816),
            camRot      = vector3(-14.047, -0.0, -64.032),
            camFov      = 50.0,
            hitbox      = { width = 0.72, height = 0.76, x = 0.492, y = 0.495 },
        },
        Projector = {
            coords      = vector3(474.81, -984.74, 34.82),
            model       = 'neox_mrpd_prop_proj_screen4',
            textureDict = 'neox_mrpd_prop_proj_screen4',
            textureName = 'neox_mrpd_white_screen_04',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
    {
        isStandalone = true,
        Projector = {
            coords      = vector3(445.54, -988.15, 34.82),
            model       = 'neox_mrpd_prop_proj_screen2',
            textureDict = 'neox_mrpd_prop_proj_screen2',
            textureName = 'neox_mrpd_white_screen_02',
            duiWidth    = 1280,
            duiHeight   = 720,
            hitbox      = { width = 2.0, height = 2.0, x = 0.0, y = 0.0 },
        },
    },
    {
        Laptop = {
            coords      = vector3(456.57, -987.22, 39.25),
            heading     = 0.0,
            model       = 'neox_mrpd05_r04_laptop_screen',
            textureDict = 'neox_mrpd05_r04_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_06',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(456.41, -987.244, 39.297),
            camRot      = vector3(-15.37, 0.0, -96.51),
            camFov      = 50.0,
            hitbox      = { width = 0.79, height = 0.85, x = 0.497, y = 0.495 },
        },
        Projector = {
            coords      = vector3(453.83, -989.96, 39.25),
            model       = 'neox_mrpd_prop_proj_screen5',
            textureDict = 'neox_mrpd_prop_proj_screen5',
            textureName = 'neox_mrpd_white_screen_05',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
    {
        Laptop = {
            coords      = vector3(465.85, -992.96, 18.67),
            heading     = 0.0,
            model       = 'neox_mrpd06_r05_laptop_screen',
            textureDict = 'neox_mrpd06_r05_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_08',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(466.108, -992.942, 18.86),
            camRot      = vector3(-17.449, -0.0, -166.561),
            camFov      = 45.0,
            hitbox      = { width = 0.89, height = 0.94, x = 0.51, y = 0.495 },
        },
        Projector = {
            coords      = vector3(464.81, -989.04, 18.67),
            model       = 'neox_mrpd_prop_proj_screen6',
            textureDict = 'neox_mrpd_prop_proj_screen6',
            textureName = 'neox_mrpd_white_screen_06',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
    {
        Laptop = {
            coords      = vector3(465.37, -1006.35, 18.67),
            heading     = 0.0,
            model       = 'neox_mrpd06_r09_laptop_screen',
            textureDict = 'neox_mrpd06_r09_laptop_screen',
            textureName = 'neox_mrpd_monitor_screen_07',
            duiWidth    = 1280,
            duiHeight   = 800,
            camCoords   = vector3(465.608, -1006.42, 18.848),
            camRot      = vector3(-14.677, -0.0, 103.088),
            camFov      = 45.0,
            hitbox      = { width = 0.84, height = 0.9, x = 0.495, y = 0.495 },
        },
        Projector = {
            coords      = vector3(468.95, -1005.1, 18.67),
            model       = 'neox_mrpd_prop_proj_screen7',
            textureDict = 'neox_mrpd_prop_proj_screen7',
            textureName = 'neox_mrpd_white_screen_07',
            duiWidth    = 1280,
            duiHeight   = 720,
        },
    },
}

-- Per index, the config block overrides the defaults field by field.
local merged = {}

for index, defaults in ipairs(DEFAULT_PROJECTORS) do
    local override = cfg.Projectors and cfg.Projectors[index]

    if override then
        local entry = {
            isStandalone = override.isStandalone or defaults.isStandalone,
            Projector    = {},
        }

        for key, value in pairs(defaults.Projector) do
            entry.Projector[key] = value
        end

        if override.Projector then
            for key, value in pairs(override.Projector) do
                entry.Projector[key] = value
            end
        end

        if not entry.isStandalone and defaults.Laptop then
            entry.Laptop = {}

            for key, value in pairs(defaults.Laptop) do
                entry.Laptop[key] = value
            end

            if override.Laptop then
                for key, value in pairs(override.Laptop) do
                    entry.Laptop[key] = value
                end
            end
        end

        merged[index] = entry
    else
        merged[index] = defaults
    end
end

cfg.Projectors = merged

-- ---------------------------------------------------------
-- Runtime screen state
-- ---------------------------------------------------------
-- index -> { proj = <screen>, laptop = <screen or nil> }
-- A screen is { cfg, txd, txn, dui, active, txdCreated, gen, activating }.
local screens = {}

for index, projector in ipairs(cfg.Projectors) do
    local entry = {
        proj = {
            cfg        = projector.Projector,
            txd        = 'neox_proj_scr_txd_' .. index,
            txn        = 'neox_proj_scr_txn_' .. index,
            dui        = nil,
            active     = false,
            txdCreated = false,
        },
    }

    if not projector.isStandalone then
        entry.laptop = {
            cfg        = projector.Laptop,
            txd        = 'neox_proj_lap_txd_' .. index,
            txn        = 'neox_proj_lap_txn_' .. index,
            dui        = nil,
            active     = false,
            txdCreated = false,
        }
    end

    screens[index] = entry
end

local editorOpen = false
local laptopLoopActive = false
local laptopCam = nil
local searchFocused = false

-- index -> the encoded applyState message, replayed into new DUIs
local stateMessages = {}
local stateRequested = {}
local stateReceived = {}

local activeProjector = nil

function Proj.debug(format, ...)
    if cfg.Debug then
        print(('[neox_projector] ' .. format):format(...))
    end
end

function Proj.closestObject(coords, model)
    return GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, model, false, false, false)
end

-- ---------------------------------------------------------
-- DUI lifecycle
-- ---------------------------------------------------------
function Proj.ensureDui(screen, mode, index)
    if screen.dui then return end

    local url = ('nui://%s/html/projector/index.html?mode=%s&proj=%d')
        :format(GetCurrentResourceName(), mode, index or 0)

    screen.dui = CreateDui(url, screen.cfg.duiWidth, screen.cfg.duiHeight)

    local deadline = GetGameTimer() + 20000
    while not IsDuiAvailable(screen.dui) and deadline > GetGameTimer() do
        Wait(50)
    end

    if not IsDuiAvailable(screen.dui) then
        print(('[neox_projector] UYARI: %s DUI hazır olmadı! html dosyalarını kontrol et.')
            :format(mode))
    end

    if not screen.txdCreated then
        local txd = CreateRuntimeTxd(screen.txd)
        CreateRuntimeTextureFromDuiHandle(txd, screen.txn, GetDuiHandle(screen.dui))
        screen.txdCreated = true
    end

    Proj.debug('%s DUI hazır (%dx%d)', mode, screen.cfg.duiWidth, screen.cfg.duiHeight)

    Wait(400)
    SendDuiMessage(screen.dui, json.encode({
        type   = 'setLocale',
        locale = cfg.Locale.ui,
    }))

    -- Replay the last known board so a fresh browser is not blank.
    if stateMessages[index] then
        SendDuiMessage(screen.dui, stateMessages[index])
    end

    if not stateRequested[index] then
        stateRequested[index] = true
        TriggerServerEvent('neox_projector:server:requestState', index)
    end
end

-- `gen` is bumped on every activate/deactivate so a thread from an older
-- activation notices it has been superseded and stops.
function Proj.activateScreen(screen, mode, index)
    if screen.active or screen.activating then return end

    screen.activating = true
    screen.gen = (screen.gen or 0) + 1

    local generation = screen.gen

    CreateThread(function()
        Proj.ensureDui(screen, mode, index)

        if screen.gen ~= generation then return end

        RequestStreamedTextureDict(screen.cfg.textureDict, false)
        AddReplaceTexture(screen.cfg.textureDict, screen.cfg.textureName,
            screen.txd, screen.txn)

        screen.active = true
        screen.activating = false

        Proj.debug("%s: AddReplaceTexture '%s'/'%s'",
            mode, screen.cfg.textureDict, screen.cfg.textureName)

        -- The replacement does not always stick on the first try, so it is
        -- reapplied 15 times quickly, then every two seconds.
        for _ = 1, 15 do
            Wait(200)
            if screen.gen ~= generation or not screen.active then return end

            AddReplaceTexture(screen.cfg.textureDict, screen.cfg.textureName,
                screen.txd, screen.txn)
        end

        while screen.gen == generation and screen.active do
            Wait(2000)
            if screen.gen ~= generation or not screen.active then return end

            AddReplaceTexture(screen.cfg.textureDict, screen.cfg.textureName,
                screen.txd, screen.txn)
        end
    end)
end

function Proj.deactivateScreen(screen)
    if not screen.active and not screen.activating then return end

    screen.gen = (screen.gen or 0) + 1

    if screen.active then
        RemoveReplaceTexture(screen.cfg.textureDict, screen.cfg.textureName)
    end

    screen.active = false
    screen.activating = false
end

function Proj.sendToScreen(screen, message)
    if screen.dui then
        SendDuiMessage(screen.dui, message)
    end
end

function Proj.clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if maxValue < value then return maxValue end
    return value
end

-- ---------------------------------------------------------
-- Opening and closing the editor
-- ---------------------------------------------------------
function Proj.closeEditor()
    if not editorOpen then return end

    local index = activeProjector

    activeProjector = nil
    editorOpen = false
    laptopLoopActive = false

    ClearFocus()
    NUI.focus('projector', false, false)
    RenderScriptCams(false, true, 400, true, true)

    if laptopCam then
        DestroyCam(laptopCam, false)
        laptopCam = nil
    end

    FreezeEntityPosition(PlayerPedId(), false)

    if index and cfg.Projectors[index] and cfg.Projectors[index].isStandalone then
        NUI.send('projector', { type = 'closeEditor' })

    elseif index then
        local screen = screens[index]
        if screen and screen.laptop then
            Proj.sendToScreen(screen.laptop, json.encode({ type = 'closeEditor' }))
        end
    end

    if index then
        TriggerServerEvent('neox_projector:server:releaseAccess', index)
    end
end

-- Controls blocked while the laptop has the screen.
local LAPTOP_BLOCKED_CONTROLS = { 1, 2, 24, 25, 30, 31, 36, 44, 142, 106, 200, 177 }

-- Maps the mouse onto the laptop's hitbox and forwards it into the DUI.
function Proj.runLaptopLoop(index)
    local laptop = screens[index].laptop
    local duiWidth = laptop.cfg.duiWidth
    local duiHeight = laptop.cfg.duiHeight

    while laptopLoopActive do
        Wait(0)

        DisablePlayerFiring(PlayerId(), true)

        for _, control in ipairs(LAPTOP_BLOCKED_CONTROLS) do
            DisableControlAction(0, control, true)
        end

        SetMouseCursorActiveThisFrame()
        SetMouseCursorSprite(1)

        -- Crouching shifts the camera, so it is cancelled.
        local ped = PlayerPedId()
        if GetPedStealthMovement(ped) then
            SetPedStealthMovement(ped, false, 0)
            ResetPedMovementClipset(ped, 0.0)
        end

        if laptop.dui then
            local hitbox = laptop.cfg.hitbox

            local width  = (hitbox and hitbox.width) or 0.85
            local height = (hitbox and hitbox.height) or 0.9
            local centerX = (hitbox and hitbox.x) or 0.5
            local centerY = (hitbox and hitbox.y) or 0.5

            if cfg.Debug then
                DrawRect(centerX, centerY, width, height, 255, 0, 0, 80)
            end

            local cursorX = GetDisabledControlNormal(0, 239)
            local cursorY = GetDisabledControlNormal(0, 240)

            local left = centerX - width / 2
            local top = centerY - height / 2

            local duiX = math.floor(Proj.clamp((cursorX - left) / width, 0.0, 1.0) * duiWidth)
            local duiY = math.floor(Proj.clamp((cursorY - top) / height, 0.0, 1.0) * duiHeight)

            SendDuiMouseMove(laptop.dui, duiX, duiY)

            if IsDisabledControlJustPressed(0, 24) then
                SendDuiMouseDown(laptop.dui, 'left')
            end

            if IsDisabledControlJustReleased(0, 24) then
                SendDuiMouseUp(laptop.dui, 'left')
            end

            if IsDisabledControlJustPressed(0, 25) then
                SendDuiMouseDown(laptop.dui, 'right')
            end

            if IsDisabledControlJustReleased(0, 25) then
                SendDuiMouseUp(laptop.dui, 'right')
            end

            if IsDisabledControlJustPressed(0, 241) then
                SendDuiMouseWheel(laptop.dui, 120, 0)
            end

            if IsDisabledControlJustPressed(0, 242) then
                SendDuiMouseWheel(laptop.dui, -120, 0)
            end
        end

        -- Escape / backspace leaves, unless the page has a text field focused.
        if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 177) then
            if not searchFocused then
                Proj.closeEditor()
            end
        end
    end
end

function Proj.openProjector(index)
    if editorOpen then return end

    editorOpen = true
    laptopLoopActive = true
    activeProjector = index

    local projector = cfg.Projectors[index]

    if projector.isStandalone then
        NUI.focus('projector', true, true)
        NUI.send('projector', { type = 'setLocale', locale = cfg.Locale.ui })

        local state = stateMessages[index]
        NUI.send('projector', {
            type  = 'openStandalone',
            state = (state and json.decode(state)) or nil,
        })
    else
        Proj.activateScreen(screens[index].laptop, 'laptop', index)
        NUI.focus('projector', true, false)

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)

        laptopCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

        local laptopCfg = screens[index].laptop.cfg

        if laptopCfg.camCoords and laptopCfg.camRot then
            SetCamCoord(laptopCam, laptopCfg.camCoords.x, laptopCfg.camCoords.y, laptopCfg.camCoords.z)
            SetCamRot(laptopCam, laptopCfg.camRot.x, laptopCfg.camRot.y, laptopCfg.camRot.z, 2)
        else
            -- No authored camera: frame the laptop prop from whichever side
            -- the player is standing on.
            local prop = Proj.closestObject(laptopCfg.coords, laptopCfg.model)

            local propCoords = (prop and prop ~= 0 and GetEntityCoords(prop)) or laptopCfg.coords
            local lookAt = vector3(propCoords.x, propCoords.y, propCoords.z + 0.3)

            local forward
            if prop and prop ~= 0 then
                forward = GetEntityForwardVector(prop)
            else
                local radians = math.rad(laptopCfg.heading or 0.0)
                forward = vector3(-math.sin(radians), math.cos(radians), 0.0)
            end

            forward = vector3(forward.x, forward.y, 0.0)

            local pedCoords = GetEntityCoords(ped)
            local toPlayer = vector3(pedCoords.x - propCoords.x, pedCoords.y - propCoords.y, 0.0)

            -- Flip the facing if the player is behind the prop.
            if forward.x * toPlayer.x + forward.y * toPlayer.y < 0.0 then
                forward = -forward
            end

            local camPos = vector3(
                lookAt.x + forward.x * 0.8,
                lookAt.y + forward.y * 0.8,
                lookAt.z + 0.2
            )

            SetCamCoord(laptopCam, camPos.x, camPos.y, camPos.z)
            PointCamAtCoord(laptopCam, lookAt.x, lookAt.y, lookAt.z)
        end

        SetCamFov(laptopCam, laptopCfg.camFov or 38.0)
        SetCamActive(laptopCam, true)
        RenderScriptCams(true, true, 400, true, true)
    end

    TriggerServerEvent('neox_projector:server:getPresets', index)

    if not cfg.Projectors[index].isStandalone then
        local state = stateMessages[index]

        Proj.sendToScreen(screens[index].laptop, json.encode({
            type  = 'openEditor',
            state = (state and json.decode(state)) or nil,
        }))

        CreateThread(function()
            Proj.runLaptopLoop(index)
        end)
    end
end

-- ---------------------------------------------------------
-- Access
-- ---------------------------------------------------------
local accessPending = false

function Proj.requestOpen(index)
    if editorOpen or accessPending then return end

    accessPending = true
    TriggerServerEvent('neox_projector:server:requestAccess', index)

    -- A reply that never arrives (server-side throttle, dropped event) must
    -- not latch the prompt shut for the rest of the session.
    SetTimeout(3000, function()
        accessPending = false
    end)
end

RegisterNetEvent('neox_projector:client:requestOpen', function(index)
    Proj.requestOpen(index)
end)

RegisterNetEvent('neox_projector:client:accessResult', function(index, granted, reason)
    accessPending = false

    if granted then
        Proj.openProjector(index)
    elseif reason == 'in_use' then
        Notify.send(cfg.Locale.in_use)
    else
        Notify.send(cfg.Locale.no_access)
    end
end)

-- ---------------------------------------------------------
-- Target zones / proximity
-- ---------------------------------------------------------
local targetZonesReady = not Target.enabled(cfg.Target.system, cfg.InteractionType)

CreateThread(function()
    if Target.enabled(cfg.Target.system, cfg.InteractionType) then
        targetZonesReady = ProjectorTarget.setup()
    end
end)

-- Streams screens in and out by distance and draws the [E] prompt.
CreateThread(function()
    local renderDistance =
        (NeoxMRPD.Config and NeoxMRPD.Config.Performance and NeoxMRPD.Config.Performance.screenDistance)
        or (cfg.Performance and cfg.Performance.screenDistance)
        or 30.0

    while true do
        -- Called for its caching side effect; the result is not used below.
        Target.enabled(cfg.Target.system, cfg.InteractionType)

        -- NOTE: the decompiled expression here was `not x or x`, a tautology,
        -- so the prompt gate is always open regardless of targetZonesReady.
        -- Preserved as-is; see the refactor notes before changing it.
        local promptsAllowed = true

        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local anyScreenNear = false

        for index, entry in ipairs(screens) do
            local projector = cfg.Projectors[index]

            local projHeight = math.abs(coords.z - entry.proj.cfg.coords.z)
            local projFlat = #(vector2(coords.x, coords.y)
                - vector2(entry.proj.cfg.coords.x, entry.proj.cfg.coords.y))

            local laptopHeight, laptopFlat = 999.0, 999.0

            if not projector.isStandalone and entry.laptop then
                laptopHeight = math.abs(coords.z - entry.laptop.cfg.coords.z)
                laptopFlat = #(vector2(coords.x, coords.y)
                    - vector2(entry.laptop.cfg.coords.x, entry.laptop.cfg.coords.y))
            end

            -- Either the screen or its laptop being in range keeps the
            -- projector surface alive.
            local projectorNear = (projHeight <= 5.0 and renderDistance > projFlat)
                or (laptopHeight <= 5.0 and renderDistance > laptopFlat)

            if projectorNear then
                anyScreenNear = true
                Proj.activateScreen(entry.proj,
                    (projector.isStandalone and 'projector_standalone') or 'projector',
                    index)
            else
                Proj.deactivateScreen(entry.proj)
            end

            local reach = (cfg.Interact and cfg.Interact.distance)
                or cfg.InteractDistance
                or 2.0

            if projector.isStandalone then
                if promptsAllowed and projHeight <= 2.5 and projFlat < reach then
                    if not editorOpen then
                        sleep = 0
                        Notify.show(cfg.Locale.help_open)

                        if IsControlJustReleased(0, 38) then
                            Proj.requestOpen(index)
                        end
                    end
                end

            elseif entry.laptop then
                local laptopNear = (laptopHeight <= 5.0 and renderDistance > laptopFlat)
                    or (projHeight <= 5.0 and renderDistance > projFlat)

                if laptopNear then
                    anyScreenNear = true
                    Proj.activateScreen(entry.laptop, 'laptop', index)
                else
                    Proj.deactivateScreen(entry.laptop)
                end
            end
        end

        -- The laptop loop clears this flag when it exits.
        if not laptopLoopActive and editorOpen then
            Proj.closeEditor()
        end

        if sleep > 0 then
            sleep = anyScreenNear and 400 or 1000
        end

        Wait(sleep)
    end
end)

-- ---------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------
-- Each one is registered twice: the shared NUI page prefixes its messages
-- with proj_, the per-laptop DUI page does not.
function Proj.onCloseEditor(_, cb)
    cb({ ok = true })
    Proj.closeEditor()
end

RegisterNUICallback('proj_closeEditor', Proj.onCloseEditor)
RegisterNUICallback('closeEditor', Proj.onCloseEditor)

function Proj.onSync(data, cb)
    cb({ ok = true })

    if type(data) == 'table' and type(data.state) == 'table' and activeProjector then
        TriggerServerEvent('neox_projector:server:sync', activeProjector, data.state)
    end
end

RegisterNUICallback('proj_sync', Proj.onSync)
RegisterNUICallback('sync', Proj.onSync)

function Proj.onDuiReady(data, cb)
    cb({ ok = true })

    local index = tonumber(data and data.proj)
    local mode = data and data.mode

    Proj.debug('duiReady: mode=%s, proj=%s', tostring(mode), tostring(index))

    if not (index and screens[index]) then return end

    local screen = (mode == 'laptop' and screens[index].laptop) or screens[index].proj
    if not (screen and screen.dui) then return end

    SendDuiMessage(screen.dui, json.encode({
        type   = 'setLocale',
        locale = cfg.Locale.ui,
    }))

    if stateMessages[index] then
        SendDuiMessage(screen.dui, stateMessages[index])
    else
        TriggerServerEvent('neox_projector:server:requestState', index)
    end
end

RegisterNUICallback('proj_duiReady', Proj.onDuiReady)
RegisterNUICallback('duiReady', Proj.onDuiReady)

function Proj.onPullState(_, cb)
    cb({ ok = true })

    if activeProjector and stateMessages[activeProjector] then
        NUI.send('projector', {
            type  = 'openEditor',
            state = { state = json.decode(stateMessages[activeProjector]).state },
        })
    end
end

RegisterNUICallback('proj_pullState', Proj.onPullState)
RegisterNUICallback('pullState', Proj.onPullState)

-- Standalone page edits are mirrored onto the laptop DUI.
function Proj.onMirror(data, cb)
    cb({ ok = true })

    if type(data) ~= 'table' or type(data.state) ~= 'table' then return end
    if not activeProjector then return end

    local screen = screens[activeProjector]
    if not (screen and screen.laptop) then return end

    Proj.sendToScreen(screen.laptop, json.encode({
        type  = 'mirror',
        state = data.state,
    }))
end

RegisterNUICallback('proj_mirror', Proj.onMirror)
RegisterNUICallback('mirror', Proj.onMirror)

-- While a text field has focus, escape must not close the editor.
function Proj.onSetSearchFocus(data, cb)
    cb({ ok = true })

    searchFocused = data.focused

    NUI.send('projector', {
        type    = 'setSearchFocus',
        focused = data.focused,
    })
end

RegisterNUICallback('proj_setSearchFocus', Proj.onSetSearchFocus)
RegisterNUICallback('setSearchFocus', Proj.onSetSearchFocus)

-- A DUI browser cannot take keyboard input directly, so the shared NUI
-- page captures keys and relays them here.
function Proj.onKeydown(data, cb)
    cb({ ok = true })

    if not activeProjector then return end

    local screen = screens[activeProjector]
    if not (screen and screen.laptop and screen.laptop.dui) then return end

    SendDuiMessage(screen.laptop.dui, json.encode({
        type  = 'forwardKeydown',
        key   = data.key,
        code  = data.code,
        ctrl  = data.ctrl,
        shift = data.shift,
        alt   = data.alt,
    }))
end

RegisterNUICallback('proj_nuiKeydown', Proj.onKeydown)
RegisterNUICallback('nuiKeydown', Proj.onKeydown)

function Proj.onPaste(data, cb)
    cb({ ok = true })

    if not activeProjector then return end

    local screen = screens[activeProjector]
    if not (screen and screen.laptop and screen.laptop.dui) then return end
    if not data.text then return end

    SendDuiMessage(screen.laptop.dui, json.encode({
        type = 'forwardPaste',
        text = data.text,
    }))
end

RegisterNUICallback('proj_nuiPaste', Proj.onPaste)
RegisterNUICallback('nuiPaste', Proj.onPaste)

function Proj.onSavePreset(data, cb)
    cb({ ok = true })

    if activeProjector and type(data) == 'table' then
        TriggerServerEvent('neox_projector:server:savePreset',
            activeProjector, data.name, data.board)
    end
end

RegisterNUICallback('proj_savePreset', Proj.onSavePreset)
RegisterNUICallback('savePreset', Proj.onSavePreset)

function Proj.onDeletePreset(data, cb)
    cb({ ok = true })

    if activeProjector and type(data) == 'table' then
        TriggerServerEvent('neox_projector:server:deletePreset', activeProjector, data.name)
    end
end

RegisterNUICallback('proj_deletePreset', Proj.onDeletePreset)
RegisterNUICallback('deletePreset', Proj.onDeletePreset)

-- ---------------------------------------------------------
-- State sync
-- ---------------------------------------------------------
-- Boards arrive asynchronously; keep asking for any that never showed up.
CreateThread(function()
    Wait(3000)

    for _ = 1, 15 do
        local missing = false

        for index in ipairs(cfg.Projectors) do
            if not stateReceived[index] then
                missing = true
                Proj.debug('state bekleniyor, tekrar isteniyor: proj %d', index)
                TriggerServerEvent('neox_projector:server:requestState', index)
            end
        end

        if not missing then return end

        Wait(3000)
    end
end)

RegisterNetEvent('neox_projector:client:update', function(index, state)
    if type(state) ~= 'table' or not index then return end

    stateReceived[index] = true

    Proj.debug('state ALINDI: proj %d, mode=%s', index, tostring(state.mode))

    stateMessages[index] = json.encode({ type = 'applyState', state = state })

    local screen = screens[index]

    if screen then
        Proj.sendToScreen(screen.proj, stateMessages[index])

        if screen.laptop then
            Proj.sendToScreen(screen.laptop, stateMessages[index])
        end
    end

    if editorOpen and activeProjector == index then
        NUI.send('projector', { type = 'syncAck' })

        if cfg.Projectors[index].isStandalone then
            NUI.send('projector', json.decode(stateMessages[index]))
        end
    end
end)

RegisterNetEvent('neox_projector:client:updatePresets', function(index, presets)
    if activeProjector ~= index then return end

    if cfg.Projectors[index].isStandalone then
        NUI.send('projector', { type = 'updatePresets', presets = presets })
    else
        local screen = screens[index]

        if screen and screen.laptop then
            Proj.sendToScreen(screen.laptop, json.encode({
                type    = 'updatePresets',
                presets = presets,
            }))
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Proj.closeEditor()
    ProjectorTarget.remove()

    for _, entry in ipairs(screens) do
        for _, screen in pairs(entry) do
            Proj.deactivateScreen(screen)

            if screen.dui then
                DestroyDui(screen.dui)
                screen.dui = nil
            end
        end
    end
end)

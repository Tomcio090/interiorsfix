-- =========================================================
-- NEOX MRPD — NOTIFY / TEXT UI BRIDGE  (OPEN FILE — edit freely)
-- =========================================================
-- Every message and every "[E] to open" prompt the resource shows
-- goes through this file. Point it at your own stack once and all
-- five modules follow.
--
-- Driven by config/config.lua:
--   Config.Notify.system    'auto' | 'native' | 'qb' | 'qbox'
--                           | 'esx' | 'ox_lib' | 'okok' | 'custom'
--   Config.Notify.duration  default lifetime in ms
--   Config.Notify.antiSpam  drop identical text inside this window
--   Config.TextUI.system    'auto' | 'native' | 'ox_lib' | 'qb' | 'custom'
--   Config.TextUI.position  ox_lib anchor
--
-- API
--   Notify.send(msg, type, duration)   feed notification
--   Notify.show(msg)                   persistent prompt (show)
--   Notify.hide()                      persistent prompt (hide)
--   Notify.help(msg)                   one-shot help box
--   Notify.topHelp(msg)                help box for per-frame loops
--   Notify.text3D(x, y, z, msg)        world-space label
--   Notify.toPlayer(src, msg, ...)     SERVER side
-- =========================================================

Notify = Notify or {}

local isServer = IsDuplicityVersion()

-- ---------------------------------------------------------
-- Backend resolution
-- ---------------------------------------------------------
local function resourceUp(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local notifyBackend, textBackend

local function resolveNotify()
    if notifyBackend then return notifyBackend end

    local want = (Config.Notify and Config.Notify.system) or 'auto'

    if want ~= 'auto' then
        notifyBackend = want
        return notifyBackend
    end

    if resourceUp('qbx_core')    then notifyBackend = 'qbox'
    elseif resourceUp('qb-core')     then notifyBackend = 'qb'
    elseif resourceUp('ox_lib')      then notifyBackend = 'ox_lib'
    elseif resourceUp('es_extended') then notifyBackend = 'esx'
    elseif resourceUp('okokNotify')  then notifyBackend = 'okok'
    else                                  notifyBackend = 'native'
    end

    return notifyBackend
end

local function resolveTextUI()
    if textBackend then return textBackend end

    local want = (Config.TextUI and Config.TextUI.system) or 'native'

    if want ~= 'auto' then
        textBackend = want
        return textBackend
    end

    if resourceUp('ox_lib') then textBackend = 'ox_lib'
    else                         textBackend = 'native'
    end

    return textBackend
end

-- ox_lib and okokNotify use different type names than QB
local OX_TYPE = { primary = 'inform', info = 'inform', success = 'success', error = 'error' }
local OKOK_TYPE = { primary = 'info', info = 'info', success = 'success', error = 'error' }

-- ---------------------------------------------------------
-- Notify.custom — your own notification resource goes here.
-- Set Config.Notify.system = 'custom' to use it.
-- ---------------------------------------------------------
function Notify.custom(msg, nType, duration)
    -- Example:
    -- exports['my_notify']:Alert(msg, nType, duration)
    print(('[neox_mrpd_scripts] %s: %s'):format(nType, msg))
end

-- ---------------------------------------------------------
-- Notify.send
-- ---------------------------------------------------------
local lastMsg, lastAt = nil, 0

local function nativeNotify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

function Notify.send(msg, nType, duration)
    if isServer or not msg or msg == '' then return end

    local cfg = Config.Notify or {}
    local window = cfg.antiSpam or 0

    if window > 0 then
        local now = GetGameTimer()
        if msg == lastMsg and (now - lastAt) < window then return end
        lastMsg, lastAt = msg, now
    end

    nType = nType or 'primary'
    duration = duration or cfg.duration or 3500

    local backend = resolveNotify()
    local ok = pcall(function()
        if backend == 'qbox' and resourceUp('qbx_core') then
            exports.qbx_core:Notify(msg, nType, duration)

        elseif backend == 'qb' and Bridge.core and Bridge.core.Functions then
            Bridge.core.Functions.Notify(msg, nType, duration)

        elseif backend == 'ox_lib' and resourceUp('ox_lib') then
            exports.ox_lib:notify({
                description = msg,
                type        = OX_TYPE[nType] or 'inform',
                duration    = duration,
            })

        elseif backend == 'esx' and Bridge.core then
            Bridge.core.ShowNotification(msg)

        elseif backend == 'okok' and resourceUp('okokNotify') then
            exports['okokNotify']:Alert('MRPD', msg, duration, OKOK_TYPE[nType] or 'info')

        elseif backend == 'custom' then
            Notify.custom(msg, nType, duration)

        else
            nativeNotify(msg)
        end
    end)

    -- Never lose a message because a notification resource misbehaved.
    if not ok then nativeNotify(msg) end
end

-- ---------------------------------------------------------
-- Persistent prompt: Notify.show / Notify.hide
--
-- The native help box expires by itself, so the modules that draw a
-- prompt do it every frame and simply stop when the player walks
-- away. An ox_lib / qb text UI does NOT expire, so a prompt drawn
-- that way would stick to the screen forever.
--
-- Notify.show is therefore refresh-based: it remembers the frame it
-- was last called on, and a watchdog closes the prompt once nothing
-- has refreshed it. Callers may keep calling it every frame exactly
-- as they did with the native box, and every backend behaves.
-- ---------------------------------------------------------
local textShown  = false
local textMsg    = nil
local lastShowAt = 0

local REFRESH_GRACE = 250 -- ms without a refresh before the prompt closes

local function openText(msg, backend)
    if backend == 'ox_lib' and resourceUp('ox_lib') then
        pcall(function()
            exports.ox_lib:showTextUI(msg, {
                position = (Config.TextUI and Config.TextUI.position) or 'left-center',
            })
        end)
    elseif backend == 'qb' then
        pcall(function() TriggerEvent('qb-core:client:DrawText', msg, 'left') end)
    elseif backend == 'custom' then
        Notify.customTextUI(msg, true)
    end
end

local function closeText(backend)
    if backend == 'ox_lib' and resourceUp('ox_lib') then
        pcall(function() exports.ox_lib:hideTextUI() end)
    elseif backend == 'qb' then
        pcall(function() TriggerEvent('qb-core:client:HideText') end)
    elseif backend == 'custom' then
        Notify.customTextUI(nil, false)
    else
        ClearAllHelpMessages()
    end
end

function Notify.show(msg)
    if isServer or not msg then return end

    lastShowAt = GetGameTimer()
    local backend = resolveTextUI()

    if backend == 'native' or backend == 'auto' then
        -- redraws itself each frame; nothing to track
        Notify.topHelp(msg)
        textShown = true
        textMsg = msg
        return
    end

    if not textShown then
        openText(msg, backend)
        textShown = true
        textMsg = msg
    elseif msg ~= textMsg then
        -- text changed while the prompt was up
        closeText(backend)
        openText(msg, backend)
        textMsg = msg
    end
end

function Notify.hide()
    if isServer or not textShown then return end
    textShown = false
    textMsg = nil
    closeText(resolveTextUI())
end

-- Watchdog: closes a prompt nothing is refreshing any more.
if not isServer then
    CreateThread(function()
        while true do
            Wait(150)
            if textShown and (GetGameTimer() - lastShowAt) > REFRESH_GRACE then
                Notify.hide()
            end
        end
    end)
end

-- Set Config.TextUI.system = 'custom' to use this.
function Notify.customTextUI(msg, visible)
    -- Example:
    -- if visible then exports['my_textui']:Show(msg) else exports['my_textui']:Hide() end
end

-- ---------------------------------------------------------
-- Notify.help — one-shot instructional box (plays a sound)
-- ---------------------------------------------------------
function Notify.help(msg)
    if isServer or not msg then return end
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local lastTopHelpMsg = nil

function Notify.topHelp(msg)
    if isServer or not msg then return end
    if msg ~= lastTopHelpMsg then
        AddTextEntry('NEOX_MRPD_HELP', msg)
        lastTopHelpMsg = msg
    end
    BeginTextCommandDisplayHelp('NEOX_MRPD_HELP')
    EndTextCommandDisplayHelp(0, false, false, -1)
end

-- ---------------------------------------------------------
-- Notify.text3D — floating world-space label
-- ---------------------------------------------------------
function Notify.text3D(x, y, z, text)
    if isServer or not text then return end

    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)

    local factor = string.len(text) / 370
    DrawRect(sx, sy + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- ---------------------------------------------------------
-- Notify.toPlayer — SERVER side
-- ---------------------------------------------------------
function Notify.toPlayer(src, msg, nType, chatPrefix)
    if not isServer or not src or src <= 0 or not msg then return end

    nType = nType or 'primary'

    local ok = pcall(function()
        if Bridge.isQBox() and resourceUp('qbx_core') then
            exports.qbx_core:Notify(src, msg, nType)
        elseif Bridge.isQB() then
            TriggerClientEvent('QBCore:Notify', src, msg, nType)
        elseif Bridge.isESX() then
            TriggerClientEvent('esx:showNotification', src, msg)
        else
            error('no framework notify')
        end
    end)

    if not ok then
        local colour = (nType == 'error') and '^1' or '^2'
        TriggerClientEvent('chat:addMessage', src, {
            args = { colour .. (chatPrefix or '[MRPD]'), msg },
        })
    end
end

-- A stale text UI must never survive a resource restart.
if not isServer then
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            Notify.hide()
        end
    end)
end

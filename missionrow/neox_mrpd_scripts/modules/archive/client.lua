-- =========================================================
-- NEOX MRPD — DIGITAL ARCHIVE (client)
-- =========================================================

if not NeoxMRPD.enabled('archive') then return end

Arch = Arch or {}

local cfg = NeoxMRPD.Config.Archive

local archiveOpen = false
local accessPending = false

local ANIM_DICT = (cfg.Animation and cfg.Animation.dict)
    or 'anim@amb@casino@hangout@ped_male@stand@02b@idles'
local ANIM_NAME = (cfg.Animation and cfg.Animation.name) or 'idle_a'

-- Every label the NUI panel needs; each one is looked up by its own name.
local PANEL_TEXT_KEYS = {
    'header_title', 'header_subtitle', 'badge_text',
    'label_rank', 'label_name', 'label_badge', 'label_service', 'label_status',
    'val_rank', 'val_name', 'val_badge', 'val_service', 'val_status',
    'footer_copy', 'footer_close', 'story',
}

-- Falls back to the key itself so a missing translation shows something.
function Arch.text(key)
    return (cfg.Locale and cfg.Locale[key]) or key
end

-- ---------------------------------------------------------
-- Opening / closing the panel
-- ---------------------------------------------------------
function Arch.open()
    if archiveOpen then return end
    archiveOpen = true

    local ped = PlayerPedId()

    CreateThread(function()
        RequestAnimDict(ANIM_DICT)
        while not HasAnimDictLoaded(ANIM_DICT) do
            Wait(10)
        end

        -- May have been closed again while the dict was streaming in.
        if archiveOpen then
            TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end)

    local payload = {
        action = 'open',
        type   = 'SHOW_ARCHIVE',
        photo  = cfg.OfficerPhoto or 'officer.png',
    }

    for _, key in ipairs(PANEL_TEXT_KEYS) do
        payload[key] = Arch.text(key)
    end

    NUI.send('archive', payload)
    NUI.focus('archive', true, true)

    -- Releases focus once something else flips archiveOpen back to false.
    CreateThread(function()
        while archiveOpen do
            Wait(100)
        end

        NUI.focus('archive', false, false)
        EnableAllControlActions(0)
    end)
end

function Arch.close()
    if not archiveOpen then return end
    archiveOpen = false

    NUI.send('archive', { action = 'close', type = 'HIDE_ARCHIVE' })
    NUI.focus('archive', false, false)
    ClearPedTasks(PlayerPedId())
end

function Arch.requestOpen()
    if archiveOpen or accessPending then return end

    local access = cfg.Access

    -- Restricted shafts ask the server to vet the player; unrestricted ones
    -- open straight away.
    if access and access.restrict then
        accessPending = true
        TriggerServerEvent('neox_mrpd_archive:server:requestAccess')

        -- A reply that never arrives (server-side throttle, dropped event)
        -- must not latch the prompt shut for the rest of the session.
        SetTimeout(3000, function()
            accessPending = false
        end)
    else
        Arch.open()
    end
end

RegisterNetEvent('neox_mrpd_archive:client:accessResult', function(granted)
    accessPending = false

    if granted then
        Arch.open()
    else
        Notify.send(Arch.text('no_access'), 'error', 4000)
    end
end)

RegisterNUICallback('closeArchive', function(_, cb)
    Arch.close()
    cb('ok')
end)

-- ---------------------------------------------------------
-- Interaction
-- ---------------------------------------------------------
function Arch.targetEnabled()
    return Target.enabled(cfg.Target.system, cfg.InteractionType)
end

function Arch.removeTargets()
    Target.removeAll('neox_mrpd_archive_')
end

function Arch.setupTarget()
    if not Arch.targetEnabled() then return end

    Arch.removeTargets()

    local target = cfg.Target or {}

    Target.addBox('neox_mrpd_archive_point', cfg.Coords,
        target.size or vec3(1.2, 1.2, 1.5),
        target.heading or 0.0,
        {
            {
                icon        = target.icon or 'fas fa-box-archive',
                label       = Arch.text('target_label') or Arch.text('blip_label'),
                distance    = target.distance or 2.0,
                action      = function() Arch.requestOpen() end,
                canInteract = function() return not archiveOpen end,
            },
        },
        cfg.Target.system, cfg.InteractionType)
end

function Arch.refreshTargets()
    Wait(1000)
    Arch.setupTarget()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', Arch.refreshTargets)
RegisterNetEvent('esx:playerLoaded', Arch.refreshTargets)
AddEventHandler('playerSpawned', Arch.refreshTargets)

CreateThread(function()
    Wait(1500)
    Arch.setupTarget()
end)

-- [E] prompt loop — used when targeting is off
CreateThread(function()
    while true do
        local sleep = 2000
        local coords = GetEntityCoords(PlayerPedId())
        local dist = #(coords - cfg.Coords)

        if dist < 15.0 then sleep = 500 end

        if not Arch.targetEnabled() then
            if dist < (cfg.InteractionDistance or 1.0) then
                sleep = 0

                if not archiveOpen then
                    Notify.show(Arch.text('prompt_label'))

                    if IsControlJustReleased(0, 38) then
                        Arch.requestOpen()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ---------------------------------------------------------
-- Blip
-- ---------------------------------------------------------
CreateThread(function()
    if not (cfg.Blip and cfg.Blip.enable) then return end

    local blip = AddBlipForCoord(cfg.Coords.x, cfg.Coords.y, cfg.Coords.z)
    SetBlipSprite(blip, cfg.Blip.sprite or 57)
    SetBlipColour(blip, cfg.Blip.color or 3)
    SetBlipScale(blip, cfg.Blip.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Arch.text('blip_label'))
    EndTextCommandSetBlipName(blip)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if archiveOpen then
        Arch.close()
    end

    Arch.removeTargets()
end)

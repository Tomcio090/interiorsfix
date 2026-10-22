-- =========================================================
-- NEOX MRPD — HYGIENE: SINKS (WASH HANDS)
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

local cfg = NeoxMRPD.Config.Hygiene

local WASH_DICT = 'missheist_agency3aig_23'
local WASH_ANIM = 'urinal_sink_loop'
local DRY_DICT  = 'mp_arresting'
local DRY_ANIM  = 'a_uncuff'

RegisterNetEvent('neox_shower:startWashHands')
AddEventHandler('neox_shower:startWashHands', function(index)
    if Hyg.busy then
        Notify.send(cfg.Locale.busy, 'error')
        return
    end

    local sink = cfg.Sinks[index]
    if not sink then return end

    Hyg.busy = true

    local ped = PlayerPedId()
    Notify.send(cfg.Locale.wash_start, 'info')

    Hyg.exitFirstPerson()

    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, sink.pos.x, sink.pos.y, sink.pos.z, false, false, false)
    SetEntityHeading(ped, sink.heading)
    Wait(500)

    Hyg.loadAnimDict(WASH_DICT)
    TaskPlayAnim(ped, WASH_DICT, WASH_ANIM, 8.0, -8.0, 2500, 49, 0.0, 0, 0, 0)
    FreezeEntityPosition(ped, true)

    TriggerServerEvent('neox_shower:syncWash', sink.waterPos)
    PlaySoundFromEntity(-1, 'Event_Message_Purple', ped, 'GTAO_FM_Events_Soundset', 0, 0)
    Wait(2500)

    FreezeEntityPosition(ped, false)

    Hyg.loadAnimDict(DRY_DICT)
    TaskPlayAnim(ped, DRY_DICT, DRY_ANIM, 8.0, -8.0, 5000, 49, 0.0, 0, 0, 0)
    Wait(5000)

    ClearPedTasks(ped)
    Notify.send(cfg.Locale.wash_done, 'success')
    Hyg.relieveStress('washHands')
    Hyg.busy = false

    TriggerServerEvent('neox_shower:setSinkUse', index, false)
end)

-- Running water for everyone else nearby.
RegisterNetEvent('neox_shower:syncWashFx')
AddEventHandler('neox_shower:syncWashFx', function(waterPos, serverId)
    CreateThread(function()
        if not Hyg.resolveSyncPed(waterPos, serverId) then return end

        Hyg.loadPtfx('core')

        local deadline = GetGameTimer() + 2500
        while deadline > GetGameTimer() do
            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedAtCoord('water_splash_ped',
                waterPos.x, waterPos.y, waterPos.z,
                0.0, 0.0, 0.0,
                cfg.SinkParticleScale or 0.3,
                false, false, false)
            Wait(100)
        end
    end)
end)

--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — HYGIENE: TOILETS
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

local cfg = NeoxMRPD.Config.Hygiene

local SEAT_SCENARIO = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER'
local PELVIS_BONE   = 11816

-- Particle handles currently playing, keyed by the owner's server id.
local poopFx = {}
local peeFx = {}

-- Component 4 is the legs slot; 14 / 15 are the underwear drawables.
function Hyg.wearUnderwear(ped, gender)
    if gender == 'male' then
        SetPedComponentVariation(ped, 4, 14, 0, 2)
    else
        SetPedComponentVariation(ped, 4, 15, 0, 2)
    end
end

-- Sitting is handled with a scenario rather than an animation so the ped
-- lines up with the bowl.
function Hyg.sitOnToilet(ped)
    local seat = GetOffsetFromEntityInWorldCoords(ped, 0.0, -0.5, -0.5)
    ClearPedTasks(ped)
    TaskStartScenarioAtPosition(ped, SEAT_SCENARIO,
        seat.x, seat.y, seat.z, GetEntityHeading(ped), 0, true, false)
end

-- Drops the player onto the toilet coordinates and settles them there.
function Hyg.placeAtToilet(ped, toilet, heading)
    Hyg.exitFirstPerson()

    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, toilet.pos.x, toilet.pos.y, toilet.pos.z, false, false, false)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    Wait(500)
    FreezeEntityPosition(ped, false)
end

-- ---------------------------------------------------------
-- Pooping
-- ---------------------------------------------------------
RegisterNetEvent('neox_shower:startPoop')
AddEventHandler('neox_shower:startPoop', function(index)
    if Hyg.busy then
        Notify.send(cfg.Locale.busy, 'error')
        return
    end

    local toilet = cfg.Toilets[index]
    if not toilet then return end

    Hyg.busy = true

    local ped = PlayerPedId()
    local gender = Bridge.GetPlayerGender()

    Notify.send(cfg.Locale.poop_start, 'info')
    Hyg.saveClothing(ped)
    Hyg.wearUnderwear(ped, gender)

    Hyg.placeAtToilet(ped, toilet, toilet.heading)

    TriggerServerEvent('neox_shower:syncPoop', gender)

    if gender == 'female' then
        Hyg.sitOnToilet(ped)
    else
        Hyg.loadAnimDict('timetable@ron@ig_3_couch')
        TaskPlayAnim(ped, 'timetable@ron@ig_3_couch', 'base', 1.0, -1.0, -1, 1, 1, 0, 0, 0)
    end

    Wait(cfg.PoopDuration or 5000)

    ClearPedTasks(ped)
    Hyg.restoreClothing(ped)
    Notify.send(cfg.Locale.poop_done, 'success')
    Hyg.relieveStress('poop')
    Wait(1000)

    Hyg.loadAnimDict('move_p_m_two_idles@generic')
    TaskPlayAnim(ped, 'move_p_m_two_idles@generic', 'fidget_sniff_fingers',
        8.0, -8.0, 3000, 0, 0.0, 0, 0, 0)
    Wait(3000)

    ClearPedTasks(ped)
    Hyg.busy = false

    TriggerServerEvent('neox_shower:setToiletUse', index, false)
end)

-- ---------------------------------------------------------
-- Urinating
-- ---------------------------------------------------------
RegisterNetEvent('neox_shower:startPee')
AddEventHandler('neox_shower:startPee', function(index)
    if Hyg.busy then
        Notify.send(cfg.Locale.busy, 'error')
        return
    end

    local toilet = cfg.Toilets[index]
    if not toilet then return end

    Hyg.busy = true

    local ped = PlayerPedId()
    local gender = Bridge.GetPlayerGender()

    Notify.send(cfg.Locale.pee_start, 'info')

    if gender == 'female' then
        Hyg.saveClothing(ped)
        Hyg.wearUnderwear(ped, gender)
    end

    -- Men stand facing away from the bowl.
    local heading = toilet.heading
    if gender == 'male' then
        heading = heading - 180.0
    end

    Hyg.placeAtToilet(ped, toilet, heading)

    TriggerServerEvent('neox_shower:syncPee', gender)

    local duration = cfg.PeeDuration or 5000

    if gender == 'female' then
        Hyg.sitOnToilet(ped)
    else
        Hyg.loadAnimDict('misscarsteal2peeing')
        TaskPlayAnim(ped, 'misscarsteal2peeing', 'peeing_loop',
            8.0, -8.0, duration, 0, 0.0, 0, 0, 0)
    end

    Wait(duration)

    ClearPedTasks(ped)
    Notify.send(cfg.Locale.pee_done, 'success')
    Hyg.relieveStress('pee')
    Hyg.busy = false

    if gender == 'female' then
        Hyg.restoreClothing(ped)
    end

    TriggerServerEvent('neox_shower:setToiletUse', index, false)
end)

-- ---------------------------------------------------------
-- Effects for everyone else nearby
-- ---------------------------------------------------------
RegisterNetEvent('neox_shower:syncPoopFx')
AddEventHandler('neox_shower:syncPoopFx', function(originPos, serverId, gender)
    CreateThread(function()
        local ped = Hyg.resolveSyncPed(originPos, serverId)
        if not ped then return end

        Hyg.loadPtfx('scr_amb_chop')
        poopFx[serverId] = {}

        local boneIndex = GetPedBoneIndex(ped, PELVIS_BONE)
        local duration = cfg.PoopDuration or 5000
        local bursts = math.max(1, math.floor(math.max(1000, duration - 2000) / 1500))

        Wait(2000)

        for _ = 0, bursts do
            UseParticleFxAssetNextCall('scr_amb_chop')

            local offsetY, offsetZ
            if gender == 'male' then
                offsetY, offsetZ = -0.6, -0.7
            else
                offsetY, offsetZ = -0.1, -0.25
            end

            local handle = StartParticleFxLoopedOnPedBone('ent_anim_dog_poo', ped,
                0.0, offsetY, offsetZ,
                0.0, 0.0, 20.0,
                boneIndex, 1.5, false, false, false)

            table.insert(poopFx[serverId], handle)
            Wait(1500)
        end

        Hyg.clearFx(poopFx[serverId])
        poopFx[serverId] = nil
    end)
end)

RegisterNetEvent('neox_shower:syncPeeFx')
AddEventHandler('neox_shower:syncPeeFx', function(originPos, serverId, gender)
    CreateThread(function()
        local ped = Hyg.resolveSyncPed(originPos, serverId)
        if not ped then return end

        Hyg.loadPtfx('core')
        peeFx[serverId] = {}

        local boneIndex = GetPedBoneIndex(ped, PELVIS_BONE)
        UseParticleFxAssetNextCall('core')

        local handle
        if gender == 'male' then
            handle = StartParticleFxLoopedOnPedBone('ent_amb_peeing', ped,
                0.0, 0.2, 0.0,
                -140.0, 0.0, 0.0,
                boneIndex, 1.0, false, false, false)
        else
            handle = StartParticleFxLoopedOnPedBone('ent_amb_peeing', ped,
                0.0, 0.0, -0.35,
                0.0, 0.0, 20.0,
                boneIndex, 0.1, false, false, false)
        end

        table.insert(peeFx[serverId], handle)

        -- Keep wiping the puddle decals the effect leaves behind.
        local deadline = GetGameTimer() + (cfg.PeeDuration or 5000)

        while deadline > GetGameTimer() do
            local pedCoords = GetEntityCoords(ped)
            RemoveDecalsInRange(pedCoords.x, pedCoords.y, pedCoords.z - 1.0, 2.0)
            Wait(200)
        end

        Hyg.clearFx(peeFx[serverId])
        RemoveParticleFxFromEntity(ped)
        peeFx[serverId] = nil
    end)
end)

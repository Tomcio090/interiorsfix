--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — HYGIENE: SHOWERS
-- =========================================================
-- Also owns saveClothing / restoreClothing, which toilet.lua reuses.
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

local cfg = NeoxMRPD.Config.Hygiene

local showerActive = false
local showerCam = nil

-- Component/prop snapshot taken before the player strips down.
local savedComponents = {}
local savedProps = {}

local MALE_SHOWER_ANIMS = {
    { dict = 'anim@mp_yacht@shower@male@', anim = 'male_shower_idle_a' },
    { dict = 'anim@mp_yacht@shower@male@', anim = 'male_shower_idle_c' },
    { dict = 'anim@mp_yacht@shower@male@', anim = 'male_shower_idle_d' },
}

local FEMALE_SHOWER_ANIMS = {
    { dict = 'mp_safehouseshower@female@',   anim = 'shower_idle_a' },
    { dict = 'anim@mp_yacht@shower@female@', anim = 'shower_idle_a' },
    { dict = 'anim@mp_yacht@shower@female@', anim = 'shower_idle_b' },
}

local FEMALE_ENTER_DICT = 'mp_safehouseshower@female@'
local FEMALE_ENTER_ANIM = 'shower_enter_into_idle'
local MALE_ENTER_DICT   = 'anim@mp_yacht@shower@male@'
local MALE_ENTER_ANIM   = 'male_shower_idle_d'

-- Movement, attacking, entering vehicles and swapping weapons while in
-- the shower.
local BLOCKED_CONTROLS = { 1, 2, 24, 25, 30, 31, 36, 44, 142, 106 }

local EXIT_CONTROL = 73 -- INPUT_VEH_DUCK

-- ---------------------------------------------------------
-- Clothing snapshot / restore (shared with toilet.lua)
-- ---------------------------------------------------------
function Hyg.saveClothing(ped)
    savedComponents = {}
    for component = 0, 11 do
        savedComponents[component] = {
            drawable = GetPedDrawableVariation(ped, component),
            texture  = GetPedTextureVariation(ped, component),
        }
    end

    savedProps = {}
    for slot = 0, 7 do
        savedProps[slot] = {
            index   = GetPedPropIndex(ped, slot),
            texture = GetPedPropTextureIndex(ped, slot),
        }
    end
end

function Hyg.restoreClothing(ped)
    for component = 0, 11 do
        local saved = savedComponents[component]
        if saved then
            SetPedComponentVariation(ped, component, saved.drawable, saved.texture, 2)
        end
    end

    for slot = 0, 7 do
        local saved = savedProps[slot]

        -- A saved index of -1 means the slot was empty, so clear it rather
        -- than restoring it.
        if saved and saved.index ~= -1 then
            SetPedPropIndex(ped, slot, saved.index, saved.texture, true)
        else
            ClearPedProp(ped, slot)
        end
    end

    savedComponents = {}
    savedProps = {}
end

function Hyg.stripForShower(ped)
    local gender = Bridge.GetPlayerGender()

    SetPedComponentVariation(ped, 3, 15, 0, 2)
    SetPedComponentVariation(ped, 8, 15, 0, 2)
    SetPedComponentVariation(ped, 11, 15, 0, 2)

    if gender == 'male' then
        SetPedComponentVariation(ped, 4, 14, 0, 2)
        SetPedComponentVariation(ped, 6, 34, 0, 2)
    else
        SetPedComponentVariation(ped, 4, 15, 0, 2)
        SetPedComponentVariation(ped, 6, 35, 0, 2)
    end

    ClearAllPedProps(ped)
end

-- ---------------------------------------------------------
-- Camera
-- ---------------------------------------------------------
function Hyg.createCamera(ped)
    local camOffset = cfg.ShowerCamOffset
    local lookAtOffset = cfg.ShowerCamLookAt

    local camPos = GetOffsetFromEntityInWorldCoords(ped, camOffset.x, camOffset.y, camOffset.z)
    local lookAt = GetOffsetFromEntityInWorldCoords(ped, lookAtOffset.x, lookAtOffset.y, lookAtOffset.z)

    showerCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(showerCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(showerCam, lookAt.x, lookAt.y, lookAt.z)
    SetCamFov(showerCam, cfg.ShowerCamFov)
    SetCamActive(showerCam, true)
    RenderScriptCams(true, true, 1000, true, false)
end

function Hyg.destroyCamera()
    if not showerCam then return end

    RenderScriptCams(false, true, 1000, true, false)
    DestroyCam(showerCam, false)
    showerCam = nil
end

-- ---------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------
-- Offsets in the config are shower-relative, so rotate them onto the
-- shower's heading before they are used as world coordinates.
function Hyg.rotateOffset(origin, offset, heading)
    local radians = math.rad(heading)
    local cosH, sinH = math.cos(radians), math.sin(radians)

    return
        origin.x + offset.x * cosH + offset.y * sinH,
        origin.y + offset.x * sinH - offset.y * cosH,
        origin.z + offset.z
end

-- True while the ped is in any of the shower animations.
function Hyg.isShowerAnimPlaying(ped)
    if IsEntityPlayingAnim(ped, FEMALE_ENTER_DICT, FEMALE_ENTER_ANIM, 3) then
        return true
    end

    for _, entry in pairs(MALE_SHOWER_ANIMS) do
        if IsEntityPlayingAnim(ped, entry.dict, entry.anim, 3) then return true end
    end

    for _, entry in pairs(FEMALE_SHOWER_ANIMS) do
        if IsEntityPlayingAnim(ped, entry.dict, entry.anim, 3) then return true end
    end

    return false
end

-- ---------------------------------------------------------
-- Taking a shower
-- ---------------------------------------------------------
RegisterNetEvent('neox_shower:startShower')
AddEventHandler('neox_shower:startShower', function(index)
    if Hyg.busy then
        Notify.send(cfg.Locale.busy, 'error')
        return
    end

    local shower = cfg.Showers[index]
    if not shower then return end

    Hyg.busy = true
    showerActive = true

    local ped = PlayerPedId()
    local gender = Bridge.GetPlayerGender()

    Hyg.saveClothing(ped)
    Hyg.stripForShower(ped)

    local offset = cfg.ShowerPlayerOffset or vector3(0.0, 0.0, 0.0)
    local standX, standY, standZ = Hyg.rotateOffset(shower.pos, offset, shower.heading)

    Hyg.exitFirstPerson()

    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, standX, standY, standZ, false, false, false)
    SetEntityHeading(ped, shower.heading)
    FreezeEntityPosition(ped, true)
    Wait(500)

    Hyg.createCamera(ped)
    TriggerServerEvent('neox_shower:syncShower', shower.pos, shower.heading)

    if gender == 'female' then
        Hyg.loadAnimDict(FEMALE_ENTER_DICT)
        TaskPlayAnim(ped, FEMALE_ENTER_DICT, FEMALE_ENTER_ANIM, 8.0, -8.0, 5000, 0, 0.0, 0, 0, 0)
        Wait(4000)
    else
        Hyg.loadAnimDict(MALE_ENTER_DICT)
        TaskPlayAnim(ped, MALE_ENTER_DICT, MALE_ENTER_ANIM, 8.0, -8.0, 5000, 0, 0.0, 0, 0, 0)
        Wait(3000)
    end

    local animSet = (gender == 'female' and FEMALE_SHOWER_ANIMS) or MALE_SHOWER_ANIMS
    local animIndex = 1

    local deadline = GetGameTimer() + (cfg.ShowerDuration or 20000)
    local exitPrompt = cfg.Locale.shower_exit or 'Press ~INPUT_VEH_DUCK~ to exit the shower'

    -- Outer pass cycles the idle animations; the inner pass holds each one
    -- for six seconds while blocking input and watching for the exit key.
    while showerActive and deadline > GetGameTimer() do
        local entry = animSet[animIndex]
        Hyg.loadAnimDict(entry.dict)
        TaskPlayAnim(ped, entry.dict, entry.anim, 8.0, -8.0, -1, 0, 0.0, 0, 0, 0)

        local animUntil = GetGameTimer() + 6000

        while showerActive and animUntil > GetGameTimer() and deadline > GetGameTimer() do
            DisablePlayerFiring(PlayerId(), true)

            for _, control in ipairs(BLOCKED_CONTROLS) do
                DisableControlAction(0, control, true)
            end

            Notify.show(exitPrompt)

            if IsControlJustPressed(0, EXIT_CONTROL) then
                showerActive = false
                TriggerServerEvent('neox_shower:stopShower')
                break
            end

            Wait(0)
        end

        animIndex = (animIndex % #animSet) + 1
    end

    -- Ran out the clock rather than pressing the exit key.
    if showerActive then
        showerActive = false
        TriggerServerEvent('neox_shower:stopShower')
    end

    Notify.hide()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    Hyg.destroyCamera()
    Hyg.restoreClothing(ped)
    Notify.send(cfg.Locale.shower_done, 'success')
    Hyg.relieveStress('shower')
    Hyg.busy = false

    TriggerServerEvent('neox_shower:setShowerUse', index, false)
end)

-- ---------------------------------------------------------
-- Running water for everyone else nearby
-- ---------------------------------------------------------
local showerFx = {}

RegisterNetEvent('neox_shower:syncShowerEffect')
AddEventHandler('neox_shower:syncShowerEffect', function(showerPos, heading, originPos, serverId)
    CreateThread(function()
        if not Hyg.resolveSyncPed(originPos, serverId) then return end

        Hyg.loadPtfx('scr_carwash')
        showerFx[serverId] = {}
        UseParticleFxAssetNextCall('scr_carwash')

        local rotation = cfg.ShowerParticleRotation
        local fxX, fxY, fxZ = Hyg.rotateOffset(showerPos, cfg.ShowerParticleOffset, heading)

        local handle = StartParticleFxLoopedAtCoord('ent_amb_car_wash_jet',
            fxX, fxY, fxZ,
            rotation.x, rotation.y, rotation.z + heading + 180.0,
            cfg.ShowerParticleScale,
            false, false, false, false)

        table.insert(showerFx[serverId], handle)

        -- Hard five-minute ceiling in case the stop event never arrives.
        local elapsed = 0

        while 300000 > elapsed do
            Wait(1000)
            elapsed = elapsed + 1000

            if showerFx[serverId] == nil then break end

            local targetPed = GetPlayerPed(GetPlayerFromServerId(serverId))
            if targetPed == 0 then break end

            -- Two consecutive misses mean they are out of the shower; a
            -- single miss is usually just an animation transition.
            if not Hyg.isShowerAnimPlaying(targetPed) then
                Wait(2000)
                if not Hyg.isShowerAnimPlaying(targetPed) and showerFx[serverId] ~= nil then
                    break
                end
            end
        end

        if showerFx[serverId] then
            Hyg.clearFx(showerFx[serverId])
            showerFx[serverId] = nil
        end
    end)
end)

RegisterNetEvent('neox_shower:stopShowerEffect')
AddEventHandler('neox_shower:stopShowerEffect', function(serverId)
    if not showerFx[serverId] then return end

    Hyg.clearFx(showerFx[serverId])
    showerFx[serverId] = nil
end)

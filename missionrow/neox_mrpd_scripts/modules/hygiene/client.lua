--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — HYGIENE: SHARED HELPERS, OCCUPANCY, INTERACTION
-- =========================================================
-- Owns the [E] prompt loop and the target-zone registration for
-- every shower, toilet and sink. The activities themselves live in
-- shower.lua / toilet.lua / sink.lua.
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

local cfg = NeoxMRPD.Config.Hygiene

-- ---------------------------------------------------------
-- Helpers shared with the activity files
-- ---------------------------------------------------------
function Hyg.drawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)

    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)

    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function Hyg.distance(from, to)
    return #(from - to)
end

function Hyg.loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

function Hyg.loadPtfx(asset)
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(10)
    end
end

-- A spot parked at x=0, y=0 is a disabled placeholder row in the config.
function Hyg.isPlaceholder(spot)
    return spot.pos.x == 0.0 and spot.pos.y == 0.0
end

-- First person hides the activity animations, so drop back to third.
function Hyg.exitFirstPerson()
    if GetFollowPedCamViewMode() == 4 then
        SetFollowPedCamViewMode(0)
        Wait(50)
    end
end

function Hyg.clearFx(handles)
    for _, handle in pairs(handles or {}) do
        StopParticleFxLooped(handle, true)
        RemoveParticleFx(handle, false)
    end
end

-- Shared gate for the sync-effect handlers: returns the owning player's
-- ped, or nil when they are out of range or no longer streamed in.
function Hyg.resolveSyncPed(originPos, serverId)
    local coords = GetEntityCoords(PlayerPedId())
    if Hyg.distance(coords, originPos) > cfg.SyncDistance then return nil end

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return nil end

    local ped = GetPlayerPed(player)
    if ped == 0 then return nil end

    return ped
end

function Hyg.targetEnabled()
    return Target.enabled(cfg.Target.system, cfg.InteractionType)
end

Hyg.busy = false

-- ---------------------------------------------------------
-- Occupancy, mirrored from the server
-- ---------------------------------------------------------
-- Plain locals rather than fields on a table: receiveStates swaps the
-- whole table in, and every closure below reads them as upvalues.
local showerInUse, toiletInUse, sinkInUse = {}, {}, {}

RegisterNetEvent('neox_shower:updateShowerState')
AddEventHandler('neox_shower:updateShowerState', function(index, inUse)
    showerInUse[index] = inUse
end)

RegisterNetEvent('neox_shower:updateToiletState')
AddEventHandler('neox_shower:updateToiletState', function(index, inUse)
    toiletInUse[index] = inUse
end)

RegisterNetEvent('neox_shower:updateSinkState')
AddEventHandler('neox_shower:updateSinkState', function(index, inUse)
    sinkInUse[index] = inUse
end)

RegisterNetEvent('neox_shower:receiveStates')
AddEventHandler('neox_shower:receiveStates', function(showers, toilets, sinks)
    showerInUse, toiletInUse, sinkInUse = showers, toilets, sinks
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('neox_shower:requestStates')
end)

-- ---------------------------------------------------------
-- [E] prompt loop — used when targeting is off
-- ---------------------------------------------------------
-- Each pass walks every spot, keeps the shortest sleep any of them asked
-- for and leaves `prompt` holding the text for the closest usable one.
CreateThread(function()
    Wait(1500)
    if Hyg.targetEnabled() then return end

    local lastPrompt = nil

    while true do
        local sleep = 2000
        local coords = GetEntityCoords(PlayerPedId())
        local prompt = nil

        for index, shower in ipairs(cfg.Showers) do
            if not Hyg.isPlaceholder(shower) and not showerInUse[index] then
                local dist = Hyg.distance(coords, shower.pos)

                if dist < 10.0 and sleep > 500 then sleep = 500 end

                if dist < cfg.InteractionDistance then
                    sleep = 0
                    prompt = cfg.Locale.shower_prompt

                    if not Hyg.busy and IsControlJustReleased(0, 38) then
                        TriggerServerEvent('neox_shower:setShowerUse', index, true)
                        TriggerEvent('neox_shower:startShower', index)
                        Notify.hide()
                        prompt = nil
                    end
                end
            end
        end

        for index, toilet in ipairs(cfg.Toilets) do
            if not Hyg.isPlaceholder(toilet) and not toiletInUse[index] then
                local dist = Hyg.distance(coords, toilet.pos)

                if dist < 10.0 and sleep > 500 then sleep = 500 end

                if dist < cfg.InteractionDistance then
                    sleep = 0

                    if toilet.type == 'both' then
                        prompt = cfg.Locale.toilet_prompt
                    elseif toilet.type == 'pee_only' then
                        prompt = cfg.Locale.pee_prompt
                    else
                        prompt = cfg.Locale.poop_prompt
                    end

                    if not Hyg.busy then
                        if toilet.type == 'both' or toilet.type == 'poop_only' then
                            if IsControlJustReleased(0, 38) then
                                TriggerServerEvent('neox_shower:setToiletUse', index, true)
                                TriggerEvent('neox_shower:startPoop', index)
                                Notify.hide()
                                prompt = nil
                            end
                        end

                        if toilet.type == 'both' or toilet.type == 'pee_only' then
                            if IsControlJustReleased(0, 47) then
                                TriggerServerEvent('neox_shower:setToiletUse', index, true)
                                TriggerEvent('neox_shower:startPee', index)
                                Notify.hide()
                                prompt = nil
                            end
                        end
                    end
                end
            end
        end

        for index, sink in ipairs(cfg.Sinks) do
            if not Hyg.isPlaceholder(sink) and not sinkInUse[index] then
                local dist = Hyg.distance(coords, sink.pos)

                if dist < 10.0 and sleep > 500 then sleep = 500 end

                if dist < cfg.SinkInteractionDistance then
                    sleep = 0
                    prompt = '[E] ' .. cfg.Locale.wash_target

                    if not Hyg.busy and IsControlJustReleased(0, 38) then
                        TriggerServerEvent('neox_shower:setSinkUse', index, true)
                        TriggerEvent('neox_shower:startWashHands', index)
                        Notify.hide()
                        prompt = nil
                    end
                end
            end
        end

        if prompt then
            lastPrompt = prompt
            Notify.show((prompt
                :gsub('%[E%]', '~INPUT_CONTEXT~')
                :gsub('%[G%]', '~INPUT_DETONATE~')))
        elseif lastPrompt then
            Notify.hide()
            lastPrompt = nil
        end

        Wait(sleep)
    end
end)

-- ---------------------------------------------------------
-- Target zones — used when targeting is on
-- ---------------------------------------------------------
CreateThread(function()
    Wait(1500)
    if not Hyg.targetEnabled() then return end

    local targetSystem = cfg.Target.system

    for index, shower in ipairs(cfg.Showers) do
        if not Hyg.isPlaceholder(shower) then
            Target.addSphere('neox_mrpd_shower_' .. index, shower.pos, cfg.InteractionDistance, {
                {
                    icon     = 'fas fa-shower',
                    label    = cfg.Locale.shower_target,
                    distance = cfg.InteractionDistance,
                    action   = function()
                        TriggerEvent('neox_shower:startShower', index)
                    end,
                },
            }, targetSystem, cfg.InteractionType)
        end
    end

    for index, toilet in ipairs(cfg.Toilets) do
        if not Hyg.isPlaceholder(toilet) then
            local options = {}

            if toilet.type == 'both' or toilet.type == 'poop_only' then
                options[#options + 1] = {
                    icon     = 'fas fa-toilet',
                    label    = cfg.Locale.poop_target,
                    distance = cfg.InteractionDistance,
                    action   = function()
                        TriggerEvent('neox_shower:startPoop', index)
                    end,
                }
            end

            if toilet.type == 'both' or toilet.type == 'pee_only' then
                options[#options + 1] = {
                    icon     = 'fas fa-restroom',
                    label    = cfg.Locale.pee_target,
                    distance = cfg.InteractionDistance,
                    action   = function()
                        TriggerEvent('neox_shower:startPee', index)
                    end,
                }
            end

            -- NOTE: the original passes no `interaction` argument here, unlike
            -- the shower and sink zones above/below. Kept as-is: it only shows
            -- up when Config.ModuleInteraction.hygiene is set, and changing it
            -- would alter behaviour.
            Target.addSphere('neox_mrpd_toilet_' .. index, toilet.pos,
                cfg.InteractionDistance, options, targetSystem)
        end
    end

    for index, sink in ipairs(cfg.Sinks) do
        if not Hyg.isPlaceholder(sink) then
            Target.addSphere('neox_mrpd_sink_' .. index, sink.pos, cfg.SinkInteractionDistance, {
                {
                    icon     = 'fas fa-hands-wash',
                    label    = cfg.Locale.wash_target,
                    distance = cfg.SinkInteractionDistance,
                    action   = function()
                        TriggerEvent('neox_shower:startWashHands', index)
                    end,
                },
            }, targetSystem, cfg.InteractionType)
        end
    end
end)

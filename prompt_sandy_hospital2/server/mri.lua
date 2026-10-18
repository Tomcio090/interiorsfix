-- ============================================================
-- MRI Scanner – Server-side
-- Orchestrates state, validates actions.
-- The bed entity is spawned CLIENT-SIDE (by the patient) so
-- the owning client always has full network control for
-- smooth movement.  The server tracks netID for coordination.
-- ============================================================

-- ── Framework initialisation (server-side only) ──────────────
-- Uncomment ONE block that matches your framework.

-- ESX (all versions – event-based, most compatible)
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- QBCore / QBox
-- QBCore = exports['qb-core']:GetCoreObject()

local bedModel = joaat(MRIConfig.bedModel)

-- ────────────────────────────────────────────────────────────
-- State
-- ────────────────────────────────────────────────────────────
local mriState = {
    bedNetID    = nil,       -- network id (entity created on client)
    bedPosition = 'outside', -- 'outside' | 'inside' | 'moving'
    patient     = nil,       -- source id of the patient
    scanning    = false,
}

-- /testmri bypass set – admin testers skip the canOperate check
local mriTestBypass = {}

--- Check operator permission, honouring /testmri bypass.
local function canOperateOrBypass(source)
    if mriTestBypass[source] then return true end
    return MRIConfig.canOperate(source)
end

--- Send an ox_lib notification to a specific player from the server.
local function notifyPlayer(target, description, type)
    TriggerClientEvent('ox_lib:notify', target, {
        title       = 'MRI Scanner',
        description = description,
        type        = type or 'info',
    })
end

-- ────────────────────────────────────────────────────────────
-- Helpers
-- ────────────────────────────────────────────────────────────

--- Get the server-side entity handle from the stored netID.
local function getBedEntity()
    if not mriState.bedNetID then return nil end
    local entity = NetworkGetEntityFromNetworkId(mriState.bedNetID)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        return entity
    end
    return nil
end

--- Delete the dynamic bed (if it still exists) and restore the static one.
local function cleanupDynamicBed()
    local entity = getBedEntity()
    if entity then
        DeleteEntity(entity)
    end

    mriState.bedNetID    = nil
    mriState.bedPosition = 'outside'
    mriState.scanning    = false

    -- Restore the static bed on every client
    TriggerClientEvent('prompt_sandy_hospital2:mri:toggleBedVisibility', -1, true, MRIConfig.bedOutsideCoords)
end

--- Tell the patient client to move the bed via state bag.
--- The patient owns the entity so movement is always smooth.
--- Blocks until the slide finishes.
local function moveBedViaStateBag(fromCoords, toCoords, duration)
    local entity = getBedEntity()
    if not entity then return end

    -- Set state bag – the owning client will handle smooth interpolation
    Entity(entity).state:set('bedMovement', {
        from     = { x = fromCoords.x, y = fromCoords.y, z = fromCoords.z },
        to       = { x = toCoords.x,   y = toCoords.y,   z = toCoords.z   },
        duration = duration,
    }, true) -- replicated

    -- Wait for the slide to finish
    Wait(duration + 500)

    -- Clear the state bag
    if entity and DoesEntityExist(entity) then
        Entity(entity).state:set('bedMovement', nil, true)
    end
end

-- ────────────────────────────────────────────────────────────
-- Callbacks
-- ────────────────────────────────────────────────────────────

--- Patient requests to lie on the MRI bed.
--- Returns true if the slot is available. The CLIENT will spawn the entity.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:lieDown', function(source)
    -- Already occupied
    if mriState.patient then
        return false
    end

    -- Distance check
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    if #(playerCoords - MRIConfig.bedOutsideCoords) > 5.0 then
        return false
    end

    mriState.patient = source
    return true
end)

--- Client tells the server the netID of the bed it just spawned.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:registerBed', function(source, netID)
    if mriState.patient ~= source then return false end
    if not netID or netID == 0 then return false end

    mriState.bedNetID    = netID
    mriState.bedPosition = 'outside'

    -- Hide the static bed on every client
    TriggerClientEvent('prompt_sandy_hospital2:mri:toggleBedVisibility', -1, false, MRIConfig.bedOutsideCoords)

    return true
end)

--- Patient aborts lie-down because the bed entity failed to spawn on client.
--- Cleans up state so the bed slot is freed.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:abortLieDown', function(source)
    if mriState.patient ~= source then return false end

    print(('[prompt_sandy_hospital2] Player %s aborted lie-down – bed failed on client'):format(source))
    mriState.patient  = nil
    mriState.scanning = false
    mriTestBypass[source] = nil
    cleanupDynamicBed()
    return true
end)

--- Patient gets up off the bed.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:getUp', function(source)
    if mriState.patient ~= source then return false end

    mriState.patient  = nil
    mriState.scanning = false
    mriTestBypass[source] = nil

    -- If the bed is inside the tube, slide it back out first
    if mriState.bedPosition == 'inside' and mriState.bedNetID then
        mriState.bedPosition = 'moving'
        moveBedViaStateBag(MRIConfig.bedInsideCoords, MRIConfig.bedOutsideCoords, MRIConfig.slideDuration)
    end

    cleanupDynamicBed()
    return true
end)

--- Operator requests current MRI state (for building the menu).
--- @return table|nil state
lib.callback.register('prompt_sandy_hospital2:mri:getState', function(source)
    if not canOperateOrBypass(source) then
        return nil
    end

    return {
        hasPatient  = mriState.patient ~= nil,
        bedPosition = mriState.bedPosition,
        scanning    = mriState.scanning,
    }
end)

--- Operator requests to move the bed in or out.
--- @param direction string 'inside' | 'outside'
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:moveBed', function(source, direction)
    if not canOperateOrBypass(source) then return false end
    if not mriState.patient then return false end
    if not mriState.bedNetID then return false end
    if mriState.bedPosition == 'moving' then return false end
    if mriState.scanning then return false end

    if direction == 'inside'  and mriState.bedPosition ~= 'outside' then return false end
    if direction == 'outside' and mriState.bedPosition ~= 'inside'  then return false end

    local fromCoords = direction == 'inside' and MRIConfig.bedOutsideCoords or MRIConfig.bedInsideCoords
    local toCoords   = direction == 'inside' and MRIConfig.bedInsideCoords  or MRIConfig.bedOutsideCoords

    mriState.bedPosition = 'moving'

    -- State bag triggers client-side smooth movement
    moveBedViaStateBag(fromCoords, toCoords, MRIConfig.slideDuration)

    mriState.bedPosition = (direction == 'inside') and 'inside' or 'outside'
    return true
end)

--- Operator starts the MRI scan.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:startScan', function(source)
    if not canOperateOrBypass(source) then return false end
    if not mriState.patient then return false end
    if mriState.bedPosition ~= 'inside' then return false end
    if mriState.scanning then return false end

    mriState.scanning = true

    -- Tell the patient to show the progress circle
    TriggerClientEvent('prompt_sandy_hospital2:mri:scanProgress', mriState.patient, MRIConfig.scanDuration)

    -- Tell ALL clients to start the flashing scan light
    TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStart', -1, MRIConfig.scanDuration)

    -- After the scan finishes
    local operator = source
    local patient  = mriState.patient
    SetTimeout(MRIConfig.scanDuration + 500, function()
        mriState.scanning = false

        -- Stop the scan light on all clients (safety net)
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStop', -1)

        -- Fire the configurable callback
        if MRIConfig.onScanComplete then
            MRIConfig.onScanComplete(patient, operator)
        end

        -- Notify the operator
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanDone', operator)
    end)

    return true
end)

--- Operator forces the patient off the bed.
--- @return boolean
lib.callback.register('prompt_sandy_hospital2:mri:releasePatient', function(source)
    if not canOperateOrBypass(source) then return false end
    if not mriState.patient then return false end

    local patientSrc = mriState.patient

    -- Tell the patient client to detach immediately
    TriggerClientEvent('prompt_sandy_hospital2:mri:forceGetUp', patientSrc)

    -- Stop scan light if it was running
    TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStop', -1)

    mriState.patient  = nil
    mriState.scanning = false
    mriTestBypass[patientSrc] = nil

    -- Slide bed back out if it was inside
    if mriState.bedPosition == 'inside' and mriState.bedNetID then
        mriState.bedPosition = 'moving'
        moveBedViaStateBag(MRIConfig.bedInsideCoords, MRIConfig.bedOutsideCoords, MRIConfig.slideDuration)
    end

    cleanupDynamicBed()
    return true
end)

-- ────────────────────────────────────────────────────────────
-- /testmri  –  admin-only solo test command
-- Requires ace: add_ace group.admin command.testmri allow
-- ────────────────────────────────────────────────────────────
RegisterCommand('testmri', function(source)
    if source == 0 then
        print('[prompt_sandy_hospital2] /testmri can only be used by a player')
        return
    end
    mriTestBypass[source] = true
    TriggerClientEvent('prompt_sandy_hospital2:mri:runTest', source)
end, true) -- restricted = true → needs ace 'command.testmri'

--- /testoperator – admin-only, runs the operator sequence for whoever is on the bed.
--- Usage: lie on the bed first (or /testmri to auto-lie), then /testoperator to
---        simulate an operator pressing the buttons (move in → scan → move out).
RegisterCommand('testoperator', function(source)
    if source == 0 then
        print('[prompt_sandy_hospital2] /testoperator can only be used by a player')
        return
    end

    -- Reuse the same ACE as /testmri so no extra ace entry is needed
    if not IsPlayerAceAllowed(tostring(source), 'command.testmri') then
        notifyPlayer(source, 'You do not have permission to use this command.', 'error')
        return
    end

    mriTestBypass[source] = true

    if not mriState.patient then
        notifyPlayer(source, 'No patient on the bed. Lie down first (/testmri or interact with bed).', 'error')
        return
    end

    if not mriState.bedNetID then
        notifyPlayer(source, 'Bed entity not registered yet. Wait a moment and try again.', 'error')
        return
    end

    -- Run the operator sequence in a thread so it doesn't block
    CreateThread(function()
        notifyPlayer(source, 'Operator test: Moving bed inside...', 'info')

        -- 1. Move inside
        if mriState.bedPosition == 'outside' then
            mriState.bedPosition = 'moving'
            moveBedViaStateBag(MRIConfig.bedOutsideCoords, MRIConfig.bedInsideCoords, MRIConfig.slideDuration)
            mriState.bedPosition = 'inside'
        end

        Wait(500)

        -- 2. Start scan
        notifyPlayer(source, 'Operator test: Starting scan...', 'info')

        mriState.scanning = true
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanProgress', mriState.patient, MRIConfig.scanDuration)
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStart', -1, MRIConfig.scanDuration)

        Wait(MRIConfig.scanDuration + 500)

        mriState.scanning = false
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStop', -1)

        if MRIConfig.onScanComplete and mriState.patient then
            MRIConfig.onScanComplete(mriState.patient, source)
        end
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanDone', source)

        Wait(500)

        -- 3. Move outside
        notifyPlayer(source, 'Operator test: Moving bed outside...', 'info')

        if mriState.bedPosition == 'inside' then
            mriState.bedPosition = 'moving'
            moveBedViaStateBag(MRIConfig.bedInsideCoords, MRIConfig.bedOutsideCoords, MRIConfig.slideDuration)
            mriState.bedPosition = 'outside'
        end

        notifyPlayer(source, 'Operator test complete! Patient can now get up.', 'success')
    end)
end, false) -- unrestricted – reuses /testmri ACE check internally

-- ────────────────────────────────────────────────────────────
-- Cleanup
-- ────────────────────────────────────────────────────────────

-- Player disconnects while on the bed
AddEventHandler('playerDropped', function()
    local src = source
    mriTestBypass[src] = nil
    if mriState.patient == src then
        mriState.patient  = nil
        mriState.scanning = false
        TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStop', -1)
        cleanupDynamicBed()
    end
end)

-- Resource stops
AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    TriggerClientEvent('prompt_sandy_hospital2:mri:scanLightStop', -1)
    cleanupDynamicBed()
end)

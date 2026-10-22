-- =========================================================
-- NEOX MRPD — ELEVATOR RUNTIME (client)
-- =========================================================
-- Spawns and drives the cabin and door props, carries riders along,
-- and owns the on-prop button panel view.
--
-- Shaft position is authoritative on the server and published through
-- GlobalState; this file interpolates between stops locally so the ride
-- stays smooth, using a clock offset measured against the server.
-- =========================================================

-- shaftId -> live state for that shaft (entity handles, trip, riders)
local shaftRuntime = {}

-- Panel view
local panelCam = nil
local panelActive = false
local panelShaftId = nil
local savedCamHeading = nil
local savedCamPitch = nil

-- Server clock
local clockOffset = 0
local clockSynced = false
local clockSample = nil

function ServerNow()
    return GetGameTimer() + clockOffset
end

function ReadShaftState(shaftId, key, default)
    local value = GlobalState[Neox.StateKey(shaftId, key)]
    if value == nil then return default end
    return value
end

function Lerp(from, to, t)
    return from + (to - from) * t
end

function VecLerp(from, to, t, clamp)
    if clamp then
        if t < 0.0 then t = 0.0 end
        if t > 1.0 then t = 1.0 end
    end

    return vector3(
        Lerp(from.x, to.x, t),
        Lerp(from.y, to.y, t),
        Lerp(from.z, to.z, t)
    )
end

function IsAnyTripRunning()
    for _, runtime in pairs(shaftRuntime) do
        if runtime.trip and not runtime.trip.finished then
            return true
        end
    end

    return false
end

-- ---------------------------------------------------------
-- Clock sync
-- ---------------------------------------------------------
-- The reply carries back the timestamp we sent, so round trip time is
-- measurable; the sample with the lowest RTT wins.
RegisterNetEvent(Neox.Event('clock:reply'), function(sentAt, serverTime)
    local now = GetGameTimer()
    local roundTrip = now - sentAt
    if roundTrip < 0 then return end

    if clockSample == nil or roundTrip < clockSample.rtt then
        clockSample = {
            rtt    = roundTrip,
            offset = serverTime + math.floor(roundTrip / 2) - now,
        }

        if not clockSynced then
            clockOffset = clockSample.offset
            clockSynced = true
        end
    end
end)

CreateThread(function()
    while true do
        clockSample = nil

        for _ = 1, 5 do
            TriggerServerEvent(Neox.Event('clock'), GetGameTimer())
            Wait(200)
        end

        if clockSample then
            -- Never retime the clock mid-ride: it would make the cabin jump.
            while clockSynced and IsAnyTripRunning() do
                Wait(250)
            end

            clockOffset = clockSample.offset
            clockSynced = true
        end

        Wait(60000)
    end
end)

-- ---------------------------------------------------------
-- Drawing / maths helpers
-- ---------------------------------------------------------
function RotationToDirection(rotation)
    local radians = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )

    return vector3(
        -math.sin(radians.z) * math.abs(math.cos(radians.x)),
        math.cos(radians.z) * math.abs(math.cos(radians.x)),
        math.sin(radians.x)
    )
end

-- Turns a screen-relative cursor position into a world point 10m in front
-- of the camera, by measuring how far one degree of camera yaw/pitch moves
-- a point on screen and scaling from that.
function ScreenRelToWorld(camPos, camRot, relX, relY)
    local forward = RotationToDirection(camRot)
    local center = camPos + forward * 10.0

    local yawRight = RotationToDirection(vector3(camRot.x, camRot.y, camRot.z + 1.0))
    local yawLeft  = RotationToDirection(vector3(camRot.x, camRot.y, camRot.z - 1.0))
    local deltaYaw = yawRight - yawLeft

    local pitchUp   = RotationToDirection(vector3(camRot.x + 1.0, camRot.y, camRot.z))
    local pitchDown = RotationToDirection(vector3(camRot.x - 1.0, camRot.y, camRot.z))
    local deltaPitch = pitchUp - pitchDown

    -- Roll the two axes so they line up with the screen.
    local roll = -(camRot.y * math.pi / 180.0)
    local screenRight = deltaYaw * math.cos(roll) - deltaPitch * math.sin(roll)
    local screenUp    = deltaYaw * math.sin(roll) + deltaPitch * math.cos(roll)

    local probe = center + screenRight + screenUp

    local _, probeX, probeY = GetScreenCoordFromWorldCoord(probe.x, probe.y, probe.z)
    if probeX == nil or probeY == nil then
        return center
    end

    local _, centerX, centerY = GetScreenCoordFromWorldCoord(center.x, center.y, center.z)

    -- Degenerate projection (camera looking straight along an axis).
    if 0.001 > math.abs(probeX - centerX) or 0.001 > math.abs(probeY - centerY) then
        return center
    end

    local scaleX = (relX - centerX) / (probeX - centerX)
    local scaleY = (relY - centerY) / (probeY - centerY)

    return center + screenRight * scaleX + screenUp * scaleY
end

-- ---------------------------------------------------------
-- Cabin volume: deciding who is inside the cabin
-- ---------------------------------------------------------
-- model hash -> { min, max }, or false when the bounds looked unusable
local modelBoundsCache = {}

function GetCabinModelBounds(entity)
    local model = GetEntityModel(entity)
    if not model or model == 0 then return nil end

    local cached = modelBoundsCache[model]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end

    local min, max = GetModelDimensions(model)
    if not min or not max then return nil end

    local width = max.x - min.x
    local length = max.y - min.y
    local maxBounds = Config.Ride.volume.maxBounds or 6.0

    if Config.Debug.enabled then
        print(('[neox_elevator] cabin bounds x[%.2f..%.2f] y[%.2f..%.2f] z[%.2f..%.2f]')
            :format(min.x, max.x, min.y, max.y, min.z, max.z))
    end

    if width < 0.5 or length < 0.5 or width > maxBounds or length > maxBounds then
        print(('[neox_elevator] cabin model bounds look wrong (%.2f x %.2f) - falling back to Config.Ride.volume.')
            :format(width, length))
        modelBoundsCache[model] = false
        return nil
    end

    local bounds = { min = min, max = max }
    modelBoundsCache[model] = bounds
    return bounds
end

function GetCabinVolumeConfig(shaftId)
    local shaft = shaftId and Config.Shafts[shaftId]
    return (shaft and shaft.volume) or Config.Ride.volume
end

-- entity -> cached oriented box, rebuilt when the cabin turns
local cabinVolumeCache = {}

function GetCabinVolume(entity, volumeCfg, coords)
    if not DoesEntityExist(entity) then return nil end

    if not volumeCfg then
        volumeCfg = Config.Ride.volume
    end

    local offset = volumeCfg.offset or {}
    local heading = GetEntityHeading(entity)

    local volume = cabinVolumeCache[entity]

    local reusable = volume
        and volume.config == volumeCfg
        and volume.heading == heading
        and volume.width == volumeCfg.width
        and volume.length == volumeCfg.length
        and volume.height == volumeCfg.height
        and volume.offsetForward == offset.forward
        and volume.offsetRight == offset.right
        and volume.offsetUp == offset.up

    if not reusable then
        local width  = volumeCfg.width  or 2.55
        local length = volumeCfg.length or 2.6
        local height = volumeCfg.height or 2.55

        local offsetForward = offset.forward or 0.0
        local offsetRight   = offset.right or 0.0
        local offsetUp      = offset.up or -1.25

        local forward = GetEntityForwardVector(entity)
        local radians = math.rad(heading)
        local right = vector3(math.cos(radians), math.sin(radians), 0.0)

        -- up = right x forward
        local up = vector3(
            right.y * forward.z - right.z * forward.y,
            right.z * forward.x - right.x * forward.z,
            right.x * forward.y - right.y * forward.x
        )

        volume = {
            config        = volumeCfg,
            heading       = heading,
            width         = volumeCfg.width,
            length        = volumeCfg.length,
            height        = volumeCfg.height,
            offsetForward = offset.forward,
            offsetRight   = offset.right,
            offsetUp      = offset.up,
            min           = vector3(-width / 2, -length / 2, 0),
            max           = vector3(width / 2, length / 2, height),
            forward       = forward,
            right         = right,
            up            = up,
            centerOffset  = vector3(
                forward.x * offsetForward + right.x * offsetRight + up.x * offsetUp,
                forward.y * offsetForward + right.y * offsetRight + up.y * offsetUp,
                forward.z * offsetForward + right.z * offsetRight + up.z * offsetUp
            ),
        }

        cabinVolumeCache[entity] = volume
    end

    volume.center = (coords or GetEntityCoords(entity)) + volume.centerOffset

    return volume
end

function IsPedInCabin(ped, cabin, shaftId, cabinCoords, pedCoords)
    if not (cabin and DoesEntityExist(cabin)) then return false end
    if not (ped and DoesEntityExist(ped)) then return false end

    local volumeCfg = GetCabinVolumeConfig(shaftId)

    -- Preferred path: test against the cabin model's own bounding box.
    if volumeCfg.useModelBounds ~= false then
        local bounds = GetCabinModelBounds(cabin)

        if bounds then
            local inset = volumeCfg.inset or 0.15
            local coords = pedCoords or GetEntityCoords(ped)
            local localPos = GetOffsetFromEntityGivenWorldCoords(cabin, coords.x, coords.y, coords.z)

            if localPos.x < bounds.min.x + inset or localPos.x > bounds.max.x - inset then
                return false
            end

            if localPos.y < bounds.min.y + inset or localPos.y > bounds.max.y - inset then
                return false
            end

            -- Vertical tolerance is looser: feet may clip below the floor.
            if localPos.z < bounds.min.z - 0.6 or localPos.z > bounds.max.z + 0.3 then
                return false
            end

            return true
        end
    end

    -- Fallback: the configured box, projected onto the cabin's own axes.
    local volume = GetCabinVolume(cabin, volumeCfg, cabinCoords)
    if not volume then return false end

    local coords = pedCoords or GetEntityCoords(ped)
    local center = volume.center

    local delta = vector3(
        coords.x - center.x,
        coords.y - center.y,
        coords.z - center.z
    )

    local alongRight = delta.x * volume.right.x
        + delta.y * volume.right.y
        + delta.z * volume.right.z

    local alongForward = delta.x * volume.forward.x
        + delta.y * volume.forward.y
        + delta.z * volume.forward.z

    local alongUp = delta.x * volume.up.x
        + delta.y * volume.up.y
        + delta.z * volume.up.z

    -- Only peds inside the full 3D cabin volume may become riders. In
    -- particular, a ped calling the elevator from the landing must stay put.
    return alongRight >= volume.min.x and alongRight <= volume.max.x
        and alongForward >= volume.min.y and alongForward <= volume.max.y
        and alongUp >= volume.min.z and alongUp <= volume.max.z
end

-- Debug overlay: the twelve edges of the cabin box.
local CABIN_VOLUME_EDGES = {
    { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 },
    { 1, 3 }, { 2, 4 }, { 5, 7 }, { 6, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

function DrawCabinVolume(entity, inside, shaftId)
    local volume = GetCabinVolume(entity, GetCabinVolumeConfig(shaftId))
    if not volume then return end

    local corners = {}
    local count = 0

    for _, x in ipairs({ volume.min.x, volume.max.x }) do
        for _, y in ipairs({ volume.min.y, volume.max.y }) do
            for _, z in ipairs({ volume.min.z, volume.max.z }) do
                count = count + 1
                corners[count] = volume.center
                    + volume.right * x
                    + volume.forward * y
                    + volume.up * z
            end
        end
    end

    local red = inside and 0 or 255
    local green = inside and 255 or 60

    for _, edge in ipairs(CABIN_VOLUME_EDGES) do
        local from = corners[edge[1]]
        local to = corners[edge[2]]
        DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, red, green, 90, 200)
    end
end

-- ---------------------------------------------------------
-- Panel geometry
-- ---------------------------------------------------------
-- Returns the panel's world position and whether it came from a bone.
function GetPanelOrigin(entity, shaftId)
    local shaft = shaftId and Config.Shafts[shaftId]
    local boneName = (shaft and shaft.panel.bone) or 'panel'

    local bone = GetEntityBoneIndexByName(entity, boneName)
    if bone == -1 then
        bone = GetEntityBoneIndexByName(entity, 'asansorpanel')
    end

    if bone ~= -1 then
        return GetWorldPositionOfEntityBone(entity, bone), true
    end

    local offset = (shaft and shaft.panelOffset) or vec3(0.0, 0.4, 0.2)
    return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z), false
end

-- One entry per stop, carrying the bone names to probe and a stacked
-- offset to fall back on when the model has no button bones.
function GetStopButtons(shaftId)
    local shaft = Config.Shafts[shaftId]
    if not (shaft and shaft.stops) then return {} end

    local stopIds = {}
    for stopId in pairs(shaft.stops) do
        stopIds[#stopIds + 1] = stopId
    end
    table.sort(stopIds)

    local buttons = {}

    for index, stopId in ipairs(stopIds) do
        local stop = shaft.stops[stopId]
        local key = tostring(stop.key or stopId)

        buttons[#buttons + 1] = {
            floor = stopId,
            names = {
                key,
                'button_' .. key,
                'btn_' .. key,
                'b' .. key,
            },
            fallbackOffset = vec3(0.0, 0.02, -0.05 + (index - 1) * 0.08),
        }
    end

    return buttons
end

function GetStopButtonPosition(entity, shaftId, button)
    local shaft = Config.Shafts[shaftId]
    local configured = shaft and shaft.panel.buttons and shaft.panel.buttons[button.floor]

    if configured then
        return GetOffsetFromEntityInWorldCoords(entity, configured.x, configured.y, configured.z)
    end

    for _, name in ipairs(button.names) do
        local bone = GetEntityBoneIndexByName(entity, name)
        if bone ~= -1 then
            return GetWorldPositionOfEntityBone(entity, bone)
        end
    end

    local origin = GetPanelOrigin(entity, shaftId)
    local localOrigin = GetOffsetFromEntityGivenWorldCoords(entity, origin.x, origin.y, origin.z)

    return GetOffsetFromEntityInWorldCoords(entity,
        localOrigin.x + button.fallbackOffset.x,
        localOrigin.y + button.fallbackOffset.y,
        localOrigin.z + button.fallbackOffset.z)
end

-- ---------------------------------------------------------
-- Shaft runtime bookkeeping
-- ---------------------------------------------------------
function GetShaftRuntime(shaftId)
    return shaftRuntime[shaftId]
end

function HasStop(shaftId, stopId)
    local shaft = Config.Shafts[shaftId]
    if not (shaft and shaft.stops) then return false end
    return shaft.stops[stopId] ~= nil
end

function ResetShaftRuntime()
    for shaftId in pairs(Config.Shafts) do
        shaftRuntime[shaftId] = {
            isNearby         = false,
            entity           = nil,
            leftDoor         = nil,
            rightDoor        = nil,
            doorOffset       = vec3(0, 0, 0),
            doorDimensions   = vec3(0, 0, 0),
            attachedEntities = {},
            isAttached       = false,
            isInCabin        = false,
            soundId          = nil,
            previousState    = nil,
            trip             = nil,
            tripId           = nil,
            pinnedRoom       = {},
        }
    end
end

-- ---------------------------------------------------------
-- Panel view
-- ---------------------------------------------------------
function EnterPanelView(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return end

    local shaft = Config.Shafts[shaftId]

    if panelCam ~= nil and DoesCamExist(panelCam) then
        DestroyCam(panelCam, false)
        panelCam = nil
    end

    -- Remembered so the gameplay camera can be put back on exit.
    savedCamHeading = GetGameplayCamRelativeHeading()
    savedCamPitch = GetGameplayCamRelativePitch()

    local boneName = shaft.panel.bone or 'panel'
    local origin, foundBone = GetPanelOrigin(runtime.entity, shaftId)
    local heading = GetEntityHeading(runtime.entity)

    local camera = shaft.panel.camera or {
        offset   = vec3(1.095, 0.01, 0.1),
        rotation = vec3(1.0, 0.0, 0.0),
        fov      = 60.0,
    }

    -- The camera is attached in the cabin's local space so it rides along.
    local localOrigin = GetOffsetFromEntityGivenWorldCoords(runtime.entity,
        origin.x, origin.y, origin.z)

    local localCam = vec3(
        localOrigin.x + camera.offset.x,
        localOrigin.y + camera.offset.y,
        localOrigin.z + camera.offset.z
    )

    local worldCam = GetOffsetFromEntityInWorldCoords(runtime.entity,
        localCam.x, localCam.y, localCam.z)

    panelCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        worldCam.x, worldCam.y, worldCam.z,
        camera.rotation.x, camera.rotation.y, heading - camera.rotation.z,
        camera.fov, false, 0)

    AttachCamToEntity(panelCam, runtime.entity, localCam.x, localCam.y, localCam.z, true)
    SetCamRot(panelCam, camera.rotation.x, camera.rotation.y, heading - camera.rotation.z, 2)
    SetCamActive(panelCam, true)
    RenderScriptCams(true, true, 500, true, true)

    if Config.Debug.enabled then
        print(("[neox_elevator] %s panel cam: bone '%s' %s, local offset %.3f %.3f %.3f"):format(
            shaftId,
            boneName,
            foundBone and 'found' or 'MISSING (using config.panelOffset)',
            localCam.x, localCam.y, localCam.z))
    end

    panelShaftId = shaftId
    panelActive = true

    TriggerServerEvent(Neox.Event('panel:claim'), shaftId)
end

function ExitPanelView()
    if panelShaftId then
        TriggerServerEvent(Neox.Event('panel:release'), panelShaftId)
    end

    if savedCamHeading then
        SetGameplayCamRelativeHeading(savedCamHeading)
        SetGameplayCamRelativePitch(savedCamPitch or 0.0, 1.0)
        savedCamHeading = nil
        savedCamPitch = nil
    end

    if panelCam ~= nil and DoesCamExist(panelCam) then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(panelCam, false)
        panelCam = nil
    end

    panelActive = false
    SetNuiFocus(false, false)
    panelShaftId = nil
end

-- ---------------------------------------------------------
-- ox_target: cabin panel
-- ---------------------------------------------------------
local function PanelTargetName(shaftId)
    return ('neox_mrpd_elevator:%s:panel'):format(shaftId)
end

local function CanOpenPanelTarget(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.isInCabin and panelCam == nil) then return false end
    if not (runtime.entity and DoesEntityExist(runtime.entity)) then return false end
    if CanInteractWithElevator and not CanInteractWithElevator(shaftId) then return false end

    return true
end

local function RegisterCabinTarget(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return end
    if runtime.panelTarget or GetResourceState('ox_target') ~= 'started' then return end

    local optionName = PanelTargetName(shaftId)

    exports.ox_target:addLocalEntity(runtime.entity, {
        {
            name     = optionName,
            icon     = Config.Interaction.target.panelIcon,
            label    = Config.Interaction.text.panel,
            distance = Config.Interaction.target.panelDistance,
            canInteract = function()
                return CanOpenPanelTarget(shaftId)
            end,
            onSelect = function()
                if CanOpenPanelTarget(shaftId) then
                    -- Keeps the existing animated camera and mouse panel intact.
                    EnterPanelView(shaftId)
                end
            end,
        },
    })

    runtime.panelTarget = optionName
end

local function UnregisterCabinTarget(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not runtime then return end

    local optionName = runtime.panelTarget
    runtime.panelTarget = nil

    if optionName and runtime.entity and GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeLocalEntity(runtime.entity, optionName)
    end
end

-- ---------------------------------------------------------
-- Keeping props in the right interior room
-- ---------------------------------------------------------
-- Props spawned outside the MRPD interior get culled by the portal system,
-- so each one is forced into the room the player is standing in.
local ROOM_PIN_INTERVAL = 250
local ROOM_PIN_RADIUS = 9.0
local ROOM_PIN_HEIGHT = 2.0

function PinPropToRoom(entity, runtime, pedCoords, interior, roomKey)
    if not (entity and DoesEntityExist(entity)) then return end

    local coords = GetEntityCoords(entity)

    if math.abs(coords.z - pedCoords.z) > ROOM_PIN_HEIGHT then return end

    local flat = #(vec2(coords.x, coords.y) - vec2(pedCoords.x, pedCoords.y))
    if flat > ROOM_PIN_RADIUS then return end

    if runtime.pinnedRoom[entity] == roomKey then return end

    ForceRoomForEntity(entity, interior, roomKey)
    runtime.pinnedRoom[entity] = roomKey
end

function PinPropsToRoom(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return end

    local now = GetGameTimer()
    if runtime.roomPinAt and now < runtime.roomPinAt then return end
    runtime.roomPinAt = now + ROOM_PIN_INTERVAL

    local ped = PlayerPedId()

    local interior = GetInteriorFromEntity(ped)
    if not interior or interior == 0 then return end

    local roomKey = GetRoomKeyFromEntity(ped)
    if not roomKey or roomKey == 0 then return end

    local pedCoords = GetEntityCoords(ped)
    runtime.pinnedRoom = runtime.pinnedRoom or {}

    PinPropToRoom(runtime.entity, runtime, pedCoords, interior, roomKey)
    PinPropToRoom(runtime.leftDoor, runtime, pedCoords, interior, roomKey)
    PinPropToRoom(runtime.rightDoor, runtime, pedCoords, interior, roomKey)

    if runtime.landingDoors then
        for _, doors in pairs(runtime.landingDoors) do
            PinPropToRoom(doors.left, runtime, pedCoords, interior, roomKey)
            PinPropToRoom(doors.right, runtime, pedCoords, interior, roomKey)
        end
    end
end

-- ---------------------------------------------------------
-- Prop lifecycle
-- ---------------------------------------------------------
function LoadPropModel(model, timeoutMs)
    local hash = GetHashKey(model)
    local deadline = GetGameTimer() + (timeoutMs or 5000)

    while not HasModelLoaded(hash) do
        RequestModel(hash)

        if deadline < GetGameTimer() then
            return false
        end

        Wait(0)
    end

    return true
end

function HardenAgainstCulling(entity)
    if not (entity and DoesEntityExist(entity)) then return end

    SetEntityAlwaysPrerender(entity, true)
    SetEntityLodDist(entity, 65535)
end

function ApplyCabinAlpha(entity)
    local alpha = Config.Ride.cabinAlpha
    if not alpha or alpha >= 255 then return end
    if not (entity and DoesEntityExist(entity)) then return end

    SetEntityAlpha(entity, alpha, false)
end

function BuildShaft(shaftId)
    local shaft = Config.Shafts[shaftId]
    if not shaft then return false end

    local runtime = shaftRuntime[shaftId]
    if not runtime then return false end

    for _, model in ipairs({ shaft.cabin.model, shaft.doors.model }) do
        if not LoadPropModel(model) then
            if not runtime.warnedModel then
                runtime.warnedModel = true
                print(("[neox_elevator] model '%s' could not be loaded for %s - retrying.")
                    :format(tostring(model), shaftId))
            end
            return false
        end
    end

    runtime.warnedModel = nil

    RequestScriptAudioBank('Freight_Elevator', false)

    local baseStop = shaft.stops[1]
    local currentStop = shaft.stops[ReadShaftState(shaftId, 'stop', 1)] or baseStop

    -- A cabin left over from a previous session would collide with ours.
    local leftover = GetClosestObjectOfType(
        shaft.cabin.position.x, shaft.cabin.position.y, currentStop.position.z,
        5.0, GetHashKey(shaft.cabin.model), false, false, false)

    if leftover and leftover ~= 0 then
        SetEntityAsMissionEntity(leftover, true, true)
        DeleteEntity(leftover)
    end

    local cabin = CreateObjectNoOffset(GetHashKey(shaft.cabin.model),
        shaft.cabin.position.x, shaft.cabin.position.y, currentStop.position.z,
        false, true, true)

    SetModelAsNoLongerNeeded(GetHashKey(shaft.cabin.model))
    SetEntityRotation(cabin,
        shaft.cabin.rotation.x, shaft.cabin.rotation.y, shaft.cabin.rotation.z, 2, true)
    SetEntityInvincible(cabin, true)
    FreezeEntityPosition(cabin, true)
    SetEntityAsMissionEntity(cabin, true, true)
    ApplyCabinAlpha(cabin)
    HardenAgainstCulling(cabin)

    runtime.entity = cabin

    if Config.Debug.enabled then
        GetCabinModelBounds(cabin)
    end

    runtime.trip = nil
    runtime.tripId = nil
    runtime.pinnedRoom = {}
    runtime.roomPinAt = nil
    runtime.poseCabinZ = nil
    runtime.poseRatio = nil
    runtime.poseStop = nil

    -- Cabin doors: parented to nothing, repositioned every frame by
    -- DriveDoors so they track the cabin and slide independently.
    local leftDoor = CreateObjectNoOffset(GetHashKey(shaft.doors.model),
        0.0, 0.0, 0.0, false, true, true)
    local rightDoor = CreateObjectNoOffset(GetHashKey(shaft.doors.model),
        0.0, 0.0, 0.0, false, true, true)

    SetEntityCoordsNoOffset(leftDoor,
        shaft.cabin.position.x, shaft.cabin.position.y, currentStop.position.z,
        false, false, false)
    SetEntityCoordsNoOffset(rightDoor,
        shaft.cabin.position.x + 4.0, shaft.cabin.position.y + 4.0, currentStop.position.z,
        false, false, false)

    SetEntityRotation(leftDoor, 0.0, 0.0, 0.0, 2, true)
    SetEntityRotation(rightDoor, 0.0, 0.0, 0.0, 2, true)
    SetEntityHasGravity(leftDoor, false)
    SetEntityHasGravity(rightDoor, false)
    SetEntityRecordsCollisions(leftDoor, false)
    SetEntityRecordsCollisions(rightDoor, false)
    SetEntityInvincible(leftDoor, true)
    SetEntityInvincible(rightDoor, true)
    ApplyCabinAlpha(leftDoor)
    HardenAgainstCulling(leftDoor)
    ApplyCabinAlpha(rightDoor)
    HardenAgainstCulling(rightDoor)

    local cabinDoors = shaft.doors.cabin or {}

    FreezeEntityPosition(leftDoor, true)
    FreezeEntityPosition(rightDoor, true)

    runtime.leftDoor = leftDoor
    runtime.rightDoor = rightDoor
    runtime.baseLeftLocal = cabinDoors.left or vec3(-0.83, 0.9, -1.2)
    runtime.baseRightLocal = cabinDoors.right or vec3(0.77, 0.9, -1.2)
    runtime.leftRot = cabinDoors.leftRot or vec3(0.0, 0.0, 0.0)
    runtime.rightRot = cabinDoors.rightRot or vec3(0.0, 0.0, 180.0)
    runtime.landingDoors = {}

    -- Landing doors. Each sliding door is attached to an invisible cabin
    -- prop acting as an anchor, so sliding is a local-space offset on the
    -- attachment rather than a world move.
    for stopId, stop in pairs(shaft.stops) do
        local doors = stop.doors

        if doors and doors.left and doors.right
            and doors.left.position and doors.right.position
        then
            local fallbackZ = stop.position.z + (shaft.doors.offset or 0.0)

            local baseLeft = vec3(
                doors.left.position.x,
                doors.left.position.y,
                doors.left.position.z or fallbackZ
            )

            local baseRight = vec3(
                doors.right.position.x,
                doors.right.position.y,
                doors.right.position.z or fallbackZ
            )

            local leftRotation = doors.left.rotation or vec3(0.0, 0.0, 0.0)
            local rightRotation = doors.right.rotation or vec3(0.0, 0.0, 180.0)

            local leftAnchor = CreateObjectNoOffset(GetHashKey(shaft.cabin.model),
                baseLeft.x, baseLeft.y, baseLeft.z, false, false, true)
            local rightAnchor = CreateObjectNoOffset(GetHashKey(shaft.cabin.model),
                baseRight.x, baseRight.y, baseRight.z, false, false, true)

            for _, anchor in ipairs({ leftAnchor, rightAnchor }) do
                SetEntityVisible(anchor, false, false)
                SetEntityHasGravity(anchor, false)
                SetEntityRecordsCollisions(anchor, false)
                SetEntityCollision(anchor, false, false)
                FreezeEntityPosition(anchor, true)
            end

            SetEntityRotation(leftAnchor,
                leftRotation.x, leftRotation.y, leftRotation.z, 2, true)
            SetEntityRotation(rightAnchor,
                rightRotation.x, rightRotation.y, rightRotation.z, 2, true)

            local landingLeft = CreateObjectNoOffset(GetHashKey(shaft.doors.model),
                baseLeft.x, baseLeft.y, baseLeft.z, false, true, true)
            local landingRight = CreateObjectNoOffset(GetHashKey(shaft.doors.model),
                baseRight.x, baseRight.y, baseRight.z, false, true, true)

            for _, door in ipairs({ landingLeft, landingRight }) do
                SetEntityHasGravity(door, false)
                SetEntityRecordsCollisions(door, false)
                SetEntityInvincible(door, true)
                HardenAgainstCulling(door)
            end

            AttachEntityToEntity(landingLeft, leftAnchor, 0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                false, false, true, false, 2, true)
            AttachEntityToEntity(landingRight, rightAnchor, 0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                false, false, true, false, 2, true)

            runtime.landingDoors[stopId] = {
                left       = landingLeft,
                right      = landingRight,
                leftDummy  = leftAnchor,
                rightDummy = rightAnchor,
                baseLeft   = baseLeft,
                baseRight  = baseRight,
            }
        end
    end

    DriveCabin(shaftId, true)
    DriveDoors(shaftId)
    RegisterCabinTarget(shaftId)

    return true
end

function ClearShaft(shaftId)
    local shaft = Config.Shafts[shaftId]
    if not shaft then return end

    local runtime = shaftRuntime[shaftId]
    if not runtime then return end

    ReleaseScriptAudioBank('Freight_Elevator')

    if runtime.landingDoors then
        for _, doors in pairs(runtime.landingDoors) do
            for _, key in ipairs({ 'left', 'right', 'leftDummy', 'rightDummy' }) do
                local entity = doors[key]
                if entity and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
        end

        runtime.landingDoors = nil
    end

    UnloadRiders(shaftId)

    if runtime.leftDoor then
        DeleteEntity(runtime.leftDoor)
        runtime.leftDoor = nil
    end

    if runtime.rightDoor then
        DeleteEntity(runtime.rightDoor)
        runtime.rightDoor = nil
    end

    runtime.attachedEntities = {}
    runtime.isInCabin = nil
    runtime.trip = nil
    runtime.tripId = nil
    runtime.pinnedRoom = {}
    runtime.roomPinAt = nil
    runtime.poseCabinZ = nil
    runtime.poseRatio = nil
    runtime.poseStop = nil

    if runtime.entity then
        UnregisterCabinTarget(shaftId)
        cabinVolumeCache[runtime.entity] = nil
        DeleteEntity(runtime.entity)
        runtime.entity = nil
    end

    if runtime.soundId then
        StopSound(runtime.soundId)
        ReleaseSoundId(runtime.soundId)
        runtime.soundId = nil
    end
end

-- ---------------------------------------------------------
-- Audio
-- ---------------------------------------------------------
function DriveCabinAudio(shaftId, phase, coords)
    if not phase then
        phase = ReadShaftState(shaftId, 'phase', Neox.Phase.IDLE)
    end

    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity) then return end

    -- Nothing changed and no motor to reposition.
    if phase == runtime.previousState
        and phase ~= Neox.Phase.TRAVELLING
        and not runtime.soundId
    then
        return
    end

    -- Arrival chime, on the travelling -> opening edge.
    if runtime.previousState == Neox.Phase.TRAVELLING and phase == Neox.Phase.OPENING then
        local at = coords or GetEntityCoords(runtime.entity)
        local chime = GetSoundId()

        PlaySoundFromCoord(chime, 'INFO', at.x, at.y, at.z,
            'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 5.0, false)
        ReleaseSoundId(chime)
    end

    if runtime.previousState ~= phase then
        runtime.previousState = phase
    end

    if phase == Neox.Phase.TRAVELLING then
        if not runtime.soundId then
            local at = coords or GetEntityCoords(runtime.entity)
            runtime.soundId = GetSoundId()

            PlaySoundFromCoord(runtime.soundId, 'FREIGHT_ELEVATOR_01_MOTOR',
                at.x, at.y, at.z, '', false, 25.0, false)
        end
    elseif runtime.soundId then
        StopSound(runtime.soundId)
        ReleaseSoundId(runtime.soundId)
        runtime.soundId = nil
    end

    if runtime.soundId then
        local at = coords or GetEntityCoords(runtime.entity)
        UpdateSoundCoord(runtime.soundId, at.x, at.y, at.z)
    end
end

-- ---------------------------------------------------------
-- Trips
-- ---------------------------------------------------------
-- Takes a shaft TABLE (not an id), unlike Neox.GetStopPosition.
function GetStopPosition(shaft, target)
    if not target then return nil end

    if type(target) == 'vector3' then
        return target
    end

    if type(target) == 'table' and target.x and target.y and target.z then
        return vector3(target.x + 0.0, target.y + 0.0, target.z + 0.0)
    end

    local stop = shaft and shaft.stops and shaft.stops[target]
    return (stop and stop.position) or nil
end

function EaseMoveProgress(progress)
    return Neox.EaseMoveProgress(progress)
end

-- Attaches every ped standing in the cabin so they move with it.
function LoadRiders(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return end
    if runtime.isAttached then return end

    local now = GetGameTimer()
    if runtime.attachRetryAt and now < runtime.attachRetryAt then return end
    runtime.attachRetryAt = now + 100

    local attached = {}
    local count = 0

    for _, ped in pairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) and IsPedInCabin(ped, runtime.entity, shaftId) then
            NetworkAllowRemoteAttachmentModification(ped, true)

            local coords = GetEntityCoords(ped)
            local localPos = GetOffsetFromEntityGivenWorldCoords(runtime.entity,
                coords.x, coords.y, coords.z)
            local rotation = GetEntityRotation(ped) - GetEntityRotation(runtime.entity)

            AttachEntityToEntity(ped, runtime.entity, -1,
                localPos.x, localPos.y, localPos.z,
                0.0, 0.0, rotation.z,
                false, false, false, false, 2, false)

            if IsEntityAttachedToEntity(ped, runtime.entity) then
                attached[ped] = true
                count = count + 1
            end
        end
    end

    if count == 0 then return end

    runtime.attachedEntities = attached
    runtime.isAttached = true

    if Config.Debug.enabled then
        print(('[neox_elevator] %s: %d rider(s) attached to cabin'):format(shaftId, count))
    end
end

function UnloadRiders(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.isAttached) then return end

    runtime.isAttached = false
    runtime.attachRetryAt = nil

    if runtime.attachedEntities then
        for entity in pairs(runtime.attachedEntities) do
            if DoesEntityExist(entity) then
                -- Detaching drops the ped at the origin, so put it back.
                local coords = GetEntityCoords(entity)
                DetachEntity(entity, false, false)
                SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, false)
                SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            end
        end
    end

    runtime.attachedEntities = {}
end

-- Starts a local animation of a trip the server announced. Without a
-- synced clock the server's start timestamp is meaningless, so such a
-- trip is only accepted when the caller forces it.
function LatchTrip(shaftId, tripId, fromStop, toStop, startTime, duration, force)
    local runtime = shaftRuntime[shaftId]
    local shaft = Config.Shafts[shaftId]
    if not runtime or not shaft then return end
    if not (runtime.entity and DoesEntityExist(runtime.entity)) then return end

    local fromPos = GetStopPosition(shaft, fromStop)
    local toPos = GetStopPosition(shaft, toStop)
    if not fromPos or not toPos then return end

    if type(duration) ~= 'number' or duration <= 0 then
        duration = Neox.GetTripDuration(shaftId, fromStop, toStop)
    end

    local useLocalClock = not clockSynced
    if useLocalClock and not force then return end

    runtime.tripId = tripId
    runtime.trip = {
        toStop        = toStop,
        fromPos       = fromPos,
        toPos         = toPos,
        startTime     = useLocalClock and GetGameTimer() or startTime,
        duration      = duration,
        useLocalClock = useLocalClock,
        finished      = false,
    }
    runtime.attachRetryAt = nil

    if Config.Debug.enabled then
        print(('[neox_elevator] %s: trip #%s %s -> %s (%sms, progress %.2f, %s clock)'):format(
            shaftId,
            tostring(tripId),
            tostring(fromStop),
            tostring(toStop),
            tostring(duration),
            GetTripProgress(runtime.trip),
            useLocalClock and 'local' or 'server'))
    end
end

function GetTripProgress(trip)
    local now = trip.useLocalClock and GetGameTimer() or ServerNow()
    local progress = (now - trip.startTime) / trip.duration

    if progress < 0.0 then return 0.0 end
    if progress > 1.0 then return 1.0 end

    return progress
end

function AdoptTripFromState(shaftId)
    local runtime = shaftRuntime[shaftId]
    if not runtime then return end

    local trip = ReadShaftState(shaftId, 'trip', nil)

    if type(trip) ~= 'table' then
        -- The shaft is idle again; drop our copy once it finished animating.
        if runtime.tripId ~= nil then
            if not (runtime.trip and not runtime.trip.finished) then
                runtime.tripId = nil
                runtime.trip = nil
            end
        end
        return
    end

    if trip.id == runtime.tripId then return end

    LatchTrip(shaftId, trip.id, trip.from, trip.to, trip.start, trip.duration)
end

RegisterNetEvent(Neox.Event('trip'), function(shaftId, tripId, fromStop, toStop, startTime, duration)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity) then return end
    if runtime.tripId == tripId then return end

    LatchTrip(shaftId, tripId, fromStop, toStop, startTime, duration, true)
    DriveCabin(shaftId)
end)

-- Moves the cabin to where it should be this frame. Returns the position
-- it settled on, so callers can reuse it instead of re-reading coords.
function DriveCabin(shaftId, force, coords)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.entity and DoesEntityExist(runtime.entity)) then return nil end

    local shaft = Config.Shafts[shaftId]

    AdoptTripFromState(shaftId)

    local target = nil
    local trip = runtime.trip

    if trip then
        local progress = GetTripProgress(trip)

        if not trip.finished then
            LoadRiders(shaftId)
        end

        target = VecLerp(trip.fromPos, trip.toPos, EaseMoveProgress(progress), true)

        if progress >= 1.0 and not trip.finished then
            trip.finished = true
            UnloadRiders(shaftId)
        end

        -- Only let go of the trip once the shaft state agrees we arrived.
        if trip.finished then
            local phase = ReadShaftState(shaftId, 'phase', Neox.Phase.IDLE)
            local stop = ReadShaftState(shaftId, 'stop', trip.toStop)

            if phase ~= Neox.Phase.TRAVELLING and stop == trip.toStop then
                runtime.trip = nil
            end
        end
    else
        target = GetStopPosition(shaft, ReadShaftState(shaftId, 'stop', 1))
    end

    if not target then return coords end

    local current = coords or GetEntityCoords(runtime.entity)

    if force or #(current - target) > 0.001 then
        SetEntityCoordsNoOffset(runtime.entity, target.x, target.y, target.z, true, true, false)
    end

    return target
end

-- ---------------------------------------------------------
-- Doors
-- ---------------------------------------------------------
function DriveDoors(shaftId, phase, stopId, coords)
    local shaft = Config.Shafts[shaftId]

    if not phase then
        phase = ReadShaftState(shaftId, 'phase', Neox.Phase.IDLE)
    end

    if not stopId then
        stopId = ReadShaftState(shaftId, 'stop', 1)
    end

    local stop = shaft.stops[stopId]
    local runtime = shaftRuntime[shaftId]

    if not stop or not runtime then return end
    if not (runtime.entity and DoesEntityExist(runtime.entity)) then return end

    -- Door travel is timed from the moment the phase began.
    if phase == Neox.Phase.OPENING or phase == Neox.Phase.CLOSING then
        if not runtime.doorStartTime then
            runtime.doorStartTime = GetGameTimer()
        end
    else
        runtime.doorStartTime = nil
    end

    local elapsed = (runtime.doorStartTime and (GetGameTimer() - runtime.doorStartTime)) or 0

    -- ratio runs from 0 (shut) to -1 (fully open).
    local ratio = 0.0
    -- doorState is assigned in every branch but never read; the original
    -- tracked it the same way, so it is kept for parity.
    local doorState = 1

    if phase == Neox.Phase.OPENING then
        doorState = 3
        ratio = -math.min(elapsed / (Config.Timing.doorOpen * 1000), 1.0)

    elseif phase == Neox.Phase.OPEN then
        doorState = 3
        ratio = -1.0

    elseif phase == Neox.Phase.CLOSING then
        doorState = 3
        ratio = -1.0 + math.min(elapsed / (Config.Timing.doorClose * 1000), 1.0)

    elseif phase == Neox.Phase.IDLE then
        doorState = 5
        ratio = -1.0

    else
        doorState = 4
        ratio = 0.0
    end

    -- Doors stay shut while the cabin is in motion, or when locked.
    if runtime.trip and not runtime.trip.finished then
        doorState = 4
        ratio = 0.0
    end

    if Config.Interaction.lockDoors then
        doorState = 4
        ratio = 0.0
    end

    local cabinZ = (coords or GetEntityCoords(runtime.entity)).z

    -- Same stop, same openness, same height: nothing to rewrite.
    if runtime.poseStop == stopId
        and runtime.poseRatio == ratio
        and runtime.poseCabinZ == cabinZ
    then
        return
    end

    runtime.poseCabinZ = cabinZ
    runtime.poseRatio = ratio
    runtime.poseStop = stopId

    if runtime.landingDoors then
        local slide = shaft.doors.slide or 0.6

        for landingStopId, doors in pairs(runtime.landingDoors) do
            -- Only the floor the cabin is parked at opens.
            local openAmount = (landingStopId == stopId and -ratio) or 0.0
            if openAmount < 0.0 then openAmount = 0.0 end

            local slideBy = slide * openAmount

            if doors.left and doors.leftDummy then
                AttachEntityToEntity(doors.left, doors.leftDummy, 0,
                    -slideBy, 0.0, 0.0, 0.0, 0.0, 0.0,
                    false, false, true, false, 2, true)
            end

            if doors.right and doors.rightDummy then
                AttachEntityToEntity(doors.right, doors.rightDummy, 0,
                    -slideBy, 0.0, 0.0, 0.0, 0.0, 0.0,
                    false, false, true, false, 2, true)
            end
        end
    end

    if runtime.leftDoor and runtime.rightDoor
        and DoesEntityExist(runtime.leftDoor) and DoesEntityExist(runtime.rightDoor)
    then
        local slide = shaft.doors.slide or 0.6
        local heading = GetEntityHeading(runtime.entity)

        local leftX = runtime.baseLeftLocal.x + slide * ratio
        local rightX = runtime.baseRightLocal.x - slide * ratio

        local leftWorld = GetOffsetFromEntityInWorldCoords(runtime.entity,
            leftX, runtime.baseLeftLocal.y, runtime.baseLeftLocal.z)
        SetEntityCoords(runtime.leftDoor,
            leftWorld.x, leftWorld.y, leftWorld.z, false, false, false, false)

        local leftRot = runtime.leftRot or vec3(0.0, 0.0, 0.0)
        SetEntityRotation(runtime.leftDoor,
            leftRot.x, leftRot.y, heading + leftRot.z, 2, true)

        local rightWorld = GetOffsetFromEntityInWorldCoords(runtime.entity,
            rightX, runtime.baseRightLocal.y, runtime.baseRightLocal.z)
        SetEntityCoords(runtime.rightDoor,
            rightWorld.x, rightWorld.y, rightWorld.z, false, false, false, false)

        local rightRot = runtime.rightRot or vec3(0.0, 0.0, 180.0)
        SetEntityRotation(runtime.rightDoor,
            rightRot.x, rightRot.y, heading + rightRot.z, 2, true)
    end
end

-- Dev tool: nudge a landing door's base position/rotation at runtime.
AddEventHandler(Neox.Event('dev:door'), function(shaftId, stopId, side, x, y, z, rotX, rotY, rotZ)
    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.landingDoors and runtime.landingDoors[stopId]) then return end

    local doors = runtime.landingDoors[stopId]

    if side == 'left' then
        doors.baseLeft = vec3(x, y, z)

        if doors.left and DoesEntityExist(doors.left) then
            SetEntityRotation(doors.left, rotX, rotY, rotZ, 2, true)
        end
    else
        doors.baseRight = vec3(x, y, z)

        if doors.right and DoesEntityExist(doors.right) then
            SetEntityRotation(doors.right, rotX, rotY, rotZ, 2, true)
        end
    end

    -- Force DriveDoors to rebuild the pose on the next frame.
    runtime.poseCabinZ = nil
    runtime.poseRatio = nil
    runtime.poseStop = nil

    print(('[Elevator Dev] Live-updated floor %s %s door.')
        :format(tostring(stopId), tostring(side)))
end)

-- ---------------------------------------------------------
-- Calling the cabin
-- ---------------------------------------------------------
-- stop table -> { raw, pos, heading }
local callPointCache = {}

function GetStopCallPoint(stop)
    local call = stop and stop.call
    if not call then return nil end

    local cached = callPointCache[stop]
    if cached and cached.raw == call then
        return cached.pos, cached.heading
    end

    local pos = vector3(call.x, call.y, call.z)
    local heading = nil

    if type(call) == 'vector4' then
        heading = call.w
    end

    callPointCache[stop] = { raw = call, pos = pos, heading = heading }

    return pos, heading
end

local CALL_REACH = 0.5
local HEADING_TOLERANCE = 20.0
local WALK_TIMEOUT = 2000
local TASK_STATUS_FINISHED = 7

function HeadingDelta(from, to)
    local delta = (from - to) % 360.0

    if delta > 180.0 then
        delta = delta - 360.0
    end

    return math.abs(delta)
end

function TurnPedToHeading(ped, heading)
    if not heading then return end
    if HeadingDelta(GetEntityHeading(ped), heading) <= HEADING_TOLERANCE then return end

    TaskAchieveHeading(ped, heading, 1000)

    local deadline = GetGameTimer() + 1000

    while deadline > GetGameTimer() do
        Wait(0)

        if HeadingDelta(GetEntityHeading(ped), heading) <= HEADING_TOLERANCE then
            break
        end
    end
end

-- Walks the player onto the call point so the bell animation lines up.
function AlignPedToCallPoint(pos, heading)
    if not pos then return end

    local ped = PlayerPedId()

    if #(GetEntityCoords(ped) - pos) <= CALL_REACH then
        TurnPedToHeading(ped, heading)
        return
    end

    TaskGoStraightToCoord(ped, pos.x, pos.y, pos.z, 1.0, -1,
        heading or GetEntityHeading(ped), CALL_REACH)

    local deadline = GetGameTimer() + WALK_TIMEOUT
    local started = false

    -- Wait for the task to start, then for it to report finished.
    while deadline > GetGameTimer() do
        Wait(0)

        local status = GetScriptTaskStatus(ped, 'SCRIPT_TASK_GO_STRAIGHT_TO_COORD')

        if status ~= TASK_STATUS_FINISHED then
            started = true
        elseif started then
            break
        end
    end
end

function RequestCabinAtStop(shaftId, stopId)
    if CanUseStop and not CanUseStop(shaftId, stopId) then return end

    local runtime = shaftRuntime[shaftId]
    if runtime and runtime.isCalling then return end
    if runtime then runtime.isCalling = true end

    local shaft = Config.Shafts[shaftId]

    CreateThread(function()
        local playBell = shaft ~= nil

        if playBell then
            RequestAnimDict('mp_doorbell')
        end

        local callPos, callHeading = GetStopCallPoint(shaft and shaft.stops and shaft.stops[stopId])
        AlignPedToCallPoint(callPos, callHeading)

        local ped = PlayerPedId()

        if playBell then
            while not HasAnimDictLoaded('mp_doorbell') do
                Wait(0)
            end

            TaskPlayAnim(ped, 'mp_doorbell', 'ring_bell_b',
                8.0, -4.0, 1600, 48, 0.0, true, true, true)
            RemoveAnimDict('mp_doorbell')
            Wait(1600)
        end

        if runtime then
            runtime.isCalling = false
        end

        TriggerServerEvent(Neox.Event('request'), shaftId, stopId)
    end)
end

-- ---------------------------------------------------------
-- ox_target: landing call buttons
-- ---------------------------------------------------------
local callTargetZones = {}

local function CanUseCallTarget(shaftId, stopId)
    local runtime = shaftRuntime[shaftId]
    if runtime and runtime.isInCabin then return false end
    if CanInteractWithElevator and not CanInteractWithElevator(shaftId) then return false end

    -- Preserve the existing debug behaviour; normal play can call every stop.
    if Config.Debug.enabled and ReadShaftState(shaftId, 'stop', 1) == stopId then
        return false
    end

    return true
end

local function CreateCallTargets()
    if GetResourceState('ox_target') ~= 'started' then return end

    for shaftId, shaft in pairs(Config.Shafts) do
        for stopId, stop in pairs(shaft.stops or {}) do
            local zoneKey = ('%s:%s'):format(shaftId, tostring(stopId))
            local callPos = GetStopCallPoint(stop)

            if callPos and not callTargetZones[zoneKey] then
                local optionName = ('neox_mrpd_elevator:%s:call:%s'):format(
                    shaftId, tostring(stopId))

                callTargetZones[zoneKey] = exports.ox_target:addSphereZone({
                    name    = optionName,
                    coords  = callPos,
                    radius  = shaft.callRadius or 1.5,
                    debug = true,
                    options = {
                        {
                            name     = optionName,
                            icon     = Config.Interaction.target.callIcon,
                            label    = Config.Interaction.text.call,
                            distance = Config.Interaction.target.callDistance,
                            canInteract = function()
                                return CanUseCallTarget(shaftId, stopId)
                            end,
                            onSelect = function()
                                if CanUseCallTarget(shaftId, stopId) then
                                    -- Keeps the existing walk-up, turn and bell animation.
                                    RequestCabinAtStop(shaftId, stopId)
                                end
                            end,
                        },
                    },
                })
            end
        end
    end
end

local function RemoveCallTargets()
    if GetResourceState('ox_target') == 'started' then
        for _, zoneId in pairs(callTargetZones) do
            exports.ox_target:removeZone(zoneId)
        end
    end

    callTargetZones = {}
end

-- Rebuild client-side targets if ox_target is restarted independently.
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'ox_target' then return end

    callTargetZones = {}
    CreateCallTargets()

    for shaftId, runtime in pairs(shaftRuntime) do
        runtime.panelTarget = nil
        RegisterCabinTarget(shaftId)
    end
end)

CreateThread(function()
    -- Let every client script finish loading before options can be selected.
    Wait(0)
    CreateCallTargets()
end)

-- ---------------------------------------------------------
-- Per-frame shaft work
-- ---------------------------------------------------------
-- Attack, aim, melee and weapon-wheel controls, blocked while riding.
local RIDE_BLOCKED_CONTROLS = { 24, 140, 141, 142, 143, 257, 263, 264 }

function BlockCombatWhileRiding(shaftId)
    if Config.Ride.blockCombat == false then return end

    local runtime = shaftRuntime[shaftId]
    if not (runtime and runtime.isAttached) then return end
    if not (runtime.entity and DoesEntityExist(runtime.entity)) then return end
    if not IsEntityAttachedToEntity(PlayerPedId(), runtime.entity) then return end

    DisablePlayerFiring(PlayerId(), true)

    for _, control in ipairs(RIDE_BLOCKED_CONTROLS) do
        DisableControlAction(0, control, true)
    end
end

local IDLE_SLEEP = 150
local VOLUME_DRAW_DISTANCE = 6.0
local CABIN_ACTIVE_DISTANCE = 4.0
local CABIN_CHECK_DISTANCE = 6.0

-- Runs one frame of a nearby shaft. Returns how long to sleep before the
-- next frame: 0 while anything is happening, IDLE_SLEEP otherwise.
function RunShaftFrame(shaftId)
    local shaft = Config.Shafts[shaftId]
    if not shaft then return IDLE_SLEEP end

    local runtime = shaftRuntime[shaftId]
    if not runtime then return IDLE_SLEEP end

    local phase = ReadShaftState(shaftId, 'phase', Neox.Phase.IDLE)
    local stopId = ReadShaftState(shaftId, 'stop', 1)

    local stop = shaft.stops[stopId]
    if not stop then return IDLE_SLEEP end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    local busy = false

    local cabinExists = runtime.entity and DoesEntityExist(runtime.entity)
    local cabinCoords = (cabinExists and GetEntityCoords(runtime.entity)) or nil

    if cabinCoords then
        local dist = #(pedCoords - cabinCoords)

        if dist < CABIN_ACTIVE_DISTANCE then
            busy = true
        end

        if dist < CABIN_CHECK_DISTANCE then
            runtime.isInCabin = IsPedInCabin(ped, runtime.entity, shaftId, cabinCoords, pedCoords)
        else
            runtime.isInCabin = false
        end

        if Config.Debug.drawVolumes and dist < VOLUME_DRAW_DISTANCE then
            busy = true
            DrawCabinVolume(runtime.entity, runtime.isInCabin, shaftId)
        end
    else
        runtime.isInCabin = false
    end

    if runtime.isInCabin then
        busy = true
    else
        -- Stepped out of the cabin while the panel was up.
        if panelCam ~= nil and panelShaftId == shaftId then
            ExitPanelView()
        end
    end

    cabinCoords = DriveCabin(shaftId, nil, cabinCoords) or cabinCoords

    BlockCombatWhileRiding(shaftId)

    -- Riders are only held while a trip is live.
    if runtime.isAttached and not runtime.trip then
        UnloadRiders(shaftId)
    end

    DriveDoors(shaftId, phase, stopId, cabinCoords)
    DriveCabinAudio(shaftId, phase, cabinCoords)
    PinPropsToRoom(shaftId)

    if runtime.trip or phase ~= Neox.Phase.IDLE then
        busy = true
    end

    if panelCam ~= nil and panelShaftId == shaftId then
        busy = true
    end

    return busy and 0 or IDLE_SLEEP
end

-- ---------------------------------------------------------
-- Streaming shafts in and out
-- ---------------------------------------------------------
CreateThread(function()
    ResetShaftRuntime()

    while not NetworkIsSessionStarted() do
        Wait(500)
    end

    while not DoesEntityExist(PlayerPedId()) do
        Wait(500)
    end

    while true do
        Wait(1000)

        local coords = GetEntityCoords(PlayerPedId())

        for shaftId, shaft in pairs(Config.Shafts) do
            if shaft.cabin.position then
                -- Measured flat: the cabin's height changes as it travels.
                local flat = #(vec2(coords.x, coords.y)
                    - vec2(shaft.cabin.position.x, shaft.cabin.position.y))

                if not shaftRuntime[shaftId].isNearby then
                    if flat < shaft.range then
                        if BuildShaft(shaftId) then
                            shaftRuntime[shaftId].isNearby = true

                            -- One frame loop per shaft, self-paced.
                            CreateThread(function()
                                while shaftRuntime[shaftId].isNearby do
                                    Wait(RunShaftFrame(shaftId) or IDLE_SLEEP)
                                end
                            end)
                        end
                    end

                -- Extra 5m of hysteresis so walking the boundary does not
                -- rebuild the shaft repeatedly.
                elseif flat > shaft.range + 5 then
                    shaftRuntime[shaftId].isNearby = false
                    ClearShaft(shaftId)
                end
            end
        end
    end
end)

-- ---------------------------------------------------------
-- Panel view: cursor picking and input
-- ---------------------------------------------------------
-- Movement, combat, camera and weapon controls, blocked while the panel
-- has the screen.
local PANEL_BLOCKED_CONTROLS = {
    0, 1, 2, 3, 4, 5, 6,
    24, 25, 257,
    140, 141, 142,
    106,
    14, 15, 16, 17,
    37,
}

CreateThread(function()
    while true do
        local sleep = 200

        if panelCam ~= nil and panelShaftId ~= nil then
            sleep = 0

            if not IsPauseMenuActive() and not IsNuiFocused() then
                SetMouseCursorActiveThisFrame()
                DisablePlayerFiring(PlayerId(), true)

                for _, control in ipairs(PANEL_BLOCKED_CONTROLS) do
                    DisableControlAction(0, control, true)
                end

                if IsControlJustPressed(0, 322)
                    or IsControlJustPressed(0, 202)
                    or IsControlJustPressed(0, 25)
                    or IsDisabledControlJustPressed(0, 25)
                then
                    ExitPanelView()
                end

                local cursorX = GetDisabledControlNormal(0, 239)
                local cursorY = GetDisabledControlNormal(0, 240)

                local camPos = GetCamCoord(panelCam)
                local camRot = GetCamRot(panelCam, 2)

                local aimPoint = ScreenRelToWorld(camPos, camRot, cursorX, cursorY)

                local runtime = shaftRuntime[panelShaftId]

                if runtime and runtime.entity and DoesEntityExist(runtime.entity) then
                    local rayLength = #(aimPoint - camPos)
                    local direction

                    if rayLength > 0.001 then
                        direction = (aimPoint - camPos) / rayLength
                    else
                        direction = vector3(0, 0, -1)
                    end

                    local shaft = Config.Shafts[panelShaftId]
                    local hitRadius = (shaft and shaft.panel.hitRadius)
                        or Config.ButtonHitRadius
                        or 0.18

                    local hoveredFloor = nil
                    local nearest = hitRadius
                    local drawn = {}

                    for _, button in ipairs(GetStopButtons(panelShaftId)) do
                        local buttonPos = GetStopButtonPosition(runtime.entity, panelShaftId, button)

                        if buttonPos then
                            drawn[#drawn + 1] = { floor = button.floor, coords = buttonPos }

                            -- Distance from the button to the cursor ray.
                            local toButton = buttonPos - camPos
                            local along = toButton.x * direction.x
                                + toButton.y * direction.y
                                + toButton.z * direction.z

                            if along > 0 then
                                local onRay = camPos + direction * along
                                local offRay = #(buttonPos - onRay)

                                if nearest > offRay then
                                    nearest = offRay
                                    hoveredFloor = button.floor
                                end
                            end
                        end
                    end

                    if Config.Debug.drawVolumes
                        and not (IsButtonTuningActive and IsButtonTuningActive())
                    then
                        for _, entry in ipairs(drawn) do
                            local hovered = entry.floor == hoveredFloor

                            DrawMarker(28,
                                entry.coords.x, entry.coords.y, entry.coords.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                hitRadius, hitRadius, hitRadius,
                                hovered and 0 or 255,
                                hovered and 255 or 200,
                                90, 90,
                                false, false, 2, false, nil, nil, false)
                        end
                    end

                    if hoveredFloor ~= nil then
                        SetMouseCursorSprite(5)

                        if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 24) then
                            if CanUseStop and not CanUseStop(panelShaftId, hoveredFloor) then
                                PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                            else
                                PlaySoundFrontend(-1, 'PIN_BUTTON', 'ATM_SOUNDS', true)
                                TriggerServerEvent(Neox.Event('request'), panelShaftId, hoveredFloor)
                                ExitPanelView()
                            end
                        end
                    else
                        SetMouseCursorSprite(1)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    RemoveCallTargets()
    ExitPanelView()

    for shaftId in pairs(Config.Shafts) do
        ClearShaft(shaftId)
    end
end)

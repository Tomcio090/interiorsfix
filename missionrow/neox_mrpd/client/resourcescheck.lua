local ELEVATOR_RESOURCE = "neox_mrpd_elevator"
local ELEVATOR_ENTITY_SET = "static_elev_01"
local ELEVATOR_COORDS = vector3(457.204, -996.127, 36.091)
local ELEVATOR_INTERIOR_TYPE_HASH = 71403308

function GetElevatorLimboInterior()
    local interiorId = GetInteriorAtCoordsWithTypehash(
        ELEVATOR_COORDS.x, ELEVATOR_COORDS.y, ELEVATOR_COORDS.z, ELEVATOR_INTERIOR_TYPE_HASH
    )

    if interiorId == 0 then
        interiorId = GetInteriorAtCoordsWithType(
            ELEVATOR_COORDS.x, ELEVATOR_COORDS.y, ELEVATOR_COORDS.z, "neox_mrpd_limbo_elev_01"
        )
    end

    return interiorId
end

function IsElevatorResourceRunning()
    local state = GetResourceState(ELEVATOR_RESOURCE)
    return state == "started" or state == "starting"
end

-- The static elevator shell is only shown when the elevator resource is absent.
function SyncElevatorEntitySet()
    local interiorId = GetElevatorLimboInterior()
    if interiorId == 0 then
        return
    end

    local shouldBeActive = not IsElevatorResourceRunning()
    if IsInteriorEntitySetActive(interiorId, ELEVATOR_ENTITY_SET) == shouldBeActive then
        return
    end

    if shouldBeActive then
        ActivateInteriorEntitySet(interiorId, ELEVATOR_ENTITY_SET)
    else
        DeactivateInteriorEntitySet(interiorId, ELEVATOR_ENTITY_SET)
    end

    RefreshInterior(interiorId)
end

CreateThread(function()
    Wait(2000)
    SyncElevatorEntitySet()
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == ELEVATOR_RESOURCE then
        SyncElevatorEntitySet()
    end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName == ELEVATOR_RESOURCE then
        SyncElevatorEntitySet()
    end
end)

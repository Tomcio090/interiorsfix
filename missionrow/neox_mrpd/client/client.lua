CreateThread(function()
    local policeHubInterior = GetInteriorAtCoordsWithType(0.0, 0.0, 0.0, "v_policehub")

    DisableInterior(policeHubInterior, true)
    UnpinInterior(policeHubInterior)
end)

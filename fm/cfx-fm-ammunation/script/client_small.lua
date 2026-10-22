-- Disable vanilla small Ammunation interiors

local vanillaLocations = {
    { coords = vector3(-663.1717,    -940.758057,    20.8291473) }, -- Little Seoul
    { coords = vector3(843.2987,      -1028.10669, 27.1947746) }, -- La Mesa
    { coords = vector3(247.371582,    -47.245163,      68.9409943) }, -- Vinewood
    { coords = vector3(2568.834,    299.788116,  107.734818)  }, -- Highway
    { coords = vector3(-327.1706,     6079.257,   30.4546967)   }, -- Paleto
}

CreateThread(function()
    for _, loc in ipairs(vanillaLocations) do
        local oldinterior = GetInteriorAtCoordsWithType(loc.coords.x, loc.coords.y, loc.coords.z, 'v_gun2')
        DisableInterior(oldinterior, true)
        UnpinInterior(oldinterior)
    end
end)
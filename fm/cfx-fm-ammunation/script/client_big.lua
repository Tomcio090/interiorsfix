-- Disable vanilla Ammunation interiors

local vanillaLocations = {
    { coords = vector3(10.9070005,   -1105.65833,    28.7969322) }, -- Legion Square
    { coords = vector3(821.144043,      -2154.8916, 28.61892) }, -- Cypress Flats
}

CreateThread(function()
    for _, loc in ipairs(vanillaLocations) do
        local oldinterior = GetInteriorAtCoordsWithType(loc.coords.x, loc.coords.y, loc.coords.z, 'v_gun')
        DisableInterior(oldinterior, true)
        UnpinInterior(oldinterior)
    end
end)
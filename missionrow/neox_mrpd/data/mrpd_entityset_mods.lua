--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

local INTERIOR_ENTITY_SETS = {
    neox_mrpd_interior_02 = {
        coords = vec3(457.204041, -996.1263, 36.091465),
        sets = {
            cells_01 = true,
            cells_02 = false,
        },
    },
}

function ApplyInteriorEntitySets(iplName, interiorData)
    RequestIpl(iplName)

    local interiorId = GetInteriorAtCoordsWithType(interiorData.coords, "neox_mrpd_limbo_col_02")
    if not IsValidInterior(interiorId) then
        return
    end

    for entitySetName, shouldBeActive in pairs(interiorData.sets) do
        if shouldBeActive then
            ActivateInteriorEntitySet(interiorId, entitySetName)
        else
            DeactivateInteriorEntitySet(interiorId, entitySetName)
        end
    end

    RefreshInterior(interiorId)
end

for iplName, interiorData in pairs(INTERIOR_ENTITY_SETS) do
    ApplyInteriorEntitySets(iplName, interiorData)
end

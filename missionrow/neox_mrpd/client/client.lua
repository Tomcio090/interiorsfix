--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

CreateThread(function()
    print('^5[FiveVault]^7 Loaded neox_mrpd - https://fivevault.net | discord.gg/fivevault')
    local policeHubInterior = GetInteriorAtCoordsWithType(0.0, 0.0, 0.0, "v_policehub")

    DisableInterior(policeHubInterior, true)
    UnpinInterior(policeHubInterior)
end)

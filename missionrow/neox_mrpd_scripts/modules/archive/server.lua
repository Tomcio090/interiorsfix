--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — DIGITAL ARCHIVE (server)
-- =========================================================
-- The archive panel is read-only and built entirely from locale strings
-- on the client, so the only thing the server owns is the access gate.
-- =========================================================

if not NeoxMRPD.enabled('archive') then return end

RegisterNetEvent('neox_mrpd_archive:server:requestAccess', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'archive:access', 1000) then return end

    local granted = Bridge.HasAccess(src, NeoxMRPD.accessOf('archive'))

    TriggerClientEvent('neox_mrpd_archive:client:accessResult', src, granted)
end)

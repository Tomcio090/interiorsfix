--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — HYGIENE: STRESS REDUCTION
-- =========================================================

if not NeoxMRPD.enabled('hygiene') then return end

Hyg = Hyg or {}

local cfg = NeoxMRPD.Config.Hygiene

-- activity is a key under Config.Hygiene.StressReduction
-- ('shower' | 'poop' | 'pee' | 'washHands')
function Hyg.relieveStress(activity)
    local stress = cfg.StressReduction
    if not stress or not stress.enabled then return end

    local entry = stress[activity]
    if not entry or not entry.enabled then return end

    local amount = entry.amount
    if not amount or amount <= 0 then return end

    Bridge.RemoveStress(amount)
end

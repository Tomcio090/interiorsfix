--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — KILL HOUSE :: EDITABLE SERVER  (OPEN FILE)
-- =========================================================
-- Scoring and retention rules for the kill house leaderboard. Loaded
-- after modules/killhouse/server.lua, which reads these at call time —
-- so changing anything here needs no edits anywhere else.
-- =========================================================

KillhouseRules = {}

-- How many rows the board keeps. The DUI shows the top 10.
KillhouseRules.maxEntries = 25

-- true  one row per player, replaced only when they beat their own run
-- false every run is its own row
KillhouseRules.bestPerPlayer = true

-- ---------------------------------------------------------
-- Ranking
-- ---------------------------------------------------------
-- Return true when `a` should sit above `b`.
-- Each entry is { name, identifier, score, weapon, timeFormatted,
-- seconds, at }.
--
-- Default: most targets wins, and a tie is broken by the faster run.
function KillhouseRules.isBetter(a, b)
    if a.score ~= b.score then
        return (a.score or 0) > (b.score or 0)
    end

    return (a.seconds or math.huge) < (b.seconds or math.huge)
end

-- ---------------------------------------------------------
-- Hook
-- ---------------------------------------------------------
-- Called once a run has been written to the board. Wire payouts,
-- Discord logs or job XP in here.
function KillhouseRules.onScoreSaved(src, entry)
    -- Example:
    -- if entry.score >= 16 then
    --     exports.ox_inventory:AddItem(src, 'money', 500)
    -- end
end

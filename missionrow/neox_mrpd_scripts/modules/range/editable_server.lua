--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — SHOOTING RANGE :: EDITABLE SERVER  (OPEN FILE)
-- =========================================================
-- Scoring and retention rules for the range leaderboard. Loaded after
-- modules/range/server.lua, which reads these at call time — so changing
-- anything here needs no edits anywhere else.
-- =========================================================

RangeRules = {}

-- How many rows the board keeps. The DUI shows the top 10.
RangeRules.maxEntries = 25

-- true  one row per officer, replaced only when they beat their own run
-- false every run is its own row
RangeRules.bestPerPlayer = true

-- ---------------------------------------------------------
-- Ranking
-- ---------------------------------------------------------
-- Return true when `a` should sit above `b`.
-- Each entry is { name, identifier, score, weapon, mode, timeFormatted,
-- seconds, at }.
--
-- Default: most targets hit wins, and a tie goes to the shorter run.
function RangeRules.isBetter(a, b)
    if a.score ~= b.score then
        return (a.score or 0) > (b.score or 0)
    end

    return (a.seconds or math.huge) < (b.seconds or math.huge)
end

-- ---------------------------------------------------------
-- Hook
-- ---------------------------------------------------------
-- Called once a run has been written to the board. Wire payouts,
-- Discord logs or marksmanship certifications in here.
function RangeRules.onScoreSaved(src, entry)
    -- Example: reward a perfect burst-mode run
    -- if entry.mode == 'Burst' and entry.score >= 20 then
    --     exports.ox_inventory:AddItem(src, 'money', 750)
    -- end
end

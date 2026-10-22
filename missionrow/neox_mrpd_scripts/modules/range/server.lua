-- =========================================================
-- NEOX MRPD — SHOOTING RANGE (server)
-- =========================================================
-- Owns booth occupancy, the shared target distances, the single AimLab
-- session, the persisted leaderboard and per-officer stats.
--
-- Target distances are intentionally in memory only: a restart should
-- put every target back at its configured position.
--
-- Ranking and retention rules live in editable_server.lua.
-- =========================================================

if not NeoxMRPD.enabled('range') then return end

local cfg = NeoxMRPD.Config.Range

local SCORES_FILE = 'range_scores.json'
local STATS_FILE = 'range_stats.json'

-- { name, identifier, score, weapon, mode, timeFormatted, seconds, at }
local scores = NeoxMRPD.ReadData(SCORES_FILE, {})

-- identifier -> { name, sessions, hits, totalMisses, shots, bestScore, weapons = { [weapon] = count } }
local stats = NeoxMRPD.ReadData(STATS_FILE, {})

-- boothId -> src
local boothOwners = {}

-- boothId -> current target X
local targetX = {}

local aimLab = {
    active     = false,
    player     = nil,
    playerName = '',
    mode       = 'single',
    phase      = 'idle',
}

local DEFAULT_RULES = {
    maxEntries    = 25,
    bestPerPlayer = true,
}

function RangeRule(key)
    local rules = RangeRules
    if rules and rules[key] ~= nil then return rules[key] end
    return DEFAULT_RULES[key]
end

function RangeIsBetter(a, b)
    local rules = RangeRules
    if rules and rules.isBetter then
        return rules.isBetter(a, b)
    end

    if a.score ~= b.score then
        return (a.score or 0) > (b.score or 0)
    end

    return (a.seconds or math.huge) < (b.seconds or math.huge)
end

-- ---------------------------------------------------------
-- Target positions
-- ---------------------------------------------------------
for index, booth in ipairs(cfg.Booths or {}) do
    targetX[index] = booth.targetPos.x
end

function RangeAllTargetPositions()
    local out = {}
    for index, x in pairs(targetX) do
        out[index] = x
    end
    return out
end

-- ---------------------------------------------------------
-- Leaderboard and stats
-- ---------------------------------------------------------
function RangeLeaderboard()
    local board = {}

    for _, entry in ipairs(scores) do
        board[#board + 1] = {
            name          = entry.name,
            score         = entry.score,
            weapon        = entry.weapon,
            mode          = entry.mode,
            timeFormatted = entry.timeFormatted,
        }
    end

    return board
end

function RangeSortScores()
    table.sort(scores, RangeIsBetter)

    local maxEntries = RangeRule('maxEntries') or 25
    while #scores > maxEntries do
        table.remove(scores)
    end
end

function RangeBroadcastScoreboard(target)
    TriggerClientEvent('neox_shootingrange:client:SyncScoreboard', target or -1, RangeLeaderboard())
end

-- The most-used weapon category, for the personal stats tab.
function RangeFavouriteWeapon(record)
    local best, bestCount = nil, 0

    for weapon, count in pairs(record.weapons or {}) do
        if count > bestCount then
            best, bestCount = weapon, count
        end
    end

    return best or 'NONE'
end

function RangeStatsFor(src)
    local _, identifier = Bridge.GetIdentity(src)
    local record = stats[identifier]

    if not record then
        return {
            sessions       = 0,
            hits           = 0,
            totalMisses    = 0,
            misses         = 0,
            shots          = 0,
            accuracy       = 0,
            bestScore      = 0,
            score          = 0,
            favoriteWeapon = 'NONE',
        }
    end

    local shots = record.shots or 0
    local accuracy = 0
    if shots > 0 then
        accuracy = math.floor(((record.hits or 0) / shots) * 100 + 0.5)
    end

    return {
        sessions       = record.sessions or 0,
        hits           = record.hits or 0,
        totalMisses    = record.totalMisses or 0,
        misses         = record.totalMisses or 0,
        shots          = shots,
        accuracy       = accuracy,
        bestScore      = record.bestScore or 0,
        score          = record.bestScore or 0,
        favoriteWeapon = RangeFavouriteWeapon(record),
    }
end

-- ---------------------------------------------------------
-- Screens
-- ---------------------------------------------------------
function RangeScreenPayload()
    if aimLab.active then
        return {
            type   = 'SYNC_AIMLAB_BUSY',
            player = aimLab.playerName,
            name   = aimLab.playerName,
            mode   = aimLab.mode,
        }
    end

    return { type = 'SYNC_IDLE' }
end

function RangeBroadcastScreen(payload, target)
    TriggerClientEvent('neox_shootingrange:client:SyncScreen', target or -1,
        payload or RangeScreenPayload())
end

function RangeBroadcastAimLabState(target)
    if not aimLab.active then
        TriggerClientEvent('neox_shootingrange:client:SyncAimLabState', target or -1, nil)
        return
    end

    TriggerClientEvent('neox_shootingrange:client:SyncAimLabState', target or -1, {
        active     = true,
        player     = aimLab.player,
        playerName = aimLab.playerName,
        mode       = aimLab.mode,
        phase      = aimLab.phase,
    })
end

-- ---------------------------------------------------------
-- State / stats requests
-- ---------------------------------------------------------
RegisterNetEvent('neox_shootingrange:server:RequestState', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'range:state', 500) then return end

    RangeBroadcastScreen(nil, src)
    RangeBroadcastScoreboard(src)
    RangeBroadcastAimLabState(src)

    TriggerClientEvent('neox_shootingrange:client:SyncAllTargetPositions', src,
        RangeAllTargetPositions())
end)

-- NOTE: the personal stats tab lives in the obfuscated range DUI, and the
-- exact field placement could not be fully recovered from it, so the
-- payload carries the numbers both nested under `data` and flat.
RegisterNetEvent('neox_shootingrange:server:RequestMyStats', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'range:mystats', 500) then return end

    local record = RangeStatsFor(src)

    local payload = { type = 'SYNC_MY_STATS', data = record, stats = record }
    for key, value in pairs(record) do
        payload[key] = value
    end

    RangeBroadcastScreen(payload, src)
end)

-- ---------------------------------------------------------
-- Booths
-- ---------------------------------------------------------
RegisterNetEvent('neox_shootingrange:server:RequestBooth', function(boothId)
    local src = source
    if NeoxMRPD.Throttle(src, 'range:booth', 750) then return end

    if type(boothId) ~= 'number' or not (cfg.Booths and cfg.Booths[boothId]) then return end

    if not Bridge.HasAccess(src, NeoxMRPD.accessOf('range')) then
        TriggerClientEvent('neox_shootingrange:client:BoothResponse', src,
            false, boothId, nil, 'no_access')
        return
    end

    -- A live AimLab session owns the lanes; the client guards on this too.
    if aimLab.active then
        TriggerClientEvent('neox_shootingrange:client:BoothResponse', src,
            false, boothId, nil, 'aimlab_in_progress')
        return
    end

    local owner = boothOwners[boothId]
    if owner and owner ~= src and GetPlayerName(owner) then
        TriggerClientEvent('neox_shootingrange:client:BoothResponse', src,
            false, boothId, nil, 'occupied')
        return
    end

    -- One booth per player.
    for id, holder in pairs(boothOwners) do
        if holder == src and id ~= boothId then
            boothOwners[id] = nil
        end
    end

    boothOwners[boothId] = src

    TriggerClientEvent('neox_shootingrange:client:BoothResponse', src,
        true, boothId, targetX[boothId])
end)

RegisterNetEvent('neox_shootingrange:server:LeaveBooth', function(boothId)
    local src = source
    if type(boothId) ~= 'number' then return end

    if boothOwners[boothId] == src then
        boothOwners[boothId] = nil
    end
end)

RegisterNetEvent('neox_shootingrange:server:UpdateTargetPos', function(boothId, x)
    local src = source

    if type(boothId) ~= 'number' or type(x) ~= 'number' then return end
    if not (cfg.Booths and cfg.Booths[boothId]) then return end
    if boothOwners[boothId] ~= src then return end

    local limits = cfg.TargetLimits or {}
    x = NeoxMRPD.clamp(x, limits.minX or 486.0, limits.maxX or 499.0)

    targetX[boothId] = x

    TriggerClientEvent('neox_shootingrange:client:SyncTargetPos', -1, boothId, x)
end)

-- ---------------------------------------------------------
-- AimLab
-- ---------------------------------------------------------
RegisterNetEvent('neox_shootingrange:server:RequestAimLab', function(mode)
    local src = source
    if NeoxMRPD.Throttle(src, 'range:aimlab', 1000) then return end

    if not Bridge.HasAccess(src, NeoxMRPD.accessOf('range')) then
        TriggerClientEvent('neox_shootingrange:client:AimLabResponse', src, false, 'no_access')
        return
    end

    if aimLab.active and aimLab.player ~= src and GetPlayerName(aimLab.player) then
        -- The client formats this reason into "aimlab_in_progress", so the
        -- holder's name is what it wants here.
        TriggerClientEvent('neox_shootingrange:client:AimLabResponse', src,
            false, aimLab.playerName)
        return
    end

    -- Somebody shooting a booth would be standing in the lanes.
    for boothId, holder in pairs(boothOwners) do
        if holder ~= src and GetPlayerName(holder) then
            TriggerClientEvent('neox_shootingrange:client:AimLabResponse', src, false, 'busy')
            return
        end
    end

    local name = Bridge.GetIdentity(src)

    aimLab.active = true
    aimLab.player = src
    aimLab.playerName = name
    aimLab.mode = (mode == 'burst' and 'burst') or 'single'
    aimLab.phase = 'claimed'

    TriggerClientEvent('neox_shootingrange:client:AimLabResponse', src, true)

    RangeBroadcastAimLabState()
    RangeBroadcastScreen()
end)

RegisterNetEvent('neox_shootingrange:server:UpdateAimLabPhase', function(phase)
    local src = source
    if not aimLab.active or aimLab.player ~= src then return end

    aimLab.phase = tostring(phase or 'idle')
    RangeBroadcastAimLabState()
end)

RegisterNetEvent('neox_shootingrange:server:SyncAimLabLiveStats', function(timeFormatted, score)
    local src = source
    if not aimLab.active or aimLab.player ~= src then return end

    -- Mirrors the running player's HUD onto the wall screens.
    RangeBroadcastScreen({
        type   = 'SYNC_ACTIVE',
        player = aimLab.playerName,
        name   = aimLab.playerName,
        mode   = aimLab.mode,
        time   = tostring(timeFormatted or '00:00'),
        score  = tonumber(score) or 0,
    })
end)

RegisterNetEvent('neox_shootingrange:server:SyncAimLabTargetPopup', function(index, popped)
    local src = source
    if not aimLab.active or aimLab.player ~= src then return end
    if type(index) ~= 'number' then return end

    -- Everyone except the runner, who already moved its own target.
    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        if playerId ~= src then
            TriggerClientEvent('neox_shootingrange:client:SyncAimLabTargetPopup', playerId,
                index, popped == true)
        end
    end
end)

RegisterNetEvent('neox_shootingrange:server:StopAimLab', function()
    local src = source
    if not aimLab.active or aimLab.player ~= src then return end

    aimLab.active = false
    aimLab.player = nil
    aimLab.playerName = ''
    aimLab.phase = 'idle'

    RangeBroadcastAimLabState()
    RangeBroadcastScreen()
end)

-- ---------------------------------------------------------
-- Scoring
-- ---------------------------------------------------------
RegisterNetEvent('neox_shootingrange:server:SaveScore',
    function(score, timeFormatted, seconds, weapon, mode)
        local src = source
        if not aimLab.active or aimLab.player ~= src then return end

        local name, identifier = Bridge.GetIdentity(src)

        local entry = {
            name          = name,
            identifier    = identifier,
            score         = tonumber(score) or 0,
            weapon        = tostring(weapon or 'Pistol'),
            mode          = tostring(mode or 'Single'),
            timeFormatted = tostring(timeFormatted or '00:00'),
            seconds       = tonumber(seconds) or 0,
            at            = os.time(),
        }

        local replaced = false

        if RangeRule('bestPerPlayer') then
            for index, existing in ipairs(scores) do
                if existing.identifier == identifier then
                    -- Keep whichever run was better; the row is theirs either way.
                    if RangeIsBetter(entry, existing) then
                        scores[index] = entry
                    end

                    replaced = true
                    break
                end
            end
        end

        if not replaced then
            scores[#scores + 1] = entry
        end

        RangeSortScores()
        NeoxMRPD.QueueWrite(SCORES_FILE, scores)
        RangeBroadcastScoreboard()

        -- Fires for every completed run, whether or not it made the board.
        if RangeRules and RangeRules.onScoreSaved then
            pcall(RangeRules.onScoreSaved, src, entry)
        end
    end)

RegisterNetEvent('neox_shootingrange:server:SaveAimLabStats',
    function(hits, misses, shots, weapon)
        local src = source
        if not aimLab.active or aimLab.player ~= src then return end

        local name, identifier = Bridge.GetIdentity(src)

        local record = stats[identifier] or {
            name        = name,
            sessions    = 0,
            hits        = 0,
            totalMisses = 0,
            shots       = 0,
            bestScore   = 0,
            weapons     = {},
        }

        record.name = name
        record.sessions = (record.sessions or 0) + 1
        record.hits = (record.hits or 0) + (tonumber(hits) or 0)
        record.totalMisses = (record.totalMisses or 0) + (tonumber(misses) or 0)
        record.shots = (record.shots or 0) + (tonumber(shots) or 0)

        if (tonumber(hits) or 0) > (record.bestScore or 0) then
            record.bestScore = tonumber(hits) or 0
        end

        local category = tostring(weapon or 'Pistol')
        record.weapons = record.weapons or {}
        record.weapons[category] = (record.weapons[category] or 0) + 1

        stats[identifier] = record
        NeoxMRPD.QueueWrite(STATS_FILE, stats)
    end)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    local changed = false

    for boothId, holder in pairs(boothOwners) do
        if holder == src then
            boothOwners[boothId] = nil
            changed = true
        end
    end

    if aimLab.active and aimLab.player == src then
        aimLab.active = false
        aimLab.player = nil
        aimLab.playerName = ''
        aimLab.phase = 'idle'
        changed = true
    end

    if changed then
        RangeBroadcastAimLabState()
        RangeBroadcastScreen()
    end
end)

-- ---------------------------------------------------------
-- Exports
-- ---------------------------------------------------------
-- fxmanifest declares these under server_exports, which exposes global
-- functions by name — so they are globals rather than exports() calls.
function GetRangeScoreboard()
    return RangeLeaderboard()
end

function ResetRangeScoreboard()
    scores = {}
    NeoxMRPD.WriteData(SCORES_FILE, scores)
    RangeBroadcastScoreboard()
    return true
end

RegisterCommand('range_reset', function(source)
    if not Bridge.IsAdmin(source) then
        if source > 0 then
            Notify.toPlayer(source, 'Not allowed.', 'error')
        end
        return
    end

    scores = {}
    NeoxMRPD.WriteData(SCORES_FILE, scores)
    RangeBroadcastScoreboard()

    print('^2[neox_mrpd_scripts]^7 shooting range scoreboard reset')
end, false)

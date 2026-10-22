-- =========================================================
-- NEOX MRPD — KILL HOUSE (server)
-- =========================================================
-- One operator runs the course at a time. This file owns that lock, the
-- persisted leaderboard, and the two in-world screens (live run and
-- scoreboard), which are driven through SyncScreen / SyncScoreboard.
--
-- Ranking and retention rules live in editable_server.lua.
-- =========================================================

if not NeoxMRPD.enabled('killhouse') then return end

local DATA_FILE = 'killhouse_scores.json'

-- { name, identifier, score, weapon, timeFormatted, seconds, at }
local scores = NeoxMRPD.ReadData(DATA_FILE, {})

-- nil, or { src, name, identifier, startedAt }
local session = nil

-- editable_server.lua loads after this file, so the rules are looked up
-- at call time with these as the fallback.
local DEFAULT_RULES = {
    maxEntries   = 25,
    bestPerPlayer = true,
}

function KillhouseRule(key)
    local rules = KillhouseRules
    if rules and rules[key] ~= nil then return rules[key] end
    return DEFAULT_RULES[key]
end

-- Higher score first, then the faster run.
function KillhouseIsBetter(a, b)
    local rules = KillhouseRules
    if rules and rules.isBetter then
        return rules.isBetter(a, b)
    end

    if a.score ~= b.score then
        return (a.score or 0) > (b.score or 0)
    end

    return (a.seconds or math.huge) < (b.seconds or math.huge)
end

-- ---------------------------------------------------------
-- Leaderboard
-- ---------------------------------------------------------
function KillhouseLeaderboard()
    local board = {}

    for _, entry in ipairs(scores) do
        board[#board + 1] = {
            name          = entry.name,
            score         = entry.score,
            weapon        = entry.weapon,
            timeFormatted = entry.timeFormatted,
        }
    end

    return board
end

function KillhouseSortScores()
    table.sort(scores, KillhouseIsBetter)

    local maxEntries = KillhouseRule('maxEntries') or 25
    while #scores > maxEntries do
        table.remove(scores)
    end
end

function KillhouseRecordScore(src, score, timeFormatted, seconds, weapon)
    local name, identifier = Bridge.GetIdentity(src)

    local entry = {
        name          = name,
        identifier    = identifier,
        score         = tonumber(score) or 0,
        weapon        = tostring(weapon or 'Pistol'),
        timeFormatted = tostring(timeFormatted or '00:00'),
        seconds       = tonumber(seconds) or 0,
        at            = os.time(),
    }

    local replaced = false

    if KillhouseRule('bestPerPlayer') then
        for index, existing in ipairs(scores) do
            if existing.identifier == identifier then
                -- Keep whichever run was better; the row is theirs either way.
                if KillhouseIsBetter(entry, existing) then
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

    KillhouseSortScores()
    NeoxMRPD.QueueWrite(DATA_FILE, scores)

    -- Fires for every completed run, whether or not it made the board.
    if KillhouseRules and KillhouseRules.onScoreSaved then
        pcall(KillhouseRules.onScoreSaved, src, entry)
    end

    return entry
end

function KillhouseBroadcastScoreboard(target)
    TriggerClientEvent('neox_killhouse:client:SyncScoreboard', target or -1, KillhouseLeaderboard())
end

-- ---------------------------------------------------------
-- Screen
-- ---------------------------------------------------------
-- The DUI reads `player`/`name` for the operator and `score`/`targets`
-- for the counters; both spellings are sent so either layout renders.
function KillhouseScreenPayload()
    if not session then
        return { type = 'SYNC_IDLE' }
    end

    return {
        type    = 'SYNC_ACTIVE',
        player  = session.name,
        name    = session.name,
        time    = session.time or '00:00',
        score   = session.score or 0,
        targets = session.targets or (NeoxMRPD.Config.Killhouse.TotalTargets or 16),
    }
end

function KillhouseBroadcastScreen(payload, target)
    TriggerClientEvent('neox_killhouse:client:SyncScreen', target or -1,
        payload or KillhouseScreenPayload())
end

-- ---------------------------------------------------------
-- Events
-- ---------------------------------------------------------
RegisterNetEvent('neox_killhouse:server:RequestState', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'killhouse:state', 500) then return end

    KillhouseBroadcastScreen(nil, src)
    KillhouseBroadcastScoreboard(src)
end)

RegisterNetEvent('neox_killhouse:server:RequestStart', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'killhouse:start', 1000) then return end

    if not Bridge.HasAccess(src, NeoxMRPD.accessOf('killhouse')) then
        TriggerClientEvent('neox_killhouse:client:StartResponse', src, false, 'no_access')
        return
    end

    -- Somebody else is inside — unless they have since disconnected.
    if session and session.src ~= src and GetPlayerName(session.src) then
        TriggerClientEvent('neox_killhouse:client:StartResponse', src, false, 'operator_inside')
        return
    end

    local name = Bridge.GetIdentity(src)

    session = {
        src       = src,
        name      = name,
        startedAt = GetGameTimer(),
        score     = 0,
        time      = '00:00',
        targets   = NeoxMRPD.Config.Killhouse.TotalTargets or 16,
    }

    TriggerClientEvent('neox_killhouse:client:StartResponse', src, true)
    KillhouseBroadcastScreen()
end)

RegisterNetEvent('neox_killhouse:server:SyncUpdate', function(timeFormatted, score, totalTargets)
    local src = source
    if not session or session.src ~= src then return end

    session.time = tostring(timeFormatted or '00:00')
    session.score = tonumber(score) or 0
    session.targets = tonumber(totalTargets) or session.targets

    KillhouseBroadcastScreen()
end)

RegisterNetEvent('neox_killhouse:server:SaveScore', function(score, timeFormatted, seconds, weapon)
    local src = source
    if not session or session.src ~= src then return end

    KillhouseRecordScore(src, score, timeFormatted, seconds, weapon)
    KillhouseBroadcastScoreboard()
end)

RegisterNetEvent('neox_killhouse:server:StopSession',
    function(reason, timeFormatted, score, totalTargets)
        local src = source
        if not session or session.src ~= src then return end

        local finished = reason == 'finished'
        local operator = session.name

        session = nil

        if finished then
            KillhouseBroadcastScreen({
                type    = 'SYNC_RESULT',
                player  = operator,
                name    = operator,
                time    = tostring(timeFormatted or '00:00'),
                score   = tonumber(score) or 0,
                targets = tonumber(totalTargets) or 0,
                reason  = reason,
            })

            -- Leave the result up briefly, then fall back to idle.
            SetTimeout(8000, function()
                if not session then
                    KillhouseBroadcastScreen()
                end
            end)
        else
            KillhouseBroadcastScreen()
        end
    end)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
AddEventHandler('playerDropped', function()
    if session and session.src == source then
        session = nil
        KillhouseBroadcastScreen()
    end
end)

-- ---------------------------------------------------------
-- Exports
-- ---------------------------------------------------------
-- fxmanifest declares these under server_exports, which exposes global
-- functions by name — so they are globals rather than exports() calls.
function GetKillhouseScoreboard()
    return KillhouseLeaderboard()
end

function ResetKillhouseScoreboard()
    scores = {}
    NeoxMRPD.WriteData(DATA_FILE, scores)
    KillhouseBroadcastScoreboard()
    return true
end

RegisterCommand('killhouse_reset', function(source)
    if not Bridge.IsAdmin(source) then
        if source > 0 then
            Notify.toPlayer(source, 'Not allowed.', 'error')
        end
        return
    end

    scores = {}
    NeoxMRPD.WriteData(DATA_FILE, scores)
    KillhouseBroadcastScoreboard()

    print('^2[neox_mrpd_scripts]^7 kill house scoreboard reset')
end, false)

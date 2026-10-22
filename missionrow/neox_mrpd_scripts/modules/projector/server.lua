--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — BRIEFING PROJECTOR (server)
-- =========================================================
-- Holds the authoritative board for each projector so every screen in
-- the building shows the same thing, keeps the saved presets, and lets
-- one officer edit a projector at a time.
--
-- The board is whatever the editor sends; the server stores it verbatim
-- and only ever supplies the empty default.
-- =========================================================

if not NeoxMRPD.enabled('projector') then return end

local cfg = NeoxMRPD.Config.Projector

local BOARDS_FILE = 'projector_boards.json'
local PRESETS_FILE = 'projector_presets.json'

-- index -> { board = { strokes, texts, images }, url, mode }
local boards = NeoxMRPD.ReadData(BOARDS_FILE, {})

-- index -> { [presetName] = board }   (the UI reads this as a map)
local presets = NeoxMRPD.ReadData(PRESETS_FILE, {})

local claims = NeoxMRPD.NewClaims('projector')

function ProjectorExists(index)
    return type(index) == 'number' and cfg.Projectors and cfg.Projectors[index] ~= nil
end

function ProjectorBoard(index)
    local state = boards[index]

    if type(state) ~= 'table' then
        state = {
            mode  = 'board',
            url   = '',
            board = { strokes = {}, texts = {}, images = {} },
        }
        boards[index] = state
    end

    return state
end

function ProjectorPresets(index)
    local saved = presets[index]

    if type(saved) ~= 'table' then
        saved = {}
        presets[index] = saved
    end

    return saved
end

function ProjectorSendState(index, target)
    TriggerClientEvent('neox_projector:client:update', target or -1, index, ProjectorBoard(index))
end

function ProjectorSendPresets(index, target)
    TriggerClientEvent('neox_projector:client:updatePresets', target or -1,
        index, ProjectorPresets(index))
end

-- ---------------------------------------------------------
-- State
-- ---------------------------------------------------------
RegisterNetEvent('neox_projector:server:requestState', function(index)
    local src = source
    if not ProjectorExists(index) then return end
    if NeoxMRPD.Throttle(src, 'projector:state:' .. index, 400) then return end

    ProjectorSendState(index, src)
end)

RegisterNetEvent('neox_projector:server:sync', function(index, state)
    local src = source
    if not ProjectorExists(index) then return end
    if type(state) ~= 'table' then return end

    -- Only the officer holding the projector may change what it shows.
    if claims.ownerOf(index) ~= src then return end

    boards[index] = state
    NeoxMRPD.QueueWrite(BOARDS_FILE, boards)

    ProjectorSendState(index)
end)

-- ---------------------------------------------------------
-- Access
-- ---------------------------------------------------------
RegisterNetEvent('neox_projector:server:requestAccess', function(index)
    local src = source
    if not ProjectorExists(index) then return end
    if NeoxMRPD.Throttle(src, 'projector:access', 750) then return end

    if not Bridge.HasAccess(src, NeoxMRPD.accessOf('projector')) then
        TriggerClientEvent('neox_projector:client:accessResult', src, index, false, 'no_access')
        return
    end

    local granted = claims.claim(index, src)
    if not granted then
        TriggerClientEvent('neox_projector:client:accessResult', src, index, false, 'in_use')
        return
    end

    -- One projector per officer.
    for key, owner in pairs(claims.owners) do
        if owner == src and key ~= index then
            claims.release(key, src)
        end
    end

    TriggerClientEvent('neox_projector:client:accessResult', src, index, true)
end)

RegisterNetEvent('neox_projector:server:releaseAccess', function(index)
    local src = source
    if type(index) ~= 'number' then return end

    claims.release(index, src)
end)

-- ---------------------------------------------------------
-- Presets
-- ---------------------------------------------------------
RegisterNetEvent('neox_projector:server:getPresets', function(index)
    local src = source
    if not ProjectorExists(index) then return end
    if NeoxMRPD.Throttle(src, 'projector:presets', 400) then return end

    ProjectorSendPresets(index, src)
end)

RegisterNetEvent('neox_projector:server:savePreset', function(index, name, board)
    local src = source
    if not ProjectorExists(index) then return end
    if claims.ownerOf(index) ~= src then return end
    if type(board) ~= 'table' then return end

    name = tostring(name or ''):gsub('^%s*(.-)%s*$', '%1')
    if name == '' or #name > 48 then return end

    local saved = ProjectorPresets(index)

    -- Keep the preset list from being used as unbounded storage.
    local count = 0
    for _ in pairs(saved) do count = count + 1 end
    if count >= 32 and saved[name] == nil then return end

    saved[name] = board
    NeoxMRPD.QueueWrite(PRESETS_FILE, presets)

    ProjectorSendPresets(index)
end)

RegisterNetEvent('neox_projector:server:deletePreset', function(index, name)
    local src = source
    if not ProjectorExists(index) then return end
    if claims.ownerOf(index) ~= src then return end

    name = tostring(name or '')
    local saved = ProjectorPresets(index)

    if saved[name] == nil then return end

    saved[name] = nil
    NeoxMRPD.QueueWrite(PRESETS_FILE, presets)

    ProjectorSendPresets(index)
end)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
AddEventHandler('playerDropped', function()
    claims.releaseAll(source)
end)

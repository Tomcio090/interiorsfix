--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — CCTV (server)
-- =========================================================
-- Owns the monitor claims, the camera list (config cameras plus any
-- added in game with the setup tool), each officer's bookmarks, and the
-- shared incident log.
-- =========================================================

if not NeoxMRPD.enabled('cctv') then return end

local cfg = NeoxMRPD.Config.CCTV

local CAMERAS_FILE = 'cctv_cameras.json'
local BOOKMARKS_FILE = 'cctv_bookmarks.json'
local ALERTS_FILE = 'cctv_alerts.json'

-- Cameras placed in game with /cctv_setup, appended to the config list.
local customCameras = NeoxMRPD.ReadData(CAMERAS_FILE, {})

-- identifier -> { camId, camId, ... }
local bookmarks = NeoxMRPD.ReadData(BOOKMARKS_FILE, {})

-- newest first
local alerts = NeoxMRPD.ReadData(ALERTS_FILE, {})

local MAX_ALERTS = 50

local claims = NeoxMRPD.NewClaims('cctv')

-- ---------------------------------------------------------
-- Cameras
-- ---------------------------------------------------------
function CctvCameraList()
    local list = {}

    for _, camera in ipairs(cfg.Cameras or {}) do
        list[#list + 1] = camera
    end

    for _, camera in ipairs(customCameras) do
        list[#list + 1] = camera
    end

    return list
end

function CctvNextCameraId()
    local highest = 0

    for _, camera in ipairs(CctvCameraList()) do
        local id = tonumber(camera.id) or 0
        if id > highest then highest = id end
    end

    return highest + 1
end

function CctvBroadcastCameras(target)
    TriggerClientEvent('neox_mrpd_cctv:client:syncCameras', target or -1, CctvCameraList())
end

-- ---------------------------------------------------------
-- Bookmarks
-- ---------------------------------------------------------
-- NOTE: sent as a flat array of camera ids. The bookmark rendering lives
-- in the obfuscated CCTV front-end and its exact expected shape could not
-- be confirmed, so if stars do not light up, try a map of id -> true.
function CctvBookmarksFor(src)
    local _, identifier = Bridge.GetIdentity(src)
    return identifier, bookmarks[identifier] or {}
end

function CctvSendBookmarks(src)
    local _, list = CctvBookmarksFor(src)
    TriggerClientEvent('neox_mrpd_cctv:client:syncBookmarks', src, list)
end

-- ---------------------------------------------------------
-- Alerts
-- ---------------------------------------------------------
function CctvSendAlerts(src)
    TriggerClientEvent('neox_mrpd_cctv:client:syncAlerts', src, alerts)
end

-- ---------------------------------------------------------
-- Access
-- ---------------------------------------------------------
RegisterNetEvent('neox_mrpd_cctv:server:requestAccess', function(monitorId)
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:access', 750) then return end

    if type(monitorId) ~= 'number' then return end

    -- The monitor layout is built in modules/cctv/client.lua, so the server
    -- normally has no list to check against and the id is just a lock key.
    -- A config that overrides Config.CCTV.Monitors is validated properly.
    local monitors = cfg.Monitors
    if monitors and monitors[monitorId] == nil then return end

    if not Bridge.HasAccess(src, NeoxMRPD.accessOf('cctv')) then
        TriggerClientEvent('neox_mrpd_cctv:client:accessResult', src, monitorId, false, 'no_access')
        return
    end

    local granted = claims.claim(monitorId, src)
    if not granted then
        TriggerClientEvent('neox_mrpd_cctv:client:accessResult', src, monitorId, false, 'in_use')
        return
    end

    -- One monitor per officer.
    for key, owner in pairs(claims.owners) do
        if owner == src and key ~= monitorId then
            claims.release(key, src)
        end
    end

    TriggerClientEvent('neox_mrpd_cctv:client:accessResult', src, monitorId, true)
end)

RegisterNetEvent('neox_mrpd_cctv:server:releaseAccess', function(monitorId)
    local src = source
    if type(monitorId) ~= 'number' then return end

    claims.release(monitorId, src)
end)

-- ---------------------------------------------------------
-- UI data
-- ---------------------------------------------------------
RegisterNetEvent('neox_mrpd_cctv:server:requestCameras', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:cameras', 500) then return end

    CctvBroadcastCameras(src)
end)

RegisterNetEvent('neox_mrpd_cctv:server:requestBookmarks', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:bookmarks', 500) then return end

    CctvSendBookmarks(src)
end)

RegisterNetEvent('neox_mrpd_cctv:server:requestAlerts', function()
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:alerts', 500) then return end

    CctvSendAlerts(src)
end)

RegisterNetEvent('neox_mrpd_cctv:server:toggleBookmark', function(camId)
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:bookmark', 250) then return end

    camId = tonumber(camId)
    if not camId then return end

    if not NeoxMRPD.Allowed(src, 'cctv') then return end

    local identifier, list = CctvBookmarksFor(src)
    if identifier == 'Unknown' then return end

    local removed = false
    for index, existing in ipairs(list) do
        if tonumber(existing) == camId then
            table.remove(list, index)
            removed = true
            break
        end
    end

    if not removed then
        list[#list + 1] = camId
    end

    bookmarks[identifier] = list
    NeoxMRPD.QueueWrite(BOOKMARKS_FILE, bookmarks)

    CctvSendBookmarks(src)
end)

-- The UI decides what an incident looks like, so its fields are passed
-- through and only the reporter and timestamp are added here.
RegisterNetEvent('neox_mrpd_cctv:server:reportIncident', function(data)
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:incident', 3000) then return end

    if not NeoxMRPD.Allowed(src, 'cctv') then return end

    local alert = {}

    -- Only scalars are copied, so the UI cannot push nested data in.
    if type(data) == 'table' then
        for key, value in pairs(data) do
            local valueType = type(value)
            if valueType == 'string' or valueType == 'number' or valueType == 'boolean' then
                alert[key] = value
            end
        end
    end

    local name = Bridge.GetIdentity(src)

    local newestId = 0
    if alerts[1] then
        newestId = tonumber(alerts[1].id) or 0
    end

    alert.id = newestId + 1
    alert.officer = name
    alert.at = os.time()
    alert.time = os.date('%H:%M')

    table.insert(alerts, 1, alert)
    while #alerts > MAX_ALERTS do
        table.remove(alerts)
    end

    NeoxMRPD.QueueWrite(ALERTS_FILE, alerts)

    TriggerClientEvent('neox_mrpd_cctv:client:addAlert', -1, alert)
end)

-- ---------------------------------------------------------
-- Camera setup tool
-- ---------------------------------------------------------
RegisterNetEvent('neox_mrpd_cctv:server:saveCustomCamera', function(camera)
    local src = source
    if NeoxMRPD.Throttle(src, 'cctv:savecam', 1000) then return end

    if not Bridge.IsAdmin(src) then
        Notify.toPlayer(src, 'Not allowed.', 'error')
        return
    end

    if type(camera) ~= 'table' or not camera.camCoords then return end

    local entry = {
        id        = CctvNextCameraId(),
        label     = tostring(camera.label or 'NEW CAM'),
        name      = tostring(camera.name or 'Unknown'),
        district  = tostring(camera.district or 'General'),
        camCoords = camera.camCoords,
        camRot    = camera.camRot,
        camFov    = tonumber(camera.camFov) or 60.0,
        custom    = true,
    }

    customCameras[#customCameras + 1] = entry
    NeoxMRPD.WriteData(CAMERAS_FILE, customCameras)

    CctvBroadcastCameras()

    Notify.toPlayer(src, ('Camera %s saved (id %d).'):format(entry.label, entry.id), 'success')
    print(('^2[neox_mrpd_scripts]^7 CCTV camera %d saved by %s'):format(entry.id, GetPlayerName(src)))
end)

RegisterCommand('cctv_setup', function(source)
    if source == 0 then
        print('^3[neox_mrpd_scripts] /cctv_setup must be run in game.^7')
        return
    end

    if not Bridge.IsAdmin(source) then
        Notify.toPlayer(source, 'Not allowed.', 'error')
        return
    end

    TriggerClientEvent('neox_mrpd_cctv:client:startSetup', source)
end, false)

RegisterCommand('cctv_cameras_reset', function(source)
    if not Bridge.IsAdmin(source) then
        if source > 0 then
            Notify.toPlayer(source, 'Not allowed.', 'error')
        end
        return
    end

    customCameras = {}
    NeoxMRPD.WriteData(CAMERAS_FILE, customCameras)
    CctvBroadcastCameras()

    print('^2[neox_mrpd_scripts]^7 custom CCTV cameras cleared')
end, false)

-- ---------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------
AddEventHandler('playerDropped', function()
    claims.releaseAll(source)
end)

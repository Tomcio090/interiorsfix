-- IPL Manager Server Script
local serverIPLStates = {}

-- Initialize server IPL states based on config
local function initializeServerIPLStates()
    for i, iplData in ipairs(Config.IPLs) do
        serverIPLStates[iplData.ipl] = {
            name = iplData.name,
            description = iplData.description,
            loaded = iplData.enabled, -- Use config default
            enabled = iplData.enabled
        }
    end
    
    print("^2[IPL MANAGER] Server initialized with " .. #Config.IPLs .. " IPLs^0")
end

-- Send current IPL states to a specific player
local function sendIPLStatesToPlayer(playerId)
    TriggerClientEvent('ipl_manager:syncStates', playerId, serverIPLStates)
end

-- Broadcast IPL state change to all players
local function broadcastIPLStateChange(iplName, loaded)
    if serverIPLStates[iplName] then
        serverIPLStates[iplName].loaded = loaded
        TriggerClientEvent('ipl_manager:stateChanged', -1, iplName, loaded)
        
        local status = loaded and "loaded" or "unloaded"
        print("^3[IPL MANAGER] Server: " .. serverIPLStates[iplName].name .. " " .. status .. " for all players^0")
    end
end

-- Handle IPL load request from client
RegisterNetEvent('ipl_manager:requestLoad', function(iplName)
    local playerId = source
    
    if not serverIPLStates[iplName] then
        print("^1[IPL MANAGER] Invalid IPL request from player " .. playerId .. ": " .. iplName .. "^0")
        return
    end
    
    if serverIPLStates[iplName].loaded then
        print("^3[IPL MANAGER] IPL already loaded: " .. iplName .. "^0")
        return
    end
    
    broadcastIPLStateChange(iplName, true)
end)

-- Handle IPL unload request from client
RegisterNetEvent('ipl_manager:requestUnload', function(iplName)
    local playerId = source
    
    if not serverIPLStates[iplName] then
        print("^1[IPL MANAGER] Invalid IPL request from player " .. playerId .. ": " .. iplName .. "^0")
        return
    end
    
    if not serverIPLStates[iplName].loaded then
        print("^3[IPL MANAGER] IPL already unloaded: " .. iplName .. "^0")
        return
    end
    
    broadcastIPLStateChange(iplName, false)
end)

-- Handle IPL toggle request from client
RegisterNetEvent('ipl_manager:requestToggle', function(iplName)
    local playerId = source
    
    if not serverIPLStates[iplName] then
        print("^1[IPL MANAGER] Invalid IPL request from player " .. playerId .. ": " .. iplName .. "^0")
        return
    end
    
    local newState = not serverIPLStates[iplName].loaded
    broadcastIPLStateChange(iplName, newState)
end)

-- Handle load all enabled request
RegisterNetEvent('ipl_manager:requestLoadAllEnabled', function()
    local playerId = source
    
    for iplName, iplData in pairs(serverIPLStates) do
        if iplData.enabled and not iplData.loaded then
            broadcastIPLStateChange(iplName, true)
        end
    end
end)

-- Handle unload all request
RegisterNetEvent('ipl_manager:requestUnloadAll', function()
    local playerId = source
    
    for iplName, iplData in pairs(serverIPLStates) do
        if iplData.loaded then
            broadcastIPLStateChange(iplName, false)
        end
    end
end)

-- Send current states to player when they join
RegisterNetEvent('ipl_manager:requestSync', function()
    local playerId = source
    sendIPLStatesToPlayer(playerId)
end)

-- Get current server IPL states (for exports)
local function getServerIPLStates()
    return serverIPLStates
end

-- Get specific IPL state (for exports)
local function getServerIPLState(iplName)
    return serverIPLStates[iplName] and serverIPLStates[iplName].loaded or false
end

-- Initialize on resource start
CreateThread(function()
    initializeServerIPLStates()
end)

-- Export functions for other resources
exports('getServerIPLStates', getServerIPLStates)
exports('getServerIPLState', getServerIPLState)
exports('loadIPLServer', function(iplName)
    if serverIPLStates[iplName] and not serverIPLStates[iplName].loaded then
        broadcastIPLStateChange(iplName, true)
        return true
    end
    return false
end)
exports('unloadIPLServer', function(iplName)
    if serverIPLStates[iplName] and serverIPLStates[iplName].loaded then
        broadcastIPLStateChange(iplName, false)
        return true
    end
    return false
end) 
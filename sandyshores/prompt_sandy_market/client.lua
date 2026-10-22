CreateThread(function()
    local oldinterior = GetInteriorAtCoordsWithType(1972.74707, 3818.12744, 32.02555, 'v_trailer')
    DisableInterior(oldinterior, true)
    UnpinInterior(oldinterior)
end)

-- IPL Manager Client Script
-- ox_lib jest OPCJONALNY (fallback to komendy) — sprawdzamy stan zasobu
-- przy każdym użyciu, a nie tylko przy starcie (odporność na kolejność startu).
local function isOxLibAvailable()
    return GetResourceState('ox_lib') == 'started'
end
local loadedIPLs = {}

-- Initialize IPL states based on config
local function initializeIPLStates()
    for i, iplData in ipairs(Config.IPLs) do
        loadedIPLs[iplData.ipl] = {
            name = iplData.name,
            description = iplData.description,
            loaded = false,
            enabled = iplData.enabled
        }
    end
end

-- Actually load an IPL (called from server events)
local function applyIPLLoad(iplName)
    if not loadedIPLs[iplName] then
        return false
    end
    
    if not loadedIPLs[iplName].loaded then
        RequestIpl(iplName)
        loadedIPLs[iplName].loaded = true
        print("^2[IPL MANAGER] Loaded: " .. loadedIPLs[iplName].name .. "^0")
    end
    
    return true
end

-- Actually unload an IPL (called from server events)
local function applyIPLUnload(iplName)
    if not loadedIPLs[iplName] then
        return false
    end
    
    if loadedIPLs[iplName].loaded then
        RemoveIpl(iplName)
        loadedIPLs[iplName].loaded = false
        print("^1[IPL MANAGER] Unloaded: " .. loadedIPLs[iplName].name .. "^0")
    end
    
    return true
end

-- Request IPL load from server
local function requestLoadIPL(iplName)
    TriggerServerEvent('ipl_manager:requestLoad', iplName)
end

-- Request IPL unload from server
local function requestUnloadIPL(iplName)
    TriggerServerEvent('ipl_manager:requestUnload', iplName)
end

-- Request IPL toggle from server
local function requestToggleIPL(iplName)
    TriggerServerEvent('ipl_manager:requestToggle', iplName)
end

-- Create ox_lib menu
local function createOxLibMenu()
    if not isOxLibAvailable() then
        return
    end
    
    local lib = exports.ox_lib
    local options = {}
    
    -- Add toggle options for each IPL (kolejność jak w configu — stabilna)
    for _, iplData in ipairs(Config.IPLs) do
        local iplName = iplData.ipl
        local state = loadedIPLs[iplName]
        if state then
            table.insert(options, {
                title = state.name,
                description = state.description,
                icon = state.loaded and 'fa-solid fa-eye' or 'fa-solid fa-eye-slash',
                iconColor = state.loaded and 'green' or 'red',
                onSelect = function()
                    requestToggleIPL(iplName)
                    -- Refresh the menu after toggling
                    Wait(100)
                    createOxLibMenu()
                end
            })
        end
    end
    
    -- Add utility options
    table.insert(options, {
        title = "Load All Enabled",
        description = "Load all IPLs marked as enabled in config",
        icon = 'fa-solid fa-download',
        iconColor = 'blue',
        onSelect = function()
            TriggerServerEvent('ipl_manager:requestLoadAllEnabled')
            Wait(100)
            createOxLibMenu()
        end
    })
    
    table.insert(options, {
        title = "Unload All",
        description = "Unload all currently loaded IPLs",
        icon = 'fa-solid fa-upload',
        iconColor = 'orange',
        onSelect = function()
            TriggerServerEvent('ipl_manager:requestUnloadAll')
            Wait(100)
            createOxLibMenu()
        end
    })
    
    -- Eksporty ox_lib wywołujemy składnią z kropką (zgodnie z API ox_lib;
    -- wywołanie przez ":" mogłoby przekazać tabelę proxy jako pierwszy argument).
    lib.registerContext({
        id = 'ipl_manager_menu',
        title = Config.Menu.title,
        menu = Config.Menu.subtitle,
        position = Config.Menu.position,
        options = options
    })
    
    lib.showContext('ipl_manager_menu')
end

-- Fallback menu using basic chat commands
local function showFallbackMenu()
    print("^6=== Sandy Market IPL Manager ===^0")
    print("^3Available Commands:^0")
    print("^2/pm_ipl load <name>^0 - Load specific IPL")
    print("^2/pm_ipl unload <name>^0 - Unload specific IPL")
    print("^2/pm_ipl toggle <name>^0 - Toggle IPL state")
    print("^2/pm_ipl list^0 - List all IPLs and their states")
    print("^2/pm_ipl loadall^0 - Load all enabled IPLs")
    print("^2/pm_ipl unloadall^0 - Unload all IPLs")
    print("^6===============================^0")
end

-- List all IPLs and their states
local function listIPLs()
    print("^6=== IPL Status ===^0")
    for _, iplData in ipairs(Config.IPLs) do
        local state = loadedIPLs[iplData.ipl]
        if state then
            local status = state.loaded and "^2LOADED^0" or "^1UNLOADED^0"
            local enabled = state.enabled and "(Enabled)" or "(Disabled)"
            print(string.format("^3%s^0: %s %s - %s", state.name, status, enabled, state.description))
        end
    end
    print("^6==================^0")
end

-- Handle server state synchronization
RegisterNetEvent('ipl_manager:syncStates', function(serverStates)
    for iplName, serverData in pairs(serverStates) do
        if loadedIPLs[iplName] then
            if serverData.loaded and not loadedIPLs[iplName].loaded then
                applyIPLLoad(iplName)
            elseif not serverData.loaded and loadedIPLs[iplName].loaded then
                applyIPLUnload(iplName)
            end
        end
    end
    print("^2[IPL MANAGER] Synchronized with server state^0")
end)

-- Handle individual IPL state changes from server
RegisterNetEvent('ipl_manager:stateChanged', function(iplName, loaded)
    if loaded then
        applyIPLLoad(iplName)
    else
        applyIPLUnload(iplName)
    end
end)

-- Initialize on resource start
CreateThread(function()
    initializeIPLStates()
    
    -- Wait for world to load, then request sync from server
    Wait(2000)
    TriggerServerEvent('ipl_manager:requestSync')
end)

-- ── Wspólna permisja ACE dla komend pakietu Prompt Sandy Shores ─────
-- Wszystkie komendy z tego repo sprawdzają JEDEN obiekt ACE:
-- command.sandyshores (ANALIZA.md, rozdz. 11). Konfiguracja serwera:
--   add_ace group.admin command.sandyshores allow
--   add_principal identifier.license:XXXX group.admin
-- Na kliencie poprawną natywką jest IsAceAllowed (IsPlayerAceAllowed to API
-- serwerowe). Komendy rejestrujemy z restricted=false i sprawdzamy ręcznie,
-- bo wbudowany flag FiveM patrzy na osobne "command.<nazwa_komendy>".
local SANDY_COMMAND_ACE = "command.sandyshores"

local function canUseSandyCommand()
    if IsAceAllowed(SANDY_COMMAND_ACE) then
        return true
    end
    print("^1[SANDY] Missing ACE permission: " .. SANDY_COMMAND_ACE .. "^0")
    return false
end

-- Register main command
RegisterCommand(Config.Command.name, function(source, args, rawCommand)
    if not canUseSandyCommand() then
        return
    end
    if isOxLibAvailable() then
        createOxLibMenu()
    else
        showFallbackMenu()
    end
end, false)

-- Register fallback IPL commands
RegisterCommand("pm_ipl", function(source, args, rawCommand)
    if not canUseSandyCommand() then
        return
    end
    if #args == 0 then
        showFallbackMenu()
        return
    end
    
    local action = args[1]:lower()
    
    if action == "list" then
        listIPLs()
    elseif action == "loadall" then
        TriggerServerEvent('ipl_manager:requestLoadAllEnabled')
    elseif action == "unloadall" then
        TriggerServerEvent('ipl_manager:requestUnloadAll')
    elseif action == "load" or action == "unload" or action == "toggle" then
        if #args < 2 then
            print("^1[ERROR] Usage: /pm_ipl " .. action .. " <ipl_name>^0")
            return
        end
        
        local iplName = args[2]
        local found = false
        
        -- Find IPL by partial name match
        for ipl, data in pairs(loadedIPLs) do
            if ipl:find(iplName) or data.name:lower():find(iplName:lower()) then
                if action == "load" then
                    requestLoadIPL(ipl)
                elseif action == "unload" then
                    requestUnloadIPL(ipl)
                elseif action == "toggle" then
                    requestToggleIPL(ipl)
                end
                found = true
                break
            end
        end
        
        if not found then
            print("^1[ERROR] IPL not found: " .. iplName .. "^0")
            print("^3Use '/pm_ipl list' to see available IPLs^0")
        end
    else
        print("^1[ERROR] Unknown action: " .. action .. "^0")
        showFallbackMenu()
    end
end, false)

-- Export functions for other resources
exports('loadIPL', requestLoadIPL)
exports('unloadIPL', requestUnloadIPL)
exports('toggleIPL', requestToggleIPL)
exports('getIPLState', function(iplName)
    return loadedIPLs[iplName] and loadedIPLs[iplName].loaded or false
end)
exports('getAllIPLStates', function()
    return loadedIPLs
end) 
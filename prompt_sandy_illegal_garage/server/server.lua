---------------------------------------------------------------------
-- PROMPT SANDY ILLEGAL GARAGE — Server
-- Stan propów w GlobalState:
--   ilegal_carwash        = { [propName] = true/false }  (otwarty/zamknięty)
--   ilegal_carwash_busy   = { [propName] = true/false }  (animacja w toku)
--   ilegal_carwash_locks  = { [propName] = true/false }  (zamek rolety, tylko AutoOpen)
-- Uprawnienia: ServerHasJobAccess (joby frameworka / ACE / wyłączone).
---------------------------------------------------------------------

-- Czy source eventu wygląda na prawdziwego gracza?
function validateSource(playerSource)
    return type(playerSource) == "number" and playerSource > 0
end

-- Tylko JEDEN prop jest traktowany jako roleta AutoOpen (po nazwie modelu)
function isGarageRollup(propName)
    return type(propName) == "string" and propName == "prompt_sandy_is_garage_rollup"
end

-- ── Wykrywanie frameworka (cache) ───────────────────────────────────

local detectedFramework = nil   -- 'qbox' | 'qbcore' | 'esx' | 'standalone'
local QBCore = nil              -- obiekt core qb-core (jeśli dotyczy)
local ESX = nil                 -- shared object ESX (jeśli dotyczy)
local standaloneWarningShown = false

local function getFramework()
    if detectedFramework then
        return detectedFramework
    end

    local framework = (Config.Permissions and Config.Permissions.framework) or "auto"

    if framework ~= "auto" then
        detectedFramework = (framework == "qb") and "qbcore" or framework
    else
        if GetResourceState("qbx_core") == "started" then
            detectedFramework = "qbox"
        elseif GetResourceState("qb-core") == "started" then
            detectedFramework = "qbcore"
        elseif GetResourceState("es_extended") == "started" then
            detectedFramework = "esx"
        else
            -- UWAGA (jak w oryginale): 'standalone' NIE jest zapisywane
            -- do cache — każde wywołanie wykrywa framework od nowa.
            return "standalone"
        end
    end

    if detectedFramework == "qbcore" then
        QBCore = exports["qb-core"]:GetCoreObject()
    elseif detectedFramework == "esx" then
        ESX = exports.es_extended:getSharedObject()
    end

    return detectedFramework
end

-- Nazwa joba gracza małymi literami albo nil
local function getPlayerJobName(playerSource)
    local framework = getFramework()

    if framework == "qbcore" then
        local player = QBCore and QBCore.Functions.GetPlayer(playerSource)
        if not player then return nil end

        local job = player.PlayerData.job
        -- Rekonstrukcja: zdekompilowany kod zwracał w tym miejscu
        -- potencjalnie całą tabelę job zamiast nazwy/nil.
        if job and job.name then
            return job.name:lower()
        end
        return nil
    elseif framework == "qbox" then
        local player = exports.qbx_core:GetPlayer(playerSource)
        if not player then return nil end

        local job = player.PlayerData.job
        if job and job.name then
            return job.name:lower()
        end
        return nil
    elseif framework == "esx" then
        local player = ESX and ESX.GetPlayerFromId(playerSource)
        if not player then return nil end

        if player.job and player.job.name then
            return player.job.name:lower()
        end
        return nil
    end

    -- 'standalone' oraz nieznane wartości framework
    return nil
end

-- Szuka konfiguracji propa po nazwie modelu (Config.Props.*.name)
local function getPropConfigByName(propName)
    if type(propName) ~= "string" then return nil end

    for _, prop in pairs(Config.Props) do
        if prop.name == propName then
            return prop
        end
    end
    return nil
end

-- ── Uprawnienia (serwer) ────────────────────────────────────────────

function ServerHasJobAccess(playerSource, propName)
    -- System uprawnień wyłączony -> każdy ma dostęp
    if not (Config.Permissions and Config.Permissions.enabled) then
        return true
    end

    local propConfig = getPropConfigByName(propName)
    if not propConfig then
        return true
    end

    -- ACE: jeśli włączone, a prop MA ustawione acePermission, decyduje ACE.
    -- Jeśli prop NIE ma acePermission, kod spada dalej do sprawdzenia joba.
    if Config.Permissions.useAce and propConfig.acePermission then
        return IsPlayerAceAllowed(playerSource, propConfig.acePermission)
    end

    -- Brak restrykcji joba na tym propie -> dostęp
    if not propConfig.allowedJobs or #propConfig.allowedJobs == 0 then
        return true
    end

    -- Są restrykcje, ale nie ma frameworka, który mógłby dać joba:
    -- fail-closed (odmowa) + jednorazowe ostrzeżenie w konsoli.
    if getFramework() == "standalone" then
        if not standaloneWarningShown then
            standaloneWarningShown = true
            print(("^1[%s] Config.Permissions job restrictions are enabled but no framework (qbx_core/qb-core/es_extended) is running — denying restricted interactions. Use ACE permissions (Config.Permissions.useAce) on standalone servers.^0"):format(GetCurrentResourceName()))
        end
        return false
    end

    local jobName = getPlayerJobName(playerSource)
    if not jobName then
        return false
    end

    for _, allowedJob in ipairs(propConfig.allowedJobs) do
        if type(allowedJob) == "string" and allowedJob:lower() == jobName then
            return true
        end
    end

    return false
end

-- ── Inicjalizacja stanu ─────────────────────────────────────────────

CreateThread(function()
    GlobalState.ilegal_carwash = {}
    GlobalState.ilegal_carwash_busy = {}

    if Config.AutoOpen then
        local locks = {}
        for _, prop in pairs(Config.Props) do
            if isGarageRollup(prop.name) then
                locks[prop.name] = (Config.AutoOpenDefaultLocked ~= false)
            end
        end
        GlobalState.ilegal_carwash_locks = locks
    end
end)

-- Ustawia stan propa i emituje lokalny event serwerowy (do debug/API)
function updateGlobalPropState(propName, state)
    local states = GlobalState.ilegal_carwash or {}
    states[propName] = state
    GlobalState.ilegal_carwash = states

    TriggerEvent("prompt_sandy_illegal_garage:liftStateChanged", propName, state)
end

exports("getLiftState", function(propName)
    local states = GlobalState.ilegal_carwash or {}
    return states[propName]
end)

exports("isLiftBusy", function(propName)
    local busyStates = GlobalState.ilegal_carwash_busy or {}
    return busyStates[propName] or false
end)

-- ── Zajętość strefy rolety (którzy gracze są w środku) ─────────────
-- doorOccupants[propName] = { [serverId] = true, ... }

local doorOccupants = {}

local function getOccupantCount(propName)
    local occupants = doorOccupants[propName]
    if not occupants then
        return 0
    end

    local count = 0
    for _ in pairs(occupants) do
        count = count + 1
    end
    return count
end

-- ── Busy + watchdog ─────────────────────────────────────────────────
-- busyTokens[propName]       = token bieżącej animacji (nil = wolny)
-- busyTokenCounters[propName] = rosnący licznik tokenów (nigdy nie kasowany,
--   żeby stary SetTimeout nie trafił w token nowej animacji)

local busyTokens = {}
local busyTokenCounters = {}

local function setBusy(propName, busy)
    if busy then
        busyTokenCounters[propName] = (busyTokenCounters[propName] or 0) + 1
        busyTokens[propName] = busyTokenCounters[propName]
    else
        busyTokens[propName] = nil
    end

    local busyStates = GlobalState.ilegal_carwash_busy or {}
    busyStates[propName] = busy and true or false
    GlobalState.ilegal_carwash_busy = busyStates

    return busyTokens[propName]
end

exports("isDoorLocked", function(propName)
    local locks = GlobalState.ilegal_carwash_locks or {}
    return locks[propName] or false
end)

local function notifyPlayer(playerSource, description, notifyType)
    TriggerClientEvent("ox_lib:notify", playerSource, {
        description = description,
        type = notifyType or "error",
        duration = 3000
    })
end

-- ── Walidacja pozycji gracza względem stref interakcji ──────────────
-- Strefy w configu są boxami (coords = środek, size = pełne wymiary,
-- rotation obecnie wszędzie 0.0). Serwer sprawdza rozszerzony box:
-- tolerancja pokrywa lag synchronizacji pozycji i interakcję targetem
-- spoza samego boxa, a nadal odrzuca eventy z drugiego końca mapy.

local function isPlayerNearZone(playerSource, zone, tolerance)
    if not zone or not zone.coords then return false end

    local ped = GetPlayerPed(playerSource)
    if not ped or ped == 0 then return false end

    local pos = GetEntityCoords(ped)
    if not pos then return false end

    local size = zone.size
    local halfX = (size and size.x or 2.0) / 2.0
    local halfY = (size and size.y or 2.0) / 2.0
    local halfZ = (size and size.z or 2.0) / 2.0
    tolerance = tolerance or 7.5

    return math.abs(pos.x - zone.coords.x) <= halfX + tolerance
        and math.abs(pos.y - zone.coords.y) <= halfY + tolerance
        and math.abs(pos.z - zone.coords.z) <= halfZ + tolerance
end

local function isPlayerNearProp(playerSource, propConfig, tolerance)
    if not propConfig then return false end

    if isPlayerNearZone(playerSource, propConfig.interactionZone, tolerance) then
        return true
    end

    if propConfig.extraZones then
        for _, zone in ipairs(propConfig.extraZones) do
            if isPlayerNearZone(playerSource, zone, tolerance) then
                return true
            end
        end
    end

    return false
end

-- ── Start animacji propa (jedyna droga zmiany stanu) ────────────────
-- pendingPlayerAnims[serverId] = { propName, dict, anim, token, synced }
-- lastZoneExits[serverId]      = { propName, at } (do walidacji requestAutoClose)

local pendingPlayerAnims = {}
local lastZoneExits = {}

local beginPropAnimation, scheduleBusyClear

local function getPropAnimDuration(propConfig)
    local duration = propConfig.animations and propConfig.animations.duration
    if type(duration) ~= "number" or duration <= 0 then
        duration = 5000
    end
    return math.floor(duration)
end

-- Buduje dane animacji gracza WYŁĄCZNIE z configa (nigdy z danych klienta).
-- position/heading mogą być pojedynczą wartością albo tabelą per nazwa
-- animacji (engine_full: domkrat_up/domkrat_down).
local function resolvePlayerAnimation(propConfig, state)
    local playerAnim = propConfig.playerAnimation
    if not playerAnim then return nil end

    local animName = state and playerAnim.name or (playerAnim.closeName or playerAnim.name)

    local position = playerAnim.position
    if type(position) == "table" and animName and position[animName] then
        position = position[animName]
    end

    local heading = playerAnim.heading
    if type(heading) == "table" and animName and heading[animName] ~= nil then
        heading = heading[animName]
    end

    if type(playerAnim.dict) ~= "string" or type(animName) ~= "string"
        or not position or position.x == nil or position.y == nil or position.z == nil
        or type(heading) ~= "number" then
        return nil
    end

    return {
        dict = playerAnim.dict,
        anim = animName,
        position = position,
        heading = heading,
        propName = propConfig.name,
        state = state
    }
end

-- Planuje zwolnienie busy po zakończeniu animacji. Token chroni przed
-- zwolnieniem busy nowszej animacji przez stary timer. Po zwolnieniu
-- busy rolety AutoOpen ponawiamy próbę auto-otwarcia dla oczekujących.
scheduleBusyClear = function(propName, delayMs, token)
    token = token or busyTokens[propName]
    if not token then return end

    SetTimeout(delayMs, function()
        if busyTokens[propName] ~= token then return end

        setBusy(propName, false)

        -- Failsafe mógł zadziałać przed powrotem callbacka animacji gracza:
        -- usuń osierocony wpis whitelist, żeby nie dało się go użyć później.
        for pendingSource, pending in pairs(pendingPlayerAnims) do
            if pending.propName == propName and pending.token == token then
                pendingPlayerAnims[pendingSource] = nil
            end
        end

        if Config.AutoOpen and isGarageRollup(propName) then
            local locks = GlobalState.ilegal_carwash_locks or {}
            local states = GlobalState.ilegal_carwash or {}

            if not locks[propName] and not states[propName] and getOccupantCount(propName) > 0 then
                beginPropAnimation(propName, true, nil)
            end
        end
    end)
end

-- Ustawia busy, (opcjonalnie) gra animację gracza u inicjatora i dopiero
-- zmienia stan w GlobalState — wszyscy klienci (też inicjator) animują
-- propa z handlera state-baga. Watchdog zwalnia busy nawet, gdy inicjator
-- wyjdzie z serwera albo callback animacji gracza nigdy nie wróci.
beginPropAnimation = function(propName, state, playerSource)
    local propConfig = getPropConfigByName(propName)
    if not propConfig then return false end
    if busyTokens[propName] then return false end

    local duration = getPropAnimDuration(propConfig)
    local token = setBusy(propName, true)

    local function applyState()
        updateGlobalPropState(propName, state)
        scheduleBusyClear(propName, duration + 1000, token)
    end

    if playerSource and Config.EnablePlayerAnimations ~= false and propConfig.playerAnimation then
        local animData = resolvePlayerAnimation(propConfig, state)
        if not animData then
            print("Error: Datos incompletos para la solicitud de animación")
            setBusy(propName, false)
            return false
        end

        -- Jeden gracz może mieć naraz tylko jeden pending callback;
        -- nadpisanie wpisu odebrałoby poprzedniej animacji whitelistę sync.
        if pendingPlayerAnims[playerSource] then
            setBusy(propName, false)
            return false
        end

        pendingPlayerAnims[playerSource] = {
            propName = propName,
            dict = animData.dict,
            anim = animData.anim,
            token = token,
            synced = false
        }

        -- Failsafe: dojście gracza na pozycję (<=5 s) + animacja + margines
        scheduleBusyClear(propName, 8000 + duration + 2000, token)

        lib.callback("ilegal_anims:playPlayerAnimation", playerSource, function(success)
            local pending = pendingPlayerAnims[playerSource]
            if pending and pending.token == token then
                pendingPlayerAnims[playerSource] = nil
            end

            -- Timeout/watchdog zdążył zwolnić albo ruszyła nowsza animacja
            if busyTokens[propName] ~= token then return end

            if not success then
                print("Error: La animación del jugador falló")
                setBusy(propName, false)
                return
            end

            applyState()
        end, animData)
    else
        applyState()
    end

    return true
end

-- ── Eventy od klienta ───────────────────────────────────────────────
-- Serwer jest autorytatywny: klient może jedynie POPROSIĆ o zmianę stanu
-- (requestToggleProp / eventy AutoOpen). Dawne eventy-klient-decycjne
-- (updatePropState, setPropBusy, requestPlayerAnimation, initializeState)
-- zostały usunięte — stan początkowy ustawia wątek init, busy zwalnia
-- wyłącznie watchdog, a dane animacji gracza pochodzą z configa.

-- Jedyny event ręcznego przełączania propa.
-- desiredState: boolean albo nil (= przełącz na przeciwny).
RegisterNetEvent("ilegal_anims:requestToggleProp", function(propName, desiredState)
    local playerSource = source
    if not validateSource(playerSource) then return end
    if desiredState ~= nil and type(desiredState) ~= "boolean" then return end

    local propConfig = getPropConfigByName(propName)
    if not propConfig then return end

    -- Rolęta przy włączonym AutoOpen obsługuje wyłącznie przepływ
    -- zamek + strefy; ręczne open/close omijałoby zamek.
    if Config.AutoOpen and isGarageRollup(propName) then return end

    if not isPlayerNearProp(playerSource, propConfig, 7.5) then return end

    if not ServerHasJobAccess(playerSource, propName) then
        notifyPlayer(playerSource,
            (Config.Permissions and Config.Permissions.noAccessMessage) or "You don't have access to this",
            "error")
        return
    end

    local busyStates = GlobalState.ilegal_carwash_busy or {}
    if busyStates[propName] then return end

    local states = GlobalState.ilegal_carwash or {}
    local currentState = states[propName] == true
    local targetState = desiredState
    if targetState == nil then
        targetState = not currentState
    end
    if targetState == currentState then return end

    beginPropAnimation(propName, targetState, playerSource)
end)

-- Rozgłasza animację gracza do innych klientów — tylko w ramach animacji
-- rozpoczętej przez serwer dla tego gracza (whitelist z pendingPlayerAnims)
-- i tylko raz. Dowolne dict/anim od klienta są ignorowane.
RegisterNetEvent("ilegal_anims:syncAnimation", function(animDict, animName, duration)
    local playerSource = source

    if not validateSource(playerSource) then
        print("Error: Fuente inválida para la sincronización de animación")
        return
    end

    if type(animDict) ~= "string" or type(animName) ~= "string" then
        print("Error: Datos incompletos para la sincronización de animación")
        return
    end

    local pending = pendingPlayerAnims[playerSource]
    if not pending or pending.synced or pending.dict ~= animDict or pending.anim ~= animName
        or busyTokens[pending.propName] ~= pending.token then
        return
    end
    pending.synced = true

    TriggerClientEvent("ilegal_anims:syncAnimation", -1, playerSource, animDict, animName,
        type(duration) == "number" and duration or -1)
end)

-- Wyjście gracza w trakcie animacji gracza: callback nigdy nie wróci,
-- więc zwalniamy busy od razu zamiast czekać na failsafe watchdog.
AddEventHandler("playerDropped", function()
    local playerSource = source

    local pending = pendingPlayerAnims[playerSource]
    if pending then
        pendingPlayerAnims[playerSource] = nil
        if busyTokens[pending.propName] == pending.token then
            setBusy(pending.propName, false)
        end
    end

    lastZoneExits[playerSource] = nil
end)

-- ── AutoOpen: strefy, automatyczne otwieranie/zamykanie, zamki ─────

if Config.AutoOpen then
    RegisterNetEvent("ilegal_anims:zoneEnter", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        -- Odrzuć zgłoszenia graczy fizycznie daleko od strefy
        if not isPlayerNearProp(playerSource, getPropConfigByName(propName), 7.5) then return end

        if not doorOccupants[propName] then
            doorOccupants[propName] = {}
        end
        doorOccupants[propName][playerSource] = true
    end)

    RegisterNetEvent("ilegal_anims:zoneExit", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        local wasOccupant = doorOccupants[propName] and doorOccupants[propName][playerSource]
        if wasOccupant then
            doorOccupants[propName][playerSource] = nil
        end

        -- Zapamiętaj legalne wyjście (był occupantem albo jest blisko strefy);
        -- requestAutoClose przyjmujemy tylko po takim wyjściu / z bliska.
        if wasOccupant or isPlayerNearProp(playerSource, getPropConfigByName(propName), 25.0) then
            lastZoneExits[playerSource] = { propName = propName, at = GetGameTimer() }
        end
    end)

    RegisterNetEvent("ilegal_anims:requestAutoOpen", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end
        if not isPlayerNearProp(playerSource, getPropConfigByName(propName), 7.5) then return end
        if not ServerHasJobAccess(playerSource, propName) then return end

        local locks = GlobalState.ilegal_carwash_locks or {}
        if locks[propName] then return end

        local busyStates = GlobalState.ilegal_carwash_busy or {}
        if busyStates[propName] then return end

        local states = GlobalState.ilegal_carwash or {}
        if states[propName] then return end

        -- Gracz fizycznie jest przy drzwiach — licz go jako occupanta nawet,
        -- gdyby jego zoneEnter zgubił wyścig z synchronizacją pozycji.
        if not doorOccupants[propName] then
            doorOccupants[propName] = {}
        end
        doorOccupants[propName][playerSource] = true

        beginPropAnimation(propName, true, nil)
    end)

    RegisterNetEvent("ilegal_anims:requestAutoClose", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        -- Żądanie musi pochodzić z niedawnego, legalnego wyjścia ze strefy
        -- ( klient wysyła je AutoOpenCloseDelay po zoneExit ) albo z bliska.
        -- Bez sprawdzenia joba: drzwi mają się zamknąć po ostatnim wychodzącym,
        -- niezależnie od jego uprawnień do otwierania.
        local lastExit = lastZoneExits[playerSource]
        local recentExit = lastExit and lastExit.propName == propName
            and (GetGameTimer() - lastExit.at) <= (Config.AutoOpenCloseDelay or 3000) + 15000
        if not recentExit and not isPlayerNearProp(playerSource, getPropConfigByName(propName), 25.0) then
            return
        end
        if recentExit then
            lastZoneExits[playerSource] = nil
        end

        if getOccupantCount(propName) > 0 then return end

        local busyStates = GlobalState.ilegal_carwash_busy or {}
        if busyStates[propName] then return end

        local states = GlobalState.ilegal_carwash or {}
        if not states[propName] then return end

        beginPropAnimation(propName, false, nil)
    end)

    RegisterNetEvent("ilegal_anims:toggleLock", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end
        if not isPlayerNearProp(playerSource, getPropConfigByName(propName), 7.5) then return end

        if not ServerHasJobAccess(playerSource, propName) then
            notifyPlayer(playerSource,
                (Config.Permissions and Config.Permissions.noAccessMessage) or "You don't have access to this",
                "error")
            return
        end

        -- Nie przełączaj zamka (i stanu) w trakcie trwania animacji
        local busyStates = GlobalState.ilegal_carwash_busy or {}
        if busyStates[propName] then
            notifyPlayer(playerSource,
                (Config.Messages and Config.Messages.alreadyInUse) or "This object is already in use",
                "error")
            return
        end

        local locks = GlobalState.ilegal_carwash_locks or {}

        -- REKONSTRUKCJA po uszkodzonej dekompilacji: w zdekompilowanym kodzie
        -- było `newLocked = not old and old` (w Lua zawsze false/nil), więc
        -- poprawną intencją jest zwykłe przełączenie dotychczasowego stanu.
        local newLocked = not locks[propName]

        locks[propName] = newLocked
        GlobalState.ilegal_carwash_locks = locks

        notifyPlayer(playerSource,
            newLocked and Config.Messages.locked or Config.Messages.unlocked,
            newLocked and "error" or "success")

        -- Odblokowanie: otwórz od razu, jeśli ktoś stoi w strefie
        if not newLocked then
            local states = GlobalState.ilegal_carwash or {}

            if not states[propName] and getOccupantCount(propName) > 0 then
                beginPropAnimation(propName, true, nil)
            end
        end

        -- Zablokowanie: zamknij otwartą roletę
        if newLocked then
            local states = GlobalState.ilegal_carwash or {}

            if states[propName] then
                beginPropAnimation(propName, false, nil)
            end
        end
    end)

    -- Gracz wyszedł z serwera: usuń go ze stref i ewentualnie
    -- zaplanuj autozamknięcie pustej rolety po AutoOpenCloseDelay.
    AddEventHandler("playerDropped", function()
        local playerSource = source

        for propName, occupants in pairs(doorOccupants) do
            if occupants[playerSource] then
                occupants[playerSource] = nil

                if getOccupantCount(propName) == 0 then
                    local states = GlobalState.ilegal_carwash or {}
                    local busyStates = GlobalState.ilegal_carwash_busy or {}

                    if states[propName] and not busyStates[propName] then
                        SetTimeout(Config.AutoOpenCloseDelay, function()
                            if getOccupantCount(propName) == 0 then
                                local currentStates = GlobalState.ilegal_carwash or {}
                                local currentBusy = GlobalState.ilegal_carwash_busy or {}

                                if currentStates[propName] and not currentBusy[propName] then
                                    beginPropAnimation(propName, false, nil)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

-- ── Komenda testowa: /testautodoors_ig (ACE: command.testautodoors_ig) ──
-- UWAGA: testy MUTUJĄ żywy stan (GlobalState, occupants, dozwolone joby)
-- i na końcu na sztywno zostawiają roletę ZAMKNIĘTĄ, not busy, ZABLOKOWANĄ.

RegisterCommand("testautodoors_ig", function(playerSource, args)
    local passed = 0
    local failed = 0
    local results = {}

    local function check(testName, condition)
        if condition then
            passed = passed + 1
            results[#results + 1] = "^2  PASS^0: " .. testName
        else
            failed = failed + 1
            results[#results + 1] = "^1  FAIL^0: " .. testName
        end
    end

    print("^3[TEST] ========== Auto-Door Test Suite (Illegal Garage) ==========^0")

    check('isGarageRollup("prompt_sandy_is_garage_rollup") == true', isGarageRollup("prompt_sandy_is_garage_rollup") == true)
    check('isGarageRollup("prompt_sandy_is_lift") == false', isGarageRollup("prompt_sandy_is_lift") == false)
    check("isGarageRollup(nil) == false", isGarageRollup(nil) == false)
    check("isGarageRollup(123) == false", isGarageRollup(123) == false)
    check("Config.AutoOpen exists", Config.AutoOpen ~= nil)
    check("Config.AutoOpenCloseDelay is number", type(Config.AutoOpenCloseDelay) == "number")
    check("Config.Messages.lock exists", Config.Messages.lock ~= nil)
    check("Config.Messages.unlock exists", Config.Messages.unlock ~= nil)
    check("Config.Messages.locked exists", Config.Messages.locked ~= nil)
    check("Config.Messages.unlocked exists", Config.Messages.unlocked ~= nil)

    if Config.Permissions then
        local rollupProp = Config.Props.garage_rollup
        local originalEnabled = Config.Permissions.enabled
        local originalAllowedJobs = rollupProp and rollupProp.allowedJobs

        Config.Permissions.enabled = false
        check("Permissions disabled: ServerHasJobAccess allows", ServerHasJobAccess(0, "prompt_sandy_is_garage_rollup") == true)

        if rollupProp then
            Config.Permissions.enabled = true
            rollupProp.allowedJobs = { "mechanic" }

            local hasQbox = GetResourceState("qbx_core") == "started"
            local framework = Config.Permissions.framework or "auto"
            if framework == "auto" and not hasQbox then
                check("No framework: restricted prop denies (fail closed)", ServerHasJobAccess(0, "prompt_sandy_is_garage_rollup") == false)
            end

            rollupProp.allowedJobs = originalAllowedJobs
        end

        Config.Permissions.enabled = originalEnabled
    end

    check("GlobalState.ilegal_carwash exists", GlobalState.ilegal_carwash ~= nil)
    check("GlobalState.ilegal_carwash_busy exists", GlobalState.ilegal_carwash_busy ~= nil)

    if Config.AutoOpen then
        local ROLLUP = "prompt_sandy_is_garage_rollup"

        local locks = GlobalState.ilegal_carwash_locks
        check("GlobalState.ilegal_carwash_locks exists", locks ~= nil)

        if locks then
            local doorCount = 0
            local allLocked = true
            for lockName, isLocked in pairs(locks) do
                doorCount = doorCount + 1
                if not isLocked then
                    allLocked = false
                end
                check("Lock entry is garage_rollup: " .. lockName, isGarageRollup(lockName))
            end
            check("1 garage door in lock state (got " .. doorCount .. ")", doorCount == 1)
            check("All doors default to locked", allLocked)
        end

        check("getOccupantCount for unknown door == 0", getOccupantCount(ROLLUP) == 0)

        -- setBusy (oryginał czytał tu jeszcze poprzednią wartość busy,
        -- ale nigdy jej nie przywracał — martwy odczyt, pominięty)
        setBusy(ROLLUP, true)
        check("setBusy(rollup, true) sets busy", (GlobalState.ilegal_carwash_busy or {})[ROLLUP] == true)

        setBusy(ROLLUP, false)
        check("setBusy(rollup, false) clears busy", (GlobalState.ilegal_carwash_busy or {})[ROLLUP] == false)

        -- Przełączenie zamka tam i z powrotem
        local toggleLocks = GlobalState.ilegal_carwash_locks or {}
        local originalLocked = toggleLocks[ROLLUP]
        toggleLocks[ROLLUP] = not originalLocked
        GlobalState.ilegal_carwash_locks = toggleLocks
        check("Lock toggle changes state", (GlobalState.ilegal_carwash_locks or {})[ROLLUP] == (not originalLocked))
        toggleLocks[ROLLUP] = originalLocked
        GlobalState.ilegal_carwash_locks = toggleLocks

        -- Przygotuj stan: odblokowana, not busy, zamknięta
        local testLocks = GlobalState.ilegal_carwash_locks or {}
        testLocks[ROLLUP] = false
        GlobalState.ilegal_carwash_locks = testLocks

        setBusy(ROLLUP, false)

        local testStates = GlobalState.ilegal_carwash or {}
        testStates[ROLLUP] = nil
        GlobalState.ilegal_carwash = testStates

        -- REKONSTRUKCJA: zdekompilowany warunek był uszkodzony
        -- (kolejne odczyty nadpisywały tę samą zmienną, a na końcu
        --  stało `not x and x`). Z opisu testu chodzi o koniunkcję:
        local canAutoOpen = not (GlobalState.ilegal_carwash_locks or {})[ROLLUP]
            and not (GlobalState.ilegal_carwash_busy or {})[ROLLUP]
            and not (GlobalState.ilegal_carwash or {})[ROLLUP]
        check("Unlocked + not busy + not open = can auto-open", canAutoOpen == true)

        -- Symuluj auto-otwarcie
        setBusy(ROLLUP, true)
        updateGlobalPropState(ROLLUP, true)
        check("After auto-open: door state is true", (GlobalState.ilegal_carwash or {})[ROLLUP] == true)
        check("After auto-open: busy is true", (GlobalState.ilegal_carwash_busy or {})[ROLLUP] == true)

        doorOccupants[ROLLUP] = { [999] = true }
        check("With occupant: getOccupantCount == 1", getOccupantCount(ROLLUP) == 1)

        local noOccupants = (getOccupantCount(ROLLUP) == 0)
        check("With occupant: close is rejected", noOccupants == false)

        doorOccupants[ROLLUP] = {}
        setBusy(ROLLUP, false)

        -- REKONSTRUKCJA jak wyżej (uszkodzona koniunkcja w dekompilacji)
        local canAutoClose = getOccupantCount(ROLLUP) == 0
            and not (GlobalState.ilegal_carwash_busy or {})[ROLLUP]
            and (GlobalState.ilegal_carwash or {})[ROLLUP]
        check("No occupants + not busy + open = can auto-close", canAutoClose == true)

        -- Sprzątanie po teście: zamknięta, not busy, zablokowana, brak occupants
        setBusy(ROLLUP, false)
        updateGlobalPropState(ROLLUP, false)

        local cleanupLocks = GlobalState.ilegal_carwash_locks or {}
        cleanupLocks[ROLLUP] = true
        GlobalState.ilegal_carwash_locks = cleanupLocks

        doorOccupants[ROLLUP] = nil

        check("Locked door blocks auto-open check", (GlobalState.ilegal_carwash_locks or {})[ROLLUP] == true)
    else
        print("^3[TEST] Config.AutoOpen is false — skipping auto-open tests^0")
    end

    print("^3[TEST] ---------- Results ----------^0")
    for _, line in ipairs(results) do
        print("[TEST] " .. line)
    end
    print("^3[TEST] ========== " .. passed .. " passed, " .. failed .. " failed ==========^0")

    if playerSource > 0 then
        TriggerClientEvent("ox_lib:notify", playerSource, {
            description = passed .. " passed, " .. failed .. " failed",
            type = (failed == 0) and "success" or "error",
            duration = 5000
        })
    end
end, true)

local PROMPT_MAP_ID = "prompt_sandy_gasstation_carwash" -- musi być = MapId w sv_loader.lua
local PROMPT_MAP_NAME = "Gas"
local PROMPT_MAP_LOCATIONS = { "sandy" }

AddEventHandler(PROMPT_MAP_ID .. ":mapExists", function(cb)
    if type(cb) == "function" then cb(true) end
end)

AddEventHandler("promptmap:i_exist_" .. PROMPT_MAP_ID, function(cb)
    if type(cb) == "function" then cb(true) end
end)

AddEventHandler("promptmap:locations_" .. PROMPT_MAP_ID, function(cb)
    if type(cb) == "function" then cb(PROMPT_MAP_LOCATIONS) end
end)

AddEventHandler(PROMPT_MAP_ID .. ":mapFullNameSend", function(returnEvent, id)
    if type(returnEvent) == "string" then
        TriggerEvent(returnEvent, PROMPT_MAP_NAME, id)
    end
end)

AddEventHandler(PROMPT_MAP_ID .. ":mapFinal", function()
    -- legacy: checker powiadamia ostatnią wykrytą mapę; nic nie robimy
end)

-- ── Debug: log zmian stanu ──────────────────────────────────────────

if Config.Debug then
    AddEventHandler("prompt_sandy_illegal_garage:liftStateChanged", function(propName, state)
        print(("[SANDY ILLEGAL GARAGE EXPORT DEBUG] [SERVER] liftStateChanged -> propName: %s | state: %s (%s)"):format(
            tostring(propName), tostring(state), state and "UP" or "DOWN"))
    end)
end

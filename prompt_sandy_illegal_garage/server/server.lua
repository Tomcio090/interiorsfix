---------------------------------------------------------------------
-- PROMPT SANDY ILLEGAL GARAGE — Server
-- Stan propów w GlobalState:
--   ilegal_carwash        = { [propName] = true/false }  (otwarty/zamknięty)
--   ilegal_carwash_busy   = { [propName] = true/false }  (animacja w toku)
--   ilegal_carwash_locks  = { [propName] = true/false }  (zamek rolety, tylko AutoOpen)
-- Uprawnienia: ServerHasJobAccess (joby frameworka / ACE / wyłączone).
---------------------------------------------------------------------

-- Czy source eventu wygląda na prawdziwego gracza?
-- Zwraca wartość "prawda/fałsz" w sensie Lua (dla nil zwraca nil).
function validateSource(playerSource)
    return playerSource and playerSource > 0
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

-- ── Uprawnienia (serwer) ────────────────────────────────────────────

function ServerHasJobAccess(playerSource, propName)
    -- System uprawnień wyłączony -> każdy ma dostęp
    if not (Config.Permissions and Config.Permissions.enabled) then
        return true
    end

    -- Szukaj propa po nazwie
    local propConfig = nil
    for _, prop in pairs(Config.Props) do
        if prop.name == propName then
            propConfig = prop
            break
        end
    end
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

local function setBusy(propName, busy)
    local busyStates = GlobalState.ilegal_carwash_busy or {}
    busyStates[propName] = busy and true or false
    GlobalState.ilegal_carwash_busy = busyStates
end

exports("isDoorLocked", function(propName)
    local locks = GlobalState.ilegal_carwash_locks or {}
    return locks[propName] or false
end)

-- ── Eventy od klienta: stan / synchronizacja ────────────────────────

RegisterNetEvent("ilegal_anims:initializeState", function(initialState)
    if not validateSource(source) then return end

    -- Przyjmuje stan startowy tylko, jeśli jeszcze żaden nie istnieje.
    -- (W praktyce wątek init powyżej zawsze tworzy {} na starcie serwera.)
    if not GlobalState.ilegal_carwash then
        GlobalState.ilegal_carwash = initialState or {}
    end
end)

RegisterNetEvent("ilegal_anims:updatePropState", function(propName, state)
    if not validateSource(source) then return end

    if propName then
        updateGlobalPropState(propName, state)
    end
end)

-- Rozgłasza animację gracza (widoczną dla innych) do wszystkich klientów
RegisterNetEvent("ilegal_anims:syncAnimation", function(animDict, animName, duration)
    local playerSource = source

    if not validateSource(playerSource) then
        print("Error: Fuente inválida para la sincronización de animación")
        return
    end

    if not animDict or not animName then
        print("Error: Datos incompletos para la sincronización de animación")
        return
    end

    TriggerClientEvent("ilegal_anims:syncAnimation", -1, playerSource, animDict, animName, duration)
end)

-- Klient prosi o odegranie animacji gracza przed animacją propa.
-- Serwer woła callback ox_lib na tym kliencie i dopiero po sukcesie
-- każe mu animować propa (ilegal_anims:animatePropAfterPlayerAnim).
RegisterNetEvent("ilegal_anims:requestPlayerAnimation", function(animData)
    local playerSource = source

    if not validateSource(playerSource) then
        print("Error: Fuente inválida para la solicitud de animación")
        return
    end

    if not (animData and animData.dict and animData.anim and animData.propName) then
        print("Error: Datos incompletos para la solicitud de animación")
        return
    end

    if not (animData.position and animData.heading) then
        print("Error: Posición o heading no proporcionados para la animación")
        return
    end

    lib.callback("ilegal_anims:playPlayerAnimation", playerSource, function(success)
        if success then
            TriggerClientEvent("ilegal_anims:animatePropAfterPlayerAnim", playerSource, {
                propName = animData.propName,
                state = animData.state
            })
        else
            print("Error: La animación del jugador falló")
        end
    end, animData)
end)

-- Klient ustawia "busy" (zwykle: true przed animacją, false po niej).
-- Po wyczyszczeniu busy dla rolety AutoOpen serwer ponawia próbę
-- auto-otwarcia, jeśli ktoś nadal stoi w strefie.
RegisterNetEvent("ilegal_anims:setPropBusy", function(propName, busy)
    if not validateSource(source) then return end
    if not propName then return end

    -- W oryginale zapis busy był tu zduplikowany zamiast wywołania
    -- lokalnego helpera — efekt identyczny, więc używamy setBusy().
    setBusy(propName, busy)

    if Config.AutoOpen and not busy and isGarageRollup(propName) then
        local locks = GlobalState.ilegal_carwash_locks or {}
        local states = GlobalState.ilegal_carwash or {}

        if not locks[propName] and not states[propName] and getOccupantCount(propName) > 0 then
            setBusy(propName, true)
            updateGlobalPropState(propName, true)
        end
    end
end)

-- ── AutoOpen: strefy, automatyczne otwieranie/zamykanie, zamki ─────

if Config.AutoOpen then
    RegisterNetEvent("ilegal_anims:zoneEnter", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        if not doorOccupants[propName] then
            doorOccupants[propName] = {}
        end
        doorOccupants[propName][playerSource] = true
    end)

    RegisterNetEvent("ilegal_anims:zoneExit", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        if doorOccupants[propName] then
            doorOccupants[propName][playerSource] = nil
        end
    end)

    RegisterNetEvent("ilegal_anims:requestAutoOpen", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end
        if not ServerHasJobAccess(playerSource, propName) then return end

        local locks = GlobalState.ilegal_carwash_locks or {}
        if locks[propName] then return end

        local busyStates = GlobalState.ilegal_carwash_busy or {}
        if busyStates[propName] then return end

        local states = GlobalState.ilegal_carwash or {}
        if states[propName] then return end

        setBusy(propName, true)
        updateGlobalPropState(propName, true)
    end)

    RegisterNetEvent("ilegal_anims:requestAutoClose", function(propName)
        if not validateSource(source) then return end
        if not isGarageRollup(propName) then return end
        if getOccupantCount(propName) > 0 then return end

        local busyStates = GlobalState.ilegal_carwash_busy or {}
        if busyStates[propName] then return end

        local states = GlobalState.ilegal_carwash or {}
        if not states[propName] then return end

        setBusy(propName, true)
        updateGlobalPropState(propName, false)
    end)

    RegisterNetEvent("ilegal_anims:toggleLock", function(propName)
        local playerSource = source
        if not validateSource(playerSource) then return end
        if not isGarageRollup(propName) then return end

        if not ServerHasJobAccess(playerSource, propName) then
            TriggerClientEvent("ox_lib:notify", playerSource, {
                description = Config.Permissions.noAccessMessage or "You don't have access to this",
                type = "error",
                duration = 3000
            })
            return
        end

        local locks = GlobalState.ilegal_carwash_locks or {}

        -- REKONSTRUKCJA po uszkodzonej dekompilacji: w zdekompilowanym
        -- kodzie było tu dosłownie `newLocked = not old and old`
        -- (w Lua zawsze false/nil), przez co zamka nie dało się nigdy
        -- zamknąć. Z kontekstu (notify locked/unlocked, gałęzie poniżej)
        -- jednoznacznie chodzi o zwykłe przełączenie stanu:
        local newLocked = not locks[propName]

        locks[propName] = newLocked
        GlobalState.ilegal_carwash_locks = locks

        TriggerClientEvent("ox_lib:notify", playerSource, {
            description = newLocked and Config.Messages.locked or Config.Messages.unlocked,
            type = newLocked and "error" or "success",
            duration = 3000
        })

        -- Odblokowanie: otwórz od razu, jeśli ktoś stoi w strefie
        if not newLocked then
            local states = GlobalState.ilegal_carwash or {}
            local busyStates = GlobalState.ilegal_carwash_busy or {}

            if not states[propName] and not busyStates[propName] and getOccupantCount(propName) > 0 then
                setBusy(propName, true)
                updateGlobalPropState(propName, true)
            end
        end

        -- Zablokowanie: zamknij otwartą roletę
        -- (uwaga: ta gałąź, w przeciwieństwie do odblokowania,
        --  nie sprawdza busy przed nadpisaniem stanu)
        if newLocked then
            local states = GlobalState.ilegal_carwash or {}

            if states[propName] then
                setBusy(propName, true)
                updateGlobalPropState(propName, false)
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
                                    setBusy(propName, true)
                                    updateGlobalPropState(propName, false)
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

-- ── Debug: log zmian stanu ──────────────────────────────────────────

if Config.Debug then
    AddEventHandler("prompt_sandy_illegal_garage:liftStateChanged", function(propName, state)
        print(("[SANDY ILLEGAL GARAGE EXPORT DEBUG] [SERVER] liftStateChanged -> propName: %s | state: %s (%s)"):format(
            tostring(propName), tostring(state), state and "UP" or "DOWN"))
    end)
end

---------------------------------------------------------------------
-- PROMPT SANDY CITYHALL — Server
-- Stan windy w GlobalState (pisze wyłącznie serwer, klienci
-- odtwarzają animacje po zmianie state-baga), autorytatywne
-- potwierdzenie ruchu oraz synchronizacja animacji gracza przy
-- drzwiach między klientami.
--
-- Plik przepisany z zapisu dekompilatora (L0_1/A0_2) na czytelny
-- kod — zachowane wszystkie nazwy eventów, walidacje, czasy i
-- kolejność rejestracji; patrz ANALIZA.md, rozdz. 13.
---------------------------------------------------------------------

-- Inicjalizacja stanu windy (jeden state-bag dla wszystkich klientów)
CreateThread(function()
    GlobalState.elevator = {
        currentFloor = 1,
        targetFloor = nil,
        isMoving = false,
        doorsOpen = true
    }
end)

-- Czy czeka na animację drzwi z animacją gracza (jedna na raz —
-- serwer blokuje drugi ruch windy, póki animacja nie dojdzie)
local doorAnimationBusy = false

-- Czeka, aż klient gracza playerId zakończy animację gracza przy
-- drzwiach (callback ox_lib "elevator:playerDoorAnimation").
-- Parametr "open" jest przekazywany do callbacka (true = otwarcie).
-- Limit: 7000 ms — po czasie przechodzimy dalej niezależnie.
local function waitForPlayerDoorAnimation(playerId, open)
    local done = false
    CreateThread(function()
        pcall(lib.callback.await, "elevator:playerDoorAnimation", playerId, open)
        done = true
    end)

    local deadline = GetGameTimer() + 7000
    while not done do
        if not (deadline > GetGameTimer()) then
            break
        end
        Wait(50)
    end
end

-- Klient prosi o ruch windy. Serwer waliduje żądanie, blokuje
-- nakładanie ruchów i po duration + czasie na animacje drzwi
-- ustawia windę na piętrze docelowym (drzwi otwarte).
RegisterNetEvent("elevator:updateState", function(state)
    local src = source

    -- Walidacja żądania
    if type(state) ~= "table" then return end
    if not state.isMoving then return end
    if type(state.targetFloor) ~= "number" then return end
    if not Config.Elevator.floors[state.targetFloor] then return end

    local currentFloor = GlobalState.elevator.currentFloor
    if state.targetFloor == currentFloor then return end

    -- serverId zgłasza inicjator; ufaczmy tylko żądaniu "własnego"
    -- gracza (nie może podawać czyjegoś ID, by przejąć animację)
    local serverId = state.serverId
    if serverId and serverId ~= src then
        serverId = nil
    end

    -- Jeden ruch windy naraz
    if doorAnimationBusy then return end
    doorAnimationBusy = true

    -- Czas przejazdu: z żądania (clamp 3000..15000 ms) albo domyślny
    local duration = tonumber(state.duration) or Config.Elevator.timePerFloor
    duration = math.max(3000, math.min(duration, 15000))

    -- Najpierw drzwi (animacja gracza przy zamykaniu, o ile gracz
    -- wezwał windę i Config.EnablePlayerAnimations)
    if serverId then
        waitForPlayerDoorAnimation(serverId, false)
    end

    -- Zmiana stanu: winda jedzie na targetFloor, drzwi zamknięte
    GlobalState.elevator = {
        currentFloor = currentFloor,
        targetFloor = state.targetFloor,
        isMoving = true,
        doorsOpen = false
    }

    -- Po przejeździe + czasie na animacje drzwi: winda stoi,
    -- drzwi otwarte, busy zwolnione
    local doorWait = Config.Elevator.door.animations.duration * 2 + 300
    SetTimeout(duration + doorWait, function()
        if serverId then
            waitForPlayerDoorAnimation(serverId, true)
        end
        GlobalState.elevator = {
            currentFloor = state.targetFloor,
            targetFloor = nil,
            isMoving = false,
            doorsOpen = true
        }
        doorAnimationBusy = false
    end)
end)

-- Zgłoszenie animacji gracza przy drzwiach (z client.lua):
-- po zarejestrowaniu nazwy (oryginalna linia z dekompilacji, bez
-- handlera — rejestracja samej nazwy eventu) serwer sprawdza
-- słownik/nazwę klipu i transmituje do wszystkich.
RegisterServerEvent("prompt_elevator:send:animation")

AddEventHandler("prompt_elevator:send:animation", function(animDict, animName, heading)
    local src = source

    -- Whitelist: tylko słownik i klipy znane z configa
    if animDict ~= Config.Elevator.door.playerAnimation.dict then return end
    if animName ~= "right_open" and animName ~= "right_close" then return end

    TriggerClientEvent("prompt_elevator:sync:animation", -1, src, animDict, animName, heading)
end)

---------------------------------------------------------------------
-- PROMPT SANDY CITYHALL — Elevator (client)
-- Funkcjonalna winda ratusza: platformsa + drzwi + kolizje +
-- strzałki pięter, sterowanie przez strefy (open.lua) i state-bag
-- "elevator" (stan pilnuje serwer, patrz server/server.lua).
--
-- Plik przepisany z zapisu dekompilatora
-- na czytelny kod. Zachowano: wszystkie nazwy globalne (open.lua
-- używa getNearestFloor/SelectFloor/CallElevator), eventy, czasy,
-- współrzędne, kolejność wywołań native. Patrz ANALIZA.md, rozdz. 13.
--
-- Świadome odstępstwa od dosłownego zapisu (identyczne zachowanie):
--   * Argументy AttachEntityToEntity: w dekompilacji vertexIndex
--     wyszedł jako `false`, a collision jako `2` (w bindingu natywnym
--     false=0, 2=true) — znormalizowane na `0`/`true`.
--   * Ostatni argумент TaskPlayAnim w sync animacji (lockZ) w
--     dekompliacji to wartość headingu (niezerowa = true) —
--     przepuszczamy ją dalej bez zmian (patrz komentarz w miejscu).
--   * Usunięty martwy local `ensureElevatorState` (nigdy nieniywany;
--     wysyłał "elevator:initializeState", dla którego serwer NIE ma
--     handlera) oraz nieużywany local `isInsideElevator` (globalną
--     nazwą o tej samej nazwie zarządza open.lua).
---------------------------------------------------------------------

local hasOxLib = GetResourceState("ox_lib") == "started"
local interiorId = GetInteriorAtCoords(1753.6223, 3804.645, 35.4474)

-- Brak ox_lib albo winda wyłączona w configu -> statyczne entity set
if not hasOxLib then
    print("[PROMPT ELEVATOR DISABLED - ox_lib not found]")
    ActivateInteriorEntitySet(interiorId, "static_elevator")
    RefreshInterior(interiorId)
    return
end

if not Config.FunctionalElevator then
    print("[PROMPT ELEVATOR DISABLED]")
    ActivateInteriorEntitySet(interiorId, "static_elevator")
    RefreshInterior(interiorId)
    return
end

-- Wymiana statycznego entity set na funkcyjną windę
DeactivateInteriorEntitySet(interiorId, "static_elevator")
RefreshInterior(interiorId)

-- ── Stan lokalny (encje windy) ─────────────────────────────────────
local elevatorObj = nil          -- platformsa windy
local doorObj = nil              -- drzwi (widok)
local doorCollision = nil        -- drzwi (kolizja)
local indicatorObjs = {}         -- strzałki wskazujące piętro
local floorDoorObjs = {}         -- [numer piętra] = drzwi piętra (widok)
local floorDoorCollisions = {}   -- [numer piętra] = drzwi piętra (kolizja)

-- Najbliższe piętro dla podanej wysokości (z)
function getNearestFloor(z)
    local floors = Config.Elevator.floors
    local bestFloor = 1
    local bestDistance = math.abs(floors[1].coords.z - z)

    for i = 2, #floors do
        local distance = math.abs(floors[i].coords.z - z)
        if bestDistance > distance then
            bestDistance = distance
            bestFloor = i
        end
    end

    return bestFloor
end

-- Dźwięk drzwi (OPENING/CLOSING) — gra tylko dla gracza w roomie
-- danego piętra lub w roomie całego wnętrza.
function playDoorElevatorSound(open, coords, floor)
    local roomId = Config.Elevator.sounds_roomid[floor]
    if not roomId then return end

    local myRoom = GetRoomKeyFromEntity(cache.ped)
    if myRoom ~= roomId and myRoom ~= -1984934778 then
        return
    end

    local soundName = open and "OPENING" or "CLOSING"
    PlaySoundFromCoord(-1, soundName, coords.x, coords.y, coords.z,
        "MP_PROPERTIES_ELEVATOR_DOORS", true, 0, false)
end

-- Animuje drzwi windy (klip na obiekcie drzwi + ruch kolizji).
-- open: bool
-- doorEntity/collisionEntity: encje drzwi (głównych albo piętra)
-- attachedTo: encja platformsy (nil dla drzwi pięter — są statyczne)
-- floor: numer piętra (dla dźwięku i offsetu drzwi piętra)
--
-- Przez 900 ms (Config.Elevator.door.animations.duration) wątek
-- co klatkę przesuwa kolizję: drzwi główne są odłączane i
-- dołączane na bieżący offset względem platformsy, drzwi pięter
-- dostają lerp od 0 do config.offset. Wywołanie BLOKUJE 900 ms.
local function playDoorAnimation(open, doorEntity, collisionEntity, attachedTo, floor)
    if not doorEntity or not collisionEntity then return end

    local coords = GetEntityCoords(doorEntity)
    playDoorElevatorSound(open, coords, floor)

    local animName = Config.Elevator.door.animations.close.name
    if open then
        animName = Config.Elevator.door.animations.open.name
    end

    local animDict = Config.Elevator.door.animations.dict
    if pcall(lib.requestAnimDict, animDict) then
        -- PlayEntityAnim(entity, animName, animDict, blendDelta, bLoop,
        --                bHoldLastFrame, bDriveToPose, startPhase, flags)
        -- bLoop=false + bHoldLastFrame=true: klip gra raz i trzyma
        -- pozycję końcową (identycznie jak po naprawie w garażu, 9.3).
        PlayEntityAnim(doorEntity, animName, animDict, 8.0, false, true, false, 0.0, 0)
    end

    local doorDuration = 900
    local start = GetGameTimer()
    CreateThread(function()
        while true do
            if not (GetGameTimer() - start < doorDuration) then
                break
            end
            local progress = (GetGameTimer() - start) / doorDuration

            if attachedTo then
                -- Drzwi główne: kolizja wędruje z platformsą
                local slideOffset = open and -0.8 or 0.0
                local pos = vector3(
                    Config.Elevator.door.offset.x + slideOffset * progress,
                    Config.Elevator.door.offset.y,
                    Config.Elevator.door.offset.z
                )
                DetachEntity(collisionEntity, false, false)
                AttachEntityToEntity(collisionEntity, attachedTo, 0,
                    pos.x, pos.y, pos.z, 0.0, 0.0, 0.0,
                    false, false, true, 0, true, true)
            else
                -- Drzwi piętra: kolizja przesuwana względem drzwi
                local base = GetEntityCoords(doorEntity)
                local doorConfig = nil
                for floorId, data in pairs(Config.Elevator.floorDoors) do
                    if floorDoorObjs[floorId] == doorEntity then
                        doorConfig = data
                        break
                    end
                end
                if doorConfig then
                    local offset = open and doorConfig.offset or vector3(0.0, 0.0, 0.0)
                    local moved = vector3(
                        math.lerp(0, offset.x, progress),
                        math.lerp(0, offset.y, progress),
                        0.0
                    )
                    SetEntityCoords(collisionEntity,
                        base.x + moved.x, base.y + moved.y, base.z,
                        false, false, false, false)
                end
            end
            Wait(0)
        end
    end)

    Wait(doorDuration)
end

-- Tworzy drzwi na każdym piętrze (widok + kolizja, zamrożone)
local function createFloorDoors()
    for floorId, data in pairs(Config.Elevator.floorDoors) do
        lib.requestModel(Config.Elevator.door.model)
        local visual = CreateObjectNoOffset(joaat(Config.Elevator.door.model),
            data.coords.x, data.coords.y, data.coords.z, false, false, false)

        lib.requestModel(Config.Elevator.door.collisionModel)
        local collision = CreateObjectNoOffset(joaat(Config.Elevator.door.collisionModel),
            data.coords.x, data.coords.y, data.coords.z, false, false, false)

        SetEntityRotation(visual, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)
        SetEntityRotation(collision, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)

        SetEntityCollision(visual, false, false)
        SetEntityCollision(collision, true, true)
        FreezeEntityPosition(collision, true)
        FreezeEntityPosition(visual, true)
        SetEntityVisible(collision, false)

        floorDoorObjs[floorId] = visual
        floorDoorCollisions[floorId] = collision
    end
end

-- Tworzy strzałki wskazujące piętro (wszystkie na obecne piętro)
local function createIndicators()
    for _, indicator in ipairs(indicatorObjs) do
        DeleteEntity(indicator)
    end
    indicatorObjs = {}

    local currentFloor = GlobalState.elevator and GlobalState.elevator.currentFloor or 1

    for _, position in ipairs(Config.Elevator.indicators.positions) do
        lib.requestModel(Config.Elevator.indicators.model)
        local obj = CreateObject(joaat(Config.Elevator.indicators.model),
            position.coords.x, position.coords.y, position.coords.z, false, false, false)

        -- Każda strzałka pokazuje piętro, na którym stoi winda
        local rotation = Config.Elevator.indicators.positions[currentFloor].rotation
        SetEntityRotation(obj, rotation.x, rotation.y, rotation.z, 2, true)
        FreezeEntityPosition(obj, true)
        table.insert(indicatorObjs, obj)
    end
end

-- Animuje strzałki: obrót (osie y) od piętra bieżącego do docelowego
local function animateIndicators(targetFloor, duration, startTime)
    if not indicatorObjs or #indicatorObjs == 0 then return end

    local currentRotation = Config.Elevator.indicators.positions[GlobalState.elevator.currentFloor].rotation
    local targetRotation = Config.Elevator.indicators.positions[targetFloor].rotation
    if not targetRotation then return end

    local start = startTime or GetNetworkTimeAccurate()
    local easing = bezier(0.42, 0, 0.58, 1)

    local function lerpY(t)
        return math.lerp(currentRotation.y, targetRotation.y, t)
    end

    CreateThread(function()
        while true do
            local t = math.min((GetNetworkTimeAccurate() - start) / duration, 1.0)
            if t >= 1.0 then
                for _, indicator in ipairs(indicatorObjs) do
                    SetEntityRotation(indicator,
                        targetRotation.x, targetRotation.y, targetRotation.z, 2, true)
                end
                break
            end

            local y = lerpY(easing(t))
            for _, indicator in ipairs(indicatorObjs) do
                SetEntityRotation(indicator,
                    vector3(currentRotation.x, y, currentRotation.z))
            end
            Wait(0)
        end
    end)
end

-- Spawnuje platformę + drzwi + kolizje na podanym piętrze i
-- odtwarza animacje drzwi zgodnie z bieżącym stanem.
local function spawnElevator(floor)
    if elevatorObj then return end

    local floorData = Config.Elevator.floors[floor]
    if not floorData then return end

    while not IsModelValid(joaat(Config.Elevator.model)) do
        Wait(0)
    end
    lib.requestModel(Config.Elevator.model)
    elevatorObj = CreateObjectNoOffset(joaat(Config.Elevator.model),
        floorData.coords.x, floorData.coords.y, floorData.coords.z, false, false, false)

    local rotation = Config.Elevator.position.rotation
    SetEntityRotation(elevatorObj, rotation.x, rotation.y, rotation.z, 2, true)

    local elevatorCoords = GetEntityCoords(elevatorObj)
    local doorCoords = elevatorCoords + Config.Elevator.door.offset

    lib.requestModel(Config.Elevator.door.model)
    doorObj = CreateObject(joaat(Config.Elevator.door.model),
        doorCoords.x, doorCoords.y, doorCoords.z, false, false, false)
    SetEntityRotation(doorObj, rotation.x, rotation.y, rotation.z, 2, true)

    lib.requestModel(Config.Elevator.door.collisionModel)
    doorCollision = CreateObject(joaat(Config.Elevator.door.collisionModel),
        doorCoords.x, doorCoords.y, doorCoords.z, false, false, true)
    SetEntityRotation(doorCollision, rotation.x, rotation.y, rotation.z, 2, true)

    SetEntityCollision(doorObj, false, false)
    SetEntityCollision(doorCollision, true, true)
    FreezeEntityPosition(doorCollision, true)
    SetEntityVisible(doorCollision, false)

    AttachEntityToEntity(doorObj, elevatorObj, 0,
        doorCoords.x, doorCoords.y, doorCoords.z, 0.0, 0.0, 0.0,
        false, false, false, 0, true, true)

    -- Kolizja drzwi startuje w pozycji zależnej od stanu (otwarte?)
    local collisionOffset = Config.Elevator.door.animations.close.collisionOffset
    if GlobalState.elevator and GlobalState.elevator.doorsOpen then
        collisionOffset = Config.Elevator.door.animations.open.collisionOffset
    end
    AttachEntityToEntity(doorCollision, elevatorObj, 0,
        doorCoords.x + collisionOffset.x,
        doorCoords.y + collisionOffset.y,
        doorCoords.z + collisionOffset.z,
        0.0, 0.0, 0.0, false, false, true, 0, true, true)

    createFloorDoors()

    if GlobalState.elevator then
        local state = GlobalState.elevator
        playDoorAnimation(state.doorsOpen, doorObj, doorCollision, elevatorObj, state.currentFloor)
        if floorDoorObjs[state.currentFloor] then
            playDoorAnimation(state.doorsOpen,
                floorDoorObjs[state.currentFloor],
                floorDoorCollisions[state.currentFloor], nil, state.currentFloor)
        end
    end
end

-- Strefa spawnu windy (promień 35 m)
local spawnPoint = lib.points.new({
    coords = Config.Elevator.spawnZone.coords,
    distance = Config.Elevator.spawnZone.radius,

    onEnter = function()
        local floor = GlobalState.elevator and GlobalState.elevator.currentFloor
        if not floor then
            floor = getNearestFloor(cache.coords.z)
        end
        spawnElevator(floor)
        createIndicators()
    end,

    onExit = function()
        if elevatorObj then
            DeleteEntity(elevatorObj)
            DeleteEntity(doorObj)
            DeleteEntity(doorCollision)
            elevatorObj = nil
            doorObj = nil
            doorCollision = nil
        end
        for _, indicator in ipairs(indicatorObjs) do
            DeleteEntity(indicator)
        end
        indicatorObjs = {}
        for floorId, visual in pairs(floorDoorObjs) do
            DeleteEntity(visual)
            if floorDoorCollisions[floorId] then
                DeleteEntity(floorDoorCollisions[floorId])
            end
        end
        floorDoorObjs = {}
        floorDoorCollisions = {}
    end
})

-- Czas przejazdu między piętrami (clamp 3000..15000 ms)
function calculateElevatorDuration(fromFloor, toFloor)
    local floorDifference = math.abs(toFloor - fromFloor)
    local floorDistance = math.abs(Config.Elevator.floors[2].coords.z - Config.Elevator.floors[1].coords.z)
    local msPerFloor = floorDistance / Config.Elevator.moveSpeed * 5000
    local total = msPerFloor * floorDifference
    return math.max(3000, math.min(total, 15000))
end

-- Wybór piętra z wnętrza windy (menu w open.lua)
function SelectFloor(targetFloor, currentFloor)
    local duration = calculateElevatorDuration(currentFloor, targetFloor)
    local state = {
        currentFloor = currentFloor,
        targetFloor = targetFloor,
        isMoving = true,
        doorsOpen = false,
        duration = duration
    }

    -- Opcjonalna animacja gracza przy drzwiach (decyduje serwer)
    if Config.EnablePlayerAnimations then
        local serverId = GetPlayerServerId(PlayerId())
        if serverId then
            state.serverId = serverId
        end
    end

    playSelectFloorSound()
    TriggerServerEvent("elevator:updateState", state)
end

-- Wezwanie windy z korytarza (przycisk w open.lua)
function CallElevator(soundCoords, targetFloor)
    local currentFloor = GlobalState.elevator.currentFloor
    local duration = calculateElevatorDuration(currentFloor, targetFloor)
    local state = {
        currentFloor = currentFloor,
        targetFloor = targetFloor,
        isMoving = true,
        doorsOpen = false,
        duration = duration
    }

    TriggerServerEvent("elevator:updateState", state)

    if Config.EnablePlayerAnimations then
        playPlayerButtonAnimation(targetFloor)
        Wait(1300)
    end
    playSelectFloorSound(soundCoords)
end

-- Sprzątanie przy stopie zasobu
AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() ~= resource then return end

    if elevatorObj then
        DeleteEntity(elevatorObj)
        DeleteEntity(doorObj)
        DeleteEntity(doorCollision)
    end
    for _, indicator in ipairs(indicatorObjs) do
        DeleteEntity(indicator)
    end
    for floorId, visual in pairs(floorDoorObjs) do
        DeleteEntity(visual)
        if floorDoorCollisions[floorId] then
            DeleteEntity(floorDoorCollisions[floorId])
        end
    end

    elevatorObj = nil
    doorObj = nil
    doorCollision = nil
    indicatorObjs = {}
    floorDoorObjs = {}
    floorDoorCollisions = {}
    isInsideElevator = false
end)

-- Przesuwa platformę na piętro docelowe (krzywa cubic-bezier z utils)
local function moveElevatorToFloor(targetFloor)
    if not elevatorObj then return end

    local currentFloor = GlobalState.elevator.currentFloor
    local startCoords = GetEntityCoords(elevatorObj)
    local endCoords = Config.Elevator.floors[targetFloor].coords
    local duration = math.max(3000,
        math.min(calculateElevatorDuration(currentFloor, targetFloor), 15000))
    local curveKey = currentFloor .. "_to_" .. targetFloor
    local startTime = GetNetworkTimeAccurate()

    TranslateObjectCoordsCubicBezier(elevatorObj, endCoords, duration,
        Config.Elevator.bezierCurve, curveKey, targetFloor, startTime)
end

-- Reakcja na zmianę stanu windy (serwer jest autorytatywny).
-- Sygnatura callbacka CFX: (bagName, key, value, reserved, replicated)
AddStateBagChangeHandler("elevator", nil, function(bagName, key, newState)
    if not (newState and elevatorObj) then return end

    if newState.targetFloor then
        -- Winda ma ruszyć / jedzie
        if newState.isMoving then
            -- Zamknij drzwi (główne + drzwi piętra, na którym stoi)
            playDoorAnimation(false, doorObj, doorCollision, elevatorObj, newState.currentFloor)
            if floorDoorObjs[newState.currentFloor] then
                playDoorAnimation(false,
                    floorDoorObjs[newState.currentFloor],
                    floorDoorCollisions[newState.currentFloor], nil, newState.currentFloor)
            end

            if newState.currentFloor ~= newState.targetFloor then
                local duration = calculateElevatorDuration(
                    newState.currentFloor, newState.targetFloor)
                local startTime = GetNetworkTimeAccurate()
                CreateThread(function()
                    animateIndicators(newState.targetFloor, duration, startTime)
                    moveElevatorToFloor(newState.targetFloor)
                end)
            end
        end
    else
        -- Winda dotarła
        if not newState.isMoving and newState.doorsOpen then
            playElevatorArrivalSound(newState.currentFloor)
            playDoorAnimation(true, doorObj, doorCollision, elevatorObj, newState.currentFloor)
            if floorDoorObjs[newState.currentFloor] then
                playDoorAnimation(true,
                    floorDoorObjs[newState.currentFloor],
                    floorDoorCollisions[newState.currentFloor], nil, newState.currentFloor)
            end
        end
    end
end)

-- Animacja gracza przy drzwiach (wołana przez serwer callbackiem
-- ox_lib). Prowadzi peda do drzwi, ustawia heading, zgłasza serwerowi
-- (serwer broadcastuje innym graczom) i zwraca true po zakończeniu.
lib.callback.register("elevator:playerDoorAnimation", function(open)
    if not elevatorObj then
        return false
    end

    local ped = cache.ped

    local animName = "right_open"
    if open then
        animName = "right_close"
    end

    -- rawOffset obrócony o rotację windy (system współrzędnych windy)
    local angle = math.rad(Config.Elevator.position.rotation.z)
    local rawOffset = Config.Elevator.door.playerAnimation.rawOffset
    local offset = {}
    offset.x = rawOffset.x * math.cos(angle) + rawOffset.y * math.sin(angle)
    offset.y = rawOffset.y * math.cos(angle) - rawOffset.x * math.sin(angle)
    offset.z = rawOffset.z
    offset.w = rawOffset.w

    local elevatorCoords = GetEntityCoords(elevatorObj)
    local pedAngle = math.rad(GetEntityRotation(ped, 2).z)

    local targetX = elevatorCoords.x + offset.x * math.cos(pedAngle) - offset.y * math.sin(pedAngle)
    local targetY = elevatorCoords.y + offset.y * math.cos(pedAngle) + offset.x * math.sin(pedAngle)
    local targetZ = elevatorCoords.z + offset.z

    -- Podchodzenie do drzwi (limit 5 s)
    TaskPedSlideToCoord(ped, targetX, targetY, targetZ, offset.w, 500)
    local start = GetGameTimer()
    while true do
        local pedCoords = GetEntityCoords(ped)
        local distance = #(vector3(targetX, targetY, targetZ) - pedCoords)
        if distance < 0.1 then
            break
        end
        if GetGameTimer() - start > 5000 then
            break
        end
        Wait(0)
    end

    SetEntityHeading(ped, offset.w)
    Wait(100)

    -- Serwer przekaże animację innym graczom w windzie
    TriggerServerEvent("prompt_elevator:send:animation",
        Config.Elevator.door.playerAnimation.dict, animName, offset.w)
    Wait(300)
    return true
end)

-- Rejestracja nazwy eventu (oryginalna linia z dekompilacji) +
-- odtworzenie animacji gracza u innych (tylko we wnętrzu ratusza)
RegisterNetEvent("prompt_elevator:sync:animation")

AddEventHandler("prompt_elevator:sync:animation", function(srcPlayerId, animDict, animName, heading)
    if GetRoomKeyFromEntity(cache.ped) ~= -1984934778 then
        return
    end

    local localPlayer = GetPlayerFromServerId(srcPlayerId)
    if localPlayer == -1 then
        return
    end

    local ped = GetPlayerPed(localPlayer)
    if not pcall(lib.requestAnimDict, animDict) then
        return
    end

    -- TaskPlayAnim(ped, dict, anim, blendIn, blendOut, duration, flag,
    --               shift, playbackRate, lockX, lockY, lockZ)
    -- duration=-1 (klip do czasu zastąpienia); 12. arg. (lockZ) w
    -- dekompliacji przyjmował wartość headingu (niezerowa = true) —
    -- przepuszczamy go bez zmian (identyczne zachowanie).
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 0, 0, false, false, heading)
end)

-- Dźwięk "pik" przy wyborze piętra (domyślnie przy windzie)
function playSelectFloorSound(coords)
    local pos = coords or GetEntityCoords(elevatorObj)
    PlaySoundFromCoord(-1, "Pin_Centred", pos.x, pos.y, pos.z,
        "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", false, 0, false)
end

-- Dzwonek przyjazdu — tylko dla gracza w roomie danego piętra
-- (albo w roomie całego wnętrza); bank audio z prompt_audio.
function playElevatorArrivalSound(floor)
    local roomId = Config.Elevator.sounds_roomid[floor]
    if not roomId then return end

    local myRoom = GetRoomKeyFromEntity(cache.ped)
    if myRoom ~= roomId and myRoom ~= -1984934778 then
        return
    end
    if not elevatorObj then return end

    local coords = GetEntityCoords(elevatorObj)
    CreateThread(function()
        local deadline = GetGameTimer() + 3000
        while true do
            if RequestScriptAudioBank("dlc_promptaudio/prompt_audio", false) then
                break
            end
            if GetGameTimer() > deadline then
                return
            end
            Wait(100)
        end
        PlaySoundFromCoord(-1, "elevator_bell", coords.x, coords.y, coords.z,
            "special_soundset", false, 2, false)
    end)
end

-- Podchodzenie do przycisku + animacja naciśnięcia
function playPlayerButtonAnimation(floor)
    local position = Config.Elevator.playerAskElevatorPositions[floor]
    if not position then return end

    local ped = cache.ped
    TaskPedSlideToCoord(ped,
        position.coords.x, position.coords.y, position.coords.z,
        position.heading, 500)

    local start = GetGameTimer()
    while true do
        local pedCoords = GetEntityCoords(ped)
        if #(position.coords - pedCoords) < 0.1 then
            break
        end
        if GetGameTimer() - start > 5000 then
            break
        end
        Wait(0)
    end

    SetEntityHeading(ped, position.heading)

    local buttonAnim = Config.Elevator.buttonAnimation
    lib.requestAnimDict(buttonAnim.dict)
    TaskPlayAnim(ped, buttonAnim.dict, buttonAnim.name, 8.0, -8.0, -1, 0, 0, false, false, false)
end

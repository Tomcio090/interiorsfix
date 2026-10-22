-- Sprawdzenie czy ox_lib jest uruchomiony i załadowany
local isOxLibStarted = GetResourceState("ox_lib") == "started"
local hasLib = isOxLibStarted

if isOxLibStarted then
    hasLib = lib ~= nil
end

local function debugPrint(...)
    if Config.Debug then
        print(...)
    end
end

-- Współrzędne wnętrza (Interior)
local garageCoords = vector3(1705.4022, 3690.8555, 34.5232)
local interiorID = nil

-- Forward declarations (deklaracje wyprzedzające, żeby uniknąć błędów nil value)
local createProp, createCollision, createLinkedProp, animateProp, playPropAnimation, playStaticAnimation, getOxTargetLabels

-- Funkcja wyszukująca ID wnętrza dla podanych współrzędnych
local function getGarageInterior()
    if interiorID and interiorID ~= 0 then
        return interiorID
    end

    for i = 0, 49 do
        interiorID = GetInteriorAtCoords(garageCoords.x, garageCoords.y, garageCoords.z)
        if interiorID and interiorID ~= 0 then
            debugPrint("[COMPOUND] Interior found: " .. tostring(interiorID))
            return interiorID
        end
        Wait(100)
    end

    debugPrint("[COMPOUND WARNING] Could not find interior after 5 seconds")
    return 0
end

-- Włączenie domyślnego zestawu obiektów (entity set)
local function enableDefaultEntitySet()
    local interior = getGarageInterior()
    if interior == 0 then return end

    debugPrint("[COMPOUND] Enabling default entity set (InteriorId: " .. tostring(interior) .. ")")
    ActivateInteriorEntitySet(interior, "default")
    RefreshInterior(interior)
end
enableDefault = enableDefaultEntitySet

-- Wyłączenie domyślnego zestawu obiektów (gdy używamy własnych propów animowanych)
local function disableDefaultEntitySet()
    local interior = getGarageInterior()
    if interior == 0 then return end

    debugPrint("[COMPOUND] Disabling default entity set (InteriorId: " .. tostring(interior) .. ")")
    DeactivateInteriorEntitySet(interior, "default")
    RefreshInterior(interior)
end
disableDefault = disableDefaultEntitySet

-- Sprawdzenie konfiguracji animacji
local animsEnabled = hasLib
if hasLib then
    animsEnabled = Config.EnableAnimations
end

if not animsEnabled then
    CreateThread(function()
        enableDefaultEntitySet()
    end)

    local errorMsg = ""
    if not isOxLibStarted then
        errorMsg = "ox_lib resource not started"
    elseif not hasLib then
        errorMsg = "ox_lib failed to initialize (lib global missing)"
    else
        errorMsg = "Config.EnableAnimations is false"
    end

    debugPrint("[COMPOUND ANIMS DISABLED] " .. errorMsg)
    return
end

-- Jeśli animacje są włączone, wyłączamy domyślny zestaw obiektów i używamy własnych propów
CreateThread(function()
    disableDefaultEntitySet()
end)

debugPrint("[COMPOUND ANIMS ENABLED] Using animated props instead of default entity set")

if useTarget then
    debugPrint("[COMPOUND] Target system detected: " .. TargetSystem .. " - using target interactions")
else
    debugPrint("[COMPOUND] No target system available or disabled - using zone interactions")
end

-- Globalne tablice przechowujące stany, obiekty i strefy
local spawnedProps = {}
local collisionProps = {}
local linkedPropsTable = {}
local currentTextUI = nil
local isInInteractionZone = false
local activeZones = {}
local oxTargetZones = {}
local zoneEnterCounts = {}
local activeZoneData = {}
local propSpawnPending = {}

-- Pomocnicza funkcja sprawdzająca czy to jedna z pięciu rolet mechanika.
-- W dekompilacji warunek został uszkodzony do samego type(...) == "string",
-- przez co AutoOpen obejmowało także podnośniki.
local function isGarageRollup(propName)
    return type(propName) == "string" and propName:match("^garage_rollup_%d+$") ~= nil
end

-- Jedyna droga inicjowania zmiany stanu przez klienta: prośba do serwera.
-- Serwer waliduje prop/dystans/uprawnienia/busy, zmienia GlobalState,
-- a wszyscy klienci (też inicjator) odtwarzają animację ze state-baga.
local function requestPropState(propName, state)
    TriggerServerEvent("compound_anims:requestToggleProp", propName, state)
end

-- Funkcja pomocnicza do tworzenia obiektów (propów) bez offsetu
local function spawnObjectModel(model, coords, rotation, isCollision, freezeCollision)
    if not model or not IsModelValid(model) then
        debugPrint("[COMPOUND] Model not valid: " .. tostring(model))
        return nil
    end

    local modelLoadResult = lib.requestModel(model)
    if modelLoadResult and type(modelLoadResult) == "table" and modelLoadResult.await then
        modelLoadResult.await()
    end

    local entity = CreateObjectNoOffset(joaat(model), coords.x, coords.y, coords.z, false, false, isCollision or false)
    if not entity or entity == 0 then
        debugPrint("[COMPOUND] Failed to create entity for model: " .. tostring(model))
        return nil
    end

    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
    FreezeEntityPosition(entity, true)

    if isCollision then
        SetEntityCollision(entity, true, true)
        if freezeCollision then
            FreezeEntityPosition(entity, true)
        end
        SetEntityVisible(entity, false)
    end

    SetModelAsNoLongerNeeded(model)
    return entity
end

-- Tworzenie kolizji dla obiektów
createCollision = function(propData)
    if propData.collision then
        local collisionName = propData.collision.name
        if collisionProps[collisionName] and DoesEntityExist(collisionProps[collisionName]) then
            return collisionProps[collisionName]
        end
    else
        return
    end

    local coords = propData.collision.coords
    local rotation = propData.collision.rotation
    local propStates = GlobalState.sandy_compound
    local stateValue = propStates and propStates[propData.name]

    if propData.collision.moveType == "coords" and stateValue ~= nil then
        if stateValue then
            coords = propData.collision.endCoords or coords
        else
            coords = propData.collision.startCoords
        end
    elseif propData.collision.moveType == "rotation" and stateValue ~= nil then
        if stateValue then
            rotation = propData.collision.endRotation or rotation
        else
            rotation = propData.collision.startRotation
        end
    end

    local entity = spawnObjectModel(propData.collision.model, coords, rotation, true, true)
    if entity then
        collisionProps[propData.collision.name] = entity
    end
    return entity
end

-- Tworzenie powiązanych propów (linked props)
createLinkedProp = function(propData, parentName)
    if linkedPropsTable[propData.name] and DoesEntityExist(linkedPropsTable[propData.name].entity) then
        return linkedPropsTable[propData.name].entity
    end

    local entity = spawnObjectModel(propData.model, propData.coords, propData.rotation, false, false)
    if entity then
        linkedPropsTable[propData.name] = {
            entity = entity,
            parent = parentName
        }
    end
    return entity
end

-- Odtwarzanie animacji dla encji: klip gra DOKŁADNIE RAZ i trzyma ostatnią
-- klatkę (otwarte drzwi / podniesiony lift mają zostać w pozycji końcowej).
-- Wcześniej parametry duration/loop/flag/playbackRate były przekłamane:
-- każde wywołanie trafiało do PlayEntityAnim jako bLoop=true oraz liczba 0.0
-- jako bHoldLastFrame, więc każda animacja propa zapętlała się w kółko.
local function playEntityAnimation(entity, animDict, animName)
    if not entity or not DoesEntityExist(entity) then return end

    local animLoadResult = lib.requestAnimDict(animDict)
    if animLoadResult and type(animLoadResult) == "table" and animLoadResult.await then
        animLoadResult.await()
    end

    -- PlayEntityAnim(entity, animName, animDict, blendDelta,
    --                bLoop, bHoldLastFrame, bDriveToPose, startPhase, flags)
    PlayEntityAnim(entity, animName, animDict, 8.0, false, true, false, 0.0, 0)
    RemoveAnimDict(animDict)
end

-- Odtwarzanie statycznej animacji
playStaticAnimation = function(entity, propData)
    if not entity or not DoesEntityExist(entity) then return end
    if not propData.animations or not propData.animations.static then return end

    local dict = propData.animations.dict
    local staticAnim = propData.animations.static

    playEntityAnimation(entity, dict, staticAnim)

    if propData.linkedProps and propData.animations.linkedAnims then
        for index, linkedProp in ipairs(propData.linkedProps) do
            local linkedInfo = linkedPropsTable[linkedProp.name]
            if linkedInfo and linkedInfo.entity and DoesEntityExist(linkedInfo.entity) then
                local linkedAnim = propData.animations.linkedAnims[index]
                if linkedAnim and linkedAnim.static then
                    playEntityAnimation(linkedInfo.entity, dict, linkedAnim.static)
                end
            end
        end
    end
end

-- Funkcja pomocnicza do animowania wielu obiektów naraz
local function animateMultipleProps(propsList, animationsList, animDict, isOpen, speed, index)
    index = index or 1
    if index > #propsList then return end

    local propInfo = propsList[index]
    local targetProp = linkedPropsTable[propInfo.name]

    if targetProp and targetProp.entity and DoesEntityExist(targetProp.entity) then
        local animName = isOpen and animationsList[index].open or animationsList[index].close
        playEntityAnimation(targetProp.entity, animDict, animName)
    end

    animateMultipleProps(propsList, animationsList, animDict, isOpen, speed, index + 1)
end

-- Odtwarza LOKALNIE animację propa do stanu ustawionego przez serwer
-- (wywoływane z handlera state-baga oraz przy odtworzeniu stanu po spawnie).
-- Nie wysyła żadnych eventów serwerowych: busy zwalnia serwerowy watchdog.
-- emitLocalEvents: czy emitować lokalne eventy liftStateChanged/Complete
-- (false przy cichym odtworzeniu stanu po spawnie propa).
playPropAnimation = function(propConfig, propEntity, isOpen, animDict, animName, duration, emitLocalEvents)
    playEntityAnimation(propEntity, animDict, animName)

    if emitLocalEvents then
        TriggerEvent("prompt_sandy_mechanic:liftStateChanged", propConfig.name, isOpen)
    end

    if propConfig.linkedProps and propConfig.animations.linkedAnims then
        animateMultipleProps(propConfig.linkedProps, propConfig.animations.linkedAnims, animDict, isOpen, duration)
    end

    local collision = propConfig.collision
    if collision then
        local collisionEntity = collisionProps[collision.name]

        if collisionEntity and DoesEntityExist(collisionEntity) then
            if collision.moveType == "coords" and collision.startCoords and collision.endCoords then
                -- Konwencja zgodna z createCollision: otwarty = endCoords,
                -- zamknięty = startCoords (wcześniej kierunek był odwrócony).
                local startCoords = isOpen and collision.startCoords or collision.endCoords
                local endCoords = isOpen and collision.endCoords or collision.startCoords
                local moveTime = duration
                local delay = 0
                local easing = "easeInOut"

                if collision.liftSettings then
                    if isOpen then
                        delay = collision.liftSettings.upDelay or 200
                        moveTime = duration * (collision.liftSettings.upSpeedFactor or 0.8)
                        easing = collision.liftSettings.upCurve or "easeInOutQuad"
                    else
                        moveTime = duration * (collision.liftSettings.downSpeedFactor or 1.2)
                        easing = collision.liftSettings.downCurve or "easeOutCubic"
                    end
                elseif propConfig.name == "prompt_sandy_is_lift_2" then
                    if isOpen then
                        delay = 200
                        moveTime = duration * 0.8
                        easing = "easeInOutQuad"
                    else
                        moveTime = duration * 1.2
                        easing = "easeOutCubic"
                    end
                end

                local extraDelay = isOpen and collision.openDelay or collision.closeDelay
                if extraDelay then
                    SetTimeout(math.floor(extraDelay), function()
                        AnimateObjectCoords(collisionEntity, startCoords, endCoords, moveTime, easing)
                    end)
                elseif delay > 0 then
                    SetTimeout(delay, function()
                        AnimateObjectCoords(collisionEntity, startCoords, endCoords, moveTime, easing)
                    end)
                else
                    AnimateObjectCoords(collisionEntity, startCoords, endCoords, moveTime, easing)
                end
            elseif collision.moveType == "rotation" and collision.startRotation and collision.endRotation then
                local startRotation = isOpen and collision.startRotation or collision.endRotation
                local endRotation = isOpen and collision.endRotation or collision.startRotation
                AnimateObjectRotation(collisionEntity, startRotation, endRotation, duration, "easeInOut")
            end
            -- Kolizje statyczne (bez moveType): nic nie robimy.
            -- Wcześniej otrzymywały AnimateObjectCoords(nil, nil), który
            -- wyrzucał błąd w wątku przy każdej animacji.
        end
    end

    if emitLocalEvents then
        SetTimeout(duration, function()
            TriggerEvent("prompt_sandy_mechanic:liftAnimationComplete", propConfig.name, isOpen)
        end)
    end
end

-- Lokalne odtworzenie animacji propa po nazwie (TYLKO playback ze stanu
-- serwerowego; do inicjowania zmian służy requestPropState powyżej).
animateProp = function(propName, isOpen, emitLocalEvents)
    local propConfig = nil
    for _, config in pairs(Config.Props) do
        if config.name == propName then
            propConfig = config
            break
        end
    end

    local propEntity = spawnedProps[propName]
    if not propConfig or not propEntity or not DoesEntityExist(propEntity) then return false end
    if not propConfig.animations or not propConfig.animations.dict then return false end

    local animDict = propConfig.animations.dict
    local animName = isOpen and propConfig.animations.open or propConfig.animations.close

    local animLoadResult = lib.requestAnimDict(animDict)
    if animLoadResult and type(animLoadResult) == "table" and animLoadResult.await then
        animLoadResult.await()
    end

    local animDuration = GetAnimDuration(animDict, animName) * 1000
    if not animDuration or animDuration <= 0 then
        animDuration = propConfig.animations.duration or 5000
    end

    playPropAnimation(propConfig, propEntity, isOpen, animDict, animName, animDuration, emitLocalEvents)
    return true
end

-- Tworzenie pojedynczego propa na podstawie konfiguracji.
-- attempt: numer próby — po chwilowej porażce spawnu ponawiamy próbę zamiast
-- czekać, aż gracz wyjdzie i wróci w zasięg pointa (objaw: brak drzwi tuż po
-- spawnie gracza przy garażu, mimo że model jest poprawny).
createProp = function(propData, attempt)
    local existingEntity = spawnedProps[propData.name]
    if existingEntity and DoesEntityExist(existingEntity) then
        -- Przy okazji ulecz ewentualnie brakującą kolizję / linked propy
        -- (obie funkcje same odrzucają duplikaty).
        if propData.collision then
            createCollision(propData)
        end
        if propData.linkedProps then
            for _, linkedData in ipairs(propData.linkedProps) do
                createLinkedProp(linkedData, propData.name)
            end
        end
        return existingEntity
    end

    -- spawnObjectModel yielduje przy ładowaniu modelu: równoległa próba
    -- (onEnter pointa + retry) nie może utworzyć duplikatu.
    if propSpawnPending[propData.name] then
        return nil
    end
    propSpawnPending[propData.name] = true
    attempt = attempt or 1

    debugPrint("[COMPOUND] Creating prop: " .. propData.name .. " with model: " .. tostring(propData.model))
    local entity = spawnObjectModel(propData.model, propData.coords, propData.rotation, false, false)
    propSpawnPending[propData.name] = nil

    if not entity then
        if attempt <= 5 then
            SetTimeout(1000 * attempt, function()
                createProp(propData, attempt + 1)
            end)
        else
            debugPrint("[COMPOUND ERROR] Failed to create entity for prop: " .. propData.name)
        end
        return nil
    end

    debugPrint("[COMPOUND] Successfully created prop entity: " .. propData.name .. " (entity: " .. tostring(entity) .. ")")
    spawnedProps[propData.name] = entity

    if propData.collision and not createCollision(propData) then
        SetTimeout(1500, function()
            createCollision(propData)
        end)
    end

    if propData.linkedProps then
        for _, linkedData in ipairs(propData.linkedProps) do
            createLinkedProp(linkedData, propData.name)
        end
    end

    local propStates = GlobalState.sandy_compound
    if propStates and propStates[propData.name] ~= nil then
        SetTimeout(100, function()
            animateProp(propData.name, propStates[propData.name], false)
        end)
    elseif propData.animations and propData.animations.static then
        SetTimeout(100, function()
            playStaticAnimation(entity, propData)
        end)
    end

    return entity
end

-- Pobieranie etykiet (labeli) dla ox_target
getOxTargetLabels = function(propData)
    local playerId = GetPlayerServerId(PlayerId())
    local openLabel, closeLabel = nil, nil

    if type(propData.label) == "table" then
        openLabel = propData.label.open
        closeLabel = propData.label.close
    else
        openLabel = propData.label or Config.Messages.open
        closeLabel = propData.label or Config.Messages.close
    end

    return {
        open = GetCustomLabel(propData.name, playerId, openLabel),
        close = GetCustomLabel(propData.name, playerId, closeLabel)
    }
end

-- Rejestracja stref targetu dla ox_target
local function registerOxTarget(propData)
    if not propData.interactionZone then return end
    if oxTargetZones[propData.name] then return end

    local playerId = GetPlayerServerId(PlayerId())
    local targetName = "compound_" .. propData.name
    local originalName = propData.originalName or propData.name
    local isAutoOpenZone = Config.AutoOpen and isGarageRollup(originalName)

    local options = nil

    if isAutoOpenZone then
        options = {
            {
                name = targetName .. "_unlock",
                icon = "fas fa-lock-open",
                label = Config.Messages.unlock,
                canInteract = function()
                    local locks = GlobalState.sandy_compound_locks or {}
                    if not locks[originalName] then return false end
                    local busy = GlobalState.sandy_compound_busy and GlobalState.sandy_compound_busy[originalName]
                    if busy then return false end
                    return CanPlayerInteract(originalName, playerId) and HasJobAccess(originalName, playerId)
                end,
                onSelect = function()
                    TriggerServerEvent("compound_anims:toggleLock", originalName)
                end
            },
            {
                name = targetName .. "_lock",
                icon = "fas fa-lock",
                label = Config.Messages.lock,
                canInteract = function()
                    local locks = GlobalState.sandy_compound_locks or {}
                    if locks[originalName] then return false end
                    local busy = GlobalState.sandy_compound_busy and GlobalState.sandy_compound_busy[originalName]
                    if busy then return false end
                    return CanPlayerInteract(originalName, playerId) and HasJobAccess(originalName, playerId)
                end,
                onSelect = function()
                    TriggerServerEvent("compound_anims:toggleLock", originalName)
                end
            }
        }
    else
        local labels = getOxTargetLabels(propData)
        options = {
            {
                name = targetName .. "_open",
                icon = "fas fa-door-open",
                label = labels.open,
                canInteract = function()
                    local propStates = GlobalState.sandy_compound and GlobalState.sandy_compound[originalName]
                    local busy = GlobalState.sandy_compound_busy and GlobalState.sandy_compound_busy[originalName]
                    if busy or propStates then return false end
                    return CanPlayerInteract(originalName, playerId) and HasJobAccess(originalName, playerId)
                end,
                onSelect = function()
                    OnPropInteraction(originalName, playerId, false)
                    if propData.onExecute then propData.onExecute(propData) end
                    requestPropState(originalName, true)
                end
            },
            {
                name = targetName .. "_close",
                icon = "fas fa-door-closed",
                label = labels.close,
                canInteract = function()
                    local propStates = GlobalState.sandy_compound and GlobalState.sandy_compound[originalName]
                    local busy = GlobalState.sandy_compound_busy and GlobalState.sandy_compound_busy[originalName]
                    if busy or not propStates then return false end
                    return CanPlayerInteract(originalName, playerId) and HasJobAccess(originalName, playerId)
                end,
                onSelect = function()
                    OnPropInteraction(originalName, playerId, true)
                    if propData.onExecute then propData.onExecute(propData) end
                    requestPropState(originalName, false)
                end
            }
        }
    end

    TargetAddBoxZone({
        name = targetName,
        coords = propData.interactionZone.coords,
        size = propData.interactionZone.size,
        rotation = propData.interactionZone.rotation or 0,
        debug = Config.Debug,
        options = options
    })

    oxTargetZones[propData.name] = targetName
    debugPrint("[COMPOUND] Registered target zone for prop: " .. propData.name)
end

-- Usuwanie strefy ox_target
local function removeOxTarget(propData)
    local zoneName = oxTargetZones[propData.name]
    if not zoneName then return end

    TargetRemoveZone(zoneName)
    oxTargetZones[propData.name] = nil
end

-- Eksportowane funkcje globalne
exports("getLiftState", function(propName)
    local propStates = GlobalState.sandy_compound or {}
    return propStates[propName]
end)

exports("isLiftBusy", function(propName)
    local busyState = GlobalState.sandy_compound_busy or {}
    return busyState[propName] or false
end)

-- Zleca zmianę stanu serwerowi (walidacja dystansu/uprawnień/busy po jego stronie).
-- Animacja odtworzy się lokalnie dopiero po zmianie GlobalState (state-bag).
exports("setLiftState", function(propName, state)
    requestPropState(propName, state)
end)

-- Debugowanie eventów w trybie debug
if Config.Debug then
    AddEventHandler("prompt_sandy_mechanic:liftStateChanged", function(propName, state)
        print(string.format("[COMPOUND EXPORT DEBUG] [CLIENT] liftStateChanged -> propName: %s | state: %s (%s)", tostring(propName), tostring(state), state and "UP" or "DOWN"))
        local liftState = exports[GetCurrentResourceName()]:getLiftState(propName)
        print(string.format("[COMPOUND EXPORT DEBUG] [CLIENT] getLiftState(%s) = %s", tostring(propName), tostring(liftState)))
        local isBusy = exports[GetCurrentResourceName()]:isLiftBusy(propName)
        print(string.format("[COMPOUND EXPORT DEBUG] [CLIENT] isLiftBusy(%s) = %s", tostring(propName), tostring(isBusy)))
    end)

    AddEventHandler("prompt_sandy_mechanic:liftAnimationComplete", function(propName, state)
        print(string.format("[COMPOUND EXPORT DEBUG] [CLIENT] liftAnimationComplete -> propName: %s | state: %s (%s)", tostring(propName), tostring(state), state and "UP" or "DOWN"))
    end)
end

-- Aktualizacja interfejsu TextUI
local function updateTextUI(text)
    if currentTextUI ~= text then
        if text then
            lib.showTextUI(text)
        else
            lib.hideTextUI()
        end
        currentTextUI = text
    end
end

-- Tworzenie klasycznej strefy interakcji (lib.zones)
local function createInteractionZone(propData)
    if not propData.interactionZone then return end

    local isAutoOpen = Config.AutoOpen and isGarageRollup(propData.name)

    return lib.zones.box({
        coords = propData.interactionZone.coords,
        size = propData.interactionZone.size,
        rotation = propData.interactionZone.rotation,
        debug = false,
        onEnter = function()
            isInInteractionZone = true
            activeZones[propData.name] = true
            local playerId = GetPlayerServerId(PlayerId())

            activeZoneData[propData.name] = {
                canInteract = CanPlayerInteract(propData.name, playerId),
                hasAccess = HasJobAccess(propData.name, playerId),
                playerId = playerId
            }
        end,
        onExit = function()
            activeZoneData[propData.name] = nil
            activeZones[propData.name] = nil
            if next(activeZones) == nil then
                isInInteractionZone = false
                updateTextUI(nil)
            end
        end,
        inside = function()
            local zoneInfo = activeZoneData[propData.name]
            local isBusy = GlobalState.sandy_compound_busy and GlobalState.sandy_compound_busy[propData.name]

            if isBusy then
                updateTextUI(nil)
                return
            end

            if isAutoOpen then
                if not zoneInfo or not zoneInfo.canInteract or not zoneInfo.hasAccess then
                    updateTextUI(nil)
                    return
                end

                local locks = GlobalState.sandy_compound_locks or {}
                local isLocked = locks[propData.name] or false
                local lockMsg = isLocked and Config.Messages.unlock or Config.Messages.lock

                local customLabel = GetCustomLabel(propData.name, zoneInfo.playerId, lockMsg)
                updateTextUI("[" .. Config.InteractionKey.display .. "] " .. customLabel)

                if IsControlJustPressed(0, Config.InteractionKey.control) then
                    TriggerServerEvent("compound_anims:toggleLock", propData.name)
                end
            else
                if not zoneInfo or not zoneInfo.canInteract or not zoneInfo.hasAccess then
                    updateTextUI(nil)
                    return
                end

                local propStates = GlobalState.sandy_compound
                local isOpen = propStates and propStates[propData.name]
                local actionMsg = nil

                if type(propData.label) == "table" then
                    actionMsg = isOpen and propData.label.close or propData.label.open
                else
                    actionMsg = propData.label or (isOpen and Config.Messages.close .. " " .. propData.name or Config.Messages.open .. " " .. propData.name)
                end

                local customLabel = GetCustomLabel(propData.name, zoneInfo.playerId, actionMsg)
                updateTextUI("[" .. Config.InteractionKey.display .. "] " .. customLabel)

                if IsControlJustPressed(0, Config.InteractionKey.control) then
                    OnPropInteraction(propData.name, zoneInfo.playerId, isOpen)
                    if propData.onExecute then propData.onExecute(propData) end
                    requestPropState(propData.name, not isOpen)
                end
            end
        end
    })
end

-- Tworzenie stref automatycznego otwierania przy wejściu (AutoOpen)
local function createAutoOpenZone(propData)
    if not propData.interactionZone then return end

    local propName = propData.name
    zoneEnterCounts[propName] = 0

    return lib.zones.box({
        coords = propData.interactionZone.coords,
        size = propData.interactionZone.size,
        rotation = propData.interactionZone.rotation,
        debug = Config.Debug,
        onEnter = function()
            zoneEnterCounts[propName] = (zoneEnterCounts[propName] or 0) + 1
            TriggerServerEvent("compound_anims:zoneEnter", propName)

            local locks = GlobalState.sandy_compound_locks or {}
            if locks[propName] then return end

            local propStates = GlobalState.sandy_compound or {}
            if propStates[propName] then return end

            local busyState = GlobalState.sandy_compound_busy or {}
            if busyState[propName] then return end

            local playerId = GetPlayerServerId(PlayerId())
            if not CanPlayerInteract(propName, playerId) or not HasJobAccess(propName, playerId) then return end

            TriggerServerEvent("compound_anims:requestAutoOpen", propName)
        end,
        onExit = function()
            TriggerServerEvent("compound_anims:zoneExit", propName)
            local currentCount = zoneEnterCounts[propName] or 0

            SetTimeout(Config.AutoOpenCloseDelay, function()
                if (zoneEnterCounts[propName] or 0) ~= currentCount then return end
                TriggerServerEvent("compound_anims:requestAutoClose", propName)
            end)
        end
    })
end

-- Inicjalizacja wszystkich stref interakcji
local function createInteractionZones()
    if useTarget then
        debugPrint("[COMPOUND] Creating target zones for all props")
        for _, propConfig in pairs(Config.Props) do
            if propConfig.interactionZone then
                registerOxTarget(propConfig)
            end
            if propConfig.extraZones then
                for extraIndex, extraZone in ipairs(propConfig.extraZones) do
                    local clonedConfig = table.clone(propConfig)
                    clonedConfig.interactionZone = extraZone
                    clonedConfig.originalName = propConfig.name
                    clonedConfig.name = propConfig.name .. "_extra_" .. extraIndex
                    registerOxTarget(clonedConfig)
                end
            end
        end
    else
        debugPrint("[COMPOUND] Creating lib.zones for all props")
        for _, propConfig in pairs(Config.Props) do
            createInteractionZone(propConfig)
            if propConfig.extraZones then
                for _, extraZone in ipairs(propConfig.extraZones) do
                    local clonedConfig = table.clone(propConfig)
                    clonedConfig.interactionZone = extraZone
                    createInteractionZone(clonedConfig)
                end
            end
        end
    end

    if Config.AutoOpen then
        debugPrint("[COMPOUND] Creating auto-open zones for garage rollup doors")
        for _, propConfig in pairs(Config.Props) do
            if isGarageRollup(propConfig.name) and propConfig.interactionZone then
                createAutoOpenZone(propConfig)
            end
        end
    end
end

-- Tworzenie punktów spawnujących obiekty wokół gracza (Distance streaming)
local function createSpawnPoint(propData)
    local point = lib.points.new({
        coords = propData.coords,
        distance = Config.SpawnDistance,
        onEnter = function()
            debugPrint("[COMPOUND] onEnter triggered for prop: " .. propData.name)
            createProp(propData)
        end,
        onExit = function()
        end
    })

    if point then
        spawnedProps[propData.name] = nil
        debugPrint("[COMPOUND] Spawn point created and stored for: " .. propData.name)

        -- Gracz może już stać w zasięgu (spawn przy propie / restart zasobu):
        -- spróbuj od razu, nie polegaj wyłącznie na onEnter pointa.
        if #(GetEntityCoords(cache.ped) - propData.coords) <= Config.SpawnDistance then
            createProp(propData)
        end
    else
        debugPrint("[COMPOUND WARNING] Failed to create spawn point for: " .. propData.name)
    end
end

local function createSpawnPoints()
    for _, propConfig in pairs(Config.Props) do
        createSpawnPoint(propConfig)
    end
end

-- Zdarzenia sieciowe (Net Events)
RegisterNetEvent("compound_anims:syncAnimation")
AddEventHandler("compound_anims:syncAnimation", function(sourcePlayerId, animDict, animName, duration)
    if type(animDict) ~= "string" or type(animName) ~= "string" then return end

    local player = GetPlayerFromServerId(sourcePlayerId)
    if player == -1 or not NetworkIsPlayerActive(player) then return end

    local targetPed = GetPlayerPed(player)
    if not targetPed or targetPed == 0 or targetPed == cache.ped then return end

    local animLoadResult = lib.requestAnimDict(animDict)
    if animLoadResult and type(animLoadResult) == "table" and animLoadResult.await then
        animLoadResult.await()
    end

    TaskPlayAnim(targetPed, animDict, animName, 8.0, -8.0,
        type(duration) == "number" and duration or -1, 0, 0, false, false, false)
    RemoveAnimDict(animDict)
end)

-- UWAGA: dawny handler compound_anims:animatePropAfterPlayerAnim został
-- usunięty. Serwer po udanej animacji gracza zmienia GlobalState,
-- a prop animuje się u wszystkich z handlera state-baga poniżej.

-- Rejestracja handlerów zmian stanów (StateBag)
local function registerPropStateHandlers()
    AddStateBagChangeHandler("sandy_compound", nil, function(bagName, key, value)
        if not value then return end
        local propStates = GlobalState.sandy_compound or {}

        for _, propConfig in pairs(Config.Props) do
            local propName = propConfig.name
            if value[propName] ~= nil and value[propName] ~= propStates[propName] then
                if spawnedProps[propName] and DoesEntityExist(spawnedProps[propName]) then
                    animateProp(propName, value[propName], true)
                end
            end
        end
    end)

    if Config.AutoOpen then
        local previousLocks = {}
        local locksState = GlobalState.sandy_compound_locks
        if type(locksState) == "table" then
            for k, v in pairs(locksState) do
                previousLocks[k] = v
            end
        end

        AddStateBagChangeHandler("sandy_compound_locks", nil, function(bagName, key, value)
            if not value then return end

            for _, propConfig in pairs(Config.Props) do
                local propName = propConfig.name
                if isGarageRollup(propName) then
                    local currentLockState = value[propName]
                    if currentLockState ~= nil and currentLockState ~= previousLocks[propName] then
                        local coords = propConfig.coords
                        if currentLockState then
                            PlaySoundFromCoord(-1, "CLOSING", coords.x, coords.y, coords.z, "MP_PROPERTIES_ELEVATOR_DOORS", true, 0, false)
                        else
                            PlaySoundFromCoord(-1, "OPENING", coords.x, coords.y, coords.z, "MP_PROPERTIES_ELEVATOR_DOORS", true, 0, false)
                        end
                    end
                end
            end

            for k, v in pairs(value) do
                previousLocks[k] = v
            end
        end)
    end
end

-- Rejestracja callbacku ox_lib do odtwarzania animacji gracza
-- (serwer buduje animData z configa; klient dodatkowo toleruje kształty
-- tabelaryczne position/heading per nazwa animacji)
lib.callback.register("compound_anims:playPlayerAnimation", function(animData)
    if not animData or not animData.dict or not animData.anim or not animData.propName then
        debugPrint("[COMPOUND] Error: Incomplete data for the player animation")
        return false
    end

    local position = animData.position
    if type(position) == "table" and position[animData.anim] then
        position = position[animData.anim]
    end

    local heading = animData.heading
    if type(heading) == "table" and heading[animData.anim] ~= nil then
        heading = heading[animData.anim]
    end

    if not position or position.x == nil or position.y == nil or position.z == nil
        or type(heading) ~= "number" then
        debugPrint("[COMPOUND] Error: Position or heading not provided for the animation")
        return false
    end

    local targetPosition = vector3(position.x, position.y, position.z)

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    TaskGoStraightToCoord(ped, targetPosition.x, targetPosition.y, targetPosition.z, 1.0, -1, heading, 0.1)

    local targetDistance = 0.5
    local startTime = GetGameTimer()

    while true do
        local currentCoords = GetEntityCoords(ped)
        local distance = #(currentCoords - targetPosition)
        if targetDistance > distance then
            break
        end

        if GetGameTimer() - startTime > 5000 then
            SetEntityCoords(ped, targetPosition.x, targetPosition.y, targetPosition.z, false, false, false, false)
            break
        end
        Wait(100)
    end

    SetEntityCoordsNoOffset(ped, targetPosition.x, targetPosition.y, targetPosition.z, false, false, false)
    SetEntityHeading(ped, heading)

    local animLoadResult = lib.requestAnimDict(animData.dict)
    if animLoadResult and type(animLoadResult) == "table" and animLoadResult.await then
        animLoadResult.await()
    end

    TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, 8.0, -1, 0, 0, false, false, false)
    RemoveAnimDict(animData.dict)

    TriggerServerEvent("compound_anims:syncAnimation", animData.dict, animData.anim, -1)
    Wait(600)
    return true
end)

-- Czyszczenie zasobu po zatrzymaniu skryptu
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if useTarget then
        for _, zoneName in pairs(oxTargetZones) do
            TargetRemoveZone(zoneName)
        end
        oxTargetZones = {}
    end

    for _, entity in pairs(spawnedProps) do
        DeleteEntity(entity)
    end

    for _, entity in pairs(collisionProps) do
        DeleteEntity(entity)
    end

    for _, linkedInfo in pairs(linkedPropsTable) do
        DeleteEntity(linkedInfo.entity)
    end

    updateTextUI(nil)
    enableDefaultEntitySet()
    debugPrint("[COMPOUND] Resource stopped - restored default entity set")
end)

-- ── Wspólna permisja ACE dla komend pakietu Prompt Sandy Shores ─────
-- Wszystkie komendy diagnostyczne/admin z tego repo sprawdzają JEDEN obiekt
-- ACE: command.sandyshores (ANALIZA.md, rozdz. 11). Konfiguracja serwera:
--   add_ace group.admin command.sandyshores allow
--   add_principal identifier.license:XXXX group.admin
-- Na kliencie poprawną natywką jest IsAceAllowed (IsPlayerAceAllowed to API
-- serwerowe — patrz ustalenie 7.4).
local SANDY_COMMAND_ACE = "command.sandyshores"

local function canUseSandyCommand()
    if IsAceAllowed(SANDY_COMMAND_ACE) then
        return true
    end
    print("^1[SANDY] Missing ACE permission: " .. SANDY_COMMAND_ACE .. "^0")
    return false
end

-- Komenda testowa: /testsound
RegisterCommand("testsound", function(source, args)
    if not canUseSandyCommand() then
        return
    end
    if #args < 2 then
        print("[SOUND] Usage: /testsound <audioName> <audioRef> [spatial]")
        print("[SOUND] Example: /testsound BOLT_LOCK GTAO_APT_DOOR_SOUNDS")
        print("[SOUND] Add \"3d\" as 3rd arg for spatial at player coords")
        return
    end

    local audioName = args[1]
    local audioRef = args[2]
    local is3D = args[3] == "3d"

    if is3D then
        local playerCoords = GetEntityCoords(PlayerPedId())
        PlaySoundFromCoord(-1, audioName, playerCoords.x, playerCoords.y, playerCoords.z, audioRef, true, 0, false)
        print("[SOUND] PlaySoundFromCoord: " .. audioName .. " / " .. audioRef)
    else
        PlaySoundFrontend(-1, audioName, audioRef, true)
        print("[SOUND] PlaySoundFrontend: " .. audioName .. " / " .. audioRef)
    end
end, false)

-- Komenda testowa: /testautodoors_flow
RegisterCommand("testautodoors_flow", function()
    if not canUseSandyCommand() then
        return
    end
    if not Config.AutoOpen then
        print("^1[TEST] Config.AutoOpen is false — cannot run flow test^0")
        return
    end

    CreateThread(function()
        local ped = PlayerPedId()
        local passedTests = 0
        local failedTests = 0
        local resultsLog = {}

        local function logTest(testName, success)
            if success then
                passedTests = passedTests + 1
                table.insert(resultsLog, "^2  PASS^0: " .. testName)
            else
                failedTests = failedTests + 1
                table.insert(resultsLog, "^1  FAIL^0: " .. testName)
            end
        end

        local function logInfo(msg)
            print("[TEST] " .. msg)
        end

        local targetRollupName = "garage_rollup_1"
        local rollupConfig = Config.Props.garage_rollup_1
        local zoneCoords = rollupConfig.interactionZone.coords
        local outsideCoords = vector3(zoneCoords.x + 20.0, zoneCoords.y, zoneCoords.z)
        -- Poza właściwą strefą (nie wyzwala auto-open), ale w zasięgu
        -- serwerowej walidacji dystansu dla toggleLock.
        local nearbyCoords = vector3(zoneCoords.x + 8.0, zoneCoords.y, zoneCoords.z)

        logInfo("^3========== Full-Flow Auto-Door Test (Mechanic) ==========^0")
        logTest("isGarageRollup client helper works", isGarageRollup("garage_rollup_1") == true)
        logTest("isGarageRollup rejects lifts", isGarageRollup("prompt_sandy_is_lift_2") == false)

        logInfo("Step 1: Teleporting outside zone...")
        SetEntityCoordsNoOffset(ped, outsideCoords.x, outsideCoords.y, outsideCoords.z, false, false, false)
        Wait(500)

        local locks = GlobalState.sandy_compound_locks or {}
        logTest("Door starts locked", locks[targetRollupName] == true)

        local propStates = GlobalState.sandy_compound or {}
        logTest("Door starts closed", not propStates[targetRollupName])

        logInfo("Step 2: Teleporting into zone (door locked)...")
        SetEntityCoordsNoOffset(ped, zoneCoords.x, zoneCoords.y, zoneCoords.z, false, false, false)
        Wait(1500)

        propStates = GlobalState.sandy_compound or {}
        logTest("Locked door does NOT auto-open", not propStates[targetRollupName])

        logInfo("Step 3: Teleporting out...")
        SetEntityCoordsNoOffset(ped, outsideCoords.x, outsideCoords.y, outsideCoords.z, false, false, false)
        Wait(1000)

        logInfo("Step 4: Unlocking door (near, but outside the auto-open zone)...")
        SetEntityCoordsNoOffset(ped, nearbyCoords.x, nearbyCoords.y, nearbyCoords.z, false, false, false)
        Wait(500)
        TriggerServerEvent("compound_anims:toggleLock", targetRollupName)
        Wait(1000)

        locks = GlobalState.sandy_compound_locks or {}
        logTest("Door is now unlocked", locks[targetRollupName] == false)

        logInfo("Step 5: Teleporting into zone (door unlocked)...")
        SetEntityCoordsNoOffset(ped, zoneCoords.x, zoneCoords.y, zoneCoords.z, false, false, false)
        Wait(2000)

        propStates = GlobalState.sandy_compound or {}
        logTest("Unlocked door auto-opens on zone enter", propStates[targetRollupName] == true)

        logInfo("Step 6: Waiting for animation to finish...")
        local startTime = GetGameTimer()
        while true do
            local busy = GlobalState.sandy_compound_busy or {}
            if not busy[targetRollupName] then break end
            if GetGameTimer() - startTime > 8000 then break end
            Wait(200)
        end

        local busyState = GlobalState.sandy_compound_busy or {}
        logTest("Busy flag clears after animation", not busyState[targetRollupName])

        logInfo("Step 7: Teleporting out of zone...")
        SetEntityCoordsNoOffset(ped, outsideCoords.x, outsideCoords.y, outsideCoords.z, false, false, false)
        Wait(Config.AutoOpenCloseDelay + 2000)

        propStates = GlobalState.sandy_compound or {}
        logTest("Door auto-closes after leaving zone", not propStates[targetRollupName])

        logInfo("Step 8: Re-locking door (cleanup, near but outside the auto-open zone)...")
        local relockStart = GetGameTimer()
        while true do
            local busyAfterClose = GlobalState.sandy_compound_busy or {}
            if not busyAfterClose[targetRollupName] then break end
            if GetGameTimer() - relockStart > 8000 then break end
            Wait(200)
        end
        SetEntityCoordsNoOffset(ped, nearbyCoords.x, nearbyCoords.y, nearbyCoords.z, false, false, false)
        Wait(500)
        TriggerServerEvent("compound_anims:toggleLock", targetRollupName)
        Wait(1000)

        locks = GlobalState.sandy_compound_locks or {}
        logTest("Door re-locked for cleanup", locks[targetRollupName] == true)

        logInfo("^3---------- Results ----------^0")
        for _, logLine in ipairs(resultsLog) do
            print("[TEST] " .. logLine)
        end

        logInfo(string.format("^3========== %d passed, %d failed ==========^0", passedTests, failedTests))
        lib.notify({
            description = string.format("Auto-door flow test: %d passed, %d failed", passedTests, failedTests),
            type = failedTests == 0 and "success" or "error",
            duration = 8000
        })
    end)
end, false)

-- Główny wątek inicjalizujący skrypt
-- (stan początkowy GlobalState ustawia wyłącznie serwer przy starcie)
CreateThread(function()
    createInteractionZones()
    createSpawnPoints()
    registerPropStateHandlers()
    debugPrint("[COMPOUND ANIMS ENABLED] Sistema de props animados iniciado.")
end)

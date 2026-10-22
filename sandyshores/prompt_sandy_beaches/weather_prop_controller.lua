---------------------------------------------------------------------
-- PROMPT SANDY BEACHES (Marina) — Dynamiczne propy pogodowe (client)
-- Przełącza wariant propa przy rampie łodzi (1406.15, 3703.76, 35.14)
-- w zależności od aktualnej pogody, pory dnia i odległości gracza.
--
-- Plik przepisany z zapisu dekompilatora na czytelny kod Lua.
-- Zachowano wszystkie modele, współrzędne, warunki pogodowe/czasowe
-- oraz funkcje globalne (isWithinTimeRange, spawnProp, despawnProp,
-- getPlayerPosition). Patrz ANALIZA.md, rozdz. 14.
--
-- Poprawki bezpieczeństwa wykonania względem zapisu dekompilatora:
--   * Vdist dostaje jawnie 6 współrzędnych (x1, y1, z1, x2, y2, z2)
--     zamiast polegać na niejawnym rozwijaniu vector3 przez runtime.
--   * Ładowanie modelu ma limit czasu (5000 ms) oraz zwalnia model
--     przez SetModelAsNoLongerNeeded, dzięki czemu brakujący model
--     nie zawiesi wątku w nieskończonej pętli Wait(1).
--   * Dodano sprzątanie zespawnowanych propów przy onResourceStop.
---------------------------------------------------------------------

Config = Config or {}

local MODEL_LOAD_TIMEOUT_MS = 5000

local weatherProps = {
    [1] = {
        propModel = "prompt_sandy_boatramp_dweather_sunny",
        spawnCoords = vector4(1406.14893, 3703.760578, 35.143572, 1.0),
        currentProp = nil,
        weatherTypesToDespawn = {
            "RAIN",
            "THUNDER",
            "BLIZZARD"
        },
        freeze = true,
        checkWeather = true,
        checkTime = true,
        startHour = 5,
        endHour = 20,
        distanceCheck = true,
        maxDistance = 50.0
    },
    [2] = {
        propModel = "prompt_sandy_boatramp_dweather_rainy",
        spawnCoords = vector4(1406.14893, 3703.760578, 35.143572, 1.0),
        currentProp = nil,
        weatherTypesToDespawn = {
            "CLEAR",
            "EXTRASUNNY",
            "CLOUDS",
            "OVERCAST",
            "THUNDER",
            "CLEARING",
            "SMOG",
            "FOGGY",
            "XMAS",
            "SNOW",
            "SNOWLIGHT",
            "NEUTRAL",
            "BLIZZARD"
        },
        freeze = false,
        checkWeather = true,
        checkTime = false,
        distanceCheck = true,
        maxDistance = 50.0
    },
    [3] = {
        propModel = "prompt_sandy_boatramp_dweather_storm",
        spawnCoords = vector4(1406.14893, 3703.760578, 35.143572, 1.0),
        currentProp = nil,
        weatherTypesToDespawn = {
            "CLEAR",
            "EXTRASUNNY",
            "CLOUDS",
            "OVERCAST",
            "RAIN",
            "CLEARING",
            "SMOG",
            "FOGGY",
            "XMAS",
            "SNOW",
            "SNOWLIGHT",
            "NEUTRAL"
        },
        freeze = false,
        checkWeather = true,
        checkTime = false,
        distanceCheck = true,
        maxDistance = 50.0
    },
    [4] = {
        propModel = "prompt_sandy_boatramp_dweather_moon_clear",
        spawnCoords = vector4(1406.14893, 3703.760578, 35.143572, 1.0),
        currentProp = nil,
        weatherTypesToDespawn = {
            "THUNDER",
            "STORM"
        },
        freeze = true,
        checkWeather = true,
        checkTime = true,
        startHour = 20,
        endHour = 6,
        distanceCheck = true,
        maxDistance = 50.0
    }
}

-- Sprawdza, czy currentHour mieści się w przedziale [startHour, endHour),
-- z obsługą zakresów przechodzących przez północ (np. 20 -> 6).
function isWithinTimeRange(currentHour, startHour, endHour)
    if startHour <= endHour then
        return currentHour >= startHour and currentHour < endHour
    else
        return currentHour >= startHour or currentHour < endHour
    end
end

function spawnProp(propData)
    if propData.currentProp ~= nil then
        if Config.Debug then
            print("Prop already spawned:", propData.propModel)
        end
        return
    end

    local coords = propData.spawnCoords
    if Config.Debug then
        print("Spawning prop:", propData.propModel)
        print("Spawn coordinates: x=" .. coords.x .. ", y=" .. coords.y .. ", z=" .. coords.z .. ", heading=" .. coords.w)
    end

    local modelHash = GetHashKey(propData.propModel)
    if IsModelInCdimage and not IsModelInCdimage(modelHash) then
        if Config.Debug then
            print("Model not found in cdimage:", propData.propModel)
        end
        return
    end

    RequestModel(modelHash)
    local waitedMs = 0
    while not HasModelLoaded(modelHash) do
        if waitedMs >= MODEL_LOAD_TIMEOUT_MS then
            if Config.Debug then
                print("Timed out loading model:", propData.propModel)
            end
            return
        end
        Wait(1)
        waitedMs = waitedMs + 1
    end

    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, true)
    if SetModelAsNoLongerNeeded then
        SetModelAsNoLongerNeeded(modelHash)
    end

    if not obj or obj == 0 then
        return
    end

    propData.currentProp = obj
    SetEntityAsMissionEntity(obj, true, true)
    SetEntityRotation(obj, 0.0, 0.0, coords.w, 2, true)

    if Config.Debug then
        print("Prop spawned:", propData.propModel)
        if propData.freeze then
            print("Prop is frozen in position")
        end
    end

    if propData.freeze then
        FreezeEntityPosition(obj, true)
    end
end

function despawnProp(propData)
    if propData.currentProp ~= nil then
        if Config.Debug then
            print("Despawning prop:", propData.propModel)
        end
        if not DoesEntityExist or DoesEntityExist(propData.currentProp) then
            DeleteObject(propData.currentProp)
        end
        propData.currentProp = nil
        if Config.Debug then
            print("Prop despawned:", propData.propModel)
        end
    else
        if Config.Debug then
            print("No prop to despawn:", propData.propModel)
        end
    end
end

function getPlayerPosition()
    local ped = PlayerPedId()
    return GetEntityCoords(ped)
end

-- Główna pętla kontrolera pogody i pory dnia (co 5 sekund)
Citizen.CreateThread(function()
    while true do
        Wait(5000)

        local currentWeatherHash = GetPrevWeatherTypeHashName()
        local currentHour = GetClockHours()
        local playerCoords = getPlayerPosition()

        if Config.Debug then
            print("Current weather:", currentWeatherHash)
            print("Current hour:", currentHour)
            print("playercoords:", playerCoords)
        end

        local selectedProp = nil

        for _, propData in ipairs(weatherProps) do
            local shouldDespawn = false

            if propData.distanceCheck then
                local coords = propData.spawnCoords
                local distance = Vdist(
                    playerCoords.x, playerCoords.y, playerCoords.z,
                    coords.x, coords.y, coords.z
                )
                if distance > propData.maxDistance then
                    shouldDespawn = true
                end
            end

            if not shouldDespawn then
                if propData.checkWeather then
                    for _, weatherName in ipairs(propData.weatherTypesToDespawn) do
                        if GetHashKey(weatherName) == currentWeatherHash then
                            shouldDespawn = true
                            break
                        end
                    end
                end

                if propData.checkTime and not isWithinTimeRange(currentHour, propData.startHour, propData.endHour) then
                    shouldDespawn = true
                end
            end

            if not shouldDespawn then
                selectedProp = propData
                break
            end
        end

        for _, propData in ipairs(weatherProps) do
            if propData == selectedProp then
                if propData.currentProp == nil then
                    spawnProp(propData)
                end
            else
                if propData.currentProp ~= nil then
                    despawnProp(propData)
                end
            end
        end
    end
end)

-- Sprzątanie zespawnowanych encji przy zatrzymaniu/restarcie zasobu
if AddEventHandler then
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then
            return
        end
        for _, propData in ipairs(weatherProps) do
            if propData.currentProp ~= nil then
                despawnProp(propData)
            end
        end
    end)
end

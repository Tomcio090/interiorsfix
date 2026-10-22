-- ── Prompt mapdata: lokalna rejestracja mapy (bez sv_loader.lua) ─────────
-- Rejestruje WYŁĄCZNIE handlery wykrywania używane przez oficjalny checker
-- Prompt mapdata oraz lokalny raport z prompt_sandy_illegal_garage.
-- Nic nie jest pobierane z sieci ani wykonywane zdalnie, brak telemetrii.
--
-- Callback z innego zasobu jest referencja funkcyjna FXServera, dlatego
-- nie filtrujemy go przez type(cb) == "function"; wywołanie chroni pcall.

local MAP_ID = "prompt_sandy_compound" -- static w rejestrze all_data_full
local MAP_NAME = "Mechanic"
local MAP_LOCATIONS = { "sandy" }

local function replyExists(cb)
    if cb ~= nil then pcall(cb, true) end
end

RegisterNetEvent(MAP_ID .. ":mapExists", replyExists)
RegisterNetEvent("promptmap:i_exist_" .. MAP_ID, replyExists)

RegisterNetEvent("promptmap:locations_" .. MAP_ID, function(cb)
    if cb ~= nil then pcall(cb, MAP_LOCATIONS) end
end)

AddEventHandler(MAP_ID .. ":mapFullNameSend", function(returnEvent, id)
    if type(returnEvent) == "string" then
        TriggerEvent(returnEvent, MAP_NAME, id)
    end
end)

RegisterNetEvent(MAP_ID .. ":mapFinal", function() end)

print(("[%s] Prompt mapdata: zarejestrowano wykrywanie mapy %s (%s)"):format(
    GetCurrentResourceName(), MAP_NAME, MAP_ID))

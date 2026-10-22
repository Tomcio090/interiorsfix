-- ── Prompt mapdata: lokalna rejestracja mapy (bez sv_loader.lua) ─────────
-- Świadomy zamiennik sv_loadera. Rejestruje WYŁĄCZNIE handlery wykrywania,
-- których oficjalny checker mapdata (Prompt-Coder/mapdatachecker) używa do
-- rozpoznawania zainstalowanych map — lokalnymi eventami serwerowymi
-- "<static>:mapExists" z callbackiem (static = MapId z rejestru all_data_full).
--
-- Nic nie jest pobierane z sieci ani wykonywane zdalnie, brak telemetrii.
-- Oryginalny sv_loader pobierał i `load()`-ował mutowalny skrypt z GitHuba,
-- który przy jawnej (odszyfrowanej) kopii dodatkowo wysyłał dane serwera
-- (nazwa hosta, projekt, konto CFX z bufora konsoli) na
-- prompt-mapdata-api.vertex-hub.com — patrz ANALIZA.md, rozdz. 7.1 i 9.4.
--
-- Callback checkera przychodzi z INNEGO zasobu jako referencja funkcyjna
-- FXServera: type(cb) nie musi zwracać "function", mimo że wartość jest
-- wywoływalna. Odpowiadamy jak oficjalny skrypt (wołanie wprost), ale przez
-- pcall, żeby śmieciowy argument z eventu sieciowego niczego nie wywalił.

local MAP_ID = "prompt_sandy_market" -- static w rejestrze all_data_full
local MAP_NAME = "Market"
local MAP_LOCATIONS = { "sandy" }

local function replyExists(cb)
    if cb ~= nil then pcall(cb, true) end
end

-- Wykrywanie (pyta oficjalny checker oraz lokalny raport z prompt_sandy_illegal_garage)
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

-- Parzystość 1:1 z oficjalnym skryptem (legacy "final" = pusty handler;
-- raport drukuje ostatnia wykryta mapa albo prompt_sandy_illegal_garage).
RegisterNetEvent(MAP_ID .. ":mapFinal", function() end)

print(("[%s] Prompt mapdata: zarejestrowano wykrywanie mapy %s (%s)"):format(
    GetCurrentResourceName(), MAP_NAME, MAP_ID))

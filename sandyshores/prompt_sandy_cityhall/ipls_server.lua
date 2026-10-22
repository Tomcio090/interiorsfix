-- ── ACE + walidacja — zmiany stanu IPL/EntitySets (ANALIZA.md, rozdz. 11/13) ──
-- Stan GlobalState.ipls / GlobalState.entitySets zmieniają się TYLKO z
-- eventów wysyłanych przez klienta, więc (wzór z prompt_sandy_market,
-- rozdz. 10/11):
--   1. ACE command.sandyshores — IsPlayerAceAllowed(source, ACE),
--      kontrola serwerowa (kontrola klienta w ipls_command.lua jest tylko
--      UX, tę tu wykonujemy ostatecznie);
--   2. walidacja nazwy — znane 12 IPL i 4 entity sets (lista 1:1 z
--      inicjalizacją poniżej). Sfałszowany klient mógłby wpisać do
--      statebag dowolny klucz, a statebag jest replikowany do wszystkich.
local SANDY_COMMAND_ACE = "command.sandyshores"

local KNOWN_IPLS = {
    p_prompt_sandy_cityhall_fences_backopened = true,
    p_prompt_sandy_cityhall_backtables = true,
    p_prompt_sandy_cityhall_tables = true,
    p_prompt_sandy_cityhall_coffin_closed = true,
    p_prompt_sandy_cityhall_coffin_opened = true,
    p_prompt_sandy_cityhall_fences_backclosed = true,
    p_prompt_sandy_cityhall_funeral_chairs = true,
    p_prompt_sandy_cityhall_funeral_picture = true,
    p_prompt_sandy_cityhall_leaves = true,
    p_prompt_sandy_cityhall_wedding_chairs = true,
    p_prompt_sandy_cityhall_wedding_spotlight = true,
    p_prompt_sandy_cityhall_wedding_venue = true,
}

local KNOWN_ENTITY_SETS = {
    static_elevator = true,
    conference_chairs = true,
    conference_meeting_table = true,
    eventroom_voting = true,
}

local function playerCanManageIPLs(playerId)
    if type(playerId) == "number" and playerId > 0 and IsPlayerAceAllowed(playerId, SANDY_COMMAND_ACE) then
        return true
    end
    print(("^1[CITYHALL IPLS] Odrzucono żądanie zmiany stanu bez ACE %s (gracz %s)^0"):format(
        SANDY_COMMAND_ACE, tostring(playerId)))
    return false
end

-- Inicializar estados en GlobalState
CreateThread(function()
    -- IPLs
    if not GlobalState.ipls then
        GlobalState.ipls = {
            p_prompt_sandy_cityhall_fences_backopened = false,
            p_prompt_sandy_cityhall_backtables = false,
            p_prompt_sandy_cityhall_tables = false,
            p_prompt_sandy_cityhall_coffin_closed = false,
            p_prompt_sandy_cityhall_coffin_opened = false,
            p_prompt_sandy_cityhall_fences_backclosed = false,
            p_prompt_sandy_cityhall_funeral_chairs = false,
            p_prompt_sandy_cityhall_funeral_picture = false,
            p_prompt_sandy_cityhall_leaves = false,
            p_prompt_sandy_cityhall_wedding_chairs = false,
            p_prompt_sandy_cityhall_wedding_spotlight = false,
            p_prompt_sandy_cityhall_wedding_venue = false
        }
    end

    -- Entity Sets
    if not GlobalState.entitySets then
        GlobalState.entitySets = {
            static_elevator = false,
            conference_chairs = false,
            conference_meeting_table = false,
            eventroom_voting = false
        }
    end
end)

-- Event handlers para actualizar GlobalState
RegisterNetEvent('ipls:sync:toggleIPL', function(ipl, state)
    if not playerCanManageIPLs(source) then
        return
    end
    if type(ipl) ~= "string" or not KNOWN_IPLS[ipl] then
        print(("^1[CITYHALL IPLS] Nieznany IPL od gracza %s: %s^0"):format(
            tostring(source), tostring(ipl)))
        return
    end
    -- Zabezpieczenie wyścigu: event przed inicjalizacją statebag (oryginał
    -- wywalał błąd na nil, stan i tak by się nie zmienił)
    local ipls = GlobalState.ipls
    if not ipls then
        return
    end
    -- Normalizacja do boola (legalny klient i tak zawsze syła bool)
    ipls[ipl] = state and true or false
    GlobalState.ipls = ipls
end)

RegisterNetEvent('ipls:sync:toggleEntitySet', function(entitySet, state)
    if not playerCanManageIPLs(source) then
        return
    end
    if type(entitySet) ~= "string" or not KNOWN_ENTITY_SETS[entitySet] then
        print(("^1[CITYHALL IPLS] Nieznany entity set od gracza %s: %s^0"):format(
            tostring(source), tostring(entitySet)))
        return
    end
    local entitySets = GlobalState.entitySets
    if not entitySets then
        return
    end
    entitySets[entitySet] = state and true or false
    GlobalState.entitySets = entitySets
end)

-- ============================================================================
-- SANDY SHORES APARTMENTS — DEBUG COMMANDS (only when Config.Debug = true)
-- ============================================================================
-- Source-confirmed facts (RAGE engine CInteriorProxy / CPortalInst):
--   - Each MLO placement consumes its own pool slot (no sharing)
--   - DisableInterior just sets a flag — does NOT free pool slots
--   - Only RemoveIpl / not streaming the ymap frees pool slots
--   - PortalInst pool = CONFIGURED_FROM_FILE with 0.34 spillover
-- ============================================================================

if not Config or not Config.Debug then
    return
end

-- ============================================================================
-- HELPERS
-- ============================================================================

local function DistanceTo(px, py, pz, x, y, z)
    return math.sqrt((px - x) ^ 2 + (py - y) ^ 2 + (pz - z) ^ 2)
end

local function AllIplEntries()
    local list = {}
    for _, ipl in ipairs(Config.IplLocations or {}) do
        list[#list + 1] = { name = ipl.name, x = ipl.x, y = ipl.y, z = ipl.z, kind = "apt" }
    end
    for _, ipl in ipairs(Config.AdditionalProximityIPLs or {}) do
        if ipl.name and ipl.x and ipl.y and ipl.z then
            list[#list + 1] = { name = ipl.name, x = ipl.x, y = ipl.y, z = ipl.z, kind = "add" }
        end
    end
    return list
end

local function FormatBool(b)
    if b then return "^2true^7" else return "^1false^7" end
end

-- ============================================================================
-- /apts_status — full state dump
-- ============================================================================

RegisterCommand("apts_status", function()
    local pc = GetEntityCoords(PlayerPedId())
    local entries = AllIplEntries()

    local activeIpl, intLoaded, intReady, intDisabled, intCapped = 0, 0, 0, 0, 0

    print("^5======================================================^7")
    print("^5[APTS_STATUS]^7 IPL / interior state dump")
    print("^5======================================================^7")
    print(("^5Player pos:^7 %.2f %.2f %.2f"):format(pc.x, pc.y, pc.z))
    print(("^5IPL entries to check:^7 %d apartments + %d additional"):format(
        #(Config.IplLocations or {}), #(Config.AdditionalProximityIPLs or {})))
    print("")
    print("^5Idx Kind IPLName                                             Dist    Act Int Col Rdy Dis Cap^7")
    print("^5--- ---- --------------------------------------------------- ------- --- --- --- --- --- ---^7")

    for i, e in ipairs(entries) do
        local dist = DistanceTo(pc.x, pc.y, pc.z, e.x, e.y, e.z)
        local active = IsIplActive(e.name)
        local intId = GetInteriorAtCoords(e.x, e.y, e.z)
        local colInt = GetInteriorFromCollision(e.x, e.y, e.z)
        local ready = intId ~= 0 and IsInteriorReady(intId)
        local disabled = intId ~= 0 and IsInteriorDisabled(intId)
        local capped = intId ~= 0 and IsInteriorCapped(intId)

        if active then activeIpl = activeIpl + 1 end
        if intId ~= 0 then intLoaded = intLoaded + 1 end
        if ready then intReady = intReady + 1 end
        if disabled then intDisabled = intDisabled + 1 end
        if capped then intCapped = intCapped + 1 end

        local shortName = e.name
        if #shortName > 51 then shortName = shortName:sub(1, 48) .. "..." end
        print(("%3d %-4s %-51s %7.1f %-3s %3d %3d %-3s %-3s %-3s"):format(
            i, e.kind, shortName, dist,
            active and "Y" or "-",
            intId, colInt,
            ready and "Y" or "-",
            disabled and "Y" or "-",
            capped and "Y" or "-"))
    end

    print("^5--- ---- --------------------------------------------------- ------- --- --- --- --- --- ---^7")
    print(("^5Totals:^7 IPL active=^2%d^7  resolved=^2%d^7  Ready=^2%d^7  Disabled=^2%d^7  Capped=^2%d^7"):format(
        activeIpl, intLoaded, intReady, intDisabled, intCapped))
    print("^5======================================================^7")
end, false)

-- ============================================================================
-- /apts_here — interior context at player position
-- ============================================================================

RegisterCommand("apts_here", function()
    local playerPed = PlayerPedId()
    local pc = GetEntityCoords(playerPed)

    local fromEntity = GetInteriorFromEntity(playerPed)
    local atCoords = GetInteriorAtCoords(pc.x, pc.y, pc.z)
    local fromCollision = GetInteriorFromCollision(pc.x, pc.y, pc.z)

    print("^5======================================================^7")
    print("^5[APTS_HERE]^7 interior context at player position")
    print("^5======================================================^7")
    print(("^5Pos:^7 %.2f %.2f %.2f"):format(pc.x, pc.y, pc.z))
    print(("^5GetInteriorFromEntity:^7  %d"):format(fromEntity))
    print(("^5GetInteriorAtCoords:^7    %d"):format(atCoords))
    print(("^5GetInteriorFromCollision:^7 %d"):format(fromCollision))

    local function Describe(label, id)
        if id == 0 then return end
        local valid = IsValidInterior(id)
        local ready = IsInteriorReady(id)
        local disabled = IsInteriorDisabled(id)
        local capped = IsInteriorCapped(id)
        local groupId = GetInteriorGroupId(id)
        print(("^5  %s %d:^7 valid=%s ready=%s disabled=%s capped=%s group=%d"):format(
            label, id, FormatBool(valid), FormatBool(ready), FormatBool(disabled),
            FormatBool(capped), groupId or -1))
    end

    Describe("fromEntity", fromEntity)
    if atCoords ~= fromEntity then Describe("atCoords  ", atCoords) end
    if fromCollision ~= atCoords and fromCollision ~= fromEntity then
        Describe("collision ", fromCollision)
    end

    if fromCollision ~= 0 and atCoords == 0 then
        print("^1[WARNING]^7 Collision loaded but no interior resolved — ymap collision streams without IPL!")
    end

    local closest, closestDist = nil, math.huge
    for _, ipl in ipairs(Config.IplLocations or {}) do
        local d = DistanceTo(pc.x, pc.y, pc.z, ipl.x, ipl.y, ipl.z)
        if d < closestDist then closestDist = d; closest = ipl end
    end
    if closest then
        print(("^5Closest apartment IPL:^7 %s (%.1f units)"):format(closest.name, closestDist))
    end
    print("^5======================================================^7")
end, false)

-- ============================================================================
-- /apts_stream — streaming + IPL summary
-- ============================================================================

RegisterCommand("apts_stream", function()
    local pc = GetEntityCoords(PlayerPedId())
    local c = Config.ApartmentCenter or { x = 0, y = 0, z = 0 }
    local distToCenter = DistanceTo(pc.x, pc.y, pc.z, c.x, c.y, c.z)
    local streamReq = GetNumberOfStreamingRequests()

    local activeIpl, loadedInt = 0, 0
    for _, e in ipairs(AllIplEntries()) do
        if IsIplActive(e.name) then activeIpl = activeIpl + 1 end
        if GetInteriorAtCoords(e.x, e.y, e.z) ~= 0 then loadedInt = loadedInt + 1 end
    end

    local strategy = Config.Strategy or "auto_stream_only"

    print("^5======================================================^7")
    print("^5[APTS_STREAM]^7 streaming & IPL summary")
    print("^5======================================================^7")
    print(("^5Strategy:^7               %s"):format(strategy))
    print(("^5ProximityEnabled:^7       %s"):format(FormatBool(Config.ProximityEnabled)))
    print(("^5MaxConcurrentInteriors:^7 %d"):format(Config.MaxConcurrentInteriors or 0))
    print(("^5Distance to center:^7     %.1f"):format(distToCenter))
    print(("^5Streaming requests:^7     %d"):format(streamReq))
    print(("^5IPLs active:^7            %d / %d"):format(activeIpl, #AllIplEntries()))
    print(("^5Placements resolved:^7    %d / %d (each eats its own pool slot)"):format(loadedInt, #AllIplEntries()))
    print("^5======================================================^7")
end, false)

-- ============================================================================
-- /apts_nuke — aggressive RemoveIpl on everything
-- ============================================================================

RegisterCommand("apts_nuke", function()
    local entries = AllIplEntries()
    local beforeActive = 0
    for _, e in ipairs(entries) do
        if IsIplActive(e.name) then beforeActive = beforeActive + 1 end
    end

    for _, e in ipairs(entries) do
        RemoveIpl(e.name)
    end

    Citizen.Wait(200)

    local afterActive = 0
    for _, e in ipairs(entries) do
        if IsIplActive(e.name) then afterActive = afterActive + 1 end
    end

    print(("^5[APTS_NUKE]^7 RemoveIpl on all %d. Active before=%d after=%d"):format(
        #entries, beforeActive, afterActive))
    if afterActive > 0 then
        print("^1[APTS_NUKE]^7 Some IPLs survived — engine re-streamed them (this_is_a_map + extents)")
    end
end, false)

-- ============================================================================
-- /apts_tp <idx> — teleport to IPL by index
-- ============================================================================

RegisterCommand("apts_tp", function(source, args)
    local idx = tonumber(args[1])
    if not idx then
        print("^1[APTS_TP]^7 Usage: /apts_tp <index>  (see /apts_status for list)")
        return
    end
    local entries = AllIplEntries()
    local entry = entries[idx]
    if not entry then
        print(("^1[APTS_TP]^7 Invalid index %d (max %d)"):format(idx, #entries))
        return
    end
    SetEntityCoords(PlayerPedId(), entry.x, entry.y, entry.z + 1.0, false, false, false, false)
    print(("^5[APTS_TP]^7 Teleported to #%d %s"):format(idx, entry.name))
end, false)

-- ============================================================================
-- STARTUP
-- ============================================================================

CreateThread(function()
    Wait(4000)
    print("^5[APTS_DEBUG]^7 Debug commands loaded: /apts_status /apts_here /apts_stream /apts_nuke /apts_tp")
end)

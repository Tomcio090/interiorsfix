-- ============================================================
-- Seat Occupancy Manager – Server-side
-- Bulletproof state tracking: handles disconnects, crashes,
-- and resource restarts. Simple table + ox_lib callbacks.
-- ============================================================

-- occupiedSeats[seatId] = serverId (number) or nil
local occupiedSeats = {}

-- Reverse lookup: playerSeat[serverId] = seatId or nil
local playerSeat = {}

--- Check if a seat is available (not occupied and no conflicts occupied).
--- @param seatId number
--- @return boolean available
--- @return string|nil reason  'occupied' | 'blocked' | nil
local function isSeatAvailable(seatId)
    -- Direct check
    if occupiedSeats[seatId] then
        return false, 'occupied'
    end

    -- Conflict check
    local seat = CouchConfig.seats[seatId]
    if seat and seat.conflicts then
        for _, conflictId in ipairs(seat.conflicts) do
            if occupiedSeats[conflictId] then
                return false, 'blocked'
            end
        end
    end

    return true, nil
end

--- Reserve a seat for a player.
--- @param seatId number
--- @param serverId number
--- @return boolean success
--- @return string|nil reason
local function reserveSeat(seatId, serverId)
    -- Player already sitting somewhere? Release first.
    if playerSeat[serverId] then
        releaseSeat(serverId)
    end

    local available, reason = isSeatAvailable(seatId)
    if not available then
        return false, reason
    end

    occupiedSeats[seatId] = serverId
    playerSeat[serverId]  = seatId
    return true, nil
end

--- Release whatever seat a player is on.
--- @param serverId number
function releaseSeat(serverId)
    local seatId = playerSeat[serverId]
    if seatId then
        occupiedSeats[seatId] = nil
        playerSeat[serverId]  = nil
    end
end

-- ────────────────────────────────────────────────────────────
-- Callbacks (ox_lib)
-- ────────────────────────────────────────────────────────────

--- Client asks to sit on a seat.
--- Returns: success (bool), reason (string|nil)
lib.callback.register('seats:request', function(source, seatId)
    if type(seatId) ~= 'number' then return false, 'invalid' end
    if seatId < 1 or seatId > #CouchConfig.seats then return false, 'invalid' end

    return reserveSeat(seatId, source)
end)

--- Client tells server they got up.
lib.callback.register('seats:release', function(source)
    releaseSeat(source)
    return true
end)

--- Client can query if a seat is free (for canInteract checks).
lib.callback.register('seats:isAvailable', function(_, seatId)
    if type(seatId) ~= 'number' then return false end
    local available = isSeatAvailable(seatId)
    return available
end)

-- ────────────────────────────────────────────────────────────
-- Cleanup: player disconnect / crash
-- ────────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    releaseSeat(source)
end)

-- ────────────────────────────────────────────────────────────
-- Cleanup: resource stop
-- ────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    occupiedSeats = {}
    playerSeat    = {}
end)

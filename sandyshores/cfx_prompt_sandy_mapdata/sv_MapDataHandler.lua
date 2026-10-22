local maps = {
	"prompt_sandy_roads",
	"prompt_sandy_fire2",
	"prompt_sandy_hospital2",
	"prompt_sandy_corner",
	"prompt_sandy_apts",
	"prompt_sandy_bank",
	"prompt_sandy_market",
	"prompt_sandy_gasstation_carwash",
	"prompt_sandy_compound",
	"prompt_sandy_church",
	"prompt_sandy_classic_car_dealership",
	"prompt_sandy_cityhall",
	"sandy_shores_houses_pt1",
	"prompt_sandy_beaches",
	"cfx_chuz_sandy_shores_boat_house",
	"prompt_sandy_sheriff"
}

local events = {}

-- Bezpieczne wywołanie callbacku z eventu: referencja funkcyjna z innego
-- zasobu nie musi mieć type()=="function", a śmieciowy argument nie może
-- wywalić handlera.
local function replyTrue(cb)
	if cb ~= nil then pcall(cb, true) end
end

-- Sandy mapdata exists event
RegisterNetEvent("prompt:mapdata_exists", replyTrue)

-- Sandy mapdata list event
RegisterNetEvent("prompt:mapdata_sendList", function(returnevent)
	if type(returnevent) ~= "string" then return end
	if not returnevent:find("^promptmap:return_") then return end
	TriggerEvent(returnevent, maps)
end)

-- Legacy mapdata exists event
RegisterNetEvent("lyn-mapdata:exists", replyTrue)

-- Legacy support for individual map checks
for i = 1, #maps do
  local eventName = maps[i] .. ":mapDataExists"
  if Debug == true then
    print("Creating event: ", eventName)
  end
  local event = RegisterNetEvent(eventName, replyTrue)
  table.insert(events, event)
end

local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = CreateThread
function L1_1()
  local L0_2, L1_2
  L0_2 = GlobalState
  L1_2 = {}
  L1_2.currentFloor = 1
  L1_2.targetFloor = nil
  L1_2.isMoving = false
  L1_2.doorsOpen = true
  L0_2.elevator = L1_2
end
L0_1(L1_1)
L0_1 = false
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = false
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = pcall
    L1_3 = lib
    L1_3 = L1_3.callback
    L1_3 = L1_3.await
    L2_3 = "elevator:playerDoorAnimation"
    L3_3 = A0_2
    L4_3 = A1_2
    L0_3(L1_3, L2_3, L3_3, L4_3)
    L0_3 = true
    L2_2 = L0_3
  end
  L3_2(L4_2)
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L3_2 = L3_2 + 7000
  while not L2_2 do
    L4_2 = GetGameTimer
    L4_2 = L4_2()
    if not (L3_2 > L4_2) then
      break
    end
    L4_2 = Wait
    L5_2 = 50
    L4_2(L5_2)
  end
end
L2_1 = RegisterNetEvent
L3_1 = "elevator:updateState"
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = source
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = A0_2.isMoving
    if L2_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L2_2 = A0_2.targetFloor
  L3_2 = type
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if "number" == L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Elevator
    L3_2 = L3_2.floors
    L3_2 = L3_2[L2_2]
    if L3_2 then
      goto lbl_24
    end
  end
  do return end
  ::lbl_24::
  L3_2 = GlobalState
  L3_2 = L3_2.elevator
  L3_2 = L3_2.currentFloor
  if L2_2 == L3_2 then
    return
  end
  L4_2 = A0_2.serverId
  if L4_2 and L4_2 ~= L1_2 then
    L4_2 = nil
  end
  L5_2 = L0_1
  if L5_2 then
    return
  end
  L5_2 = true
  L0_1 = L5_2
  L5_2 = tonumber
  L6_2 = A0_2.duration
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = Config
    L5_2 = L5_2.Elevator
    L5_2 = L5_2.timePerFloor
  end
  L6_2 = math
  L6_2 = L6_2.max
  L7_2 = 3000
  L8_2 = math
  L8_2 = L8_2.min
  L9_2 = L5_2
  L10_2 = 15000
  L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2 = L6_2
  if L4_2 then
    L6_2 = L1_1
    L7_2 = L4_2
    L8_2 = false
    L6_2(L7_2, L8_2)
  end
  L6_2 = GlobalState
  L7_2 = {}
  L7_2.currentFloor = L3_2
  L7_2.targetFloor = L2_2
  L7_2.isMoving = true
  L7_2.doorsOpen = false
  L6_2.elevator = L7_2
  L6_2 = Config
  L6_2 = L6_2.Elevator
  L6_2 = L6_2.door
  L6_2 = L6_2.animations
  L6_2 = L6_2.duration
  L6_2 = L6_2 * 2
  L6_2 = L6_2 + 300
  L7_2 = SetTimeout
  L8_2 = L5_2 + L6_2
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = L4_2
    if L0_3 then
      L0_3 = L1_1
      L1_3 = L4_2
      L2_3 = true
      L0_3(L1_3, L2_3)
    end
    L0_3 = GlobalState
    L1_3 = {}
    L2_3 = L2_2
    L1_3.currentFloor = L2_3
    L1_3.targetFloor = nil
    L1_3.isMoving = false
    L1_3.doorsOpen = true
    L0_3.elevator = L1_3
    L0_3 = false
    L0_1 = L0_3
  end
  L7_2(L8_2, L9_2)
end
L2_1(L3_1, L4_1)
L2_1 = RegisterServerEvent
L3_1 = "prompt_elevator:send:animation"
L2_1(L3_1)
L2_1 = AddEventHandler
L3_1 = "prompt_elevator:send:animation"
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = source
  L4_2 = Config
  L4_2 = L4_2.Elevator
  L4_2 = L4_2.door
  L4_2 = L4_2.playerAnimation
  L4_2 = L4_2.dict
  if A0_2 ~= L4_2 then
    return
  end
  if "right_open" ~= A1_2 and "right_close" ~= A1_2 then
    return
  end
  L4_2 = TriggerClientEvent
  L5_2 = "prompt_elevator:sync:animation"
  L6_2 = -1
  L7_2 = L3_2
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end
L2_1(L3_1, L4_1)

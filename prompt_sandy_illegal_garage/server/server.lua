local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1
function L0_1(A0_2)
  local L1_2
  L1_2 = A0_2 or nil
  L1_2 = A0_2 and A0_2 > 0
  return L1_2
end
validateSource = L0_1
function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = "string" == L1_2 and "prompt_sandy_is_garage_rollup" == A0_2
  return L1_2
end
isGarageRollup = L0_1
L0_1 = nil
L1_1 = nil
L2_1 = nil
L3_1 = false
function L4_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if L0_2 then
    L0_2 = L0_1
    return L0_2
  end
  L0_2 = Config
  L0_2 = L0_2.Permissions
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.Permissions
    L0_2 = L0_2.framework
    if L0_2 then
      goto lbl_16
    end
  end
  L0_2 = "auto"
  ::lbl_16::
  if "auto" ~= L0_2 then
    if "qb" == L0_2 then
      L1_2 = "qbcore"
      if L1_2 then
        goto lbl_24
      end
    end
    L1_2 = L0_2
    ::lbl_24::
    L0_1 = L1_2
  else
    L1_2 = GetResourceState
    L2_2 = "qbx_core"
    L1_2 = L1_2(L2_2)
    if "started" == L1_2 then
      L1_2 = "qbox"
      L0_1 = L1_2
    else
      L1_2 = GetResourceState
      L2_2 = "qb-core"
      L1_2 = L1_2(L2_2)
      if "started" == L1_2 then
        L1_2 = "qbcore"
        L0_1 = L1_2
      else
        L1_2 = GetResourceState
        L2_2 = "es_extended"
        L1_2 = L1_2(L2_2)
        if "started" == L1_2 then
          L1_2 = "esx"
          L0_1 = L1_2
        else
          L1_2 = "standalone"
          return L1_2
        end
      end
    end
  end
  L1_2 = L0_1
  if "qbcore" == L1_2 then
    L1_2 = exports
    L1_2 = L1_2["qb-core"]
    L2_2 = L1_2
    L1_2 = L1_2.GetCoreObject
    L1_2 = L1_2(L2_2)
    L1_1 = L1_2
  else
    L1_2 = L0_1
    if "esx" == L1_2 then
      L1_2 = exports
      L1_2 = L1_2.es_extended
      L2_2 = L1_2
      L1_2 = L1_2.getSharedObject
      L1_2 = L1_2(L2_2)
      L2_1 = L1_2
    end
  end
  L1_2 = L0_1
  return L1_2
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = L4_1
  L1_2 = L1_2()
  if "qbcore" == L1_2 then
    L2_2 = L1_1
    if L2_2 then
      L2_2 = L1_1.Functions
      L2_2 = L2_2.GetPlayer
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
    end
    if not L2_2 then
      L3_2 = nil
      return L3_2
    end
    L3_2 = L2_2.PlayerData
    L3_2 = L3_2.job
    L4_2 = L3_2 or L4_2
    if L3_2 then
      L4_2 = L3_2.name
      if L4_2 then
        L4_2 = L3_2.name
        L5_2 = L4_2
        L4_2 = L4_2.lower
        L4_2 = L4_2(L5_2)
      end
    end
    return L4_2
  elseif "qbox" == L1_2 then
    L2_2 = exports
    L2_2 = L2_2.qbx_core
    L3_2 = L2_2
    L2_2 = L2_2.GetPlayer
    L4_2 = A0_2
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      L3_2 = nil
      return L3_2
    end
    L3_2 = L2_2.PlayerData
    L3_2 = L3_2.job
    L4_2 = L3_2 or L4_2
    if L3_2 then
      L4_2 = L3_2.name
      if L4_2 then
        L4_2 = L3_2.name
        L5_2 = L4_2
        L4_2 = L4_2.lower
        L4_2 = L4_2(L5_2)
      end
    end
    return L4_2
  elseif "esx" == L1_2 then
    L2_2 = L2_1
    if L2_2 then
      L2_2 = L2_1.GetPlayerFromId
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
    end
    if not L2_2 then
      L3_2 = nil
      return L3_2
    end
    L3_2 = L2_2.job
    if L3_2 then
      L3_2 = L2_2.job
      L3_2 = L3_2.name
      if L3_2 then
        L3_2 = L2_2.job
        L3_2 = L3_2.name
        L4_2 = L3_2
        L3_2 = L3_2.lower
        L3_2 = L3_2(L4_2)
      end
    end
    return L3_2
  elseif "standalone" == L1_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = nil
  return L2_2
end
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = Config
  L2_2 = L2_2.Permissions
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.Permissions
    L2_2 = L2_2.enabled
    if L2_2 then
      goto lbl_12
    end
  end
  L2_2 = true
  do return L2_2 end
  ::lbl_12::
  L2_2 = nil
  L3_2 = pairs
  L4_2 = Config
  L4_2 = L4_2.Props
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.name
    if L9_2 == A1_2 then
      L2_2 = L8_2
      break
    end
  end
  if not L2_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = Config
  L3_2 = L3_2.Permissions
  L3_2 = L3_2.useAce
  if L3_2 then
    L3_2 = L2_2.acePermission
    if L3_2 then
      L3_2 = IsPlayerAceAllowed
      L4_2 = A0_2
      L5_2 = L2_2.acePermission
      return L3_2(L4_2, L5_2)
    end
  end
  L3_2 = L2_2.allowedJobs
  if L3_2 then
    L3_2 = L2_2.allowedJobs
    L3_2 = #L3_2
    if 0 ~= L3_2 then
      goto lbl_52
    end
  end
  L3_2 = true
  do return L3_2 end
  ::lbl_52::
  L3_2 = L4_1
  L3_2 = L3_2()
  if "standalone" == L3_2 then
    L3_2 = L3_1
    if not L3_2 then
      L3_2 = true
      L3_1 = L3_2
      L3_2 = print
      L4_2 = "^1[%s] Config.Permissions job restrictions are enabled but no framework (qbx_core/qb-core/es_extended) is running \226\128\148 denying restricted interactions. Use ACE permissions (Config.Permissions.useAce) on standalone servers.^0"
      L5_2 = L4_2
      L4_2 = L4_2.format
      L6_2 = GetCurrentResourceName
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2()
      L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    end
    L3_2 = false
    return L3_2
  end
  L3_2 = L5_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = ipairs
  L5_2 = L2_2.allowedJobs
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = type
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if "string" == L10_2 then
      L11_2 = L9_2
      L10_2 = L9_2.lower
      L10_2 = L10_2(L11_2)
      if L10_2 == L3_2 then
        L10_2 = true
        return L10_2
      end
    end
  end
  L4_2 = false
  return L4_2
end
ServerHasJobAccess = L6_1
L6_1 = CreateThread
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = GlobalState
  L1_2 = {}
  L0_2.ilegal_carwash = L1_2
  L0_2 = GlobalState
  L1_2 = {}
  L0_2.ilegal_carwash_busy = L1_2
  L0_2 = Config
  L0_2 = L0_2.AutoOpen
  if L0_2 then
    L0_2 = {}
    L1_2 = pairs
    L2_2 = Config
    L2_2 = L2_2.Props
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = isGarageRollup
      L8_2 = L6_2.name
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = L6_2.name
        L8_2 = Config
        L8_2 = L8_2.AutoOpenDefaultLocked
        L8_2 = false ~= L8_2
        L0_2[L7_2] = L8_2
      end
    end
    L1_2 = GlobalState
    L1_2.ilegal_carwash_locks = L0_2
  end
end
L6_1(L7_1)
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GlobalState
  L2_2 = L2_2.ilegal_carwash
  if not L2_2 then
    L2_2 = {}
  end
  L2_2[A0_2] = A1_2
  L3_2 = GlobalState
  L3_2.ilegal_carwash = L2_2
  L3_2 = TriggerEvent
  L4_2 = "prompt_sandy_illegal_garage:liftStateChanged"
  L5_2 = A0_2
  L6_2 = A1_2
  L3_2(L4_2, L5_2, L6_2)
end
updateGlobalPropState = L6_1
L6_1 = exports
L7_1 = "getLiftState"
function L8_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalState
  L1_2 = L1_2.ilegal_carwash
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2[A0_2]
  return L2_2
end
L6_1(L7_1, L8_1)
L6_1 = exports
L7_1 = "isLiftBusy"
function L8_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalState
  L1_2 = L1_2.ilegal_carwash_busy
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2[A0_2]
  if not L2_2 then
    L2_2 = false
  end
  return L2_2
end
L6_1(L7_1, L8_1)
L6_1 = {}
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = L6_1
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    L2_2 = 0
    return L2_2
  end
  L2_2 = 0
  L3_2 = pairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2 in L3_2, L4_2, L5_2, L6_2 do
    L2_2 = L2_2 + 1
  end
  return L2_2
end
function L8_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = GlobalState
  L2_2 = L2_2.ilegal_carwash_busy
  if not L2_2 then
    L2_2 = {}
  end
  if A1_2 then
    L3_2 = true
    if L3_2 then
      goto lbl_13
    end
  end
  L3_2 = false
  ::lbl_13::
  L2_2[A0_2] = L3_2
  L3_2 = GlobalState
  L3_2.ilegal_carwash_busy = L2_2
end
L9_1 = exports
L10_1 = "isDoorLocked"
function L11_1(A0_2)
  local L1_2, L2_2
  L1_2 = GlobalState
  L1_2 = L1_2.ilegal_carwash_locks
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2[A0_2]
  if not L2_2 then
    L2_2 = false
  end
  return L2_2
end
L9_1(L10_1, L11_1)
L9_1 = RegisterNetEvent
L10_1 = "ilegal_anims:initializeState"
function L11_1(A0_2)
  local L1_2, L2_2
  L1_2 = validateSource
  L2_2 = source
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = GlobalState
  L1_2 = L1_2.ilegal_carwash
  if not L1_2 then
    L1_2 = GlobalState
    L2_2 = A0_2 or L2_2
    if not A0_2 then
      L2_2 = {}
    end
    L1_2.ilegal_carwash = L2_2
  end
end
L9_1(L10_1, L11_1)
L9_1 = RegisterNetEvent
L10_1 = "ilegal_anims:updatePropState"
function L11_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = validateSource
  L3_2 = source
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  if A0_2 then
    L2_2 = updateGlobalPropState
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end
L9_1(L10_1, L11_1)
L9_1 = RegisterNetEvent
L10_1 = "ilegal_anims:syncAnimation"
L9_1(L10_1)
L9_1 = AddEventHandler
L10_1 = "ilegal_anims:syncAnimation"
function L11_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = source
  L4_2 = validateSource
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = print
    L5_2 = "Error: Fuente inv\195\161lida para la sincronizaci\195\179n de animaci\195\179n"
    L4_2(L5_2)
    return
  end
  if not A0_2 or not A1_2 then
    L4_2 = print
    L5_2 = "Error: Datos incompletos para la sincronizaci\195\179n de animaci\195\179n"
    L4_2(L5_2)
    return
  end
  L4_2 = TriggerClientEvent
  L5_2 = "ilegal_anims:syncAnimation"
  L6_2 = -1
  L7_2 = L3_2
  L8_2 = A0_2
  L9_2 = A1_2
  L10_2 = A2_2
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end
L9_1(L10_1, L11_1)
L9_1 = RegisterNetEvent
L10_1 = "ilegal_anims:requestPlayerAnimation"
L9_1(L10_1)
L9_1 = AddEventHandler
L10_1 = "ilegal_anims:requestPlayerAnimation"
function L11_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = source
  L2_2 = validateSource
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = print
    L3_2 = "Error: Fuente inv\195\161lida para la solicitud de animaci\195\179n"
    L2_2(L3_2)
    return
  end
  if A0_2 then
    L2_2 = A0_2.dict
    if L2_2 then
      L2_2 = A0_2.anim
      if L2_2 then
        L2_2 = A0_2.propName
        if L2_2 then
          goto lbl_26
        end
      end
    end
  end
  L2_2 = print
  L3_2 = "Error: Datos incompletos para la solicitud de animaci\195\179n"
  L2_2(L3_2)
  do return end
  ::lbl_26::
  L2_2 = A0_2.position
  if L2_2 then
    L2_2 = A0_2.heading
    if L2_2 then
      goto lbl_36
    end
  end
  L2_2 = print
  L3_2 = "Error: Posici\195\179n o heading no proporcionados para la animaci\195\179n"
  L2_2(L3_2)
  do return end
  ::lbl_36::
  L2_2 = lib
  L2_2 = L2_2.callback
  L3_2 = "ilegal_anims:playPlayerAnimation"
  L4_2 = L1_2
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    if A0_3 then
      L1_3 = TriggerClientEvent
      L2_3 = "ilegal_anims:animatePropAfterPlayerAnim"
      L3_3 = L1_2
      L4_3 = {}
      L5_3 = A0_2.propName
      L4_3.propName = L5_3
      L5_3 = A0_2.state
      L4_3.state = L5_3
      L1_3(L2_3, L3_3, L4_3)
    else
      L1_3 = print
      L2_3 = "Error: La animaci\195\179n del jugador fall\195\179"
      L1_3(L2_3)
    end
  end
  L6_2 = A0_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L9_1(L10_1, L11_1)
L9_1 = RegisterNetEvent
L10_1 = "ilegal_anims:setPropBusy"
function L11_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = validateSource
  L3_2 = source
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  if not A0_2 then
    return
  end
  L2_2 = GlobalState
  L2_2 = L2_2.ilegal_carwash_busy
  if not L2_2 then
    L2_2 = {}
  end
  if A1_2 then
    L3_2 = true
    if L3_2 then
      goto lbl_22
    end
  end
  L3_2 = false
  ::lbl_22::
  L2_2[A0_2] = L3_2
  L3_2 = GlobalState
  L3_2.ilegal_carwash_busy = L2_2
  L3_2 = Config
  L3_2 = L3_2.AutoOpen
  if L3_2 and not A1_2 then
    L3_2 = isGarageRollup
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = GlobalState
      L3_2 = L3_2.ilegal_carwash_locks
      if not L3_2 then
        L3_2 = {}
      end
      L4_2 = GlobalState
      L4_2 = L4_2.ilegal_carwash
      if not L4_2 then
        L4_2 = {}
      end
      L5_2 = L3_2[A0_2]
      if not L5_2 then
        L5_2 = L4_2[A0_2]
        if not L5_2 then
          L5_2 = L7_1
          L6_2 = A0_2
          L5_2 = L5_2(L6_2)
          if L5_2 > 0 then
            L5_2 = L8_1
            L6_2 = A0_2
            L7_2 = true
            L5_2(L6_2, L7_2)
            L5_2 = updateGlobalPropState
            L6_2 = A0_2
            L7_2 = true
            L5_2(L6_2, L7_2)
          end
        end
      end
    end
  end
end
L9_1(L10_1, L11_1)
L9_1 = Config
L9_1 = L9_1.AutoOpen
if L9_1 then
  L9_1 = RegisterNetEvent
  L10_1 = "ilegal_anims:zoneEnter"
  function L11_1(A0_2)
    local L1_2, L2_2, L3_2
    L1_2 = source
    L2_2 = validateSource
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = isGarageRollup
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = L6_1
    L2_2 = L2_2[A0_2]
    if not L2_2 then
      L2_2 = L6_1
      L3_2 = {}
      L2_2[A0_2] = L3_2
    end
    L2_2 = L6_1
    L2_2 = L2_2[A0_2]
    L2_2[L1_2] = true
  end
  L9_1(L10_1, L11_1)
  L9_1 = RegisterNetEvent
  L10_1 = "ilegal_anims:zoneExit"
  function L11_1(A0_2)
    local L1_2, L2_2, L3_2
    L1_2 = source
    L2_2 = validateSource
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = isGarageRollup
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = L6_1
    L2_2 = L2_2[A0_2]
    if L2_2 then
      L2_2 = L6_1
      L2_2 = L2_2[A0_2]
      L2_2[L1_2] = nil
    end
  end
  L9_1(L10_1, L11_1)
  L9_1 = RegisterNetEvent
  L10_1 = "ilegal_anims:requestAutoOpen"
  function L11_1(A0_2)
    local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
    L1_2 = source
    L2_2 = validateSource
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = isGarageRollup
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = ServerHasJobAccess
    L3_2 = L1_2
    L4_2 = A0_2
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      return
    end
    L2_2 = GlobalState
    L2_2 = L2_2.ilegal_carwash_locks
    if not L2_2 then
      L2_2 = {}
    end
    L3_2 = L2_2[A0_2]
    if L3_2 then
      return
    end
    L3_2 = GlobalState
    L3_2 = L3_2.ilegal_carwash_busy
    if not L3_2 then
      L3_2 = {}
    end
    L4_2 = L3_2[A0_2]
    if L4_2 then
      return
    end
    L4_2 = GlobalState
    L4_2 = L4_2.ilegal_carwash
    if not L4_2 then
      L4_2 = {}
    end
    L5_2 = L4_2[A0_2]
    if L5_2 then
      return
    end
    L5_2 = L8_1
    L6_2 = A0_2
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = updateGlobalPropState
    L6_2 = A0_2
    L7_2 = true
    L5_2(L6_2, L7_2)
  end
  L9_1(L10_1, L11_1)
  L9_1 = RegisterNetEvent
  L10_1 = "ilegal_anims:requestAutoClose"
  function L11_1(A0_2)
    local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
    L1_2 = source
    L2_2 = validateSource
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = isGarageRollup
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = L7_1
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 > 0 then
      return
    end
    L2_2 = GlobalState
    L2_2 = L2_2.ilegal_carwash_busy
    if not L2_2 then
      L2_2 = {}
    end
    L3_2 = L2_2[A0_2]
    if L3_2 then
      return
    end
    L3_2 = GlobalState
    L3_2 = L3_2.ilegal_carwash
    if not L3_2 then
      L3_2 = {}
    end
    L4_2 = L3_2[A0_2]
    if not L4_2 then
      return
    end
    L4_2 = L8_1
    L5_2 = A0_2
    L6_2 = true
    L4_2(L5_2, L6_2)
    L4_2 = updateGlobalPropState
    L5_2 = A0_2
    L6_2 = false
    L4_2(L5_2, L6_2)
  end
  L9_1(L10_1, L11_1)
  L9_1 = RegisterNetEvent
  L10_1 = "ilegal_anims:toggleLock"
  function L11_1(A0_2)
    local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
    L1_2 = source
    L2_2 = validateSource
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = isGarageRollup
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L2_2 = ServerHasJobAccess
    L3_2 = L1_2
    L4_2 = A0_2
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      L2_2 = TriggerClientEvent
      L3_2 = "ox_lib:notify"
      L4_2 = L1_2
      L5_2 = {}
      L6_2 = Config
      L6_2 = L6_2.Permissions
      L6_2 = L6_2.noAccessMessage
      if not L6_2 then
        L6_2 = "You don't have access to this"
      end
      L5_2.description = L6_2
      L5_2.type = "error"
      L5_2.duration = 3000
      L2_2(L3_2, L4_2, L5_2)
      return
    end
    L2_2 = GlobalState
    L2_2 = L2_2.ilegal_carwash_locks
    if not L2_2 then
      L2_2 = {}
    end
    L3_2 = L2_2[A0_2]
    L3_2 = not L3_2 and L3_2
    L2_2[A0_2] = L3_2
    L4_2 = GlobalState
    L4_2.ilegal_carwash_locks = L2_2
    L4_2 = TriggerClientEvent
    L5_2 = "ox_lib:notify"
    L6_2 = L1_2
    L7_2 = {}
    if L3_2 then
      L8_2 = Config
      L8_2 = L8_2.Messages
      L8_2 = L8_2.locked
      if L8_2 then
        goto lbl_67
      end
    end
    L8_2 = Config
    L8_2 = L8_2.Messages
    L8_2 = L8_2.unlocked
    ::lbl_67::
    L7_2.description = L8_2
    if L3_2 then
      L8_2 = "error"
      if L8_2 then
        goto lbl_74
      end
    end
    L8_2 = "success"
    ::lbl_74::
    L7_2.type = L8_2
    L7_2.duration = 3000
    L4_2(L5_2, L6_2, L7_2)
    if not L3_2 then
      L4_2 = GlobalState
      L4_2 = L4_2.ilegal_carwash
      if not L4_2 then
        L4_2 = {}
      end
      L5_2 = GlobalState
      L5_2 = L5_2.ilegal_carwash_busy
      if not L5_2 then
        L5_2 = {}
      end
      L6_2 = L4_2[A0_2]
      if not L6_2 then
        L6_2 = L5_2[A0_2]
        if not L6_2 then
          L6_2 = L7_1
          L7_2 = A0_2
          L6_2 = L6_2(L7_2)
          if L6_2 > 0 then
            L6_2 = L8_1
            L7_2 = A0_2
            L8_2 = true
            L6_2(L7_2, L8_2)
            L6_2 = updateGlobalPropState
            L7_2 = A0_2
            L8_2 = true
            L6_2(L7_2, L8_2)
          end
        end
      end
    end
    if L3_2 then
      L4_2 = GlobalState
      L4_2 = L4_2.ilegal_carwash
      if not L4_2 then
        L4_2 = {}
      end
      L5_2 = L4_2[A0_2]
      if L5_2 then
        L5_2 = L8_1
        L6_2 = A0_2
        L7_2 = true
        L5_2(L6_2, L7_2)
        L5_2 = updateGlobalPropState
        L6_2 = A0_2
        L7_2 = false
        L5_2(L6_2, L7_2)
      end
    end
  end
  L9_1(L10_1, L11_1)
  L9_1 = AddEventHandler
  L10_1 = "playerDropped"
  function L11_1()
    local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
    L0_2 = source
    L1_2 = pairs
    L2_2 = L6_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = L6_2[L0_2]
      if L7_2 then
        L6_2[L0_2] = nil
        L7_2 = L7_1
        L8_2 = L5_2
        L7_2 = L7_2(L8_2)
        if 0 == L7_2 then
          L7_2 = GlobalState
          L7_2 = L7_2.ilegal_carwash
          if not L7_2 then
            L7_2 = {}
          end
          L8_2 = GlobalState
          L8_2 = L8_2.ilegal_carwash_busy
          if not L8_2 then
            L8_2 = {}
          end
          L9_2 = L7_2[L5_2]
          if L9_2 then
            L9_2 = L8_2[L5_2]
            if not L9_2 then
              L9_2 = SetTimeout
              L10_2 = Config
              L10_2 = L10_2.AutoOpenCloseDelay
              function L11_2()
                local L0_3, L1_3, L2_3, L3_3, L4_3
                L0_3 = L7_1
                L1_3 = L5_2
                L0_3 = L0_3(L1_3)
                if 0 == L0_3 then
                  L0_3 = GlobalState
                  L0_3 = L0_3.ilegal_carwash
                  if not L0_3 then
                    L0_3 = {}
                  end
                  L1_3 = GlobalState
                  L1_3 = L1_3.ilegal_carwash_busy
                  if not L1_3 then
                    L1_3 = {}
                  end
                  L2_3 = L5_2
                  L2_3 = L0_3[L2_3]
                  if L2_3 then
                    L2_3 = L5_2
                    L2_3 = L1_3[L2_3]
                    if not L2_3 then
                      L2_3 = L8_1
                      L3_3 = L5_2
                      L4_3 = true
                      L2_3(L3_3, L4_3)
                      L2_3 = updateGlobalPropState
                      L3_3 = L5_2
                      L4_3 = false
                      L2_3(L3_3, L4_3)
                    end
                  end
                end
              end
              L9_2(L10_2, L11_2)
            end
          end
        end
      end
    end
  end
  L9_1(L10_1, L11_1)
end
L9_1 = RegisterCommand
L10_1 = "testautodoors_ig"
function L11_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2
  L2_2 = A0_2
  L3_2 = 0
  L4_2 = 0
  L5_2 = {}
  function L6_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    if A1_3 then
      L2_3 = L3_2
      L2_3 = L2_3 + 1
      L3_2 = L2_3
      L2_3 = L5_2
      L2_3 = #L2_3
      L3_3 = L2_3 + 1
      L2_3 = L5_2
      L4_3 = "^2  PASS^0: "
      L5_3 = A0_3
      L4_3 = L4_3 .. L5_3
      L2_3[L3_3] = L4_3
    else
      L2_3 = L4_2
      L2_3 = L2_3 + 1
      L4_2 = L2_3
      L2_3 = L5_2
      L2_3 = #L2_3
      L3_3 = L2_3 + 1
      L2_3 = L5_2
      L4_3 = "^1  FAIL^0: "
      L5_3 = A0_3
      L4_3 = L4_3 .. L5_3
      L2_3[L3_3] = L4_3
    end
  end
  L7_2 = print
  L8_2 = "^3[TEST] ========== Auto-Door Test Suite (Illegal Garage) ==========^0"
  L7_2(L8_2)
  L7_2 = L6_2
  L8_2 = "isGarageRollup(\"prompt_sandy_is_garage_rollup\") == true"
  L9_2 = isGarageRollup
  L10_2 = "prompt_sandy_is_garage_rollup"
  L9_2 = L9_2(L10_2)
  L9_2 = true == L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "isGarageRollup(\"prompt_sandy_is_lift\") == false"
  L9_2 = isGarageRollup
  L10_2 = "prompt_sandy_is_lift"
  L9_2 = L9_2(L10_2)
  L9_2 = false == L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "isGarageRollup(nil) == false"
  L9_2 = isGarageRollup
  L10_2 = nil
  L9_2 = L9_2(L10_2)
  L9_2 = false == L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "isGarageRollup(123) == false"
  L9_2 = isGarageRollup
  L10_2 = 123
  L9_2 = L9_2(L10_2)
  L9_2 = false == L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.AutoOpen exists"
  L9_2 = Config
  L9_2 = L9_2.AutoOpen
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.AutoOpenCloseDelay is number"
  L9_2 = type
  L10_2 = Config
  L10_2 = L10_2.AutoOpenCloseDelay
  L9_2 = L9_2(L10_2)
  L9_2 = "number" == L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.Messages.lock exists"
  L9_2 = Config
  L9_2 = L9_2.Messages
  L9_2 = L9_2.lock
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.Messages.unlock exists"
  L9_2 = Config
  L9_2 = L9_2.Messages
  L9_2 = L9_2.unlock
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.Messages.locked exists"
  L9_2 = Config
  L9_2 = L9_2.Messages
  L9_2 = L9_2.locked
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "Config.Messages.unlocked exists"
  L9_2 = Config
  L9_2 = L9_2.Messages
  L9_2 = L9_2.unlocked
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = Config
  L7_2 = L7_2.Permissions
  if L7_2 then
    L7_2 = Config
    L7_2 = L7_2.Props
    L7_2 = L7_2.garage_rollup
    L8_2 = Config
    L8_2 = L8_2.Permissions
    L8_2 = L8_2.enabled
    L9_2 = L7_2 or L9_2
    if L7_2 then
      L9_2 = L7_2.allowedJobs
    end
    L10_2 = Config
    L10_2 = L10_2.Permissions
    L10_2.enabled = false
    L10_2 = L6_2
    L11_2 = "Permissions disabled: ServerHasJobAccess allows"
    L12_2 = ServerHasJobAccess
    L13_2 = 0
    L14_2 = "prompt_sandy_is_garage_rollup"
    L12_2 = L12_2(L13_2, L14_2)
    L12_2 = true == L12_2
    L10_2(L11_2, L12_2)
    if L7_2 then
      L10_2 = Config
      L10_2 = L10_2.Permissions
      L10_2.enabled = true
      L10_2 = {}
      L11_2 = "mechanic"
      L10_2[1] = L11_2
      L7_2.allowedJobs = L10_2
      L10_2 = GetResourceState
      L11_2 = "qbx_core"
      L10_2 = L10_2(L11_2)
      L10_2 = "started" == L10_2
      L11_2 = Config
      L11_2 = L11_2.Permissions
      L11_2 = L11_2.framework
      if not L11_2 then
        L11_2 = "auto"
      end
      if "auto" == L11_2 and not L10_2 then
        L11_2 = L6_2
        L12_2 = "No framework: restricted prop denies (fail closed)"
        L13_2 = ServerHasJobAccess
        L14_2 = 0
        L15_2 = "prompt_sandy_is_garage_rollup"
        L13_2 = L13_2(L14_2, L15_2)
        L13_2 = false == L13_2
        L11_2(L12_2, L13_2)
      end
      L7_2.allowedJobs = L9_2
    end
    L10_2 = Config
    L10_2 = L10_2.Permissions
    L10_2.enabled = L8_2
  end
  L7_2 = L6_2
  L8_2 = "GlobalState.ilegal_carwash exists"
  L9_2 = GlobalState
  L9_2 = L9_2.ilegal_carwash
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = L6_2
  L8_2 = "GlobalState.ilegal_carwash_busy exists"
  L9_2 = GlobalState
  L9_2 = L9_2.ilegal_carwash_busy
  L9_2 = nil ~= L9_2
  L7_2(L8_2, L9_2)
  L7_2 = Config
  L7_2 = L7_2.AutoOpen
  if L7_2 then
    L7_2 = GlobalState
    L7_2 = L7_2.ilegal_carwash_locks
    L8_2 = L6_2
    L9_2 = "GlobalState.ilegal_carwash_locks exists"
    L10_2 = nil ~= L7_2
    L8_2(L9_2, L10_2)
    if L7_2 then
      L8_2 = 0
      L9_2 = true
      L10_2 = pairs
      L11_2 = L7_2
      L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
      for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
        L8_2 = L8_2 + 1
        if not L15_2 then
          L9_2 = false
        end
        L16_2 = L6_2
        L17_2 = "Lock entry is garage_rollup: "
        L18_2 = L14_2
        L17_2 = L17_2 .. L18_2
        L18_2 = isGarageRollup
        L19_2 = L14_2
        L18_2, L19_2, L20_2, L21_2, L22_2, L23_2 = L18_2(L19_2)
        L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
      end
      L10_2 = L6_2
      L11_2 = "1 garage door in lock state (got "
      L12_2 = L8_2
      L13_2 = ")"
      L11_2 = L11_2 .. L12_2 .. L13_2
      L12_2 = 1 == L8_2
      L10_2(L11_2, L12_2)
      L10_2 = L6_2
      L11_2 = "All doors default to locked"
      L12_2 = L9_2
      L10_2(L11_2, L12_2)
    end
    L8_2 = L6_2
    L9_2 = "getOccupantCount for unknown door == 0"
    L10_2 = L7_1
    L11_2 = "prompt_sandy_is_garage_rollup"
    L10_2 = L10_2(L11_2)
    L10_2 = 0 == L10_2
    L8_2(L9_2, L10_2)
    L8_2 = "prompt_sandy_is_garage_rollup"
    L9_2 = GlobalState
    L9_2 = L9_2.ilegal_carwash_busy
    if not L9_2 then
      L9_2 = {}
    end
    L9_2 = L9_2[L8_2]
    L10_2 = L8_1
    L11_2 = L8_2
    L12_2 = true
    L10_2(L11_2, L12_2)
    L10_2 = GlobalState
    L10_2 = L10_2.ilegal_carwash_busy
    if not L10_2 then
      L10_2 = {}
    end
    L10_2 = L10_2[L8_2]
    L11_2 = L6_2
    L12_2 = "setBusy(rollup, true) sets busy"
    L13_2 = true == L10_2
    L11_2(L12_2, L13_2)
    L11_2 = L8_1
    L12_2 = L8_2
    L13_2 = false
    L11_2(L12_2, L13_2)
    L11_2 = GlobalState
    L11_2 = L11_2.ilegal_carwash_busy
    if not L11_2 then
      L11_2 = {}
    end
    L11_2 = L11_2[L8_2]
    L12_2 = L6_2
    L13_2 = "setBusy(rollup, false) clears busy"
    L14_2 = false == L11_2
    L12_2(L13_2, L14_2)
    L12_2 = GlobalState
    L12_2 = L12_2.ilegal_carwash_locks
    if not L12_2 then
      L12_2 = {}
    end
    L13_2 = L12_2[L8_2]
    L14_2 = not L13_2
    L12_2[L8_2] = L14_2
    L14_2 = GlobalState
    L14_2.ilegal_carwash_locks = L12_2
    L14_2 = GlobalState
    L14_2 = L14_2.ilegal_carwash_locks
    if not L14_2 then
      L14_2 = {}
    end
    L15_2 = L6_2
    L16_2 = "Lock toggle changes state"
    L17_2 = L14_2[L8_2]
    L18_2 = not L13_2
    L17_2 = L17_2 == L18_2
    L15_2(L16_2, L17_2)
    L12_2[L8_2] = L13_2
    L15_2 = GlobalState
    L15_2.ilegal_carwash_locks = L12_2
    L15_2 = GlobalState
    L15_2 = L15_2.ilegal_carwash_locks
    if not L15_2 then
      L15_2 = {}
    end
    L15_2[L8_2] = false
    L16_2 = GlobalState
    L16_2.ilegal_carwash_locks = L15_2
    L16_2 = L8_1
    L17_2 = L8_2
    L18_2 = false
    L16_2(L17_2, L18_2)
    L16_2 = GlobalState
    L16_2 = L16_2.ilegal_carwash
    if not L16_2 then
      L16_2 = {}
    end
    L16_2[L8_2] = nil
    L17_2 = GlobalState
    L17_2.ilegal_carwash = L16_2
    L17_2 = GlobalState
    L17_2 = L17_2.ilegal_carwash_locks
    if not L17_2 then
      L17_2 = {}
    end
    L17_2 = L17_2[L8_2]
    L17_2 = GlobalState
    L17_2 = L17_2.ilegal_carwash_busy
    if not L17_2 then
      L17_2 = {}
    end
    L17_2 = L17_2[L8_2]
    L17_2 = GlobalState
    L17_2 = L17_2.ilegal_carwash
    if not L17_2 then
      L17_2 = {}
    end
    L17_2 = L17_2[L8_2]
    L17_2 = not L17_2 and L17_2
    L18_2 = L6_2
    L19_2 = "Unlocked + not busy + not open = can auto-open"
    L20_2 = true == L17_2
    L18_2(L19_2, L20_2)
    L18_2 = L8_1
    L19_2 = L8_2
    L20_2 = true
    L18_2(L19_2, L20_2)
    L18_2 = updateGlobalPropState
    L19_2 = L8_2
    L20_2 = true
    L18_2(L19_2, L20_2)
    L18_2 = L6_2
    L19_2 = "After auto-open: door state is true"
    L20_2 = GlobalState
    L20_2 = L20_2.ilegal_carwash
    if not L20_2 then
      L20_2 = {}
    end
    L20_2 = L20_2[L8_2]
    L20_2 = true == L20_2
    L18_2(L19_2, L20_2)
    L18_2 = L6_2
    L19_2 = "After auto-open: busy is true"
    L20_2 = GlobalState
    L20_2 = L20_2.ilegal_carwash_busy
    if not L20_2 then
      L20_2 = {}
    end
    L20_2 = L20_2[L8_2]
    L20_2 = true == L20_2
    L18_2(L19_2, L20_2)
    L18_2 = L6_1
    L19_2 = {}
    L20_2 = 999
    L19_2[L20_2] = true
    L18_2[L8_2] = L19_2
    L18_2 = L6_2
    L19_2 = "With occupant: getOccupantCount == 1"
    L20_2 = L7_1
    L21_2 = L8_2
    L20_2 = L20_2(L21_2)
    L20_2 = 1 == L20_2
    L18_2(L19_2, L20_2)
    L18_2 = L7_1
    L19_2 = L8_2
    L18_2 = L18_2(L19_2)
    L18_2 = 0 == L18_2
    L19_2 = L6_2
    L20_2 = "With occupant: close is rejected"
    L21_2 = false == L18_2
    L19_2(L20_2, L21_2)
    L19_2 = L6_1
    L20_2 = {}
    L19_2[L8_2] = L20_2
    L19_2 = L8_1
    L20_2 = L8_2
    L21_2 = false
    L19_2(L20_2, L21_2)
    L19_2 = L7_1
    L20_2 = L8_2
    L19_2 = L19_2(L20_2)
    L19_2 = GlobalState
    L19_2 = L19_2.ilegal_carwash_busy
    if not L19_2 then
      L19_2 = {}
    end
    L19_2 = L19_2[L8_2]
    L19_2 = GlobalState
    L19_2 = L19_2.ilegal_carwash
    if not L19_2 then
      L19_2 = {}
    end
    L18_2 = 0 == L19_2 and L18_2
    L19_2 = L6_2
    L20_2 = "No occupants + not busy + open = can auto-close"
    L21_2 = true == L18_2
    L19_2(L20_2, L21_2)
    L19_2 = L8_1
    L20_2 = L8_2
    L21_2 = false
    L19_2(L20_2, L21_2)
    L19_2 = updateGlobalPropState
    L20_2 = L8_2
    L21_2 = false
    L19_2(L20_2, L21_2)
    L19_2 = GlobalState
    L19_2 = L19_2.ilegal_carwash_locks
    L15_2 = L19_2 or L15_2
    if not L19_2 then
      L19_2 = {}
      L15_2 = L19_2
    end
    L15_2[L8_2] = true
    L19_2 = GlobalState
    L19_2.ilegal_carwash_locks = L15_2
    L19_2 = L6_1
    L19_2[L8_2] = nil
    L19_2 = GlobalState
    L19_2 = L19_2.ilegal_carwash_locks
    if not L19_2 then
      L19_2 = {}
    end
    L19_2[L8_2] = true
    L20_2 = GlobalState
    L20_2.ilegal_carwash_locks = L19_2
    L20_2 = GlobalState
    L20_2 = L20_2.ilegal_carwash_locks
    if not L20_2 then
      L20_2 = {}
    end
    L20_2 = L20_2[L8_2]
    L20_2 = true == L20_2
    L21_2 = L6_2
    L22_2 = "Locked door blocks auto-open check"
    L23_2 = true == L20_2
    L21_2(L22_2, L23_2)
  else
    L7_2 = print
    L8_2 = "^3[TEST] Config.AutoOpen is false \226\128\148 skipping auto-open tests^0"
    L7_2(L8_2)
  end
  L7_2 = print
  L8_2 = "^3[TEST] ---------- Results ----------^0"
  L7_2(L8_2)
  L7_2 = ipairs
  L8_2 = L5_2
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
    L13_2 = print
    L14_2 = "[TEST] "
    L15_2 = L12_2
    L14_2 = L14_2 .. L15_2
    L13_2(L14_2)
  end
  L7_2 = print
  L8_2 = "^3[TEST] ========== "
  L9_2 = L3_2
  L10_2 = " passed, "
  L11_2 = L4_2
  L12_2 = " failed ==========^0"
  L8_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
  L7_2(L8_2)
  if L2_2 > 0 then
    L7_2 = TriggerClientEvent
    L8_2 = "ox_lib:notify"
    L9_2 = L2_2
    L10_2 = {}
    L11_2 = L3_2
    L12_2 = " passed, "
    L13_2 = L4_2
    L14_2 = " failed"
    L11_2 = L11_2 .. L12_2 .. L13_2 .. L14_2
    L10_2.description = L11_2
    if 0 == L4_2 then
      L11_2 = "success"
      if L11_2 then
        goto lbl_597
      end
    end
    L11_2 = "error"
    ::lbl_597::
    L10_2.type = L11_2
    L10_2.duration = 5000
    L7_2(L8_2, L9_2, L10_2)
  end
end
L12_1 = true
L9_1(L10_1, L11_1, L12_1)
L9_1 = Config
L9_1 = L9_1.Debug
if L9_1 then
  L9_1 = AddEventHandler
  L10_1 = "prompt_sandy_illegal_garage:liftStateChanged"
  function L11_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
    L2_2 = print
    L3_2 = "[SANDY ILLEGAL GARAGE EXPORT DEBUG] [SERVER] liftStateChanged -> propName: %s | state: %s (%s)"
    L4_2 = L3_2
    L3_2 = L3_2.format
    L5_2 = A0_2
    L6_2 = tostring
    L7_2 = A1_2
    L6_2 = L6_2(L7_2)
    if A1_2 then
      L7_2 = "UP"
      if L7_2 then
        goto lbl_14
      end
    end
    L7_2 = "DOWN"
    ::lbl_14::
    L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  end
  L9_1(L10_1, L11_1)
end

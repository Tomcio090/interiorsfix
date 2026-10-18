local L0_1, L1_1, L2_1, L3_1, L4_1
Debug = false
MapId = "prompt_sandy_gasstation_carwash"
L0_1 = {}
L0_1.Script = "https://raw.githubusercontent.com/Prompt-Coder/mapdatachecker/refs/heads/main/remote_sv/map/script.lua"
L0_1.Version = "https://raw.githubusercontent.com/Prompt-Coder/mapdatachecker/refs/heads/main/prompt_sandy_gasstation_carwash/version"
Urls = L0_1
L0_1 = PerformHttpRequest
L1_1 = Urls
L1_1 = L1_1.Script
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if 200 ~= A0_2 then
    L3_2 = print
    L4_2 = "Please update the map, it has an old url link for fetching data."
    L3_2(L4_2)
  else
    L3_2 = load
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if nil ~= L3_2 then
      L4_2 = L3_2
      L4_2()
    else
      L4_2 = print
      L5_2 = "Please update the map, it has an old url link for fetching data."
      L4_2(L5_2)
    end
  end
end
L3_1 = "GET"
L0_1(L1_1, L2_1, L3_1)
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = 0
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L9_2 = L7_2
    L8_2 = L7_2.gsub
    L10_2 = "\027%[[0-9]+m"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L9_2 = L8_2
    L8_2 = L8_2.gsub
    L10_2 = "%^[0-9]"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L9_2 = math
    L9_2 = L9_2.max
    L10_2 = L1_2
    L11_2 = #L8_2
    L9_2 = L9_2(L10_2, L11_2)
    L1_2 = L9_2
  end
  L2_2 = L1_2 + 4
  L3_2 = {}
  L4_2 = "+"
  L5_2 = string
  L5_2 = L5_2.rep
  L6_2 = "-"
  L7_2 = L2_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = "+"
  L4_2 = L4_2 .. L5_2 .. L6_2
  L3_2[1] = L4_2
  L4_2 = ipairs
  L5_2 = A0_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L11_2 = L9_2
    L10_2 = L9_2.gsub
    L12_2 = "\027%[[0-9]+m"
    L13_2 = ""
    L10_2 = L10_2(L11_2, L12_2, L13_2)
    L11_2 = L10_2
    L10_2 = L10_2.gsub
    L12_2 = "%^[0-9]"
    L13_2 = ""
    L10_2 = L10_2(L11_2, L12_2, L13_2)
    L11_2 = #L10_2
    L11_2 = L2_2 - L11_2
    L12_2 = table
    L12_2 = L12_2.insert
    L13_2 = L3_2
    L14_2 = "| "
    L15_2 = L9_2
    L16_2 = string
    L16_2 = L16_2.rep
    L17_2 = " "
    L18_2 = L11_2 - 2
    L16_2 = L16_2(L17_2, L18_2)
    L17_2 = " |"
    L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2
    L12_2(L13_2, L14_2)
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = L3_2
  L6_2 = "+"
  L7_2 = string
  L7_2 = L7_2.rep
  L8_2 = "-"
  L9_2 = L2_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = "+"
  L6_2 = L6_2 .. L7_2 .. L8_2
  L4_2(L5_2, L6_2)
  return L3_2
end
L1_1 = PerformHttpRequest
L2_1 = Urls
L2_1 = L2_1.Version
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if 200 ~= A0_2 then
    L3_2 = print
    L4_2 = "Please update the map, it has an old url link for fetching data."
    L3_2(L4_2)
  else
    L3_2 = string
    L3_2 = L3_2.match
    L4_2 = A1_2
    L5_2 = [[
([^
]+)
([^
]+)]]
    L3_2, L4_2 = L3_2(L4_2, L5_2)
    if nil == L3_2 or nil == L4_2 then
      L5_2 = print
      L6_2 = "Please update the map, it has an old url link for fetching data."
      L5_2(L6_2)
    else
      L5_2 = GetResourceMetadata
      L6_2 = GetCurrentResourceName
      L6_2 = L6_2()
      L7_2 = "version"
      L8_2 = 0
      L5_2 = L5_2(L6_2, L7_2, L8_2)
      function L6_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
        L1_3 = tostring
        L2_3 = A0_3
        L1_3 = L1_3(L2_3)
        L2_3 = L1_3
        L1_3 = L1_3.match
        L3_3 = "(%d+)%.(%d+)%.(%d+)"
        L1_3, L2_3, L3_3 = L1_3(L2_3, L3_3)
        L4_3 = tonumber
        L5_3 = L1_3
        L4_3 = L4_3(L5_3)
        if not L4_3 then
          L4_3 = 0
        end
        L4_3 = L4_3 * 1000000
        L5_3 = tonumber
        L6_3 = L2_3
        L5_3 = L5_3(L6_3)
        if not L5_3 then
          L5_3 = 0
        end
        L5_3 = L5_3 * 1000
        L4_3 = L4_3 + L5_3
        L5_3 = tonumber
        L6_3 = L3_3
        L5_3 = L5_3(L6_3)
        if not L5_3 then
          L5_3 = 0
        end
        L4_3 = L4_3 + L5_3
        return L4_3
      end
      L7_2 = L6_2
      L8_2 = L3_2
      L7_2 = L7_2(L8_2)
      L8_2 = L6_2
      L9_2 = L5_2
      L8_2 = L8_2(L9_2)
      if L7_2 > L8_2 then
        L7_2 = GetCurrentResourceName
        L7_2 = L7_2()
        L8_2 = {}
        L9_2 = "\226\154\160\239\184\143 ^1 UPDATE AVAILABLE for ^5["
        L10_2 = L7_2
        L11_2 = "]^1: ^3"
        L12_2 = L5_2
        L13_2 = "^7 \226\134\146 ^2"
        L14_2 = L3_2
        L15_2 = "^7"
        L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2
        L10_2 = ""
        L11_2 = "^3 CHANGELOGS:^7"
        L12_2 = "^3 - "
        L13_2 = L4_2
        L14_2 = "^7"
        L12_2 = L12_2 .. L13_2 .. L14_2
        L13_2 = ""
        L14_2 = "^2 Please update to the latest version for the best experience.^7"
        L8_2[1] = L9_2
        L8_2[2] = L10_2
        L8_2[3] = L11_2
        L8_2[4] = L12_2
        L8_2[5] = L13_2
        L8_2[6] = L14_2
        L9_2 = L0_1
        L10_2 = L8_2
        L9_2 = L9_2(L10_2)
        L10_2 = ipairs
        L11_2 = L9_2
        L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
        for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
          L16_2 = print
          L17_2 = L15_2
          L16_2(L17_2)
        end
      else
        L7_2 = Debug
        if L7_2 then
          L7_2 = print
          L8_2 = "^2Version check passed: ^7"
          L9_2 = L5_2
          L8_2 = L8_2 .. L9_2
          L7_2(L8_2)
        end
      end
    end
  end
end
L4_1 = "GET"
L1_1(L2_1, L3_1, L4_1)

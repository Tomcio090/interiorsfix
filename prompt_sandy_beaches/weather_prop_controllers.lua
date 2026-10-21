local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = Config
if not L0_1 then
  L0_1 = {}
end
Config = L0_1
L0_1 = Config
L0_1 = L0_1.EnablePromptSupporter
if L0_1 then
  L0_1 = SetConvar
  L1_1 = "Prompt supporter"
  L2_1 = "true"
  L0_1(L1_1, L2_1)
  L0_1 = SetConvar
  L1_1 = "sets tags"
  L2_1 = "Prompt supporter"
  L0_1(L1_1, L2_1)
  L0_1 = print
  L1_1 = "^2Prompt supporter tag is enabled^0"
  L0_1(L1_1)
else
  L0_1 = SetConvar
  L1_1 = "Prompt supporter"
  L2_1 = "false"
  L0_1(L1_1, L2_1)
  L0_1 = GetConvar
  L1_1 = "tags"
  L2_1 = ""
  L0_1 = L0_1(L1_1, L2_1)
  L1_1 = string
  L1_1 = L1_1.gsub
  L2_1 = L0_1
  L3_1 = "Prompt supporter"
  L4_1 = ""
  L1_1 = L1_1(L2_1, L3_1, L4_1)
  L2_1 = SetConvar
  L3_1 = "sets tags"
  L4_1 = L1_1
  L2_1(L3_1, L4_1)
  L2_1 = print
  L3_1 = "^1Prompt supporter tag is disabled^0"
  L2_1(L3_1)
end

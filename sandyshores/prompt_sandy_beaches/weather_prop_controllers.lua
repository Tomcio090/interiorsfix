---------------------------------------------------------------------
-- PROMPT SANDY BEACHES (Marina) — Convar wsparcia (server)
-- Plik przepisany z zapisu dekompilatora na czytelny kod Lua (1:1).
-- Patrz ANALIZA.md, rozdz. 14.
---------------------------------------------------------------------

Config = Config or {}

if Config.EnablePromptSupporter then
    SetConvar("Prompt supporter", "true")
    SetConvar("sets tags", "Prompt supporter")
    print("^2Prompt supporter tag is enabled^0")
else
    SetConvar("Prompt supporter", "false")
    local currentTags = GetConvar("tags", "")
    local updatedTags = string.gsub(currentTags, "Prompt supporter", "")
    SetConvar("sets tags", updatedTags)
    print("^1Prompt supporter tag is disabled^0")
end

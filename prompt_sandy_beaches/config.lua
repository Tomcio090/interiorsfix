---------------------------------------------------------------------
-- PROMPT SANDY BEACHES (Marina) — Konfiguracja
-- Plik przepisany z zapisu dekompilatora na czytelny kod Lua (1:1).
-- Patrz ANALIZA.md, rozdz. 14.
---------------------------------------------------------------------

Config = {}

-- Logi diagnostyczne w konsoli (konfiguracja wody i propy pogodowe)
Config.Debug = false

-- Flaga tagu wspierającego autora w convarach serwera (weather_prop_controllers.lua)
Config.EnablePromptSupporter = true

-- Strefy modyfikacji tafli i wygładzania fal (client.lua)
Config.Zones = {
    alamo_sea = {
        enable = true,
        waterLevel = 30.0,
        waterAlpha = 18
    }
}

---------------------------------------------------------------------
-- PROMPT SANDY ILLEGAL GARAGE — Server loader
-- 1) Pobiera i URUCHAMIA zdalny skrypt "mapdata checker" (load + wykonanie).
-- 2) Sprawdza, czy dostępna jest nowsza wersja zasobu (plik "version").
--
-- UWAGA: Debug / MapId / Urls są GLOBALAMI celowo — zdalny skrypt
-- (remote_sv/map/script.lua) odczytuje je jako swój interfejs.
-- Nie zmieniaj ich na local, bo zdalny checker przestanie działać.
---------------------------------------------------------------------

Debug = false
MapId = "prompt_sandy_gasstation_carwash"

Urls = {
    Script  = "https://raw.githubusercontent.com/Prompt-Coder/mapdatachecker/refs/heads/main/remote_sv/map/script.lua",
    Version = "https://raw.githubusercontent.com/Prompt-Coder/mapdatachecker/refs/heads/main/prompt_sandy_gasstation_carwash/version"
}

-- Buduje ramkę tekstową ("box") o szerokości dopasowanej do najdłuższej linii.
-- Kody kolorów ANSI (\27[...m) i FiveM (^0-^9) są pomijane przy liczeniu długości.
local function createBox(lines)
    local maxLength = 0
    for _, line in ipairs(lines) do
        local stripped = line:gsub("\027%[[0-9]+m", ""):gsub("%^[0-9]", "")
        maxLength = math.max(maxLength, #stripped)
    end

    local boxWidth = maxLength + 4
    local result = {
        "+" .. string.rep("-", boxWidth) .. "+"
    }

    for _, line in ipairs(lines) do
        local stripped = line:gsub("\027%[[0-9]+m", ""):gsub("%^[0-9]", "")
        local padding = boxWidth - #stripped
        table.insert(result, "| " .. line .. string.rep(" ", padding - 2) .. " |")
    end

    table.insert(result, "+" .. string.rep("-", boxWidth) .. "+")
    return result
end

-- ── 1) Zdalny skrypt mapdata checker ────────────────────────────────
-- Pobrany kod jest wykonywany w kontekście serwera przez load().
PerformHttpRequest(Urls.Script, function(statusCode, body, headers)
    if statusCode ~= 200 then
        print("Please update the map, it has an old url link for fetching data.")
        return
    end

    local chunk = load(body)
    if chunk ~= nil then
        chunk()
    else
        print("Please update the map, it has an old url link for fetching data.")
    end
end, "GET")

-- ── 2) Sprawdzenie wersji ───────────────────────────────────────────
-- Format pliku "version": linia 1 = numer wersji, linia 2 = changelog.
PerformHttpRequest(Urls.Version, function(statusCode, body, headers)
    if statusCode ~= 200 then
        print("Please update the map, it has an old url link for fetching data.")
        return
    end

    local latestVersion, changelog = string.match(body, "([^\n]+)\n([^\n]+)")
    if latestVersion == nil or changelog == nil then
        print("Please update the map, it has an old url link for fetching data.")
        return
    end

    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

    -- "1.2.3" -> 1002003 (porównywalna liczba; brakujące składowe = 0)
    local function versionToNumber(version)
        local major, minor, patch = tostring(version):match("(%d+)%.(%d+)%.(%d+)")
        return (tonumber(major) or 0) * 1000000
             + (tonumber(minor) or 0) * 1000
             + (tonumber(patch) or 0)
    end

    if versionToNumber(latestVersion) > versionToNumber(currentVersion) then
        local lines = {
            "⚠️ ^1 UPDATE AVAILABLE for ^5[" .. GetCurrentResourceName() .. "]^1: ^3" .. currentVersion .. "^7 → ^2" .. latestVersion .. "^7",
            "",
            "^3 CHANGELOGS:^7",
            "^3 - " .. changelog .. "^7",
            "",
            "^2 Please update to the latest version for the best experience.^7"
        }

        for _, line in ipairs(createBox(lines)) do
            print(line)
        end
    elseif Debug then
        print("^2Version check passed: ^7" .. currentVersion)
    end
end, "GET")

---------------------------------------------------------------------
-- PROMPT SANDY BEACHES (Marina) — Konfiguracja wody Alamo Sea (client)
-- Wyszukuje w pamięci gry prostokąty tafli wody (WaterQuads) oraz
-- wygładzania fal (CalmingQuads) po środkach i granicach oryginalnych
-- quadów GTA V, a następnie ustawia poziom wody, przezroczystość
-- (alpha), tłumienie fal i skorygowane granice brzegu mariny.
--
-- Plik przepisany z zapisu dekompilatora na czytelny kod Lua —
-- wszystkie 78 Water_Quads, 3 Calm_Quads oraz parametry docelowe
-- zachowane 1:1. Patrz ANALIZA.md, rozdz. 14.
--
-- Naprawione błędy oryginału i artefakty dekompilacji:
--   1. KRYTYCZNY CRASH PRZY STARCIE: natywka FiveM GetWaterQuadBounds
--      zwraca PIĘĆ wartości (found, minX, minY, maxX, maxY), tak samo
--      jak GetCalmingQuadBounds (WaterExtraNatives.cpp w citizenfx/fivem).
--      W wątku startowym (oraz w helperze getWaterQuadBounds) oryginał
--      rozpakowywał tylko 4 zmienne, przez co boolean `found = true`
--      trafiał do `string.format("... minX=%.0f ...", ...)` ZANIM
--      debugLog sprawdził `Config.Debug` — wywalało to wątek błędem
--      `bad argument #3 to format (number expected, got boolean)`
--      zanim Config.Zones w ogóle zdążyło się wykonać!
--   2. REKONSTRUKCJA PO DEKOMPILACJI w findMatchingQuad: dekompilator
--      uszkodził 4-członową koniunkcję `matches` (zostawił wyłącznie
--      porównanie `minX`, martwe odczyty `minY/maxX/maxY` oraz
--      niezadeklarowany global `matches` poniżej). Odtworzono pełne
--      porównanie wszystkich 4 granic z tolerancją 10.0 + bezpieczny
--      fallback do granic docelowych (MODIFIED_QUADS), aby żywy restart
--      zasobu (`/restart prompt_sandy_beaches`) w trakcie sesji nadal
--      rozpoznawał quady ze zmienionymi już granicami brzegu.
---------------------------------------------------------------------

local ORIGINAL_QUADS = {
    alamo_sea = {
        Water_Quads = {
            [508] = { minX = 1304, maxX = 1500, minY = 3796, maxY = 4000, center = { x = 1402.0, y = 3898.0 } },
            [382] = { minX = -84, maxX = -16, minY = 4256, maxY = 4416, center = { x = -50.0, y = 4336.0 } },
            [510] = { minX = 1000, maxX = 1500, minY = 4000, maxY = 4380, center = { x = 1250.0, y = 4190.0 } },
            [538] = { minX = 1948, maxX = 2000, minY = 3932, maxY = 3960, center = { x = 1974.0, y = 3946.0 } },
            [539] = { minX = 1500, maxX = 1540, minY = 3776, maxY = 3796, center = { x = 1520.0, y = 3786.0 } },
            [540] = { minX = 1540, maxX = 1612, minY = 3828, maxY = 3860, center = { x = 1576.0, y = 3844.0 } },
            [541] = { minX = 1500, maxX = 1540, minY = 3796, maxY = 4000, center = { x = 1520.0, y = 3898.0 } },
            [542] = { minX = 1540, maxX = 1728, minY = 3964, maxY = 4000, center = { x = 1634.0, y = 3982.0 } },
            [543] = { minX = 1728, maxX = 1816, minY = 3964, maxY = 3992, center = { x = 1772.0, y = 3978.0 } },
            [544] = { minX = 1816, maxX = 1932, minY = 3976, maxY = 3992, center = { x = 1874.0, y = 3984.0 } },
            [545] = { minX = 1932, maxX = 2000, minY = 3960, maxY = 3992, center = { x = 1966.0, y = 3976.0 } },
            [546] = { minX = 1728, maxX = 2000, minY = 3992, maxY = 4000, center = { x = 1864.0, y = 3996.0 } },
            [547] = { minX = 1684, maxX = 1728, minY = 3908, maxY = 3964, center = { x = 1706.0, y = 3936.0 } },
            [548] = { minX = 1540, maxX = 1684, minY = 3860, maxY = 3964, center = { x = 1612.0, y = 3912.0 } },
            [549] = { minX = 1656, maxX = 2000, minY = 4380, maxY = 4500, center = { x = 1828.0, y = 4440.0 } },
            [550] = { minX = 1500, maxX = 1656, minY = 4380, maxY = 4500, center = { x = 1578.0, y = 4440.0 } },
            [551] = { minX = 1500, maxX = 2000, minY = 4000, maxY = 4380, center = { x = 1750.0, y = 4190.0 } },
            [552] = { minX = 1656, maxX = 2000, minY = 4500, maxY = 4580, center = { x = 1828.0, y = 4540.0 } },
            [439] = { minX = 152, maxX = 332, minY = 3428, maxY = 3500, center = { x = 242.0, y = 3464.0 } },
            [440] = { minX = 124, maxX = 152, minY = 3428, maxY = 3500, center = { x = 138.0, y = 3464.0 } },
            [441] = { minX = 332, maxX = 500, minY = 3596, maxY = 4000, center = { x = 416.0, y = 3798.0 } },
            [442] = { minX = 104, maxX = 332, minY = 3788, maxY = 4000, center = { x = 218.0, y = 3894.0 } },
            [443] = { minX = 160, maxX = 172, minY = 3664, maxY = 3684, center = { x = 166.0, y = 3674.0 } },
            [444] = { minX = 132, maxX = 172, minY = 3684, maxY = 3788, center = { x = 152.0, y = 3736.0 } },
            [445] = { minX = 0, maxX = 104, minY = 3808, maxY = 4000, center = { x = 52.0, y = 3904.0 } },
            [446] = { minX = 76, maxX = 104, minY = 3796, maxY = 3808, center = { x = 90.0, y = 3802.0 } },
            [447] = { minX = 0, maxX = 36, minY = 3780, maxY = 3808, center = { x = 18.0, y = 3794.0 } },
            [448] = { minX = 152, maxX = 332, minY = 3500, maxY = 3596, center = { x = 242.0, y = 3548.0 } },
            [449] = { minX = 150, maxX = 152, minY = 3500, maxY = 3508, center = { x = 151.0, y = 3504.0 } },
            [450] = { minX = 172, maxX = 332, minY = 3596, maxY = 3788, center = { x = 252.0, y = 3692.0 } },
            [451] = { minX = 496, maxX = 500, minY = 4000, maxY = 4224, center = { x = 498.0, y = 4112.0 } },
            [452] = { minX = 332, maxX = 496, minY = 4000, maxY = 4340, center = { x = 414.0, y = 4170.0 } },
            [453] = { minX = 104, maxX = 332, minY = 4000, maxY = 4376, center = { x = 218.0, y = 4188.0 } },
            [581] = { minX = 2044, maxX = 2068, minY = 3876, maxY = 3900, center = { x = 2056.0, y = 3888.0 } },
            [582] = { minX = 2068, maxX = 2092, minY = 3880, maxY = 3900, center = { x = 2080.0, y = 3890.0 } },
            [583] = { minX = 2092, maxX = 2212, minY = 3928, maxY = 4000, center = { x = 2152.0, y = 3964.0 } },
            [584] = { minX = 2092, maxX = 2132, minY = 3880, maxY = 3900, center = { x = 2112.0, y = 3890.0 } },
            [585] = { minX = 2132, maxX = 2212, minY = 3880, maxY = 3900, center = { x = 2172.0, y = 3890.0 } },
            [586] = { minX = 2212, maxX = 2252, minY = 3892, maxY = 3924, center = { x = 2232.0, y = 3908.0 } },
            [587] = { minX = 2108, maxX = 2192, minY = 3832, maxY = 3844, center = { x = 2150.0, y = 3838.0 } },
            [588] = { minX = 2116, maxX = 2148, minY = 3844, maxY = 3872, center = { x = 2132.0, y = 3858.0 } },
            [589] = { minX = 2140, maxX = 2184, minY = 3808, maxY = 3832, center = { x = 2162.0, y = 3820.0 } },
            [590] = { minX = 2104, maxX = 2140, minY = 3800, maxY = 3832, center = { x = 2122.0, y = 3816.0 } },
            [591] = { minX = 2212, maxX = 2308, minY = 3924, maxY = 4000, center = { x = 2260.0, y = 3962.0 } },
            [593] = { minX = 2000, maxX = 2012, minY = 3932, maxY = 3960, center = { x = 2006.0, y = 3946.0 } },
            [594] = { minX = 2012, maxX = 2092, minY = 3928, maxY = 3960, center = { x = 2052.0, y = 3944.0 } },
            [595] = { minX = 2044, maxX = 2212, minY = 3900, maxY = 3928, center = { x = 2128.0, y = 3914.0 } },
            [596] = { minX = 2148, maxX = 2212, minY = 3844, maxY = 3880, center = { x = 2180.0, y = 3862.0 } },
            [597] = { minX = 2000, maxX = 2092, minY = 3960, maxY = 4000, center = { x = 2046.0, y = 3980.0 } },
            [598] = { minX = 2308, maxX = 2396, minY = 4000, maxY = 4056, center = { x = 2352.0, y = 4028.0 } },
            [599] = { minX = 2308, maxX = 2384, minY = 4056, maxY = 4100, center = { x = 2346.0, y = 4078.0 } },
            [600] = { minX = 2308, maxX = 2432, minY = 4100, maxY = 4500, center = { x = 2370.0, y = 4300.0 } },
            [601] = { minX = 2000, maxX = 2308, minY = 4000, maxY = 4500, center = { x = 2154.0, y = 4250.0 } },
            [602] = { minX = 2092, maxX = 2308, minY = 4500, maxY = 4676, center = { x = 2200.0, y = 4588.0 } },
            [603] = { minX = 2308, maxX = 2432, minY = 4500, maxY = 4598, center = { x = 2370.0, y = 4549.0 } },
            [605] = { minX = 2000, maxX = 2092, minY = 4500, maxY = 4580, center = { x = 2046.0, y = 4540.0 } },
            [486] = { minX = 740, maxX = 848, minY = 3624, maxY = 4000, center = { x = 794.0, y = 3812.0 } },
            [487] = { minX = 500, maxX = 740, minY = 3596, maxY = 4000, center = { x = 620.0, y = 3798.0 } },
            [488] = { minX = 848, maxX = 1000, minY = 3636, maxY = 4000, center = { x = 924.0, y = 3818.0 } },
            [489] = { minX = 500, maxX = 1000, minY = 4000, maxY = 4224, center = { x = 750.0, y = 4112.0 } },
            [490] = { minX = 840, maxX = 1000, minY = 4224, maxY = 4380, center = { x = 920.0, y = 4302.0 } },
            [364] = { minX = -172, maxX = -148, minY = 3908, maxY = 3932, center = { x = -160.0, y = 3920.0 } },
            [365] = { minX = -212, maxX = -148, minY = 3840, maxY = 3864, center = { x = -180.0, y = 3852.0 } },
            [366] = { minX = -208, maxX = -148, minY = 3864, maxY = 3900, center = { x = -178.0, y = 3882.0 } },
            [368] = { minX = -100, maxX = -20, minY = 3728, maxY = 3764, center = { x = -60.0, y = 3746.0 } },
            [360] = { minX = -16, maxX = 0, minY = 3808, maxY = 4000, center = { x = -8.0, y = 3904.0 } },
            [362] = { minX = -176, maxX = -16, minY = 3932, maxY = 4000, center = { x = -96.0, y = 3966.0 } },
            [371] = { minX = -108, maxX = -16, minY = 3764, maxY = 3932, center = { x = -62.0, y = 3848.0 } },
            [372] = { minX = -16, maxX = 0, minY = 4000, maxY = 4416, center = { x = -8.0, y = 4208.0 } },
            [373] = { minX = -176, maxX = -16, minY = 4000, maxY = 4064, center = { x = -96.0, y = 4032.0 } },
            [374] = { minX = -216, maxX = -176, minY = 4012, maxY = 4064, center = { x = -196.0, y = 4038.0 } },
            [375] = { minX = -228, maxX = -212, minY = 4064, maxY = 4088, center = { x = -220.0, y = 4076.0 } },
            [376] = { minX = -212, maxX = -16, minY = 4064, maxY = 4256, center = { x = -114.0, y = 4160.0 } },
            [454] = { minX = 0, maxX = 104, minY = 4000, maxY = 4416, center = { x = 52.0, y = 4208.0 } },
            [363] = { minX = -148, maxX = -108, minY = 3796, maxY = 3932, center = { x = -128.0, y = 3864.0 } },
            [506] = { minX = 1000, maxX = 1304, minY = 3636, maxY = 4000, center = { x = 1152.0, y = 3818.0 } },
            [507] = { minX = 1304, maxX = 1500, minY = 3676, maxY = 3796, center = { x = 1402.0, y = 3736.0 } },
            [361] = { minX = -16, maxX = 0, minY = 3768, maxY = 3808, center = { x = -8.0, y = 3788.0 } }
        },
        Calm_Quads = {
            [346] = { minX = 1384, maxX = 1500, minY = 3724, maxY = 3848, center = { x = 1442.0, y = 3786.0 } },
            [347] = { minX = 1500, maxX = 2016, minY = 3796, maxY = 3944, center = { x = 1758.0, y = 3870.0 } },
            [344] = { minX = 948, maxX = 1260, minY = 3564, maxY = 3684, center = { x = 1104.0, y = 3624.0 } }
        }
    }
}

local MODIFIED_QUADS = {
    alamo_sea = {
        Water_Quads = {
            [544] = { minX = 1816, maxX = 1932, minY = 3986, maxY = 3992 },
            [508] = { minX = 1304, maxX = 1500, minY = 3796, maxY = 4000 },
            [488] = { minX = 848, maxX = 1000, minY = 3653, maxY = 4000 },
            [506] = { minX = 1000, maxX = 1304, minY = 3653, maxY = 4000 }
        },
        Calm_Quads = {
            [346] = { minX = 1384, maxX = 1500, minY = 3724, maxY = 3898, dampening = 0.0 },
            [347] = { dampening = 0.0 },
            [344] = { minX = 948, maxX = 1260, minY = 3663, maxY = 3684, dampening = 0.0 }
        }
    }
}

local missingWaterQuads = {}
local missingCalmQuads = {}

local QUAD_MATCH_TOLERANCE = 10.0

local function debugLog(message)
    if Config.Debug then
        print("[water_edit] " .. message)
    end
end

local function getWaterQuadBounds(quadId)
    local found, minX, minY, maxX, maxY = GetWaterQuadBounds(quadId)
    if found and minX and minY and maxX and maxY then
        return {
            minX = minX,
            minY = minY,
            maxX = maxX,
            maxY = maxY
        }
    end
    return nil
end

local function calculateOverlap(minX1, minY1, maxX1, maxY1, minX2, minY2, maxX2, maxY2)
    if not (minX1 and minY1 and maxX1 and maxY1 and minX2 and minY2 and maxX2 and maxY2) then
        debugLog("Error: Valores nil en CalculateOverlap")
        return 0.0
    end

    minX1 = tonumber(minX1)
    minY1 = tonumber(minY1)
    maxX1 = tonumber(maxX1)
    maxY1 = tonumber(maxY1)
    minX2 = tonumber(minX2)
    minY2 = tonumber(minY2)
    maxX2 = tonumber(maxX2)
    maxY2 = tonumber(maxY2)

    if not (minX1 and minY1 and maxX1 and maxY1 and minX2 and minY2 and maxX2 and maxY2) then
        debugLog("Error: No se pudieron convertir valores a números en CalculateOverlap")
        return 0.0
    end

    local interMinX = math.max(minX1, minX2)
    local interMinY = math.max(minY1, minY2)
    local interMaxX = math.min(maxX1, maxX2)
    local interMaxY = math.min(maxY1, maxY2)

    if interMinX > interMaxX or interMinY > interMaxY then
        return 0.0
    end

    local area1 = (maxX1 - minX1) * (maxY1 - minY1)
    local area2 = (maxX2 - minX2) * (maxY2 - minY2)
    local interArea = (interMaxX - interMinX) * (interMaxY - interMinY)

    if area1 <= 0 or area2 <= 0 then
        return 0.0
    end

    return interArea / math.min(area1, area2)
end

local function boundsMatch(minX, minY, maxX, maxY, referenceBounds, tolerance)
    local refMinX = tonumber(referenceBounds.minX)
    local refMinY = tonumber(referenceBounds.minY)
    local refMaxX = tonumber(referenceBounds.maxX)
    local refMaxY = tonumber(referenceBounds.maxY)
    if not (refMinX and refMinY and refMaxX and refMaxY) then
        return false
    end

    return math.abs(minX - refMinX) <= tolerance
        and math.abs(minY - refMinY) <= tolerance
        and math.abs(maxX - refMaxX) <= tolerance
        and math.abs(maxY - refMaxY) <= tolerance
end

local function queryQuadAtPoint(x, y, isCalmQuad)
    local quadId
    if isCalmQuad then
        quadId = GetCalmingQuadAtCoords(x, y)
    else
        quadId = GetWaterQuadAtCoords(x, y)
    end

    if quadId == nil or quadId == -1 then
        return -1, false, nil, nil, nil, nil
    end

    local found, minX, minY, maxX, maxY
    if isCalmQuad then
        found, minX, minY, maxX, maxY = GetCalmingQuadBounds(quadId)
    else
        found, minX, minY, maxX, maxY = GetWaterQuadBounds(quadId)
    end

    return quadId, found, minX, minY, maxX, maxY
end

local function findMatchingQuad(originalQuadData, isCalmQuad, quadKey, modifiedQuadData)
    if not originalQuadData then
        debugLog("Error: originalQuadData es nil")
        return nil
    end

    local centerX = tonumber(originalQuadData.center.x)
    local centerY = tonumber(originalQuadData.center.y)
    local quadId, found, minX, minY, maxX, maxY = queryQuadAtPoint(centerX, centerY, isCalmQuad)

    if quadId ~= -1 and found and minX and minY and maxX and maxY then
        if boundsMatch(minX, minY, maxX, maxY, originalQuadData, QUAD_MATCH_TOLERANCE) then
            debugLog(string.format("Quad %d encontrado y coincide", quadId))
            return quadId
        end
    end

    -- Fallback dla restartu zasobu w trakcie trwającej sesji (gdy granice
    -- quada zostały już wcześniej przesunięte do wartości z MODIFIED_QUADS)
    if modifiedQuadData and modifiedQuadData.minX and modifiedQuadData.minY and modifiedQuadData.maxX and modifiedQuadData.maxY then
        local modCenterX = (tonumber(modifiedQuadData.minX) + tonumber(modifiedQuadData.maxX)) * 0.5
        local modCenterY = (tonumber(modifiedQuadData.minY) + tonumber(modifiedQuadData.maxY)) * 0.5
        local modQuadId, modFound, modMinX, modMinY, modMaxX, modMaxY = queryQuadAtPoint(modCenterX, modCenterY, isCalmQuad)

        if modQuadId ~= -1 and modFound and modMinX and modMinY and modMaxX and modMaxY then
            if boundsMatch(modMinX, modMinY, modMaxX, modMaxY, modifiedQuadData, QUAD_MATCH_TOLERANCE) then
                debugLog(string.format("Quad %d encontrado y coincide", modQuadId))
                return modQuadId
            end
        end
    end

    if isCalmQuad then
        table.insert(missingCalmQuads, quadKey)
    else
        table.insert(missingWaterQuads, quadKey)
    end
    return nil
end

local function updateWaterZone(zoneName, zoneConfig)
    local originalZone = ORIGINAL_QUADS[zoneName]
    if not originalZone then
        return
    end

    local waterLevel = zoneConfig.waterLevel
    local waterAlpha = zoneConfig.waterAlpha
    local modifiedZone = MODIFIED_QUADS[zoneName]

    debugLog("Iniciando actualización de zona: " .. zoneName)

    for quadKey, originalQuad in pairs(originalZone.Water_Quads) do
        local modifiedQuad = modifiedZone and modifiedZone.Water_Quads and modifiedZone.Water_Quads[quadKey] or nil
        local quadId = findMatchingQuad(originalQuad, false, quadKey, modifiedQuad)

        if quadId then
            if waterLevel then
                SetWaterQuadLevel(quadId, waterLevel)
            end
            if waterAlpha then
                SetWaterQuadAlpha(quadId, waterAlpha, waterAlpha, waterAlpha, waterAlpha)
            end
            if modifiedQuad then
                SetWaterQuadBounds(
                    quadId,
                    modifiedQuad.minX,
                    modifiedQuad.minY,
                    modifiedQuad.maxX,
                    modifiedQuad.maxY
                )
            end
        end
    end

    for quadKey, originalQuad in pairs(originalZone.Calm_Quads or {}) do
        local modifiedQuad = modifiedZone and modifiedZone.Calm_Quads and modifiedZone.Calm_Quads[quadKey] or nil
        local quadId = findMatchingQuad(originalQuad, true, quadKey, modifiedQuad)

        if quadId and modifiedQuad then
            if modifiedQuad.dampening then
                SetCalmingQuadDampening(quadId, modifiedQuad.dampening)
            end
            if modifiedQuad.minX and modifiedQuad.minY and modifiedQuad.maxX and modifiedQuad.maxY then
                SetCalmingQuadBounds(
                    quadId,
                    modifiedQuad.minX,
                    modifiedQuad.minY,
                    modifiedQuad.maxX,
                    modifiedQuad.maxY
                )
            end
        end
    end

    missingWaterQuads = {}
    missingCalmQuads = {}
    debugLog("Finalizada actualización de zona: " .. zoneName)
end

CreateThread(function()
    debugLog("Starting water zones configuration")

    local diagnosticPoints = {
        { name = "Quad [52]", x = 1076.0, y = 3930.0 },
        { name = "Calm [344]", x = 1104.0, y = 3624.0 }
    }

    for _, point in ipairs(diagnosticPoints) do
        local waterQuad = GetWaterQuadAtCoords(point.x, point.y)
        local calmQuad = GetCalmingQuadAtCoords(point.x, point.y)
        debugLog(string.format(
            "%s at (%.1f, %.1f): WaterQuad=%d, CalmQuad=%d",
            point.name, point.x, point.y, waterQuad, calmQuad
        ))

        if waterQuad ~= -1 then
            local found, minX, minY, maxX, maxY = GetWaterQuadBounds(waterQuad)
            if found then
                debugLog(string.format(
                    "  WaterQuad %d bounds: minX=%.0f, minY=%.0f, maxX=%.0f, maxY=%.0f",
                    waterQuad, minX, minY, maxX, maxY
                ))
            end
        end

        if calmQuad ~= -1 then
            local found, minX, minY, maxX, maxY = GetCalmingQuadBounds(calmQuad)
            if found then
                debugLog(string.format(
                    "  CalmQuad %d bounds: minX=%.0f, minY=%.0f, maxX=%.0f, maxY=%.0f",
                    calmQuad, minX, minY, maxX, maxY
                ))
            end
        end
    end

    for zoneName, zoneConfig in pairs(Config.Zones) do
        if zoneConfig.enable then
            updateWaterZone(zoneName, zoneConfig)
        end
    end
end)

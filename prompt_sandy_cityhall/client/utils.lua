---------------------------------------------------------------------
-- PROMPT SANDY CITYHALL — Client utils
-- Krzywe easingowe cubic-bezier (port biblioteki "bezier-easing")
-- + animowanie pozycji obiektu w czasie (winda).
--
-- Plik przepisany z zapisu dekompilatora
-- na czytelny kod — zachowane wszystkie nazwy globalne, wartości
-- i kolejność; patrz ANALIZA.md, rozdz. 13.
--
-- UWAGA: funkcje A, B, C, calcBezier, getSlope,
-- newtonRaphsonIterate, bezier, TranslateObjectCoordsCubicBezier
-- oraz math.lerp / math.invlerp są GLOBALNE celowo — w takim
-- kształcie występowały w oryginale i może z nich korzystać
-- kod zewnętrzny. Nie zmieniaj ich na local bez potrzeby.
---------------------------------------------------------------------

local NEWTON_ITERATIONS = 10
local NEWTON_MIN_SLOPE  = 0.01
local SPLINE_TABLE_SIZE = 11
local SAMPLE_STEP_SIZE  = 1.0 / (SPLINE_TABLE_SIZE - 1.0)

-- Współczynniki wielomianu krzywej Beziera (postać Hornera)
function A(a1, a2)
    return 1.0 - 3.0 * a2 + 3.0 * a1
end

function B(a1, a2)
    return 3.0 * a2 - 6.0 * a1
end

function C(a1)
    return 3.0 * a1
end

-- Interpolacja liniowa: lerp(start, koniec, t)
function math.lerp(from, to, t)
    return from + (to - from) * t
end

-- Odwrotna interpolacja: invlerp(start, koniec, wartosc) -> t
function math.invlerp(from, to, value)
    return (value - from) / (to - from)
end

-- Wartość krzywej x(t) dla parametru t
function calcBezier(t, a1, a2)
    return ((A(a1, a2) * t + B(a1, a2)) * t + C(a1)) * t
end

-- Pochodna (nachylenie) krzywej x(t) dla parametru t
function getSlope(t, a1, a2)
    return 3.0 * A(a1, a2) * t * t + 2.0 * B(a1, a2) * t + C(a1)
end

-- Szuka parametru t dla danego x metodą Newtona-Raphsona
function newtonRaphsonIterate(x, guessT, mX1, mX2)
    for _ = 1, NEWTON_ITERATIONS do
        local slope = getSlope(guessT, mX1, mX2)
        if slope == 0.0 then
            return guessT
        end

        local currentX = calcBezier(guessT, mX1, mX2) - x
        guessT = guessT - currentX / slope
    end

    return guessT
end

-- Tworzy funkcję easingową cubic-bezier(mX1, mY1, mX2, mY2) jak w CSS.
-- Zwrócona funkcja przyjmuje postęp x (0..1) i zwraca wartość y.
function bezier(mX1, mY1, mX2, mY2)
    if not (mX1 >= 0 and mX1 <= 1 and mX2 >= 0 and mX2 <= 1) then
        error("bezier x values must be in [0, 1] range")
    end

    -- Krzywa liniowa: zwracamy funkcję tożsamościową
    if mX1 == mY1 and mX2 == mY2 then
        return function(x)
            return x
        end
    end

    -- Tablica próbek x(t) co 0.1 (indeksy 1..11 odpowiadają t = 0.0..1.0)
    local sampleValues = {}
    for i = 0, SPLINE_TABLE_SIZE - 1 do
        sampleValues[i + 1] = calcBezier(i * SAMPLE_STEP_SIZE, mX1, mX2)
    end

    local function getTForX(x)
        local intervalStart = 0.0
        local currentSample = 1
        local lastSample = #sampleValues

        while currentSample < lastSample do
            if not (x >= sampleValues[currentSample]) then
                break
            end
            intervalStart = intervalStart + SAMPLE_STEP_SIZE
            currentSample = currentSample + 1
        end
        currentSample = currentSample - 1

        local dist = (x - sampleValues[currentSample])
                   / (sampleValues[currentSample + 1] - sampleValues[currentSample])
        local guessForT = intervalStart + dist * SAMPLE_STEP_SIZE

        local initialSlope = getSlope(guessForT, mX1, mX2)
        if initialSlope >= NEWTON_MIN_SLOPE then
            guessForT = newtonRaphsonIterate(x, guessForT, mX1, mX2)
        end

        return guessForT
    end

    return function(x)
        if x == 0 or x == 1 then
            return x
        end
        return calcBezier(getTForX(x), mY1, mY2)
    end
end

-- Presety krzywych. UWAGA (zachowane z oryginału jako informacja):
-- w zdekompilowanym kodzie ta tabela była tworzona jako local, ale
-- NIGDY nie była przypisana do żadnej zmiennej globalnej ani użyta
-- — to martwy kod. Winda buduje krzywe bez niej (bezier(...) z
-- jawnymi parametrami).
local EASING_PRESETS = {
    ease      = { 0.25, 0.1, 0.25, 1 },
    easeIn    = { 0.42, 0, 1, 1 },
    easeOut   = { 0, 0, 0.58, 1 },
    easeInOut = { 0.42, 0, 0.58, 1 }
}

-- Animuje pozycję obiektu z jego bieżącej pozycji do endCoords
-- w czasie duration ms, według krzywej cubic-bezier.
--
-- Parametry curveKey i targetFloor są przyjmowane dla zgodności z
-- wywołaniem w client.lua, ale w oryginale nie były w funkcji
-- używane (nazwa krzywej nie wpływa na trajektorię) — zachowane.
--
-- startTime: znacznik GetNetworkTimeAccurate, od którego liczymy
-- postęp (domyślnie: bieżący czas).
function TranslateObjectCoordsCubicBezier(entity, endCoords, duration, curveType, curveKey, targetFloor, startTime)
    if not entity or not DoesEntityExist(entity) then return end

    local startCoords = GetEntityCoords(entity)
    local start = startTime or GetNetworkTimeAccurate()

    local easing = bezier(0.42, 0, 0.58, 1)
    if curveType == "easeIn" then
        easing = bezier(0.42, 0, 1, 1)
    elseif curveType == "easeOut" then
        easing = bezier(0, 0, 0.58, 1)
    end

    local function lerpX(t) return math.lerp(startCoords.x, endCoords.x, t) end
    local function lerpY(t) return math.lerp(startCoords.y, endCoords.y, t) end
    local function lerpZ(t) return math.lerp(startCoords.z, endCoords.z, t) end

    CreateThread(function()
        while true do
            local t = math.min((GetNetworkTimeAccurate() - start) / duration, 1.0)
            if t >= 1.0 then
                -- Dokładne dotarcie do celu (bez ułamkowych resztek lerp)
                SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                break
            end

            local eased = easing(t)
            local pos = vector3(lerpX(eased), lerpY(eased), lerpZ(eased))
            SetEntityCoords(entity, pos.x, pos.y, pos.z, false, false, false, false)
            Wait(0)
        end
    end)
end

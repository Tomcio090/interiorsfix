---------------------------------------------------------------------
-- PROMPT SANDY MECHANIC — Client utils
-- Krzywe easingowe cubic-bezier (port biblioteki "bezier-easing")
-- + pomocnicze animowanie pozycji / rotacji encji w czasie.
--
-- UWAGA: funkcje A, B, C, calcBezier, getSlope, newtonRaphsonIterate,
-- bezier, AnimateObjectCoords, AnimateObjectRotation,
-- MovePlayerToPosition oraz math.lerp / math.invlerp są GLOBALNE
-- celowo — w takim kształcie występowały w oryginale i może z nich
-- korzystać kod zewnętrzny. Nie zmieniaj ich na local bez potrzeby.
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

-- Wartość krzywej dla parametru t
function calcBezier(t, a1, a2)
    return ((A(a1, a2) * t + B(a1, a2)) * t + C(a1)) * t
end

-- Pochodna (nachylenie) krzywej dla parametru t
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

        -- Uwaga: w zdekompilowanym oryginale stało tu jeszcze wywołanie
        -- calcBezier(guessForT, mX1, mX2), którego wynik nigdy nie był
        -- użyty (martwe wywołanie) — świadomie usunięte przy czyszczeniu.
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
-- NIGDY nie była przypisana do żadnej zmiennej globalnej ani użyta —
-- to martwy kod. AnimateObjectCoords buduje krzywe bez niej.
local EASING_PRESETS = {
    ease      = { 0.25, 0.1, 0.25, 1 },
    easeIn    = { 0.42, 0, 1, 1 },
    easeOut   = { 0, 0, 0.58, 1 },
    easeInOut = { 0.42, 0, 0.58, 1 }
}

-- Animuje pozycję encji z punktu startCoords do endCoords.
-- curve: nazwa krzywej (string), własna funkcja easingowa albo nil
--        (= domyślnie easeInOut cubic-bezier(0.42, 0, 0.58, 1)).
-- onComplete: opcjonalny callback wywoływany po zakończeniu.
function AnimateObjectCoords(entity, startCoords, endCoords, duration, curve, onComplete)
    if not entity or not DoesEntityExist(entity) then return end

    local startTime = GetGameTimer()
    local easing = bezier(0.42, 0, 0.58, 1)

    if type(curve) == "string" then
        if curve == "easeIn" then
            easing = bezier(0.42, 0, 1, 1)
        elseif curve == "easeOut" then
            easing = bezier(0, 0, 0.58, 1)
        elseif curve == "linear" then
            easing = function(t) return t end
        elseif curve == "easeInQuad" then
            easing = function(t) return t * t end
        elseif curve == "easeOutQuad" then
            easing = function(t) return t * (2 - t) end
        elseif curve == "easeInOutQuad" then
            easing = function(t)
                if t < 0.5 then
                    return 2 * t * t
                else
                    return -1 + (4 - 2 * t) * t
                end
            end
        elseif curve == "easeInCubic" then
            easing = function(t) return t * t * t end
        elseif curve == "easeOutCubic" then
            easing = function(t)
                t = t - 1
                return t * t * t + 1
            end
        elseif curve == "easeInOutCubic" then
            easing = function(t)
                if t < 0.5 then
                    return 4 * t * t * t
                else
                    return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
                end
            end
        elseif curve == "easeInElastic" then
            easing = function(t)
                local c4 = 2 * math.pi / 3
                if t == 0 then
                    return 0
                elseif t == 1 then
                    return 1
                else
                    -- math.pow w oryginale; operator ^ daje ten sam wynik
                    -- i działa w Lua 5.4, gdzie math.pow usunięto.
                    return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
                end
            end
        elseif curve == "easeOutElastic" then
            easing = function(t)
                local c4 = 2 * math.pi / 3
                if t == 0 then
                    return 0
                elseif t == 1 then
                    return 1
                else
                    return (2 ^ (-10 * t)) * math.sin((t * 10 - 0.75) * c4) + 1
                end
            end
        end
        -- nieznana nazwa -> zostaje domyślna easeInOut
    elseif type(curve) == "function" then
        easing = curve
    end

    local function lerpX(t) return math.lerp(startCoords.x, endCoords.x, t) end
    local function lerpY(t) return math.lerp(startCoords.y, endCoords.y, t) end
    local function lerpZ(t) return math.lerp(startCoords.z, endCoords.z, t) end

    CreateThread(function()
        while true do
            local progress = math.min((GetGameTimer() - startTime) / duration, 1.0)

            if progress >= 1.0 then
                SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                if onComplete then
                    onComplete()
                end
                break
            end

            local eased = easing(progress)
            local coords = vector3(lerpX(eased), lerpY(eased), lerpZ(eased))
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
            Wait(0)
        end
    end)
end

-- Animuje rotację encji ze startRotation do endRotation (kąty Eulera).
-- curve: obsługuje TYLKO "easeIn" / "easeOut" (jak w oryginale);
--        każda inna wartość (także funkcja) oznacza domyślną easeInOut.
function AnimateObjectRotation(entity, startRotation, endRotation, duration, curve, onComplete)
    if not entity or not DoesEntityExist(entity) then return end

    local startTime = GetGameTimer()
    -- W oryginale było tu jeszcze GetEntityRotation(entity, 0), którego
    -- wynik nigdy nie był użyty (start pochodzi z parametru) — usunięte.
    local delta = vector3(
        endRotation.x - startRotation.x,
        endRotation.y - startRotation.y,
        endRotation.z - startRotation.z
    )

    local easing = bezier(0.42, 0, 0.58, 1)
    if curve == "easeIn" then
        easing = bezier(0.42, 0, 1, 1)
    elseif curve == "easeOut" then
        easing = bezier(0, 0, 0.58, 1)
    end

    CreateThread(function()
        while true do
            local progress = math.min((GetGameTimer() - startTime) / duration, 1.0)

            if progress >= 1.0 then
                SetEntityRotation(entity, endRotation.x, endRotation.y, endRotation.z, 0, true)
                if onComplete then
                    onComplete()
                end
                break
            end

            local eased = easing(progress)
            local rotation = vector3(
                startRotation.x + delta.x * eased,
                startRotation.y + delta.y * eased,
                startRotation.z + delta.z * eased
            )
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 0, true)
            Wait(0)
        end
    end)
end

-- Przesuwa gracza do pozycji coords z podanym headingiem
-- (TaskPedSlideToCoord), po dotarciu/on timeout ustawia heading
-- i wywołuje onComplete. duration jest opcjonalne (domyślnie 1000 ms);
-- limit czasu oczekiwania to duration + 2000 ms.
function MovePlayerToPosition(coords, heading, duration, onComplete)
    local ped = cache.ped

    TaskPedSlideToCoord(ped, coords.x, coords.y, coords.z, heading, duration or 1000)

    local startTime = GetGameTimer()

    CreateThread(function()
        while true do
            local distance = #(vector3(coords.x, coords.y, coords.z) - GetEntityCoords(ped))

            if distance < 0.1 or GetGameTimer() - startTime > (duration or 1000) + 2000 then
                SetEntityHeading(ped, heading)
                if onComplete then
                    onComplete()
                end
                break
            end

            Wait(0)
        end
    end)
end

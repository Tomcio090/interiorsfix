---------------------------------------------------------------------
-- PROMPT SANDY CITYHALL — Internal config (Config.Elevator)
--
-- Plik przepisany z zapisu dekompilatora na czytelny
-- zapis tabeli — wszystkie wartości 1:1 z oryginałem; patrz
-- ANALIZA.md, rozdz. 13.
--
-- Uwaga: etykiety pięter (floors.*.label) są odczytywane z
-- Config.Messages (public_config.lua ładowany jest wcześniej,
-- patrz kolejność shared_scripts w fxmanifest.lua).
---------------------------------------------------------------------

Config.Elevator = {
    -- Nazwa logiczna windy i model platformsy
    name = "hospital_elevator",
    model = "d1n_sch_elevator",

    -- Prędkość ruchu: jednostki (m) na sekundę — używana do
    -- wyliczania czasu przejazdu między piętrami.
    moveSpeed = 0.1,
    floorWaitTime = 3000,
    timePerFloor = 10000,

    -- Krzywa animacji przemieszczania ("easeInOut"/"easeIn"/"easeOut")
    bezierCurve = "easeInOut",

    position = {
        coords = vector3(1748.177, 3807.138, 35.741),
        rotation = vector3(0, 0, 123.07747650146484)
    },

    door = {
        model = "d1n_sch_elevator_door_01",
        collisionModel = "test_door_col",

        -- Offset drzwi względem pozycji platformsy
        offset = vector3(-0.5784, -0.8483, -0.16),

        animations = {
            dict = "anim@hotel_door_test",
            duration = 900,
            open = {
                name = "d1n_sch_elevator_door_01_open",
                -- Pozycja kolizji drzwi w stanie OTWARTYM
                collisionOffset = vector3(-1.3784, -0.8483, -0.16)
            },
            close = {
                name = "d1n_sch_elevator_door_01_close",
                -- Pozycja kolizji drzwi w stanie ZAMKNIĘTYM
                collisionOffset = vector3(-0.5784, -0.8483, -0.16)
            }
        },

        -- Animacja gracza przy drzwiach (prawo: prawe drzwi windy)
        playerAnimation = {
            rawOffset = { x = 0.2876, y = 0.3542, z = -0.2939, w = 300.9762 },
            dict = "prompt@lift_door"
        }
    },

    -- Piętra (indeks = numer piętra używany w GlobalState.elevator)
    floors = {
        [1] = {
            level = 1,
            label = Config.Messages.floors.firstFloor,
            coords = vector3(1748.177, 3807.138, 35.741)
        },
        [2] = {
            level = 2,
            label = Config.Messages.floors.secondFloor,
            coords = vector3(1748.177, 3807.138, 40.242)
        },
        [3] = {
            level = 3,
            label = Config.Messages.floors.thirdFloor,
            coords = vector3(1748.177, 3807.138, 43.493)
        }
    },

    -- Strzałki-pokazujące piętro (jedna na piętro; rotacja zależy
    -- od piętra, na którym stoi winda — patrz animateIndicators)
    indicators = {
        model = "d1n_sch_elevator_number_arrow_01",
        positions = {
            [1] = {
                coords = vector3(1749.153, 3807.774, 36.771),
                rotation = vector3(0.0, -90.0, 122.99)
            },
            [2] = {
                coords = vector3(1749.153, 3807.774, 41.285),
                rotation = vector3(0.0, 0.0, 122.99)
            },
            [3] = {
                coords = vector3(1749.153, 3807.774, 44.535),
                rotation = vector3(0.0, 90.0, 122.99)
            }
        }
    },

    -- Drzwi na każdym piętrze (statyczne, nie przytwierdzone do
    -- platformsy). offset = wektor przemieszczenia kolizji przy
    -- otwieraniu (lerp od 0 do offset w 900 ms).
    floorDoors = {
        [1] = {
            coords = vector3(1749.39794921875, 3807.25, 35.5629997253418),
            rotation = vector3(0.0, 0.0, 122.99),
            offset = vector3(0.43605079, -0.672, 0.0)
        },
        [2] = {
            coords = vector3(1749.398193359375, 3807.250244140625, 40.08377456665039),
            rotation = vector3(0.0, 0.0, 122.99),
            offset = vector3(0.43605079, -0.672, 0.0)
        },
        [3] = {
            coords = vector3(1749.39794921875, 3807.25, 43.3372917175293),
            rotation = vector3(0.0, 0.0, 122.99),
            offset = vector3(0.43605079, -0.672, 0.0)
        }
    },

    -- Strefa, w której winda jest spawnowana (promień w metrach)
    spawnZone = {
        coords = vector3(1748.261, 3807.199, 35.741),
        radius = 35.0
    },

    -- Strefa "wezwij windę" (na korytarzu, przy przycisku)
    callZone = {
        coords = vector3(1749.79, 3808.25, 35.0),
        size = vector3(2.1, 1.5, 19.9),
        rotation = 302.5
    },

    -- Strefa "wewnątrz windy" (wybór piętra klawiszem E)
    insideZone = {
        coords = vector3(1748.04, 3807.04, 35.0),
        size = vector3(2.2, 2.15, 19.3),
        rotation = 303.0
    },

    -- Room-id każdego piętra (dźwięki grają tylko dla gracza
    -- znajdującego się w danym roomie lub w roomie wnętrza)
    sounds_roomid = { 558935720, 2106411162, -1725345163 },

    -- Pozycje, do których gracz jest prowadzony przy wezwaniu
    -- windy / animacji przycisku (index = piętro)
    playerAskElevatorPositions = {
        [1] = {
            coords = vector3(1750.1484, 3807.7366, 35.4476),
            heading = 124.6759
        },
        [2] = {
            coords = vector3(1750.1484, 3807.7366, 39.9424),
            heading = 124.6759
        },
        [3] = {
            coords = vector3(1750.1484, 3807.7366, 43.1909),
            heading = 124.6759
        }
    },

    -- Animacja naciśnięcia przycisku wezwania
    buttonAnimation = {
        dict = "missagency_heist_2a",
        name = "push_button",
        duration = 500
    }
}

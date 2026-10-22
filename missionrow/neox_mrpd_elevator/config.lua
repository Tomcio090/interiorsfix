--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — ELEVATOR CONFIGURATION
-- =========================================================
-- shared.lua compiles this into its runtime form on load (see
-- Neox.Compile), filling in world positions, rotations and defaults.
-- =========================================================

Config = {}

-- ============================================================
-- TIMING (seconds)
-- ============================================================
Config.Timing = {
    -- Cabin speed in metres/second. nil derives the trip length from
    -- perStop instead, which keeps every floor change evenly paced.
    speed = nil,

    -- Seconds spent travelling per floor when speed is nil.
    perStop = 4.0,

    -- Smoothstep the cabin in and out of motion. false moves it linearly.
    easing = true,

    doorOpen  = 2.0,
    doorHold  = 2.0,
    doorClose = 2.0,
}

-- ============================================================
-- RIDE
-- ============================================================
Config.Ride = {
    -- Block attacking / aiming while inside the cabin.
    blockCombat = true,

    -- Cabin prop opacity during the ride (0-255).
    cabinAlpha = 254,

    -- The box that counts as "inside the cabin", relative to the cabin
    -- prop. Used to decide who rides along.
    volume = {
        useModelBounds = false, -- true ignores the sizes below
        inset  = 0.15,
        width  = 3.55,
        length = 2.2,
        height = 2.55,
        offset = {
            forward = -0.528,
            right   = 0.0,
            up      = -1.25,
        },
    },
}

-- ============================================================
-- PANEL TEXTURES
-- ============================================================
-- Defaults for every shaft; a shaft may override any of them in its own
-- `textures` block.
Config.Panels = {
    txd = 'neox_mrpd_elevators',

    -- How often the lit/unlit state is pushed to the textures (ms).
    updateInterval = 100,

    -- Floor-number display, keyed by the stop's `number`.
    numbers = {
        ['-3'] = 'neox_mrpd_elev-floor_number_-3',
        ['-2'] = 'neox_mrpd_elev-floor_number_-2',
        ['-1'] = 'neox_mrpd_elev-floor_number_-1',
        ['1']  = 'neox_mrpd_elev-floor_number_1',
        ['2']  = 'neox_mrpd_elev-floor_number_2',
        ['3']  = 'neox_mrpd_elev-floor_number_3',
        ['00'] = 'neox_mrpd_elev-floor_number_00',
        ['0']  = 'neox_mrpd_elev-floor_number_00',
    },

    -- Direction-of-travel indicators.
    arrows = {
        up = {
            base = 'neox_white_button_up1_close',
            lit  = 'neox_white_button_up1_open',
        },
        down = {
            base = 'neox_white_button_down1_close',
            lit  = 'neox_white_button_down1_open',
        },
    },

    -- Call buttons, keyed by the stop's `key`.
    buttons = {
        ['-2'] = { base = 'neox_white_button_-2', lit = 'neox_blue_button_-2' },
        ['-1'] = { base = 'neox_white_button_-1', lit = 'neox_blue_button_-1' },
        ['1']  = { base = 'neox_white_button_01', lit = 'neox_blue_button_01' },
        ['2']  = { base = 'neox_white_button_02', lit = 'neox_blue_button_02' },
        ['3']  = { base = 'neox_white_button_03', lit = 'neox_blue_button_03' },
        ['00'] = { base = 'neox_white_button_01', lit = 'neox_blue_button_01' },
    },
}

-- ============================================================
-- INTERACTION
-- ============================================================
Config.Interaction = {
    disabled   = false, -- true removes the call / panel prompts entirely
    lockDoors  = false,

    text = {
        call       = '~INPUT_CONTEXT~ to call elevator',
        panel      = '~INPUT_CONTEXT~ to use elevator panel',
        leavePanel = 'Press ~INPUT_FRONTEND_CANCEL~ (ESC / Right Click) to exit panel',
    },
}

-- ============================================================
-- SHAFTS
-- ============================================================
-- Per shaft:
--   range       how close a player must be for the shaft to tick (m)
--   speed       optional per-shaft override of Config.Timing.speed
--   cabin.at    vec4 world position + heading of the cabin at its base stop
--   plan.*      offsets relative to the cabin, rotated onto its heading
--   panel.*     where the on-prop buttons sit and how the camera frames them
--   stops       keyed by floor id: { z, label, key, number }
--                 z      world height the cabin stops at
--                 label  shown to the player
--                 key    index into the button textures
--                 number index into the floor-number textures
--
-- The two shafts repeat the same door offsets on purpose: each shaft owns
-- its own tables, so editing one never moves the other.
Config.Shafts = {
    mrpd_main = {
        range = 25.0,

        cabin = {
            model = 'neox_mrpd_prop_elev_cabin',
            at    = vec4(453.9333, -998.4015, 31.275, 0.0),
        },

        plan = {
            doorModel  = 'v_ilev_garageliftdoor',
            slide      = 0.9,
            callRadius = 1.2,
            landing = {
                left  = vec4(-0.7429, 0.8884, -1.5998, 0.01),
                right = vec4(0.7601, 0.8884, -1.5998, 179.98),
            },
            cabinDoors = {
                left  = vec4(-0.736, 0.772, -1.577, 0.0),
                right = vec4(0.756, 0.777, -1.611, -179.47),
            },
            call = vec4(0.0367, 1.3715, -0.562, 176.51),
        },

        panel = {
            camera = {
                offset   = vec3(1.08, -0.32, -0.08),
                rotation = vec3(0.0, 0.0, 0.0),
                fov      = 60.0,
            },
            buttons = {
                [1] = vec3(1.08, 0.567, 0.133),
                [2] = vec3(1.08, 0.567, 0.2125),
                [3] = vec3(1.08, 0.567, 0.292),
            },
            hitRadius = 0.05,
        },

        textures = {
            number = 'neox_mrpd_elev-floor_number_1',
        },

        stops = {
            [1] = { 31.272, 'Main Lobby', '1', '1' },
            [2] = { 35.382, 'Offices', '2', '2' },
            [3] = { 39.81, 'Detective Offices / Meeting Room', '3', '3' },
        },
    },

    mrpd_basement = {
        range = 25.0,
        speed = 1.03,

        cabin = {
            model = 'neox_mrpd_prop_elev_cabin2',
            at    = vec4(457.9731, -998.4015, 31.27087, 0.0),
        },

        plan = {
            doorModel  = 'v_ilev_garageliftdoor',
            slide      = 0.9,
            callRadius = 1.2,
            landing = {
                left  = vec4(-0.7429, 0.8884, -1.5998, 0.01),
                right = vec4(0.7601, 0.8884, -1.5998, 179.98),
            },
            cabinDoors = {
                left  = vec4(-0.736, 0.772, -1.577, 0.0),
                right = vec4(0.756, 0.777, -1.611, -179.47),
            },
            call = vec4(-0.0231, 1.4215, -0.563, 179.77),
        },

        panel = {
            camera = {
                offset   = vec3(1.08, -0.32, -0.08),
                rotation = vec3(0.0, 0.0, 0.0),
                fov      = 60.0,
            },
            buttons = {
                [-2] = vec3(1.08, 0.562, 0.133),
                [-1] = vec3(1.082, 0.568, 0.211),
                [1]  = vec3(1.077, 0.572, 0.292),
            },
            hitRadius = 0.05,
        },

        textures = {
            number = 'neox_mrpd_elev-floor_number_1_2',
            arrows = {
                up = {
                    base = 'neox_white_button_up1_close2',
                    lit  = 'neox_white_button_up1_open2',
                },
                down = {
                    base = 'neox_white_button_down1_close2',
                    lit  = 'neox_white_button_down1_open2',
                },
            },
            buttons = {
                ['1'] = { base = 'neox_white_button_01_2', lit = 'neox_blue_button_01_2' },
            },
        },

        stops = {
            [1]  = { 31.27087, 'Main Lobby', '1', '1' },
            [-1] = { 26.24461, 'Garage / Cells', '-1', '-1' },
            [-2] = { 19.2332, 'SWAT Floor', '-2', '-2' },
        },
    },
}

-- =========================================================
-- NEOX MRPD — HYGIENE MODULE CONFIGURATION
-- =========================================================
-- Only what this module needs to differ on. Framework, language,
-- target system, notifications, debug and the access defaults all
-- come from config/config.lua unless overridden here.
-- =========================================================

Config.Hygiene = {}

-- ============================================================
-- INTERACTION
-- ============================================================
-- The mode itself comes from Config.InteractionType in
-- config/config.lua. Uncomment to force key prompts for the
-- bathrooms only — the stalls sit close together, so the third-eye
-- can be fiddly there even on a server that uses it everywhere else.
-- Config.Hygiene.InteractionType = 'drawtext'

-- Interaction distance (general)
Config.Hygiene.InteractionDistance = 1.0

-- Interaction distance (sinks only)
Config.Hygiene.SinkInteractionDistance = 0.6

-- ============================================================
-- TIMING SETTINGS (milliseconds)
-- ============================================================
Config.Hygiene.ShowerDuration = 5000   -- Shower duration
Config.Hygiene.PoopDuration   = 10000   -- Pooping duration
Config.Hygiene.PeeDuration    = 5000   -- Urinating duration

-- ============================================================
-- SYNCHRONIZATION
-- ============================================================
Config.Hygiene.SyncDistance = 40.0 -- Maximum distance at which particle effects are visible

-- ============================================================
-- SHOWER PARTICLE SETTINGS
-- ============================================================
-- Scale: Water size (1.0 = normal, 2.0 = twice as large)
Config.Hygiene.ShowerParticleScale = 1.0

-- Player Offset: Position where the player is moved relative to the interaction point (x = left/right, y = forward/backward)
-- This lets the player move to the center of the shower while the [E] prompt appears near the wall.
Config.Hygiene.ShowerPlayerOffset = vector3(0.0, -0.3, 0.0)

-- Offset: Particle position offset relative to the shower coordinates
-- x = left/right (+ right, - left)
-- y = forward/backward (+ forward, - backward)
-- z = up/down (+ up, - down)
Config.Hygiene.ShowerParticleOffset = vector3(0.0, -0.55, 1.3)

-- Rotation: Water flow direction (degrees)
-- xRot = -180.0 → flows downward (default)
-- xRot = -90.0  → flows horizontally
Config.Hygiene.ShowerParticleRotation = vector3(-180.0, 0.0, 0.0)

-- ============================================================
-- SHOWER CAMERA SETTINGS
-- ============================================================
-- Offset: Camera position relative to the player (x = left/right, y = forward/backward, z = up/down)
-- Decreasing y (e.g. -1.5) moves the camera farther away; increasing it (e.g. -0.8) moves it closer.
-- Increasing z moves the camera upward.
Config.Hygiene.ShowerCamOffset = vector3(0.0, -1.0, 0.7)

-- LookAt: Point the camera looks at (offset relative to the player)
Config.Hygiene.ShowerCamLookAt = vector3(0.0, 0.0, 0.5)

-- Fov: Camera field of view (lower value = zoom, higher value = wider angle)
Config.Hygiene.ShowerCamFov = 50.0



-- ============================================================
-- SHOWER COORDINATES (8 total)
-- ============================================================
-- pos: Shower position (vector3)
-- heading: Direction the player faces when looking at the shower (float)
Config.Hygiene.Showers = {
    { pos = vector3(462.7102, -985.946, 30.752), heading = 180.0 },
    { pos = vector3(467.2631, -985.946, 30.752), heading = 180.0 },
    { pos = vector3(462.7102, -984.004, 30.752), heading = 0.0 },
    { pos = vector3(467.2631, -984.004, 30.752), heading = 0.0 },
    { pos = vector3(483.1947, -983.986, 30.752), heading = 0.0 },
    { pos = vector3(483.2244, -985.988, 30.752), heading = 180.0 },
    { pos = vector3(487.8923, -985.988, 30.752), heading = 180.0 },
    { pos = vector3(487.8223, -983.946, 30.752), heading = 0.0 },
}

-- ============================================================
-- TOILET COORDINATES (4 total)
-- ============================================================
-- pos: Toilet position (vector3)
-- heading: Direction the player faces when looking at the toilet (float)
-- type: 'both' = both functions | 'pee_only' | 'poop_only'
Config.Hygiene.Toilets = {
    { pos = vector3(462.9000, -992.280, 30.710), heading = 270.0, type = 'both' },
    { pos = vector3(462.9000, -990.434, 30.710), heading = 270.0, type = 'both' },
    { pos = vector3(487.6454, -990.480, 30.710), heading = 90.0, type = 'both' },
    { pos = vector3(487.6454, -992.297, 30.710), heading = 90.0, type = 'both' },
}

-- ============================================================
-- STRESS REDUCTION SETTINGS
-- ============================================================
-- Automatically reduces the player's stress level when an activity is completed.
-- Active integration: qb-hud (TriggerServerEvent('hud:server:RelieveStress', amount))
-- If you use a different stress system, see the comments in
-- Bridge.RemoveStress in bridge/framework.lua.
Config.Hygiene.StressReduction = {
    enabled = true, -- Enable/disable the stress reduction system entirely

    -- Shower: enabled and amount (removed immediately on completion)
    shower = {
        enabled = true,
        amount = 25
    },

    -- Poop: enabled and amount (removed immediately on completion)
    poop = {
        enabled = true,
        amount = 15
    },

    -- Pee: enabled and amount (removed immediately on completion)
    pee = {
        enabled = true,
        amount = 10
    },

    -- Wash hands: enabled and amount (removed immediately on completion)
    washHands = {
        enabled = true,
        amount = 5
    }
}

-- ============================================================
-- SINK COORDINATES (6 total)
-- ============================================================
-- Set the size of the water effect flowing from the sink here (e.g. 0.2, 0.4, 0.6)
Config.Hygiene.SinkParticleScale = 0.3

-- pos: Sink position (vector3) (where the character stands)
-- heading: Direction the player faces when looking at the sink (float)
-- waterPos: Coordinates where the water flows (vector3) (adjust the height using the Z axis)
Config.Hygiene.Sinks = {
    { pos = vector3(467.0805, -990.385, 30.710), heading = 270.0, waterPos = vector3(467.6005, -990.385, 30.65) },
    { pos = vector3(467.0805, -991.420, 30.710), heading = 270.0, waterPos = vector3(467.6005, -991.420, 30.65) },
    { pos = vector3(467.0805, -992.450, 30.710), heading = 270.0, waterPos = vector3(467.6005, -992.450, 30.65) },
    { pos = vector3(483.5331, -992.370, 30.710), heading = 90.0, waterPos = vector3(482.8931, -992.433, 30.65) },
    -- { pos = vector3(483.5331, -991.380, 30.710), heading = 90.0, waterPos = vector3(482.8931, -991.420, 30.65) },
    { pos = vector3(483.5331, -990.335, 30.710), heading = 90.0, waterPos = vector3(482.8931, -990.385, 30.65) },
}

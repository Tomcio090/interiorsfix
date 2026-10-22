-- =========================================================
-- NEOX MRPD — PROJECTOR :: EDITABLE CLIENT  (OPEN FILE)
-- =========================================================
-- Target zone placement for every configured laptop / standalone
-- projector. Registration itself is handled by bridge/target.lua,
-- so this file only decides WHERE the zones go and WHAT they do.
-- =========================================================

if not NeoxMRPD.enabled('projector') then return end

local Config = NeoxMRPD.Config.Projector

ProjectorTarget = {}

-- Returns true when at least one zone was created, so the module knows
-- whether it still needs its [E] proximity fallback.
function ProjectorTarget.setup()
    local system = Config.Target.system
    if not Target.enabled(system, Config.InteractionType) then return false end

    local created = 0

    local reachDistance = (Config.Interact and Config.Interact.distance) or Config.InteractDistance or (Config.Target and Config.Target.distance) or 2.0
    local targetRadius = (Config.Interact and Config.Interact.targetRadius) or Config.TargetRadius or (Config.Target and Config.Target.radius) or 0.8

    for i, cfg in ipairs(Config.Projectors) do
        local interactCoords = cfg.isStandalone and cfg.Projector.coords or cfg.Laptop.coords
        local index = i

        local ok = Target.addSphere('neox_mrpd_projector_' .. i, interactCoords, targetRadius, {
            {
                icon     = 'fas fa-desktop',
                label    = Config.Locale.target_label,
                distance = reachDistance,
                action   = function()
                    TriggerEvent('neox_projector:client:requestOpen', index)
                end,
            },
        }, system, Config.InteractionType)

        if ok then created = created + 1 end
    end

    return created > 0
end

function ProjectorTarget.remove()
    Target.removeAll('neox_mrpd_projector_')
end

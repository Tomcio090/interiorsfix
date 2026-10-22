--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — NUI BRIDGE (client)
-- =========================================================
-- A resource may declare only ONE ui_page, so all five modules
-- share html/index.html. That page is a router: it hosts one
-- frame per module and dispatches whatever this bridge sends.
--
-- Modules never call SendNUIMessage / SetNuiFocus directly —
-- they go through NUI.send / NUI.focus so the router knows which
-- frame a message belongs to and which one owns the cursor.
--
-- DUI screens (render targets) are NOT routed: they are separate
-- browsers created with CreateDui and keep talking over
-- SendDuiMessage exactly as before.
-- =========================================================

NUI = NUI or {}

local focusOwner = nil

-- ---------------------------------------------------------
-- NUI.send(module, payload)
-- Delivers payload to that module's frame unchanged, so module
-- front-end code keeps reading event.data.type as it always did.
-- ---------------------------------------------------------
function NUI.send(moduleName, payload)
    SendNUIMessage({
        neox   = moduleName,
        action = 'msg',
        data   = payload,
    })
end

-- ---------------------------------------------------------
-- NUI.focus(module, keyboard, cursor)
-- Raises that module's frame, hands it the cursor when asked and
-- applies the matching SetNuiFocus. Passing false for both
-- releases focus and drops the frame back to click-through.
-- ---------------------------------------------------------
function NUI.focus(moduleName, keyboard, cursor)
    keyboard = keyboard == true
    cursor   = cursor == true

    if keyboard or cursor then
        focusOwner = moduleName
        SendNUIMessage({
            neox   = moduleName,
            action = 'focus',
            data   = { cursor = cursor },
        })
    else
        if focusOwner == moduleName or focusOwner == nil then
            focusOwner = nil
        end
        SendNUIMessage({
            neox   = moduleName,
            action = 'blur',
        })
    end

    SetNuiFocus(keyboard, cursor)
end

-- ---------------------------------------------------------
-- NUI.release(module) — drop focus without touching the frame
-- stack when another module already took over.
-- ---------------------------------------------------------
function NUI.release(moduleName)
    if focusOwner ~= nil and focusOwner ~= moduleName then return end
    NUI.focus(moduleName, false, false)
end

function NUI.focusOwner()
    return focusOwner
end

-- Never leave the player stuck with a cursor if the resource dies.
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SetNuiFocus(false, false)
    end
end)

--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — FRAMEWORK BRIDGE  (OPEN FILE — edit freely)
-- =========================================================
-- One detection pass for the whole resource. No module pulls a
-- core object itself; they all ask this bridge.
--
-- Driven by config/config.lua:
--   Config.Framework  'auto' | 'qb' | 'qbox' | 'esx' | 'vrp' | 'standalone'
--   Config.Access     the shared job / grade / ace gate
--   Config.Admin      who may reset scoreboards
--
-- API
--   Bridge.type                       resolved framework name
--   Bridge.core                       core object (nil on standalone)
--   Bridge.await(timeoutMs)           block until detection finished
--   Bridge.onReady(fn)                run fn once the core is up
--   Bridge.isQB() / isQBox() / isESX() / isVRP() / isStandalone()
--   Bridge.GetJob(src)                -> name, grade
--   Bridge.GetIdentity(src)           -> displayName, identifier
--   Bridge.GetPlayerIdentifier(src)   -> identifier only
--   Bridge.HasAccess(src, access)     job / grade / ace gate
--   Bridge.IsAdmin(src)               scoreboard reset gate
--   Bridge.GetPlayerGender()          client
--   Bridge.RemoveStress(amount)       client (relieve/decrease stress)
-- =========================================================

Bridge = Bridge or {}

local isServer = IsDuplicityVersion()

Bridge.type  = 'standalone'
Bridge.core  = nil
Bridge.ready = false

local readyCallbacks = {}

-- ---------------------------------------------------------
-- Detection
-- ---------------------------------------------------------
-- Detection asks whether a core is INSTALLED, not whether it has
-- started yet. This resource can live under [defaultmaps], which the
-- server boots before qb-core / es_extended — checking for 'started'
-- there would resolve to standalone on every restart and stay that
-- way for the whole session. GetResourceState only returns 'missing'
-- when a resource is genuinely not on the server, which is exactly
-- the question we want answered.
local function resourceInstalled(name)
    return GetResourceState(name) ~= 'missing'
end

-- Resources report 'starting' before their exports are registered,
-- so calling an export the moment the state flips can fail on a
-- cold boot. Wait for 'started' before touching one.
local function waitForResource(name, timeoutMs)
    if GetResourceState(name) == 'missing' then return false end
    local deadline = GetGameTimer() + (timeoutMs or 20000)
    while GetResourceState(name) ~= 'started' and GetGameTimer() < deadline do
        Wait(50)
    end
    return GetResourceState(name) == 'started'
end

local function detectType()
    local configured = Config.Framework

    if configured and configured ~= 'auto' then
        return configured
    end

    if resourceInstalled('qbx_core')    then return 'qbox' end
    if resourceInstalled('qb-core')     then return 'qb'   end
    if resourceInstalled('es_extended') then return 'esx'  end
    if resourceInstalled('vrp')         then return 'vrp'  end
    return 'standalone'
end

local function loadCore()
    if Bridge.type == 'qbox' then
        -- qbx_core is export-driven; qb-core is only fetched when the
        -- server also runs the compatibility shim.
        if waitForResource('qb-core', 10000) then
            local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok then Bridge.core = core end
        end

    elseif Bridge.type == 'qb' then
        if waitForResource('qb-core') then
            local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok then
                Bridge.core = core
            else
                print('^1[neox_mrpd_scripts] qb-core is running but GetCoreObject() failed.^7')
            end
        else
            print('^1[neox_mrpd_scripts] Config.Framework is "qb" but qb-core never started.^7')
        end

    elseif Bridge.type == 'esx' then
        if waitForResource('es_extended') then
            local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
            if ok then
                Bridge.core = core
            else
                print('^1[neox_mrpd_scripts] es_extended is running but getSharedObject() failed.^7')
            end
        else
            print('^1[neox_mrpd_scripts] Config.Framework is "esx" but es_extended never started.^7')
        end

    elseif Bridge.type == 'vrp' and isServer then
        local ok, Proxy = pcall(module, 'vrp', 'lib/Proxy')
        if ok and Proxy then
            Bridge.core = Proxy.getInterface('vRP')
        else
            print('^1[neox_mrpd_scripts] Config.Framework is "vrp" but the vRP proxy is unavailable.^7')
        end
    end
end

CreateThread(function()
    Bridge.type = detectType()
    loadCore()
    Bridge.ready = true

    for _, fn in ipairs(readyCallbacks) do
        CreateThread(function() pcall(fn) end)
    end
    readyCallbacks = {}
end)

-- Block the calling thread until detection finished. Returns false on
-- timeout so a caller can carry on rather than hang forever.
function Bridge.await(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 20000)
    while not Bridge.ready and GetGameTimer() < deadline do
        Wait(50)
    end
    return Bridge.ready
end

-- Run fn as soon as the framework is up (immediately if it already is).
function Bridge.onReady(fn)
    if Bridge.ready then
        CreateThread(function() pcall(fn) end)
    else
        readyCallbacks[#readyCallbacks + 1] = fn
    end
end

function Bridge.isQB()         return Bridge.type == 'qb' or Bridge.type == 'qbox' end
function Bridge.isQBox()       return Bridge.type == 'qbox' end
function Bridge.isESX()        return Bridge.type == 'esx' end
function Bridge.isVRP()        return Bridge.type == 'vrp' end
function Bridge.isStandalone() return Bridge.type == 'standalone' end

-- ---------------------------------------------------------
-- JOB (server) -> name, grade
-- ---------------------------------------------------------
function Bridge.GetJob(src)
    if not isServer then return nil, 0 end

    local ok, name, grade = pcall(function()
        if Bridge.isQBox() then
            local player = exports.qbx_core:GetPlayer(src)
            local job = player and player.PlayerData and player.PlayerData.job
            if not job then return nil, 0 end
            return job.name, (job.grade and job.grade.level) or 0

        elseif Bridge.isQB() and Bridge.core then
            local player = Bridge.core.Functions.GetPlayer(src)
            local job = player and player.PlayerData and player.PlayerData.job
            if not job then return nil, 0 end
            return job.name, (job.grade and job.grade.level) or 0

        elseif Bridge.isESX() and Bridge.core then
            local xPlayer = Bridge.core.GetPlayerFromId(src)
            local job = xPlayer and xPlayer.job
            if not job then return nil, 0 end
            return job.name, job.grade or 0
        end
        return nil, 0
    end)

    if not ok then return nil, 0 end
    return name, grade or 0
end

-- ---------------------------------------------------------
-- IDENTITY (server) -> displayName, identifier
-- ---------------------------------------------------------
local function licenseOf(src)
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if v:match('^license:') then return v end
    end
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if v:match('^steam:') then return v end
    end
    return nil
end

function Bridge.GetIdentity(src)
    if not isServer then return 'Unknown', 'Unknown' end

    local name, identifier

    if Config.NameType == 'charname' then
        pcall(function()
            if Bridge.isQBox() then
                local player = exports.qbx_core:GetPlayer(src)
                local data = player and player.PlayerData
                if data and data.charinfo then
                    name = data.charinfo.firstname .. ' ' .. data.charinfo.lastname
                    identifier = data.citizenid
                end

            elseif Bridge.isQB() and Bridge.core then
                local player = Bridge.core.Functions.GetPlayer(src)
                local data = player and player.PlayerData
                if data and data.charinfo then
                    name = data.charinfo.firstname .. ' ' .. data.charinfo.lastname
                    identifier = data.citizenid
                end

            elseif Bridge.isESX() and Bridge.core then
                local xPlayer = Bridge.core.GetPlayerFromId(src)
                if xPlayer then
                    name = xPlayer.getName()
                    identifier = xPlayer.identifier
                end

            elseif Bridge.isVRP() and Bridge.core then
                local vRP = Bridge.core
                local userId = vRP.getUserId({ src }) or vRP.getUserId(src)
                if userId then
                    identifier = tostring(userId)
                    if vRP.getUserIdentity then
                        vRP.getUserIdentity({ userId, function(identity)
                            if identity then
                                name = ((identity.name or '') .. ' ' .. (identity.firstname or '')):match('^%s*(.-)%s*$')
                            end
                        end })
                    end
                end
            end
        end)
    end

    -- Steam / license fallback, and the path Config.NameType = 'steam' takes
    if not identifier or identifier == '' then
        identifier = licenseOf(src)
    end
    if not name or name == '' then
        name = GetPlayerName(src)
    end

    return name or 'Unknown', identifier or 'Unknown'
end

function Bridge.GetPlayerIdentifier(src)
    local _, identifier = Bridge.GetIdentity(src)
    if identifier == 'Unknown' then
        return licenseOf(src) or GetPlayerIdentifier(src, 0)
    end
    return identifier
end

-- ---------------------------------------------------------
-- ACCESS GATE (server)
-- access inherits from Config.Access, so a module only sets what
-- it wants to differ. See shared/core.lua.
-- ---------------------------------------------------------
local function gradeAllowed(access, jobName, grade)
    local min = access.minGrade

    -- minGrade may be a single number or a per-job table
    if type(min) == 'table' then
        min = min[jobName]
    end

    if type(min) ~= 'number' then return true end
    return (grade or 0) >= min
end

function Bridge.HasAccess(src, access)
    access = access or Config.Access
    if not access or not access.restrict then return true end

    -- An ace grant is accepted on its own, so it works with or
    -- without a framework.
    if access.aceFallback and IsPlayerAceAllowed(src, access.aceFallback) then
        return true
    end

    if Bridge.isStandalone() then
        return access.standaloneAllowAll == true
    end

    local jobName, grade = Bridge.GetJob(src)
    if not jobName then return false end

    for _, allowed in ipairs(access.jobs or {}) do
        if jobName == allowed then
            return gradeAllowed(access, jobName, grade)
        end
    end

    return false
end

-- ---------------------------------------------------------
-- ADMIN GATE (server)
-- ---------------------------------------------------------
function Bridge.IsAdmin(src)
    if not isServer then return false end
    if src == 0 then return true end -- server console

    local admin = Config.Admin or {}
    local groups = {}
    for _, g in ipairs(admin.groups or {}) do groups[g] = true end

    local ok, allowed = pcall(function()
        if Bridge.isQBox() and exports.qbx_core and exports.qbx_core.HasPermission then
            for group in pairs(groups) do
                if exports.qbx_core:HasPermission(src, group) then return true end
            end

        elseif Bridge.isQB() and Bridge.core then
            for group in pairs(groups) do
                if Bridge.core.Functions.HasPermission(src, group) then return true end
            end

        elseif Bridge.isESX() and Bridge.core then
            local xPlayer = Bridge.core.GetPlayerFromId(src)
            if xPlayer and groups[xPlayer.getGroup()] then return true end

        elseif Bridge.isVRP() and Bridge.core then
            local vRP = Bridge.core
            local userId = vRP.getUserId({ src }) or vRP.getUserId(src)
            if userId then
                if vRP.hasPermission and vRP.hasPermission({ userId, 'admin.tickets' }) then return true end
                for group in pairs(groups) do
                    if vRP.hasGroup and vRP.hasGroup({ userId, group }) then return true end
                end
            end
        end
        return false
    end)

    if ok and allowed then return true end

    return IsPlayerAceAllowed(src, admin.aceFallback or 'neox.mrpd.admin')
end

-- ---------------------------------------------------------
-- GENDER (client)
-- ---------------------------------------------------------
function Bridge.GetPlayerGender()
    if isServer then return 'male' end
    if GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') then
        return 'female'
    end
    return 'male'
end

-- ---------------------------------------------------------
-- STRESS (client)
-- ---------------------------------------------------------
function Bridge.RemoveStress(amount)
    if isServer then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    TriggerServerEvent('hud:server:RelieveStress', amount)
end



-- =========================================================
-- TEMPORARY WEAPONS / INVENTORY BRIDGE
-- Handles weapon giving & cleanup across ox_inventory,
-- qb-inventory, ESX, and standalone.
-- =========================================================
if isServer then
    local PlayerTempWeapons = {} -- src -> { weapon = itemName, rawWeapon = weaponName, ammoType = ammoName, direct = bool }

    local function resolveOxItem(wepName)
        if not wepName then return nil end
        local upper = string.upper(wepName)
        local lower = string.lower(wepName)
        if exports.ox_inventory:Items(upper) then return upper end
        if exports.ox_inventory:Items(lower) then return lower end
        if exports.ox_inventory:Items(wepName) then return wepName end
        return upper
    end

    function Bridge.GiveTemporaryWeapon(src, weaponName, ammo, giveAsItem)
        if not src or src <= 0 or not weaponName then return end
        ammo = ammo or 250

        -- Remove any previously held temporary weapon first
        if PlayerTempWeapons[src] then
            Bridge.RemoveTemporaryWeapon(src)
        end

        if not giveAsItem then
            -- Direct weapon mode: given to ped directly on client, no items added to inventory
            PlayerTempWeapons[src] = { weapon = weaponName, rawWeapon = weaponName, direct = true }
            return
        end

        if GetResourceState('ox_inventory') == 'started' then
            local itemName = resolveOxItem(weaponName)
            local itemData = exports.ox_inventory:Items(itemName)
            
            exports.ox_inventory:AddItem(src, itemName, 1, { ammo = ammo, temporary = true, neox_temp = true })
            
            local ammoType = nil
            if itemData and itemData.ammoname and exports.ox_inventory:Items(itemData.ammoname) then
                exports.ox_inventory:AddItem(src, itemData.ammoname, 5, { temporary = true, neox_temp = true })
                ammoType = itemData.ammoname
            end

            PlayerTempWeapons[src] = { weapon = itemName, rawWeapon = weaponName, ammoType = ammoType, direct = false }
            TriggerClientEvent('neox_mrpd:client:equipTemporaryWeapon', src, itemName, weaponName, ammo)

        elseif Bridge.isQB() and Bridge.core then
            pcall(function()
                local player = (Bridge.isQBox() and exports.qbx_core and exports.qbx_core:GetPlayer(src)) or Bridge.core.Functions.GetPlayer(src)
                if player then
                    player.Functions.AddItem(weaponName, 1, nil, { ammo = ammo, temporary = true })
                end
            end)
            PlayerTempWeapons[src] = { weapon = weaponName, rawWeapon = weaponName, direct = false }
            TriggerClientEvent('neox_mrpd:client:equipTemporaryWeapon', src, weaponName, weaponName, ammo)

        elseif Bridge.isESX() and Bridge.core then
            pcall(function()
                local xPlayer = Bridge.core.GetPlayerFromId(src)
                if xPlayer and xPlayer.addWeapon then
                    xPlayer.addWeapon(weaponName, ammo)
                end
            end)
            PlayerTempWeapons[src] = { weapon = weaponName, rawWeapon = weaponName, direct = false }
            TriggerClientEvent('neox_mrpd:client:equipTemporaryWeapon', src, weaponName, weaponName, ammo)

        else
            PlayerTempWeapons[src] = { weapon = weaponName, rawWeapon = weaponName, direct = false }
            TriggerClientEvent('neox_mrpd:client:equipTemporaryWeapon', src, weaponName, weaponName, ammo)
        end
    end

    function Bridge.RemoveTemporaryWeapon(src, weaponName)
        if not src or src <= 0 then return end
        local record = PlayerTempWeapons[src]
        local wep = (record and record.weapon) or weaponName

        if wep and (not record or not record.direct) then
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    exports.ox_inventory:RemoveItem(src, string.upper(wep), 1)
                    exports.ox_inventory:RemoveItem(src, string.lower(wep), 1)
                    exports.ox_inventory:RemoveItem(src, wep, 1)
                    if record and record.ammoType then
                        exports.ox_inventory:RemoveItem(src, record.ammoType, 5)
                    end
                end)
            elseif Bridge.isQB() and Bridge.core then
                pcall(function()
                    local player = (Bridge.isQBox() and exports.qbx_core and exports.qbx_core:GetPlayer(src)) or Bridge.core.Functions.GetPlayer(src)
                    if player then
                        player.Functions.RemoveItem(wep, 1)
                    end
                end)
            elseif Bridge.isESX() and Bridge.core then
                pcall(function()
                    local xPlayer = Bridge.core.GetPlayerFromId(src)
                    if xPlayer and xPlayer.removeWeapon then
                        xPlayer.removeWeapon(wep)
                    end
                end)
            end
        end

        PlayerTempWeapons[src] = nil
        TriggerClientEvent('neox_mrpd:client:removeTemporaryWeapon', src, wep or weaponName)
    end

    RegisterNetEvent('neox_mrpd:server:giveTemporaryWeapon', function(weaponName, ammo, giveAsItem)
        local src = source
        if not src or src <= 0 then return end
        Bridge.GiveTemporaryWeapon(src, weaponName, ammo, giveAsItem)
    end)

    RegisterNetEvent('neox_mrpd:server:removeTemporaryWeapon', function(weaponName)
        local src = source
        if not src or src <= 0 then return end
        Bridge.RemoveTemporaryWeapon(src, weaponName)
    end)

    AddEventHandler('playerDropped', function()
        local src = source
        if PlayerTempWeapons[src] then
            Bridge.RemoveTemporaryWeapon(src)
        end
    end)

else
    -- Client-side
    local currentTempWeapon = nil
    local tempWeaponThreadActive = false

    function Bridge.GiveWeapon(weaponName, ammo, opts)
        ammo = ammo or 250
        opts = opts or {}
        local giveAsItem = (opts.giveAsItem == true)
        local noReload = (opts.noReload == true)
        local ped = PlayerPedId()
        local hash = GetHashKey(weaponName)

        if giveAsItem then
            if GetResourceState('ox_inventory') ~= 'started' then
                GiveWeaponToPed(ped, hash, ammo, false, true)
                SetCurrentPedWeapon(ped, hash, true)
                if noReload then
                    SetPedInfiniteAmmoClip(ped, true)
                end
            end
            currentTempWeapon = { name = weaponName, hash = hash, noReload = noReload, direct = false }
            TriggerServerEvent('neox_mrpd:server:giveTemporaryWeapon', weaponName, ammo, true)
            return
        end

        -- Direct to hand (Ped weapon, no inventory item)
        if GetResourceState('ox_inventory') == 'started' then
            TriggerEvent('ox_inventory:disarm', true)
            Citizen.Wait(80)
            pcall(function() exports.ox_inventory:weaponWheel(true) end)
        end

        GiveWeaponToPed(ped, hash, ammo, false, true)
        SetCurrentPedWeapon(ped, hash, true)
        SetPedAmmo(ped, hash, ammo)

        if noReload then
            SetPedInfiniteAmmoClip(ped, true)
            SetPedInfiniteAmmo(ped, true, hash)
        else
            SetPedInfiniteAmmoClip(ped, false)
        end

        currentTempWeapon = {
            name = weaponName,
            hash = hash,
            noReload = noReload,
            direct = true
        }

        TriggerServerEvent('neox_mrpd:server:giveTemporaryWeapon', weaponName, ammo, false)

        -- Persistent thread while holding temp weapon with noReload
        if noReload and not tempWeaponThreadActive then
            tempWeaponThreadActive = true
            Citizen.CreateThread(function()
                while currentTempWeapon and currentTempWeapon.noReload do
                    local p = PlayerPedId()
                    if GetSelectedPedWeapon(p) == currentTempWeapon.hash then
                        SetPedInfiniteAmmoClip(p, true)
                    end
                    Citizen.Wait(300)
                end
                tempWeaponThreadActive = false
            end)
        end
    end

    function Bridge.RemoveWeapon(weaponName)
        local ped = PlayerPedId()
        SetPedInfiniteAmmoClip(ped, false)

        if currentTempWeapon and currentTempWeapon.hash then
            SetPedInfiniteAmmo(ped, false, currentTempWeapon.hash)
            RemoveWeaponFromPed(ped, currentTempWeapon.hash)
        end
        if weaponName then
            local h = GetHashKey(weaponName)
            SetPedInfiniteAmmo(ped, false, h)
            RemoveWeaponFromPed(ped, h)
        end

        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)

        if GetResourceState('ox_inventory') == 'started' then
            pcall(function() exports.ox_inventory:weaponWheel(false) end)
        end

        currentTempWeapon = nil
        TriggerServerEvent('neox_mrpd:server:removeTemporaryWeapon', weaponName)
    end

    RegisterNetEvent('neox_mrpd:client:equipTemporaryWeapon', function(itemName, weaponName, ammo)
        if GetResourceState('ox_inventory') == 'started' then
            Citizen.CreateThread(function()
                local attempts = 0
                while attempts < 15 do
                    Citizen.Wait(100)
                    attempts = attempts + 1
                    local slots = exports.ox_inventory:Search('slots', itemName)
                    if not slots or #slots == 0 then
                        slots = exports.ox_inventory:Search('slots', string.lower(itemName))
                    end
                    if not slots or #slots == 0 then
                        slots = exports.ox_inventory:Search('slots', string.upper(weaponName))
                    end
                    if slots and #slots > 0 then
                        local slot = type(slots[1]) == 'table' and (slots[1].slot or slots[1]) or slots[1]
                        if slot then
                            exports.ox_inventory:useSlot(slot)
                            if currentTempWeapon and currentTempWeapon.noReload then
                                Citizen.Wait(200)
                                SetPedInfiniteAmmoClip(PlayerPedId(), true)
                            end
                            break
                        end
                    end
                end
            end)
        else
            local ped = PlayerPedId()
            local hash = GetHashKey(weaponName)
            GiveWeaponToPed(ped, hash, ammo or 250, false, true)
            SetCurrentPedWeapon(ped, hash, true)
            if currentTempWeapon and currentTempWeapon.noReload then
                SetPedInfiniteAmmoClip(ped, true)
            end
        end
    end)

    RegisterNetEvent('neox_mrpd:client:removeTemporaryWeapon', function(weaponName)
        local ped = PlayerPedId()
        SetPedInfiniteAmmoClip(ped, false)
        if currentTempWeapon and currentTempWeapon.hash then
            SetPedInfiniteAmmo(ped, false, currentTempWeapon.hash)
        end
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        if weaponName then
            RemoveWeaponFromPed(ped, GetHashKey(weaponName))
        end
        if GetResourceState('ox_inventory') == 'started' then
            pcall(function() exports.ox_inventory:weaponWheel(false) end)
        end
        currentTempWeapon = nil
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end
        SetPedInfiniteAmmoClip(PlayerPedId(), false)
        if GetResourceState('ox_inventory') == 'started' then
            pcall(function() exports.ox_inventory:weaponWheel(false) end)
        end
    end)
end



--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'frazydevelopment | FiveVault'
description 'Neonix3D - MRPD Elevator | Downloaded from FiveVault (https://fivevault.net)'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared.lua',
}

client_scripts {
    'client/runtime.lua',
    'client/panels.lua',
    'client/api.lua',
}

server_script 'server.lua'


fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'frazydevelopment'
description 'Neonix3D - MRPD Elevator'
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


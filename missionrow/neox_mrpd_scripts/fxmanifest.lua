--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'neox_mrpd_scripts'
author 'frazydevelopment | FiveVault'
description 'Neonix3D — MRPD scripts feature pack | Downloaded from FiveVault (https://fivevault.net)'
version '1.0.0'

shared_scripts {
    'locales/*.lua',
    'config/config.lua',
    'config/cctv.lua',
    'config/hygiene.lua',
    'config/killhouse.lua',
    'config/projector.lua',
    'config/range.lua',
    'config/archive.lua',
    'shared/core.lua',
    'bridge/framework.lua',
    'bridge/notify.lua',
}

client_scripts {
    'bridge/target.lua',
    'bridge/nui.lua',
    'client/init.lua',

    'modules/cctv/client.lua',

    'modules/hygiene/shared.lua',
    'modules/hygiene/client.lua',
    'modules/hygiene/shower.lua',
    'modules/hygiene/toilet.lua',
    'modules/hygiene/sink.lua',

    'modules/killhouse/client.lua',

    'modules/projector/editable_client.lua',
    'modules/projector/client.lua',

    'modules/range/client.lua',

    'modules/archive/client.lua',
}

server_scripts {
    'server/init.lua',

    'modules/cctv/server.lua',
    'modules/hygiene/server.lua',
    'modules/killhouse/server.lua',
    'modules/killhouse/editable_server.lua',
    'modules/range/server.lua',
    'modules/range/editable_server.lua',

    'modules/projector/server.lua',

    'modules/archive/server.lua',
}

files {
    'html/index.html',
    'html/shell/*.js',
    'html/cctv/index.html',
    'html/cctv/assets/**',
    'html/projector/index.html',
    'html/projector/assets/**',
    'html/killhouse/*.html',
    'html/killhouse/*.css',
    'html/killhouse/*.js',
    'html/range/*.html',
    'html/range/*.css',
    'html/range/*.js',
    'html/archive/**',
}

ui_page 'html/index.html'

server_exports {
    'GetKillhouseScoreboard',
    'ResetKillhouseScoreboard',
    'GetRangeScoreboard',
    'ResetRangeScoreboard',
}


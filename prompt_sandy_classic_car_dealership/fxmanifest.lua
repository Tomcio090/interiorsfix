-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Studio'
version '1.0.1'

escrow_ignore {
    'stream/unlocked/**',
    'client.lua'
}

lua54 'yes'

client_script 'client.lua'

server_scripts {
    -- Lokalna rejestracja wykrywania mapy, bez zdalnego kodu i telemetrii.
    'sv_mapdata.lua'
}

dependency '/assetpacks'

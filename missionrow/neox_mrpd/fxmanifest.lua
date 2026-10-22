--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

fx_version 'cerulean'
game 'gta5'
lua54 "yes"

author 'Neonix3D | FiveVault'
description 'Mission Row Police Department | Downloaded from FiveVault (https://fivevault.net)'
version '1.0.0'

this_is_a_map 'yes'


data_file 'TIMECYCLEMOD_FILE' 'neox_timecycle_mrpd.xml'
data_file 'AUDIO_GAMEDATA' 'stream/audio/10007087_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/441872C_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/3DB04BE2_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/4F76EF6F_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/CB60E749_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/21F81472_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/E5341AEF_game.dat'
data_file 'AUDIO_GAMEDATA' 'stream/audio/neox_mrpd_door_game.dat'
data_file 'DLC_ITYP_REQUEST' 'stream/sf_dlc_int_03_sec.ytyp'
data_file 'DLC_ITYP_REQUEST' 'tr_dlc_int_01_tr.ytyp'

client_scripts {
    'client/client.lua',
    'client/resourcescheck.lua',
    'data/neox_config.lua',
    'data/neox_poly_manager.lua',
    'data/mrpd_entityset_mods.lua',
}

files {
    'neox_timecycle_mrpd.xml',
    'stream/audio/10007087_game.dat151.rel',
    'stream/audio/441872C_game.dat151.rel',
    'stream/audio/3DB04BE2_game.dat151.rel',
    'stream/audio/4F76EF6F_game.dat151.rel',
    'stream/audio/CB60E749_game.dat151.rel',
    'stream/audio/21F81472_game.dat151.rel',
    'stream/audio/E5341AEF_game.dat151.rel',
    'stream/audio/neox_mrpd_door_game.dat151.rel',
}

dependencies {
    '/server:4960',
    '/gameBuild:2189',
}

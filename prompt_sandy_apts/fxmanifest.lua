-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
lua54 'yes'
fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

author 'Prompt Studio'
description 'Sandy Shores Apartments'
version '1.0.8'

client_scripts {
    'config.lua',
    'proximity_loader.lua',
    'interior_manager.lua',
    'debug_commands.lua'
}


data_file 'DLC_ITYP_REQUEST' 'stream/shells/prompt_sandy_apts_shells.ytyp'

escrow_ignore {
    'config.lua',
    'debug_commands.lua',
    'stream/map/unlocked/**'
}


server_scripts{
	'sv_mapdata.lua'
}

dependency '/assetpacks'
-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- map by---:
author 'Prompt Studio'
description 'Sandy Shores Illegal Garage & Gas Station & Car Wash'
scripts_author 'Infames Dev'
version '1.1.4'

data_file 'DLC_ITYP_REQUEST' 'stream/unlocked/illegal_garage/prompt_sandy_illegal_garage.ytyp'

escrow_ignore {
    'stream/unlocked/**',
    'config.lua',
    'open_config.lua',
    'open_functions.lua',
    'client/target_wrapper.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'open_config.lua'
}

client_scripts {
	'open_functions.lua',
    'client/target_wrapper.lua',
    'client/utils.lua',
    'client/client.lua'
}

server_scripts {
    'server/*.lua',
}

dependency 'ox_lib'
dependency '/assetpacks'
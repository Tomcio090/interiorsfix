-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods Studio'
version "2.0.8"



escrow_ignore {
    'stream/unlocked/**',
    'client_entitysets.lua',
    'config.lua',
    'config_va_houses.lua'
}

-- scripts --
lua54 'yes'


server_scripts{
	'sv_loader.lua'
}

client_scripts {
	'config.lua',
	'config_va_houses.lua',
	'client_entitysets.lua'
}


dependency '/assetpacks'
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods'
version "1.0.2"

escrow_ignore {
    'stream/unlocked/**',
    'sv_mapdata.lua'
}

-- scripts --
lua54 'yes'


server_scripts{
	-- Lokalna rejestracja wykrywania mapy (zamiennik sv_loadera — bez
	-- zdalnego kodu i telemetrii; patrz ANALIZA.md, rozdz. 7.1/10/14)
	'sv_mapdata.lua'
}
dependency '/assetpacks'

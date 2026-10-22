-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods'
version "1.2.5"




-- audio merged into shared prompt_audio (dat151 x2) 2026-06-10; zip backup in
-- C:\Scripts\_backups\prompt_audio\sheriff_audio_2026-06-10_night_pre-merge.zip
data_file 'GTXD_PARENTING_DATA' 'meta/gtxd.meta'

files {
  'meta/gtxd.meta'
}

escrow_ignore {
    'stream/unlocked/**'
}

-- scripts --
lua54 'yes'


server_scripts{
	--[['sv_Tokens.lua',
	'sv_MapChainHandler.lua',
	'sv_MapVersionCheck.lua'--]]
	-- Lokalna rejestracja wykrywania mapy (zamiennik sv_loadera — bez
	-- zdalnego kodu i telemetrii; patrz ANALIZA.md, rozdz. 7.1/10/13)
	'sv_mapdata.lua'
}
dependency '/assetpacks'
-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'cerulean'
game 'gta5'
author 'Prompt Studio & Infames Dev' 
version '1.1.5'
this_is_a_map 'yes'
description 'Sandy Shores City Hall'


-- audio (awc+dat54+dat151) merged into shared prompt_audio 2026-06-10; zip backup in
-- C:\Scripts\_backups\prompt_audio\cityhall_audio_2026-06-10_night_pre-merge.zip
files {
	'd1n_shc_timecycle.xml',
	'stream/interior/unlocked/ytyp/d1n_sch_props.ytyp',
    'stream/interior/unlocked/ytyp/d1n_sch_ytyp.ytyp'
}


data_file 'TIMECYCLEMOD_FILE' 'd1n_shc_timecycle.xml'
data_file 'DLC_ITYP_REQUEST' 'stream/interior/unlocked/ytyp/d1n_sch_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interior/unlocked/ytyp/d1n_sch_ytyp.ytyp'


escrow_ignore {
    'stream/exterior/unlocked/**',
    'stream/interior/unlocked/**',
    'public_config.lua',
    'client/open.lua',
    'ipls_command.lua',
    'ipls_server.lua',
}

-- scripts --
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'public_config.lua',
    'internal_config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/open.lua',
    'client/client.lua',
    'ipls_command.lua'
}

server_scripts {
	-- Lokalna rejestracja wykrywania mapy (zamiennik sv_loadera — bez
	-- zdalnego kodu i telemetrii; patrz ANALIZA.md, rozdz. 7.1/10/13)
	'sv_mapdata.lua',
	'server/*.lua',
	'ipls_server.lua'
}
-- ox_lib jest wymagany (lib.points/lib.zones/lib.callback w kliencie) —
-- zależność gwarantuje kolejność startu (poprzednio wykrywanie
-- GetResourceState("ox_lib") == "started" działo się tylko raz, przy
-- ładowaniu client.lua — patrz ANALIZA.md, rozdz. 7.4 i naprawy garażu)
dependency 'ox_lib'
dependency '/assetpacks'
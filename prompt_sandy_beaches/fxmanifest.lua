-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'

-- map by---:
author 'prompt'
scriptdeveloper 'Cas.vdv'
description 'Sandy Shores Marina'
version '1.0.4'

escrow_ignore {
    'stream/unlocked/**'
}

server_scripts {
    -- Lokalna rejestracja wykrywania mapy (zamiennik sv_loadera — bez
    -- zdalnego kodu i telemetrii; patrz ANALIZA.md, rozdz. 7.1/10/14)
    'sv_mapdata.lua',
    'weather_prop_controllers.lua'
}

data_file "DLC_ITYP_REQUEST" "stream/prompt_sandy_dynamic_weather_props.ytyp"

shared_scripts {
    'config.lua'
}

client_scripts {
    'weather_prop_controller.lua',
    'client.lua'
}

lua54 'yes'

dependency '/assetpacks'

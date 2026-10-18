-- Decrypted & Fixed by LuaClear | https://discord.gg/luaclear
fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods Studio | Escobar'
version "1.0.5"

-- audio merged into shared prompt_audio (dat151) 2026-06-10; zip backup in
-- C:\Scripts\_backups\prompt_audio\fire2_audio_2026-06-10_night_pre-merge.zip
files {
    'escobar_timecycle_fd_prompt.xml',
}

data_file 'TIMECYCLEMOD_FILE' 'escobar_timecycle_fd_prompt.xml'

escrow_ignore {
    'stream/unlocked/**'
}

-- scripts --
lua54 'yes'

server_scripts{
	'sv_loader.lua'
}

dependency '/assetpacks'
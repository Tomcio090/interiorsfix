--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — LOCALE: English (en)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['en'] = Locales['en'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['en'].cctv = {
    -- ===== In-game texts (help prompts / notifications) =====
    help_open     = 'Press ~INPUT_CONTEXT~ to access the CCTV system.',
    help_exit     = 'Press ~INPUT_FRONTEND_PAUSE_ALTERNATE~ to exit.',
    no_access     = 'You do not have access to this system.',
    in_use        = '~r~This console is currently in use by another officer.',
    target_label  = 'Access CCTV System',
    cam_no_coords = '~r~Camera coordinates are not set!',
    cmd_setup_no_perm   = '~r~You do not have permission to use this command.',
    setup_started       = '~g~CCTV Camera Setup Mode Started.~w~',
    setup_cancelled     = '~y~CCTV Camera setup cancelled.',
    setup_saved         = '~g~CCTV Camera created successfully! (ID: %s)',
    setup_deleted       = '~g~CCTV Camera deleted. (ID: %s)',
    setup_not_found     = '~r~Custom camera with this ID not found.',
    setup_list_header   = '^3--- CCTV Custom Camera List ---^7',
    setup_prompt_label  = 'Camera Label (e.g. MRPD CAM 05)',
    setup_prompt_name   = 'Location Name (e.g. Main Hall)',
    setup_prompt_district = 'District (e.g. MRPD / Banks / Downtown)',

    -- ===== UI texts (sent to DUI/NUI) =====
    ui = {
        -- Window / desktop
        title_bar      = 'MISSION ROW POLICE DEPARTMENT - CCTV SYSTEM',
        icon_disk      = 'Disk',
        icon_recycle   = 'Recycle Bin',
        icon_files     = 'Main Files',
        min            = 'Minimize',
        max            = 'Maximize',
        close          = 'Close',
        live           = 'LIVE',
        rec            = 'REC',

        -- Sidebar
        system_status  = 'System Status',
        operational    = 'OPERATIONAL',
        search         = 'Search',
        bookmarks      = 'Bookmarks',
        all_cameras    = 'All Cameras',

        -- Telemetry panel
        telemetry      = 'STATION TELEMETRY',
        station        = 'STATION:',
        sys_time       = 'SYS TIME:',
        operator       = 'OPERATOR:',
        on_duty        = 'ON-DUTY',
        net_link       = 'NET LINK:',
        secured        = 'SECURED',
        active_feeds   = 'ACTIVE FEEDS:',
        disk_cap       = 'DISK CAP:',

        -- Main panel
        camera_network = 'CAMERA NETWORK',
        bookmarks_title= 'BOOKMARKS',
        sort           = 'Sort:',
        sort_default   = 'Default',
        sort_name      = 'Name (A-Z)',
        sort_location  = 'Location',
        search_ph      = 'Search cameras...',
        no_cameras     = 'No cameras found',
        no_in_district = 'No cameras in this district',
        no_bookmarks   = 'No bookmarked cameras',

        -- CCTV HUD (fullscreen camera)
        disconnect     = '[ BACKSPACE ] DISCONNECT',

        -- Telemetry console log lines
        log_lines = {
            'Secure link verified',
            'Uplink established',
            'Disk check OK',
            'Channel synchronized',
            'Data packet routed',
            'Feed heartbeat OK',
            'Buffer cleared',
            'Encryption renewed',
            'Port listening...',
            'Frame cache reset',
            'Telemetry ping: 12ms',
            'Signal level: nominal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['en'].hygiene = {
    ['shower_prompt']   = '[E] Take a shower',
    ['poop_prompt']     = '[E] Poop',
    ['pee_prompt']      = '[G] Pee',
    ['toilet_prompt']   = '[E] Poop  |  [G] Pee',

    ['shower_target']   = 'Take a shower',
    ['poop_target']     = 'Poop',
    ['pee_target']      = 'Pee',
    ['wash_target']     = 'Wash Hands',

    ['shower_start']    = 'You are taking a shower...',
    ['shower_done']     = 'Shower completed!',
    ['poop_start']      = 'You are using the toilet...',
    ['poop_done']       = 'Toilet completed!',
    ['pee_start']       = 'You are using the toilet...',
    ['pee_done']        = 'Toilet completed!',
    ['wash_start']      = 'You are washing your hands...',
    ['wash_done']       = 'You washed your hands!',
    ['busy']            = 'You are busy right now!',
    
    ['shower_exit']     = 'Press ~INPUT_VEH_DUCK~ to exit the shower',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['en'].killhouse = {
    ['training_started'] = "Kill House training started! Hit as many targets as possible.",
    ['training_finished'] = "Training complete! Time: %s | Score: %s/%s",
    ['training_canceled'] = "Training canceled! You left the training area.",
    ['training_failed'] = "Civilian hit! Training failed.",
    ['menu_header'] = "Kill House - Weapon Selection",
    ['menu_desc'] = "Select this weapon and begin training.",
    ['menu_cancel'] = "Cancel",
    ['menu_cancel_desc'] = "Cancel training",
    ['ui_title'] = "KILL HOUSE TRAINING",
    ['ui_time'] = "TIME",
    ['ui_targets'] = "TARGETS",
    ['ui_footer'] = "SHOOTING CIVILIANS RESULTS IN FAILURE",
    ['weapon_given'] = "Weapon equipped.",
    ['weapon_removed'] = "Weapon returned.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ to select weapon",
    ['troll_warning'] = "You left the training area! Weapon confiscated.",
    ['operator_inside'] = "Another operator is currently inside!",
    ['target_weapon_menu'] = "Select Weapon",
    ['target_killhouse_start'] = "Start Kill House Training",
    ['scoreboard_reset_success'] = "Scoreboard reset successfully!",
    ['no_permission'] = "You do not have permission to use this command!",
    ['no_access'] = "You are not cleared to use the kill house."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['en'].projector = {
    -- ===== In-game texts =====
    help_open    = 'Press ~INPUT_CONTEXT~ to access the projector system.',
    target_label = 'Open Presentation Console',
    no_access    = 'You do not have access to this console.',
    in_use       = '~r~Another user is currently using the console.',

    -- ===== UI texts (sent to DUI/NUI) =====
    ui = {
        -- Status / display
        ready        = 'READY',
        live         = 'LIVE',
        live_edit    = 'LIVE EDIT',
        no_signal    = 'NO SIGNAL.',
        input_video  = 'INPUT: VIDEO',

        -- App menu (decorative)
        menu_file   = 'File',   menu_edit   = 'Edit',   menu_image  = 'Image',
        menu_layer  = 'Layer',  menu_type   = 'Type',   menu_select = 'Select',
        menu_filter = 'Filter', menu_view   = 'View',   menu_window = 'Window',
        menu_help   = 'Help',

        -- URL / media view
        no_content     = 'NO EMBEDDED CONTENT',
        no_content_sub = 'Load an external image, video, or stream URL',
        load           = 'LOAD',
        remove         = 'REMOVE',
        url_hint       = 'Supported extensions: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Panels
        canvas_bg     = 'CANVAS BACKGROUND',
        bg_dark       = 'Dark',
        bg_white      = 'White',
        bg_grid       = 'Grid',
        bg_dots       = 'Dots',
        board_presets = 'BOARD PRESETS',
        save          = 'SAVE',
        preset_ph     = 'Preset Name...',
        no_presets    = 'No custom presets saved.',
        character     = 'CHARACTER',
        font_family   = 'Font Family',
        font_size     = 'Font Size',
        styles        = 'Styles',
        swatches      = 'Swatches',
        actions       = 'ACTIONS',
        undo          = 'Undo Action',
        delete_sel    = 'Delete Selection',
        clear_canvas  = 'Clear Canvas',
        drop_signal   = 'DROP TO NO SIGNAL',
        transmit      = 'TRANSMIT LIVE',

        -- Image modal
        place_image = 'PLACE EMBEDDED IMAGE',
        place_hint  = 'Supports direct links: .png .jpg .jpeg .webp .gif (HTTPS only)',
        cancel      = 'Cancel',
        place       = 'Place',

        -- Standalone panel
        media_link      = 'PROJECTOR MEDIA LINK',
        url_cast        = 'URL Cast',
        supported_short = 'Supported: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'PULL FROM SCREEN',
        presets         = 'Presets',
        save_preset     = 'SAVE PRESET',
        sa_preset_ph    = 'Enter preset name to save current URL...',

        -- Desktop icons
        icon_disk    = 'Disk',
        icon_recycle = 'Recycle Bin',
        icon_drafts  = 'Drafts',

        -- Tool tooltips
        tool_move   = 'Move Tool (V)',
        tool_brush  = 'Brush Tool (B)',
        tool_eraser = 'Eraser Tool (E)',
        tool_type   = 'Horizontal Type Tool (T)',
        tool_place  = 'Place Embedded Image',
        fg_color    = 'Foreground Color',
        bg_color    = 'Background Color',
        bold        = 'Bold',
        italic      = 'Italic',

        -- Dynamic statuses (JS)
        invalid_url   = 'Invalid URL — allowed: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Media loaded locally. Press TRANSMIT LIVE to broadcast.',
        transmitting  = 'Transmitting...',
        synced        = 'Synced to projector ✓',
        local_changes = 'Changes are local until synchronized',
        all_synced    = 'All edits synchronized.',
        delete_preset = 'Delete Preset',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['en'].range = {
    ['booth_entered'] = "Entered Booth #%s! Aim at the target and fire.",
    ['booth_controls'] = "Use ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ to move the target.",
    ['training_finished'] = "Session Finished! Score: %s | Time: %s",
    ['menu_header'] = "Shooting Range - Weapon Selection",
    ['menu_desc'] = "Select this weapon for range practice.",
    ['menu_cancel'] = "Cancel",
    ['menu_cancel_desc'] = "Close menu",
    ['ui_title'] = "SHOOTING RANGE",
    ['ui_time'] = "TIME",
    ['ui_score'] = "SCORE",
    ['weapon_given'] = "Weapon equipped.",
    ['weapon_removed'] = "Weapon returned.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ to select weapon",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ to open computer (Aim Challenge)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ to enter Booth #%s",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ to start Aim Challenge (Booth #3)",
    ['select_weapon_first'] = "Please select a weapon first for Aim Challenge!",
    ['equip_weapon_first'] = "Please equip your weapon first for Aim Challenge!",
    ['booth_occupied'] = "Booth #%s is currently occupied!",
    ['range_busy_aimlab'] = "Players are currently using the range! All booths must be empty to start Aim Challenge.",
    ['aimlab_in_progress'] = "An Aim Challenge is currently in progress by %s!",
    ['aimlab_goto_booth'] = "Aim Challenge Initiated! Proceed to Booth #3 and press [E].",
    ['aimlab_finished'] = "Aim Challenge Complete! Targets Hit: %s | Weapon: %s",
    ['aimlab_canceled'] = "Aim Challenge canceled because you left the booth!",
    ['target_weapon_menu'] = "Select Weapon",
    ['target_laptop'] = "Open Computer (Aim Challenge)",
    ['target_booth'] = "Enter Booth #%s",
    ['target_aimlab'] = "Start Aim Challenge (Booth #3)",
    ['scoreboard_reset_success'] = "Scoreboard reset successfully!",
    ['no_permission'] = "You do not have permission to use this command!",
    ['no_access'] = "You are not cleared to use the shooting range."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['en'].archive = {
    ['blip_label']       = 'Digital Archive',
    ['prompt_label']     = '~INPUT_CONTEXT~ Access Digital Archive',
    ['target_label']     = 'Access Digital Archive',
    ['no_access']        = 'You do not have access to the archive.',

    ['header_title']     = 'LSPD — Digital Archive',
    ['header_subtitle']  = 'LSPD Personnel Records Archive',
    ['badge_text']       = 'FILE INACTIVE',
    ['label_rank']       = 'RANK',
    ['label_name']       = 'FULL NAME',
    ['label_badge']      = 'BADGE NO',
    ['label_service']    = 'SERVICE',
    ['label_status']     = 'STATUS',
    ['footer_copy']      = '© Los Santos Police Department',
    ['footer_close']     = '[X] Close',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Years',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

On the night of October 14th, the Los Santos Police Department lost more than a Sergeant.
The department lost a protector, a mentor, and a man who dedicated eighteen years of his life to the badge and the people behind it. Sergeant II Troy Bolo served the Mission Row Police Department with unwavering loyalty, courage, and honor. Known throughout the department for his calm leadership and deep compassion for both officers and civilians, Bolo earned the respect of every division he worked alongside. To younger officers, he was a mentor. To his fellow Sergeants, he was someone they could always rely on. To the city of Los Santos, he was one of its finest guardians.

On the evening of his passing, officers received reports of an armed kidnapping involving a family being held hostage by a gang operating out of Little Seoul. Due to the dangerous nature of the situation, a younger Sergeant had originally been assigned to command the response. Sergeant Bolo, believing the operation carried an unacceptable risk for the younger supervisor, voluntarily took command himself. Witnesses and officers on scene later stated that Bolo remained composed throughout the operation, prioritizing the safety of the hostages above all else. Through negotiation and tactical coordination, the family was successfully rescued without harm.

Moments after the hostages were secured, an injured gang member who had been lying unnoticed among the scene opened fire without warning. Sergeant Troy Bolo was struck while protecting officers and civilians nearby. Despite immediate medical response efforts, Sergeant Bolo succumbed to his injuries in the line of duty. His final actions reflected the man he had always been — selfless, fearless, and devoted to protecting others, even at the cost of his own life.

The halls of Mission Row Police Department still carry his memory. His locker remains untouched. His name continues to be spoken with pride. And the officers he trained continue to serve inspired by the example he left behind. Sergeant II Troy Bolo is survived by a department that will never forget him.

End of Watch
Sergeant II Troy Bolo
18 Years of Service
"The city sleeps safer because men like him stood watch."
]]
}

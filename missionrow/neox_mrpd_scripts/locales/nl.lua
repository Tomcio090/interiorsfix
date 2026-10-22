-- =========================================================
-- NEOX MRPD — LOCALE: Nederlands (nl)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['nl'] = Locales['nl'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['nl'].cctv = {
    -- ===== In-game teksten (meldingen / interactie) =====
    help_open     = 'Druk op ~INPUT_CONTEXT~ om het CCTV-systeem te openen.',
    help_exit     = 'Druk op ~INPUT_FRONTEND_PAUSE_ALTERNATE~ om te sluiten.',
    no_access     = 'Je hebt geen toegang tot dit systeem.',
    in_use        = '~r~Deze console wordt momenteel gebruikt door een andere agent.',
    target_label  = 'CCTV-systeem openen',
    cam_no_coords = '~r~Cameracoördinaten zijn niet ingesteld!',
    cmd_setup_no_perm   = '~r~Je hebt geen toestemming om dit commando te gebruiken.',
    setup_started       = '~g~CCTV Camera Setup Modus Gestart.~w~',
    setup_cancelled     = '~y~CCTV Camera setup geannuleerd.',
    setup_saved         = '~g~CCTV Camera succesvol aangemaakt! (ID: %s)',
    setup_deleted       = '~g~CCTV Camera verwijderd. (ID: %s)',
    setup_not_found     = '~r~Aangepaste camera met dit ID niet gevonden.',
    setup_list_header   = '^3--- CCTV Aangepaste Cameralijst ---^7',
    setup_prompt_label  = 'Cameralabel (bijv. MRPD CAM 05)',
    setup_prompt_name   = 'Locatienaam (bijv. Hoofdhal)',
    setup_prompt_district = 'District (bijv. MRPD / Banken / Downtown)',

    -- ===== UI-teksten (verzonden naar DUI/NUI) =====
    ui = {
        -- Venster / bureaublad
        title_bar      = 'POLITIEBUREAU MISSION ROW - CCTV-SYSTEEM',
        icon_disk      = 'Schijf',
        icon_recycle   = 'Prullenbak',
        icon_files     = 'Hoofdbestanden',
        min            = 'Minimaliseren',
        max            = 'Maximaliseren',
        close          = 'Sluiten',
        live           = 'LIVE',
        rec            = 'OPN',

        -- Zijbalk
        system_status  = 'Systeemstatus',
        operational    = 'OPERATIONEEL',
        search         = 'Zoeken',
        bookmarks      = 'Favorieten',
        all_cameras    = 'Alle Camera\'s',

        -- Telemetriepaneel
        telemetry      = 'BUREAU TELEMETRIE',
        station        = 'BUREAU:',
        sys_time       = 'SYSTIJD:',
        operator       = 'OPERATOR:',
        on_duty        = 'IN DIENST',
        net_link       = 'NETWERKVERBINDING:',
        secured        = 'BEVEILIGD',
        active_feeds   = 'ACTIEVE FEEDS:',
        disk_cap       = 'SCHIJFCAPACITEIT:',

        -- Hoofdpaneel
        camera_network = 'CAMERANETWERK',
        bookmarks_title= 'FAVORIETEN',
        sort           = 'Sorteren:',
        sort_default   = 'Standaard',
        sort_name      = 'Naam (A-Z)',
        sort_location  = 'Locatie',
        search_ph      = 'Camera\'s zoeken...',
        no_cameras     = 'Geen camera\'s gevonden',
        no_in_district = 'Geen camera\'s in dit district',
        no_bookmarks   = 'Geen favoriete camera\'s',

        -- CCTV HUD (volledig scherm camera)
        disconnect     = '[ BACKSPACE ] VERBINDING VERBREKEN',

        -- Telemetrie logregels
        log_lines = {
            'Beveiligde verbinding geverifieerd',
            'Uplink tot stand gebracht',
            'Schijfcontrole OK',
            'Kanaal gesynchroniseerd',
            'Gegevenspakket gerouteerd',
            'Feed heartbeat OK',
            'Buffer gewist',
            'Encryptie vernieuwd',
            'Poort luistert...',
            'Frame cache gereset',
            'Telemetrie ping: 12ms',
            'Signaalniveau: nominaal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['nl'].hygiene = {
    ['shower_prompt']   = '[E] Douchen',
    ['poop_prompt']     = '[E] Poepen',
    ['pee_prompt']      = '[G] Plassen',
    ['toilet_prompt']   = '[E] Poepen  |  [G] Plassen',

    ['shower_target']   = 'Douchen',
    ['poop_target']     = 'Poepen',
    ['pee_target']      = 'Plassen',
    ['wash_target']     = 'Handen wassen',

    ['shower_start']    = 'Je bent aan het douchen...',
    ['shower_done']     = 'Douche voltooid!',
    ['poop_start']      = 'Je gebruikt het toilet...',
    ['poop_done']       = 'Toiletbezoek voltooid!',
    ['pee_start']       = 'Je gebruikt het toilet...',
    ['pee_done']        = 'Toiletbezoek voltooid!',
    ['wash_start']      = 'Je wast je handen...',
    ['wash_done']       = 'Je hebt je handen gewassen!',
    ['busy']            = 'Je bent momenteel bezig!',
    
    ['shower_exit']     = 'Druk op ~INPUT_VEH_DUCK~ om de douche te verlaten',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['nl'].killhouse = {
    ['training_started'] = "Kill House training gestart! Raak zoveel mogelijk doelen.",
    ['training_finished'] = "Training voltooid! Tijd: %s | Score: %s/%s",
    ['training_canceled'] = "Training geannuleerd! Je hebt het trainingsgebied verlaten.",
    ['training_failed'] = "Burger geraakt! Training mislukt.",
    ['menu_header'] = "Kill House - Wapen Selectie",
    ['menu_desc'] = "Selecteer dit wapen en begin de training.",
    ['menu_cancel'] = "Annuleren",
    ['menu_cancel_desc'] = "Training annuleren",
    ['ui_title'] = "KILL HOUSE TRAINING",
    ['ui_time'] = "TIJD",
    ['ui_targets'] = "DOELEN",
    ['ui_footer'] = "HET RAKEN VAN BURGERS LEIDT TOT MISLUKKING",
    ['weapon_given'] = "Wapen uitgerust.",
    ['weapon_removed'] = "Wapen ingeleverd.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ om wapen te selecteren",
    ['troll_warning'] = "Je hebt het trainingsgebied verlaten! Wapen in beslag genomen.",
    ['operator_inside'] = "Een andere operator bevindt zich momenteel binnen!",
    ['target_weapon_menu'] = "Wapen Selecteren",
    ['target_killhouse_start'] = "Kill House Training Starten",
    ['scoreboard_reset_success'] = "Scorebord succesvol gereset!",
    ['no_permission'] = "Je hebt geen toestemming om dit commando te gebruiken!",
    ['no_access'] = "Je bent niet bevoegd om het Kill House te gebruiken."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['nl'].projector = {
    -- ===== In-game teksten =====
    help_open    = 'Druk op ~INPUT_CONTEXT~ om het projectorsysteem te openen.',
    target_label = 'Presentatieconsole Openen',
    no_access    = 'Je hebt geen toegang tot deze console.',
    in_use       = '~r~Een andere gebruiker gebruikt momenteel deze console.',

    -- ===== UI-teksten (verzonden naar DUI/NUI) =====
    ui = {
        -- Status / weergave
        ready        = 'GEREED',
        live         = 'LIVE',
        live_edit    = 'LIVE BEWERKEN',
        no_signal    = 'GEEN SIGNAAL.',
        input_video  = 'INGANG: VIDEO',

        -- App-menu (decoratief)
        menu_file   = 'Bestand',   menu_edit   = 'Bewerken',  menu_image  = 'Afbeelding',
        menu_layer  = 'Laag',      menu_type   = 'Tekst',     menu_select = 'Selecteren',
        menu_filter = 'Filter',    menu_view   = 'Weergave',  menu_window = 'Venster',
        menu_help   = 'Help',

        -- URL / mediaweergave
        no_content     = 'GEEN INGEBEDDE INHOUD',
        no_content_sub = 'Laad een externe afbeelding, video of stream-URL',
        load           = 'LADEN',
        remove         = 'VERWIJDEREN',
        url_hint       = 'Ondersteunde formaten: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Panelen
        canvas_bg     = 'CANVAS ACHTERGROND',
        bg_dark       = 'Donker',
        bg_white      = 'Wit',
        bg_grid       = 'Raster',
        bg_dots       = 'Stippen',
        board_presets = 'BORD VOORINSTELLINGEN',
        save          = 'OPSLAAN',
        preset_ph     = 'Voorinstellingsnaam...',
        no_presets    = 'Geen aangepaste voorinstellingen opgeslagen.',
        character     = 'KARAKTER',
        font_family   = 'Lettertype',
        font_size     = 'Lettergrootte',
        styles        = 'Stijlen',
        swatches      = 'Kleurstalen',
        actions       = 'ACTIES',
        undo          = 'Actie Ongedaan Maken',
        delete_sel    = 'Selectie Verwijderen',
        clear_canvas  = 'Canvas Wissen',
        drop_signal   = 'UITSCHAKELEN NAAR GEEN SIGNAAL',
        transmit      = 'LIVE UITZENDEN',

        -- Afbeelding modal
        place_image = 'INGEBEDDE AFBEELDING PLAATSEN',
        place_hint  = 'Directe links: .png .jpg .jpeg .webp .gif (alleen HTTPS)',
        cancel      = 'Annuleren',
        place       = 'Plaatsen',

        -- Standalone paneel
        media_link      = 'PROJECTOR MEDIALINK',
        url_cast        = 'URL Casten',
        supported_short = 'Ondersteund: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'OPHALEN VAN SCHERM',
        presets         = 'Voorinstellingen',
        save_preset     = 'VOORINSTELLING OPSLAAN',
        sa_preset_ph    = 'Voer naam in om huidige URL op te slaan...',

        -- Bureaublad iconen
        icon_disk    = 'Schijf',
        icon_recycle = 'Prullenbak',
        icon_drafts  = 'Concepten',

        -- Gereedschap tooltips
        tool_move   = 'Verplaatsgereedschap (V)',
        tool_brush  = 'Penseelgereedschap (B)',
        tool_eraser = 'Gomgereedschap (E)',
        tool_type   = 'Horizontale Tekstgereedschap (T)',
        tool_place  = 'Ingebedde Afbeelding Plaatsen',
        fg_color    = 'Voorgrondkleur',
        bg_color    = 'Achtergrondkleur',
        bold        = 'Vet',
        italic      = 'Cursief',

        -- Dynamische statussen (JS)
        invalid_url   = 'Ongeldige URL — toegestaan: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Media lokaal geladen. Druk op LIVE UITZENDEN om te projecteren.',
        transmitting  = 'Uitzenden...',
        synced        = 'Gesynchroniseerd met projector ✓',
        local_changes = 'Wijzigingen zijn lokaal tot synchronisatie',
        all_synced    = 'Alle bewerkingen gesynchroniseerd.',
        delete_preset = 'Voorinstelling Verwijderen',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['nl'].range = {
    ['booth_entered'] = "Schietbaan #%s betreden! Richt op het doel en vuur.",
    ['booth_controls'] = "Gebruik ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ om het doel te verplaatsen.",
    ['training_finished'] = "Sessie Voltooid! Score: %s | Tijd: %s",
    ['menu_header'] = "Schietbaan - Wapen Selectie",
    ['menu_desc'] = "Selecteer dit wapen voor schietoefeningen.",
    ['menu_cancel'] = "Annuleren",
    ['menu_cancel_desc'] = "Menu sluiten",
    ['ui_title'] = "SCHIETBAAN",
    ['ui_time'] = "TIJD",
    ['ui_score'] = "SCORE",
    ['weapon_given'] = "Wapen uitgerust.",
    ['weapon_removed'] = "Wapen ingeleverd.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ om wapen te selecteren",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ om computer te openen (Aim Challenge)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ om Schietbaan #%s te betreden",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ om Aim Challenge te starten (Schietbaan #3)",
    ['select_weapon_first'] = "Selecteer eerst een wapen voor de Aim Challenge!",
    ['equip_weapon_first'] = "Rust eerst je wapen uit voor de Aim Challenge!",
    ['booth_occupied'] = "Schietbaan #%s is momenteel bezet!",
    ['range_busy_aimlab'] = "Er zijn spelers actief op de schietbaan! Alle banen moeten leeg zijn om de Aim Challenge te starten.",
    ['aimlab_in_progress'] = "Een Aim Challenge is momenteel bezig door %s!",
    ['aimlab_goto_booth'] = "Aim Challenge gestart! Ga naar Schietbaan #3 en druk op [E].",
    ['aimlab_finished'] = "Aim Challenge Voltooid! Doelen Geraakt: %s | Wapen: %s",
    ['aimlab_canceled'] = "Aim Challenge geannuleerd omdat je de baan hebt verlaten!",
    ['target_weapon_menu'] = "Wapen Selecteren",
    ['target_laptop'] = "Computer Openen (Aim Challenge)",
    ['target_booth'] = "Schietbaan #%s Betreden",
    ['target_aimlab'] = "Aim Challenge Starten (Schietbaan #3)",
    ['scoreboard_reset_success'] = "Scorebord succesvol gereset!",
    ['no_permission'] = "Je hebt geen toestemming om dit commando te gebruiken!",
    ['no_access'] = "Je bent niet bevoegd om de schietbaan te gebruiken."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['nl'].archive = {
    ['blip_label']       = 'Digitaal Archief',
    ['prompt_label']     = '~INPUT_CONTEXT~ Toegang tot Digitaal Archief',
    ['target_label']     = 'Toegang tot Digitaal Archief',
    ['no_access']        = 'Je hebt geen toegang tot het archief.',

    ['header_title']     = 'LSPD — Digitaal Archief',
    ['header_subtitle']  = 'LSPD Personeelsdossiers Archief',
    ['badge_text']       = 'DOSSIER INACTIEF',
    ['label_rank']       = 'RANG',
    ['label_name']       = 'VOLLEDIGE NAAM',
    ['label_badge']      = 'BADGE NR',
    ['label_service']    = 'DIENSTTIJD',
    ['label_status']     = 'STATUS',
    ['footer_copy']      = '© Los Santos Police Department',
    ['footer_close']     = '[X] Sluiten',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Jaar',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

In de nacht van 14 oktober verloor de Los Santos Police Department meer dan een Sergeant.
De afdeling verloor een beschermer, een mentor en een man die achttien jaar van zijn leven wijdde aan de badge en de mensen erachter. Sergeant II Troy Bolo diende de Mission Row Police Department met onwankelbare loyaliteit, moed en eer. Bekend in de hele afdeling vanwege zijn rustige leiderschap en diepe compassie voor zowel agenten als burgers, verdiende Bolo het respect van elke divisie waarmee hij samenwerkte. Voor jongere agenten was hij een mentor. Voor zijn mede-Sergeanten was hij iemand op wie ze altijd konden rekenen. Voor de stad Los Santos was hij een van de beste bewakers.

Op de avond van zijn overlijden ontvingen agenten meldingen van een gewapende ontvoering waarbij een gezin werd gegijzeld door een bende die opereerde vanuit Little Seoul. Vanwege de gevaarlijke aard van de situatie was oorspronkelijk een jongere Sergeant toegewezen om de leiding over de reactie op zich te nemen. Sergeant Bolo geloofde dat de operatie een onaanvaardbaar risico met zich meebracht voor de jongere leidinggevende, en nam vrijwillig zelf het commando op zich. Getuigen en agenten ter plaatse verklaarden later dat Bolo tijdens de hele operatie kalm bleef, waarbij de veiligheid van de gijzelaars boven alles ging. Door middel van onderhandelingen en tactische coördinatie werd de familie succesvol en ongedeerd gered.

Seconden nadat de gijzelaars in veiligheid waren gebracht, opende een gewond bendelid dat onopgemerkt op de plaats delict had gelegen zonder waarschuwing het vuur. Sergeant Troy Bolo werd geraakt terwijl hij agenten en burgers in de buurt beschermde. Ondanks onmiddellijke medische hulpverlening bezweek Sergeant Bolo aan zijn verwondingen tijdens de uitoefening van zijn functie. Zijn laatste acties weerspiegelden de man die hij altijd was geweest — onbaatzuchtig, onbevreesd en toegewijd aan het beschermen van anderen, zelfs ten koste van zijn eigen leven.

De gangen van de Mission Row Police Department dragen nog steeds zijn herinnering. Zijn kluisje blijft onaangeroerd. Zijn naam wordt nog steeds met trots uitgesproken. En de agenten die hij heeft opgeleid, blijven dienen geïnspireerd door het voorbeeld dat hij achterliet. Sergeant II Troy Bolo laat een afdeling achter die hem nooit zal vergeten.

End of Watch
Sergeant II Troy Bolo
18 Jaar Dienst
"De stad slaapt veiliger omdat mannen zoals hij de wacht hielden."
]]
}

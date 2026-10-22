-- =========================================================
-- NEOX MRPD — LOCALE: Deutsch (de)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['de'] = Locales['de'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['de'].cctv = {
    -- ===== Spieltexte (Hilfe / Benachrichtigungen) =====
    help_open     = 'Drücke ~INPUT_CONTEXT~, um auf das CCTV-System zuzugreifen.',
    help_exit     = 'Drücke ~INPUT_FRONTEND_PAUSE_ALTERNATE~ zum Beenden.',
    no_access     = 'Du hast keinen Zugriff auf dieses System.',
    in_use        = '~r~Diese Konsole wird gerade von einem anderen Beamten verwendet.',
    target_label  = 'CCTV-System öffnen',
    cam_no_coords = '~r~Kamerakoordinaten sind nicht gesetzt!',
    cmd_setup_no_perm   = '~r~Du hast keine Berechtigung, diesen Befehl zu verwenden.',
    setup_started       = '~g~CCTV-Kamera-Einrichtungsmodus gestartet.~w~',
    setup_cancelled     = '~y~CCTV-Kamera-Einrichtung abgebrochen.',
    setup_saved         = '~g~CCTV-Kamera erfolgreich erstellt! (ID: %s)',
    setup_deleted       = '~g~CCTV-Kamera gelöscht. (ID: %s)',
    setup_not_found     = '~r~Benutzerdefinierte Kamera mit dieser ID nicht gefunden.',
    setup_list_header   = '^3--- CCTV Benutzerdefinierte Kameraliste ---^7',
    setup_prompt_label  = 'Kamerabezeichnung (z. B. MRPD CAM 05)',
    setup_prompt_name   = 'Standortname (z. B. Haupthalle)',
    setup_prompt_district = 'Bezirk (z. B. MRPD / Banks / Downtown)',

    -- ===== UI-Texte (an DUI/NUI gesendet) =====
    ui = {
        -- Fenster / Desktop
        title_bar      = 'MISSION ROW POLICE DEPARTMENT - CCTV-SYSTEM',
        icon_disk      = 'Festplatte',
        icon_recycle   = 'Papierkorb',
        icon_files     = 'Dateien',
        min            = 'Minimieren',
        max            = 'Maximieren',
        close          = 'Schließen',
        live           = 'LIVE',
        rec            = 'AUFN',

        -- Seitenleiste
        system_status  = 'Systemstatus',
        operational    = 'BETRIEBSBEREIT',
        search         = 'Suchen',
        bookmarks      = 'Lesezeichen',
        all_cameras    = 'Alle Kameras',

        -- Telemetrie-Panel
        telemetry      = 'STATIONS-TELEMETRIE',
        station        = 'STATION:',
        sys_time       = 'SYSTEMZEIT:',
        operator       = 'OPERATOR:',
        on_duty        = 'IM DIENST',
        net_link       = 'NETZWERK:',
        secured        = 'GESICHERT',
        active_feeds   = 'AKTIVE FEEDS:',
        disk_cap       = 'SPEICHER:',

        -- Hauptpanel
        camera_network = 'KAMERANETZWERK',
        bookmarks_title= 'LESEZEICHEN',
        sort           = 'Sortieren:',
        sort_default   = 'Standard',
        sort_name      = 'Name (A-Z)',
        sort_location  = 'Standort',
        search_ph      = 'Kameras durchsuchen...',
        no_cameras     = 'Keine Kameras gefunden',
        no_in_district = 'Keine Kameras in diesem Bezirk',
        no_bookmarks   = 'Keine Kameras mit Lesezeichen',

        -- CCTV-HUD (Vollbildkamera)
        disconnect     = '[ BACKSPACE ] VERBINDUNG TRENNEN',

        -- Telemetrie-Konsolenzeilen
        log_lines = {
            'Sichere Verbindung verifiziert',
            'Uplink hergestellt',
            'Festplattenprüfung OK',
            'Kanal synchronisiert',
            'Datenpaket weitergeleitet',
            'Feed-Heartbeat OK',
            'Puffer geleert',
            'Verschlüsselung erneuert',
            'Port wird überwacht...',
            'Frame-Cache zurückgesetzt',
            'Telemetrie-Ping: 12ms',
            'Signalpegel: nominal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['de'].hygiene = {
    ['shower_prompt']   = '[E] Duschen',
    ['poop_prompt']     = '[E] Großes Geschäft',
    ['pee_prompt']      = '[G] Kleines Geschäft',
    ['toilet_prompt']   = '[E] Großes Geschäft  |  [G] Kleines Geschäft',

    ['shower_target']   = 'Duschen',
    ['poop_target']     = 'Großes Geschäft',
    ['pee_target']      = 'Kleines Geschäft',
    ['wash_target']     = 'Hände waschen',

    ['shower_start']    = 'Du nimmst eine Dusche...',
    ['shower_done']     = 'Dusche beendet!',
    ['poop_start']      = 'Du benutzt die Toilette...',
    ['poop_done']       = 'Toilette beendet!',
    ['pee_start']       = 'Du benutzt die Toilette...',
    ['pee_done']        = 'Toilette beendet!',
    ['wash_start']      = 'Du wäschst dir die Hände...',
    ['wash_done']       = 'Du hast dir die Hände gewaschen!',
    ['busy']            = 'Du bist gerade beschäftigt!',
    
    ['shower_exit']     = 'Drücke ~INPUT_VEH_DUCK~, um die Dusche zu verlassen',
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['de'].projector = {
    -- ===== Spieltexte =====
    help_open    = 'Drücke ~INPUT_CONTEXT~, um auf das Projektorsystem zuzugreifen.',
    target_label = 'Präsentationskonsole öffnen',
    no_access    = 'Du hast keinen Zugriff auf diese Konsole.',
    in_use       = '~r~Die Konsole wird gerade von einem anderen Benutzer verwendet.',

    -- ===== UI-Texte (an DUI/NUI gesendet) =====
    ui = {
        -- Status / Anzeige
        ready        = 'BEREIT',
        live         = 'LIVE',
        live_edit    = 'LIVE-BEARBEITUNG',
        no_signal    = 'KEIN SIGNAL.',
        input_video  = 'EINGANG: VIDEO',

        -- App-Menü (dekorativ)
        menu_file   = 'Datei',      menu_edit   = 'Bearbeiten', menu_image  = 'Bild',
        menu_layer  = 'Ebene',      menu_type   = 'Schrift',    menu_select = 'Auswahl',
        menu_filter = 'Filter',     menu_view   = 'Ansicht',    menu_window = 'Fenster',
        menu_help   = 'Hilfe',

        -- URL- / Medienansicht
        no_content     = 'KEIN EINGEBETTETER INHALT',
        no_content_sub = 'Lade ein externes Bild, Video oder eine Stream-URL',
        load           = 'LADEN',
        remove         = 'ENTFERNEN',
        url_hint       = 'Unterstützte Formate: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Panels
        canvas_bg     = 'LEINWAND-HINTERGRUND',
        bg_dark       = 'Dunkel',
        bg_white      = 'Weiß',
        bg_grid       = 'Raster',
        bg_dots       = 'Punkte',
        board_presets = 'BOARD-VORLAGEN',
        save          = 'SPEICHERN',
        preset_ph     = 'Vorlagenname...',
        no_presets    = 'Keine Vorlagen gespeichert.',
        character     = 'ZEICHEN',
        font_family   = 'Schriftart',
        font_size     = 'Schriftgröße',
        styles        = 'Stile',
        swatches      = 'Farbfelder',
        actions       = 'AKTIONEN',
        undo          = 'Rückgängig',
        delete_sel    = 'Auswahl löschen',
        clear_canvas  = 'Leinwand leeren',
        drop_signal   = 'SIGNAL TRENNEN',
        transmit      = 'LIVE ÜBERTRAGEN',

        -- Bild-Modal
        place_image = 'EINGEBETTETES BILD PLATZIEREN',
        place_hint  = 'Direkte Links: .png .jpg .jpeg .webp .gif (nur HTTPS)',
        cancel      = 'Abbrechen',
        place       = 'Platzieren',

        -- Standalone-Panel
        media_link      = 'PROJEKTOR-MEDIENLINK',
        url_cast        = 'URL-Übertragung',
        supported_short = 'Unterstützt: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'VOM BILDSCHIRM ZIEHEN',
        presets         = 'Vorlagen',
        save_preset     = 'VORLAGE SPEICHERN',
        sa_preset_ph    = 'Vorlagenname eingeben, um aktuelle URL zu speichern...',

        -- Desktop-Symbole
        icon_disk    = 'Festplatte',
        icon_recycle = 'Papierkorb',
        icon_drafts  = 'Entwürfe',

        -- Werkzeug-Tooltips
        tool_move   = 'Verschieben-Werkzeug (V)',
        tool_brush  = 'Pinsel-Werkzeug (B)',
        tool_eraser = 'Radierer-Werkzeug (E)',
        tool_type   = 'Horizontales Text-Werkzeug (T)',
        tool_place  = 'Eingebettetes Bild platzieren',
        fg_color    = 'Vordergrundfarbe',
        bg_color    = 'Hintergrundfarbe',
        bold        = 'Fett',
        italic      = 'Kursiv',

        -- Dynamische Status (JS)
        invalid_url   = 'Ungültige URL — erlaubt: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Medien lokal geladen. Drücke LIVE ÜBERTRAGEN zum Senden.',
        transmitting  = 'Wird übertragen...',
        synced        = 'Mit Projektor synchronisiert ✓',
        local_changes = 'Änderungen sind lokal, bis sie synchronisiert werden',
        all_synced    = 'Alle Bearbeitungen synchronisiert.',
        delete_preset = 'Vorlage löschen',
    },
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['de'].killhouse = {
    ['training_started'] = "Kill House Training gestartet! Triff so viele Ziele wie möglich.",
    ['training_finished'] = "Training abgeschlossen! Zeit: %s | Punkte: %s/%s",
    ['training_canceled'] = "Training abgebrochen! Du hast den Trainingsbereich verlassen.",
    ['training_failed'] = "Zivilist getroffen! Training fehlgeschlagen.",
    ['menu_header'] = "Kill House - Waffenauswahl",
    ['menu_desc'] = "Wähle diese Waffe und starte das Training.",
    ['menu_cancel'] = "Abbrechen",
    ['menu_cancel_desc'] = "Training abbrechen",
    ['ui_title'] = "KILL HOUSE TRAINING",
    ['ui_time'] = "ZEIT",
    ['ui_targets'] = "ZIELE",
    ['ui_footer'] = "DAS ERSCHIEßEN VON ZIVILISTEN FÜHRT ZUM FEHLSCHLAG",
    ['weapon_given'] = "Waffe ausgerüstet.",
    ['weapon_removed'] = "Waffe zurückgegeben.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ zur Waffenauswahl",
    ['troll_warning'] = "Du hast den Trainingsbereich verlassen! Waffe konfisziert.",
    ['operator_inside'] = "Ein anderer Officer befindet sich bereits im Kill House!",
    ['target_weapon_menu'] = "Waffe auswählen",
    ['target_killhouse_start'] = "Kill House Training starten",
    ['scoreboard_reset_success'] = "Bestenliste erfolgreich zurückgesetzt!",
    ['no_permission'] = "Du hast keine Berechtigung für diesen Befehl!",
    ['no_access'] = "Du bist nicht berechtigt, das Kill House zu nutzen."
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['de'].range = {
    ['booth_entered'] = "Schießstand #%s betreten! Zielen und feuern.",
    ['booth_controls'] = "Nutze ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ zum Bewegen des Ziels.",
    ['training_finished'] = "Runde beendet! Punkte: %s | Zeit: %s",
    ['menu_header'] = "Schießstand - Waffenauswahl",
    ['menu_desc'] = "Wähle diese Waffe für das Schießtraining.",
    ['menu_cancel'] = "Abbrechen",
    ['menu_cancel_desc'] = "Menü schließen",
    ['ui_title'] = "SCHIEßSTAND",
    ['ui_time'] = "ZEIT",
    ['ui_score'] = "PUNKTE",
    ['weapon_given'] = "Waffe ausgerüstet.",
    ['weapon_removed'] = "Waffe zurückgegeben.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ zur Waffenauswahl",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ zum Öffnen des Computers (Aim Challenge)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ um Stand #%s zu betreten",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ um Aim Challenge zu starten (Stand #3)",
    ['select_weapon_first'] = "Bitte wähle zuerst eine Waffe für die Aim Challenge aus!",
    ['equip_weapon_first'] = "Bitte rüste zuerst deine Waffe für die Aim Challenge aus!",
    ['booth_occupied'] = "Schießstand #%s ist derzeit belegt!",
    ['range_busy_aimlab'] = "Spieler nutzen derzeit den Schießstand! Alle Stände müssen leer sein, um die Aim Challenge zu starten.",
    ['aimlab_in_progress'] = "Eine Aim Challenge wird derzeit von %s durchgeführt!",
    ['aimlab_goto_booth'] = "Aim Challenge gestartet! Gehe zu Stand #3 und drücke [E].",
    ['aimlab_finished'] = "Aim Challenge beendet! Getroffene Ziele: %s | Waffe: %s",
    ['aimlab_canceled'] = "Aim Challenge abgebrochen, da du den Stand verlassen hast!",
    ['target_weapon_menu'] = "Waffe auswählen",
    ['target_laptop'] = "Computer öffnen (Aim Challenge)",
    ['target_booth'] = "Stand #%s betreten",
    ['target_aimlab'] = "Aim Challenge starten (Stand #3)",
    ['scoreboard_reset_success'] = "Bestenliste erfolgreich zurückgesetzt!",
    ['no_permission'] = "Du hast keine Berechtigung für diesen Befehl!",
    ['no_access'] = "Du bist nicht berechtigt, den Schießstand zu nutzen."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['de'].archive = {
    ['blip_label']       = 'Digitales Archiv',
    ['prompt_label']     = '~INPUT_CONTEXT~ Auf Digitales Archiv zugreifen',
    ['target_label']     = 'Auf Digitales Archiv zugreifen',
    ['no_access']        = 'Sie haben keinen Zugriff auf das Archiv.',

    ['header_title']     = 'LSPD — Digitales Archiv',
    ['header_subtitle']  = 'LSPD Personalakten-Archiv',
    ['badge_text']       = 'AKTE INAKTIV',
    ['label_rank']       = 'RANG',
    ['label_name']       = 'VOLLSTÄNDIGER NAME',
    ['label_badge']      = 'ABZEICHEN-NR',
    ['label_service']    = 'DIENSTZEIT',
    ['label_status']     = 'STATUS',
    ['footer_copy']      = '© Los Santos Police Department',
    ['footer_close']     = '[X] Schließen',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Jahre',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

In der Nacht des 14. Oktober verlor das Los Santos Police Department mehr als einen Sergeant.
Das Department verlor einen Beschützer, einen Mentor und einen Mann, der achtzehn Jahre seines Lebens dem Abzeichen und den Menschen dahinter widmete. Sergeant II Troy Bolo diente dem Mission Row Police Department mit unerschütterlicher Loyalität, Mut und Ehre. Bekannt im gesamten Department für seine ruhige Führung und sein tiefes Mitgefühl für Beamte und Zivilisten, verdiente sich Bolo den Respekt jeder Abteilung, mit der er zusammenarbeitete. Für jüngere Beamte war er ein Mentor. Für seine Sergeant-Kollegen war er jemand, auf den sie sich immer verlassen konnten. Für die Stadt Los Santos war er einer ihrer besten Wächter.

Am Abend seines Todes erhielten die Beamten Berichte über eine bewaffnete Entführung, bei der eine Familie von einer Bande als Geiseln gehalten wurde, die von Little Seoul aus operierte. Aufgrund der Gefährlichkeit der Situation war ursprünglich ein jüngerer Sergeant mit der Leitung des Einsatzes betraut worden. Sergeant Bolo war der Ansicht, dass die Operation für den jüngeren Vorgesetzten ein inakzeptables Risiko darstellte, und übernahm freiwillig selbst das Kommando. Zeugen und Beamte vor Ort gaben später an, dass Bolo während des gesamten Einsatzes gefasst blieb und die Sicherheit der Geiseln über alles andere stellte. Durch Verhandlungen und taktische Koordination konnte die Familie erfolgreich und unversehrt gerettet werden.

Sekunden nachdem die Geiseln in Sicherheit gebracht worden waren, eröffnete ein verletztes Bandenmitglied, das unbemerkt am Tatort gelegen hatte, ohne Vorwarnung das Feuer. Sergeant Troy Bolo wurde getroffen, als er Beamte und Zivilisten in der Nähe beschützte. Trotz sofortiger medizinischer Hilfe erlag Sergeant Bolo seinen Verletzungen in Ausübung seines Dienstes. Seine letzten Handlungen spiegelten den Mann wider, der er immer gewesen war — selbstlos, furchtlos und dem Schutz anderer verpflichtet, selbst auf Kosten seines eigenen Lebens.

Die Hallen des Mission Row Police Department tragen noch immer seine Erinnerung. Sein Spind bleibt unberührt. Sein Name wird weiterhin mit Stolz ausgesprochen. Und die Beamten, die er ausgebildet hat, dienen weiterhin, inspiriert durch das Vorbild, das er hinterlassen hat. Sergeant II Troy Bolo hinterlässt ein Department, das ihn niemals vergessen wird.

End of Watch
Sergeant II Troy Bolo
18 Dienstjahre
"Die Stadt schläft sicherer, weil Männer wie er Wache hielten."
]]
}


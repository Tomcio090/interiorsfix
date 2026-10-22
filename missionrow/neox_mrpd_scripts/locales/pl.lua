--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — LOCALE: Polski (pl)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['pl'] = Locales['pl'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['pl'].cctv = {
    -- ===== Teksty w grze (podpowiedzi / powiadomienia) =====
    help_open     = 'Naciśnij ~INPUT_CONTEXT~, aby uzyskać dostęp do systemu CCTV.',
    help_exit     = 'Naciśnij ~INPUT_FRONTEND_PAUSE_ALTERNATE~, aby wyjść.',
    no_access     = 'Nie masz dostępu do tego systemu.',
    in_use        = '~r~Ta konsola jest obecnie używana przez innego funkcjonariusza.',
    target_label  = 'Dostęp do Systemu CCTV',
    cam_no_coords = '~r~Współrzędne kamery nie są ustawione!',
    cmd_setup_no_perm   = '~r~Nie masz uprawnień do użycia tej komendy.',
    setup_started       = '~g~Tryb konfiguracji kamery CCTV rozpoczęty.~w~',
    setup_cancelled     = '~y~Konfiguracja kamery CCTV anulowana.',
    setup_saved         = '~g~Kamera CCTV utworzona pomyślnie! (ID: %s)',
    setup_deleted       = '~g~Kamera CCTV usunięta. (ID: %s)',
    setup_not_found     = '~r~Nie znaleziono niestandardowej kamery o tym ID.',
    setup_list_header   = '^3--- Lista kamer niestandardowych CCTV ---^7',
    setup_prompt_label  = 'Etykieta kamery (np. MRPD CAM 05)',
    setup_prompt_name   = 'Nazwa lokalizacji (np. Główny korytarz)',
    setup_prompt_district = 'Dzielnica (np. MRPD / Banki / Centrum)',

    -- ===== Teksty UI (wysyłane do DUI/NUI) =====
    ui = {
        -- Okno / pulpit
        title_bar      = 'DEPARTAMENT POLICJI MISSION ROW - SYSTEM CCTV',
        icon_disk      = 'Dysk',
        icon_recycle   = 'Kosz',
        icon_files     = 'Główne Pliki',
        min            = 'Minimalizuj',
        max            = 'Maksymalizuj',
        close          = 'Zamknij',
        live           = 'NA ŻYWO',
        rec            = 'NAGR',

        -- Pasek boczny
        system_status  = 'Status Systemu',
        operational    = 'OPERACYJNY',
        search         = 'Szukaj',
        bookmarks      = 'Zakładki',
        all_cameras    = 'Wszystkie Kamery',

        -- Panel telemetryczny
        telemetry      = 'TELEMETRIA POSTERUNKU',
        station        = 'POSTERUNEK:',
        sys_time       = 'CZAS SYS:',
        operator       = 'OPERATOR:',
        on_duty        = 'NA SŁUŻBIE',
        net_link       = 'ŁĄCZE SIECIOWE:',
        secured        = 'ZABEZPIECZONE',
        active_feeds   = 'AKTYWNE TRANSMISJE:',
        disk_cap       = 'POJEMNOŚĆ DYSKU:',

        -- Główny panel
        camera_network = 'SIEĆ KAMER',
        bookmarks_title= 'ZAKŁADKI',
        sort           = 'Sortuj:',
        sort_default   = 'Domyślnie',
        sort_name      = 'Nazwa (A-Z)',
        sort_location  = 'Lokalizacja',
        search_ph      = 'Szukaj kamer...',
        no_cameras     = 'Nie znaleziono kamer',
        no_in_district = 'Brak kamer w tej dzielnicy',
        no_bookmarks   = 'Brak kamer w zakładkach',

        -- CCTV HUD (kamera pełnoekranowa)
        disconnect     = '[ BACKSPACE ] ROZŁĄCZ',

        -- Linie dziennika telemetrii
        log_lines = {
            'Bezpieczne łącze zweryfikowane',
            'Uplink ustanowiony',
            'Sprawdzenie dysku OK',
            'Kanał zsynchronizowany',
            'Pakiet danych przekierowany',
            'Sygnał transmisji OK',
            'Bufor wyczyszczony',
            'Szyfrowanie odnowione',
            'Nasłuchiwanie portu...',
            'Pamięć podręczna klatek zresetowana',
            'Ping telemetrii: 12ms',
            'Poziom sygnału: nominalny',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['pl'].hygiene = {
    ['shower_prompt']   = '[E] Weź prysznic',
    ['poop_prompt']     = '[E] Zrób kupę',
    ['pee_prompt']      = '[G] Zrób siku',
    ['toilet_prompt']   = '[E] Zrób kupę  |  [G] Zrób siku',

    ['shower_target']   = 'Weź prysznic',
    ['poop_target']     = 'Zrób kupę',
    ['pee_target']      = 'Zrób siku',
    ['wash_target']     = 'Umyj ręce',

    ['shower_start']    = 'Bierzesz prysznic...',
    ['shower_done']     = 'Prysznic zakończony!',
    ['poop_start']      = 'Korzystasz z toalety...',
    ['poop_done']       = 'Wizyta w toalecie zakończona!',
    ['pee_start']       = 'Korzystasz z toalety...',
    ['pee_done']        = 'Wizyta w toalecie zakończona!',
    ['wash_start']      = 'Myjesz ręce...',
    ['wash_done']       = 'Umyłeś ręce!',
    ['busy']            = 'Jesteś teraz zajęty!',
    
    ['shower_exit']     = 'Naciśnij ~INPUT_VEH_DUCK~, aby wyjść spod prysznica',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['pl'].killhouse = {
    ['training_started'] = "Trening Kill House rozpoczęty! Traf jak najwięcej celów.",
    ['training_finished'] = "Trening zakończony! Czas: %s | Wynik: %s/%s",
    ['training_canceled'] = "Trening anulowany! Opuściłeś obszar treningowy.",
    ['training_failed'] = "Cywil trafiony! Trening niezaliczony.",
    ['menu_header'] = "Kill House - Wybór Broni",
    ['menu_desc'] = "Wybierz tę broń i rozpocznij trening.",
    ['menu_cancel'] = "Anuluj",
    ['menu_cancel_desc'] = "Anuluj trening",
    ['ui_title'] = "TRENING KILL HOUSE",
    ['ui_time'] = "CZAS",
    ['ui_targets'] = "CELE",
    ['ui_footer'] = "POSTRZELENIE CYWILA SKUTKUJE PORAŻKĄ",
    ['weapon_given'] = "Broń wyposażona.",
    ['weapon_removed'] = "Broń zwrócona.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ aby wybrać broń",
    ['troll_warning'] = "Opuściłeś obszar treningowy! Broń została skonfiskowana.",
    ['operator_inside'] = "Inny operator jest obecnie w środku!",
    ['target_weapon_menu'] = "Wybierz Broń",
    ['target_killhouse_start'] = "Rozpocznij Trening Kill House",
    ['scoreboard_reset_success'] = "Tabela wyników zresetowana pomyślnie!",
    ['no_permission'] = "Nie masz uprawnień do użycia tej komendy!",
    ['no_access'] = "Nie masz uprawnień do korzystania z Kill House."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['pl'].projector = {
    -- ===== Teksty w grze =====
    help_open    = 'Naciśnij ~INPUT_CONTEXT~, aby uzyskać dostęp do projektora.',
    target_label = 'Otwórz Konsolę Prezentacji',
    no_access    = 'Nie masz dostępu do tej konsoli.',
    in_use       = '~r~Inny użytkownik korzysta obecnie z konsoli.',

    -- ===== Teksty UI (wysyłane do DUI/NUI) =====
    ui = {
        -- Status / wyświetlanie
        ready        = 'GOTOWY',
        live         = 'NA ŻYWO',
        live_edit    = 'EDYCJA NA ŻYWO',
        no_signal    = 'BRAK SYGNAŁU.',
        input_video  = 'WEJŚCIE: WIDEO',

        -- Menu aplikacji (dekoracyjne)
        menu_file   = 'Plik',      menu_edit   = 'Edycja',    menu_image  = 'Obraz',
        menu_layer  = 'Warstwa',   menu_type   = 'Tekst',     menu_select = 'Zaznacz',
        menu_filter = 'Filtr',     menu_view   = 'Widok',     menu_window = 'Okno',
        menu_help   = 'Pomoc',

        -- Widok URL / mediów
        no_content     = 'BRAK OSADZONEJ ZAWARTOŚCI',
        no_content_sub = 'Załaduj zewnętrzny obraz, wideo lub adres URL transmisji',
        load           = 'ZAŁADUJ',
        remove         = 'USUŃ',
        url_hint       = 'Obsługiwane formaty: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Panele
        canvas_bg     = 'TŁO PŁÓTNA',
        bg_dark       = 'Ciemne',
        bg_white      = 'Białe',
        bg_grid       = 'Siatka',
        bg_dots       = 'Kropki',
        board_presets = 'SZABLONY TABLICY',
        save          = 'ZAPISZ',
        preset_ph     = 'Nazwa szablonu...',
        no_presets    = 'Brak zapisanych szablonów.',
        character     = 'ZNAK',
        font_family   = 'Czcionka',
        font_size     = 'Rozmiar Czcionki',
        styles        = 'Style',
        swatches      = 'Próbki',
        actions       = 'AKCJE',
        undo          = 'Cofnij Akcję',
        delete_sel    = 'Usuń Zaznaczenie',
        clear_canvas  = 'Wyczyść Płótno',
        drop_signal   = 'PRZEŁĄCZ NA BRAK SYGNAŁU',
        transmit      = 'TRANSMITUJ NA ŻYWO',

        -- Modal obrazu
        place_image = 'WSTAW OSADZONY OBRAZ',
        place_hint  = 'Bezpośrednie linki: .png .jpg .jpeg .webp .gif (tylko HTTPS)',
        cancel      = 'Anuluj',
        place       = 'Wstaw',

        -- Panel niezależny
        media_link      = 'ŁĄCZE MULTIMEDIALNE PROJEKTORA',
        url_cast        = 'Przesyłaj URL',
        supported_short = 'Obsługiwane: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'POBIERZ Z EKRANU',
        presets         = 'Szablony',
        save_preset     = 'ZAPISZ SZABLON',
        sa_preset_ph    = 'Wpisz nazwę, aby zapisać bieżący URL...',

        -- Ikony pulpitu
        icon_disk    = 'Dysk',
        icon_recycle = 'Kosz',
        icon_drafts  = 'Wersje robocze',

        -- Etykiety narzędzi
        tool_move   = 'Narzędzie Przesuwania (V)',
        tool_brush  = 'Narzędzie Pędzel (B)',
        tool_eraser = 'Narzędzie Gumka (E)',
        tool_type   = 'Poziome Narzędzie Tekstowe (T)',
        tool_place  = 'Wstaw Osadzony Obraz',
        fg_color    = 'Kolor Pierwszoplanowy',
        bg_color    = 'Kolor Tła',
        bold        = 'Pogrubienie',
        italic      = 'Kursywa',

        -- Dynamiczne statusy (JS)
        invalid_url   = 'Nieprawidłowy adres URL — dozwolone: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Media załadowane lokalnie. Naciśnij TRANSMITUJ NA ŻYWO.',
        transmitting  = 'Transmitowanie...',
        synced        = 'Zsynchronizowano z projektorem ✓',
        local_changes = 'Zmiany są lokalne do momentu synchronizacji',
        all_synced    = 'Wszystkie edycje zsynchronizowane.',
        delete_preset = 'Usuń Szablon',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['pl'].range = {
    ['booth_entered'] = "Wszedłeś na Stanowisko #%s! Celuj w tarczę i strzelaj.",
    ['booth_controls'] = "Użyj ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~, aby przesunąć tarczę.",
    ['training_finished'] = "Sesja Zakończona! Wynik: %s | Czas: %s",
    ['menu_header'] = "Strzelnica - Wybór Broni",
    ['menu_desc'] = "Wybierz tę broń do treningu strzeleckiego.",
    ['menu_cancel'] = "Anuluj",
    ['menu_cancel_desc'] = "Zamknij menu",
    ['ui_title'] = "STRZELNICA",
    ['ui_time'] = "CZAS",
    ['ui_score'] = "WYNIK",
    ['weapon_given'] = "Broń wyposażona.",
    ['weapon_removed'] = "Broń zwrócona.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ aby wybrać broń",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ aby otworzyć komputer (Wyzwanie Celności)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ aby wejść na Stanowisko #%s",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ aby rozpocząć Wyzwanie Celności (Stanowisko #3)",
    ['select_weapon_first'] = "Najpierw wybierz broń do Wyzwania Celności!",
    ['equip_weapon_first'] = "Najpierw wyekwipuj swoją broń do Wyzwania Celności!",
    ['booth_occupied'] = "Stanowisko #%s jest obecnie zajęte!",
    ['range_busy_aimlab'] = "Gracze korzystają ze strzelnicy! Wszystkie stanowiska muszą być puste, aby rozpocząć Wyzwanie Celności.",
    ['aimlab_in_progress'] = "Wyzwanie Celności jest obecnie rozgrywane przez %s!",
    ['aimlab_goto_booth'] = "Wyzwanie Celności rozpoczęte! Udaj się na Stanowisko #3 i naciśnij [E].",
    ['aimlab_finished'] = "Wyzwanie Celności ukończone! Trafione cele: %s | Broń: %s",
    ['aimlab_canceled'] = "Wyzwanie Celności anulowane, ponieważ opuściłeś stanowisko!",
    ['target_weapon_menu'] = "Wybierz Broń",
    ['target_laptop'] = "Otwórz Komputer (Wyzwanie Celności)",
    ['target_booth'] = "Wejdź na Stanowisko #%s",
    ['target_aimlab'] = "Rozpocznij Wyzwanie Celności (Stanowisko #3)",
    ['scoreboard_reset_success'] = "Tabela wyników zresetowana pomyślnie!",
    ['no_permission'] = "Nie masz uprawnień do użycia tej komendy!",
    ['no_access'] = "Nie masz uprawnień do korzystania ze strzelnicy."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['pl'].archive = {
    ['blip_label']       = 'Cyfrowe Archiwum',
    ['prompt_label']     = '~INPUT_CONTEXT~ Uzyskaj dostęp do Cyfrowego Archiwum',
    ['target_label']     = 'Uzyskaj dostęp do Cyfrowego Archiwum',
    ['no_access']        = 'Nie masz dostępu do archiwum.',

    ['header_title']     = 'LSPD — Cyfrowe Archiwum',
    ['header_subtitle']  = 'Archiwum Akt Personelu LSPD',
    ['badge_text']       = 'AKTA NIEAKTYWNE',
    ['label_rank']       = 'STOPIEŃ',
    ['label_name']       = 'IMIĘ I NAZWISKO',
    ['label_badge']      = 'NR ODZNAKI',
    ['label_service']    = 'SŁUŻBA',
    ['label_status']     = 'STATUS',
    ['footer_copy']      = '© Los Santos Police Department',
    ['footer_close']     = '[X] Zamknij',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Lat',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

W nocy 14 października Departament Policji Los Santos stracił kogoś więcej niż Sierżanta.
Departament stracił obrońcę, mentora i człowieka, który poświęcił osiemnaście lat swojego życia odznace i ludziom, którzy za nią stoją. Sierżant II Troy Bolo służył w Departamencie Policji Mission Row z niezachwianą lojalnością, odwagą i honorem. Znany w całym departamencie ze swojego spokojnego przywództwa i głębokiego współczucia zarówno dla funkcjonariuszy, jak i cywilów, Bolo zdobył szacunek każdego wydziału, z którym współpracował. Dla młodszych funkcjonariuszy był mentorem. Dla innych Sierżantów był kimś, na kim zawsze mogli polegać. Dla miasta Los Santos był jednym z jego najlepszych strażników.

W wieczór swojej śmierci funkcjonariusze otrzymali zgłoszenia o zbrojnym porwaniu, w którym rodzina była przetrzymywana jako zakładnicy przez gang działający z Little Seoul. Ze względu na niebezpieczny charakter sytuacji początkowo wyznaczono młodszego Sierżanta do dowodzenia akcją. Sierżant Bolo, wierząc, że operacja niesie za sobą niedopuszczalne ryzyko dla młodszego przełożonego, dobrowolnie przejął dowodzenie. Świadkowie i funkcjonariusze na miejscu zdarzenia zeznali później, że Bolo zachował spokój przez całą operację, stawiając bezpieczeństwo zakładników ponad wszystko inne. Dzięki negocjacjom i koordynacji taktycznej rodzina została pomyślnie uratowana bez szwanku.

Zaledwie kilka sekund po zabezpieczeniu zakładników ranny członek gangu, który leżał niezauważony na miejscu zdarzenia, otworzył ogień bez ostrzeżenia. Sierżant Troy Bolo został trafiony podczas ochrony pobliskich funkcjonariuszy i cywilów. Pomimo natychmiastowych wysiłków ratunkowych, Sierżant Bolo zmarł w wyniku odniesionych ran na służbie. Jego ostatnie działania odzwierciedlały człowieka, którym zawsze był — bezinteresownego, nieustraszonego i oddanego ochronie innych, nawet za cenę własnego życia.

Korytarze Departamentu Policji Mission Row wciąż niosą jego pamięć. Jego szafka pozostaje nietknięta. Jego imię nadal wymawiane jest z dumą. A funkcjonariusze, których wyszkolił, nadal służą zainspirowani przykładem, który po sobie zostawił. Sierżant II Troy Bolo pozostawił po sobie departament, który nigdy go nie zapomni.

End of Watch
Sergeant II Troy Bolo
18 Lat Służby
"Miasto śpi bezpieczniej, ponieważ tacy ludzie jak on pełnili wartę."
]]
}

-- =========================================================
-- NEOX MRPD — LOCALE: Türkçe (tr)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['tr'] = Locales['tr'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['tr'].cctv = {
    -- ===== Oyun içi metinler (yardım / bildirim) =====
    help_open     = 'CCTV sistemine erişmek için ~INPUT_CONTEXT~ tuşuna bas.',
    help_exit     = 'Çıkmak için ~INPUT_FRONTEND_PAUSE_ALTERNATE~ tuşuna bas.',
    no_access     = 'Bu sisteme erişim yetkin yok.',
    in_use        = '~r~Bu konsol şu anda başka bir memur tarafından kullanılıyor.',
    target_label  = 'CCTV Sistemine Eriş',
    cam_no_coords = '~r~Kamera koordinatları ayarlanmamış!',
    cmd_setup_no_perm   = '~r~Bu komutu kullanmak için yetkiniz yok.',
    setup_started       = '~g~CCTV Kamera Kurulum Modu Başlatıldı.~w~',
    setup_cancelled     = '~y~CCTV Kamera kurulumu iptal edildi.',
    setup_saved         = '~g~CCTV Kamerası başarıyla eklendi! (ID: %s)',
    setup_deleted       = '~g~CCTV Kamerası silindi. (ID: %s)',
    setup_not_found     = '~r~Belirtilen ID\'de özel kamera bulunamadı.',
    setup_list_header   = '^3--- CCTV Özel Kamera Listesi ---^7',
    setup_prompt_label  = 'Kamera Etiketi (Örn: MRPD CAM 05)',
    setup_prompt_name   = 'Konum İsmi (Örn: Ana Koridor)',
    setup_prompt_district = 'Bölge İsmi (Örn: MRPD / Banks / Downtown)',

    -- ===== UI metinleri (DUI/NUI'ye gönderilir) =====
    ui = {
        -- Pencere / masaüstü
        title_bar      = 'MISSION ROW POLİS DEPARTMANI - CCTV SİSTEMİ',
        icon_disk      = 'Disk',
        icon_recycle   = 'Geri Dönüşüm',
        icon_files     = 'Dosyalar',
        min            = 'Küçült',
        max            = 'Büyüt',
        close          = 'Kapat',
        live           = 'CANLI',
        rec            = 'KAYIT',

        -- Kenar çubuğu
        system_status  = 'Sistem Durumu',
        operational    = 'OPERASYONEL',
        search         = 'Ara',
        bookmarks      = 'Yer İmleri',
        all_cameras    = 'Tüm Kameralar',

        -- Telemetri paneli
        telemetry      = 'İSTASYON TELEMETRİSİ',
        station        = 'İSTASYON:',
        sys_time       = 'SİSTEM SAATİ:',
        operator       = 'OPERATÖR:',
        on_duty        = 'GÖREVDE',
        net_link       = 'AĞ BAĞLANTISI:',
        secured        = 'GÜVENLİ',
        active_feeds   = 'AKTİF YAYINLAR:',
        disk_cap       = 'DİSK DOLULUĞU:',

        -- Ana panel
        camera_network = 'KAMERA AĞI',
        bookmarks_title= 'YER İMLERİ',
        sort           = 'Sırala:',
        sort_default   = 'Varsayılan',
        sort_name      = 'İsim (A-Z)',
        sort_location  = 'Konum',
        search_ph      = 'Kamera ara...',
        no_cameras     = 'Kamera bulunamadı',
        no_in_district = 'Bu bölgede kamera yok',
        no_bookmarks   = 'Yer imine eklenmiş kamera yok',

        -- CCTV HUD (tam ekran kamera)
        disconnect     = '[ BACKSPACE ] BAĞLANTIYI KES',

        -- Telemetri konsol satırları
        log_lines = {
            'Güvenli bağlantı doğrulandı',
            'Uydu bağlantısı kuruldu',
            'Disk kontrolü tamam',
            'Kanal senkronize edildi',
            'Veri paketi yönlendirildi',
            'Yayın sinyali stabil',
            'Önbellek temizlendi',
            'Şifreleme yenilendi',
            'Port dinleniyor...',
            'Kare önbelleği sıfırlandı',
            'Telemetri ping: 12ms',
            'Sinyal seviyesi: normal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['tr'].hygiene = {
    ['shower_prompt']   = '[E] Duş Al',
    ['poop_prompt']     = '[E] Büyük Tuvalet',
    ['pee_prompt']      = '[G] Küçük Tuvalet',
    ['toilet_prompt']   = '[E] Büyük Tuvalet  |  [G] Küçük Tuvalet',

    ['shower_target']   = 'Duş Al',
    ['poop_target']     = 'Büyük Tuvalet',
    ['pee_target']      = 'Küçük Tuvalet',
    ['wash_target']     = 'Elleri Yıka',

    ['shower_start']    = 'Duş alıyorsun...',
    ['shower_done']     = 'Duş tamamlandı!',
    ['poop_start']      = 'Tuvaleti kullanıyorsun...',
    ['poop_done']       = 'Tuvalet tamamlandı!',
    ['pee_start']       = 'Tuvaleti kullanıyorsun...',
    ['pee_done']        = 'Tuvalet tamamlandı!',
    ['wash_start']      = 'Ellerini yıkıyorsun...',
    ['wash_done']       = 'Ellerini yıkadın!',
    ['busy']            = 'Şu an meşgulsün!',
    
    ['shower_exit']     = 'Duştan çıkmak için ~INPUT_VEH_DUCK~ tuşuna basın',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['tr'].killhouse = {
    ['training_started'] = "Kill House eğitimi başladı! Vurabildiğin kadar hedefi vur.",
    ['training_finished'] = "Eğitim tamamlandı! Süren: %s | Skor: %s/%s",
    ['training_canceled'] = "Eğitim iptal edildi! Eğitim alanından çıktın.",
    ['training_failed'] = "Sivili vurdun! Eğitim iptal edildi.",
    ['menu_header'] = "Kill House - Silah Seçimi",
    ['menu_desc'] = "Bu silahı seç ve eğitime başla.",
    ['menu_cancel'] = "İptal",
    ['menu_cancel_desc'] = "Eğitimi başlatma",
    ['ui_title'] = "KILL HOUSE EĞİTİMİ",
    ['ui_time'] = "SÜRE",
    ['ui_targets'] = "HEDEFLER",
    ['ui_footer'] = "SİVİL VURMAK DİREKT BAŞARISIZLIKTIR",
    ['weapon_given'] = "Silah kuşandın.",
    ['weapon_removed'] = "Silah geri alındı.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ Silah Menüsünü Aç",
    ['troll_warning'] = "Eğitim alanından çıktın! Silahına el konuldu.",
    ['operator_inside'] = "Şu an içeride başka bir operatör var!",
    ['target_weapon_menu'] = "Silah Menüsünü Aç",
    ['target_killhouse_start'] = "Kill House Eğitimi Başlat",
    ['scoreboard_reset_success'] = "Scoreboard başarıyla sıfırlandı!",
    ['no_permission'] = "Bu komutu kullanmak için yetkiniz yok!",
    ['no_access'] = "Kill House'u kullanma yetkin yok."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['tr'].projector = {
    -- ===== Oyun içi metinler =====
    help_open    = 'Projeksiyon sistemine erişmek için ~INPUT_CONTEXT~ tuşuna bas.',
    target_label = 'Sunum Konsolunu Aç',
    no_access    = 'Bu konsola erişim yetkin yok.',
    in_use       = '~r~Konsol şu anda başka bir kullanıcı tarafından kullanılıyor.',

    -- ===== UI metinleri (DUI/NUI'ye gönderilir) =====
    ui = {
        -- Durum / gösterim
        ready        = 'HAZIR',
        live         = 'CANLI',
        live_edit    = 'CANLI DÜZENLEME',
        no_signal    = 'SİNYAL YOK.',
        input_video  = 'GİRİŞ: VİDEO',

        -- Uygulama menüsü (dekoratif)
        menu_file   = 'Dosya',    menu_edit   = 'Düzen',   menu_image  = 'Görüntü',
        menu_layer  = 'Katman',   menu_type   = 'Yazı',    menu_select = 'Seç',
        menu_filter = 'Filtre',   menu_view   = 'Görünüm', menu_window = 'Pencere',
        menu_help   = 'Yardım',

        -- URL / medya görünümü
        no_content     = 'GÖMÜLÜ İÇERİK YOK',
        no_content_sub = 'Harici bir görsel, video veya yayın URL\'i yükle',
        load           = 'YÜKLE',
        remove         = 'KALDIR',
        url_hint       = 'Desteklenen uzantılar: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Paneller
        canvas_bg     = 'TUVAL ARKA PLANI',
        bg_dark       = 'Koyu',
        bg_white      = 'Beyaz',
        bg_grid       = 'Izgara',
        bg_dots       = 'Nokta',
        board_presets = 'PANO ŞABLONLARI',
        save          = 'KAYDET',
        preset_ph     = 'Şablon Adı...',
        no_presets    = 'Kayıtlı şablon yok.',
        character     = 'KARAKTER',
        font_family   = 'Yazı Tipi',
        font_size     = 'Yazı Boyutu',
        styles        = 'Stiller',
        swatches      = 'Renkler',
        actions       = 'İŞLEMLER',
        undo          = 'Geri Al',
        delete_sel    = 'Seçimi Sil',
        clear_canvas  = 'Tuvali Temizle',
        drop_signal   = 'SİNYALİ KES',
        transmit      = 'CANLI AKTAR',

        -- Görsel ekleme modali
        place_image = 'GÖMÜLÜ GÖRSEL YERLEŞTİR',
        place_hint  = 'Doğrudan bağlantılar: .png .jpg .jpeg .webp .gif (yalnızca HTTPS)',
        cancel      = 'İptal',
        place       = 'Yerleştir',

        -- Standalone panel
        media_link      = 'PROJEKSİYON MEDYA BAĞLANTISI',
        url_cast        = 'URL Yayını',
        supported_short = 'Desteklenen: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'EKRANDAN ÇEK',
        presets         = 'Şablonlar',
        save_preset     = 'ŞABLONU KAYDET',
        sa_preset_ph    = 'Mevcut URL\'i kaydetmek için şablon adı gir...',

        -- Masaüstü ikonları
        icon_disk    = 'Disk',
        icon_recycle = 'Geri Dönüşüm',
        icon_drafts  = 'Taslaklar',

        -- Araç ipuçları
        tool_move   = 'Taşıma Aracı (V)',
        tool_brush  = 'Fırça Aracı (B)',
        tool_eraser = 'Silgi Aracı (E)',
        tool_type   = 'Yatay Yazı Aracı (T)',
        tool_place  = 'Gömülü Görsel Yerleştir',
        fg_color    = 'Ön Plan Rengi',
        bg_color    = 'Arka Plan Rengi',
        bold        = 'Kalın',
        italic      = 'İtalik',

        -- Dinamik durumlar (JS)
        invalid_url   = 'Geçersiz URL — izin verilen: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Medya yerel olarak yüklendi. Yayınlamak için CANLI AKTAR\'a bas.',
        transmitting  = 'Aktarılıyor...',
        synced        = 'Projeksiyona senkronize edildi ✓',
        local_changes = 'Değişiklikler senkronize edilene kadar yereldir',
        all_synced    = 'Tüm düzenlemeler senkronize.',
        delete_preset = 'Şablonu Sil',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['tr'].range = {
    ['booth_entered'] = "Kabin #%s girdiniz! Hedefe nişan alın ve ateş edin.",
    ['booth_controls'] = "Hedefi hareket ettirmek için ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ kullanın.",
    ['training_finished'] = "Atış tamamlandı! Skor: %s | Süre: %s",
    ['menu_header'] = "Atış Poligonu - Silah Seçimi",
    ['menu_desc'] = "Poligon atışı için bu silahı seçin.",
    ['menu_cancel'] = "İptal",
    ['menu_cancel_desc'] = "Menüyü kapat",
    ['ui_title'] = "ATIŞ POLİGONU",
    ['ui_time'] = "SÜRE",
    ['ui_score'] = "SKOR",
    ['weapon_given'] = "Silah kuşandın.",
    ['weapon_removed'] = "Silah geri alındı.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ Silah Menüsünü Aç",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ Bilgisayarı Aç (Aim Challenge)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ Kabin #%s Gir",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ Aim Challenge Başlat (Kabin #3)",
    ['select_weapon_first'] = "Aim Challenge başlatmak için lütfen önce bir silah seçin!",
    ['equip_weapon_first'] = "Aim Challenge başlatmak için lütfen önce silahınızı elinize alın!",
    ['booth_occupied'] = "Kabin #%s şu an dolu!",
    ['range_busy_aimlab'] = "Poligonda aktif oyuncular var! Aim Challenge için tüm kabinlerin boş olması gerekir.",
    ['aimlab_in_progress'] = "Şu an %s tarafından aktif bir Aim Challenge yürütülüyor!",
    ['aimlab_goto_booth'] = "Aim Challenge Başlatıldı! Kabin #3'e ilerleyin ve [E] basın.",
    ['aimlab_finished'] = "Aim Challenge Tamamlandı! Vurulan Hedef: %s | Silah: %s",
    ['aimlab_canceled'] = "Kabinden uzaklaştığınız için Aim Challenge iptal edildi!",
    ['target_weapon_menu'] = "Silah Menüsünü Aç",
    ['target_laptop'] = "Bilgisayarı Aç (Aim Challenge)",
    ['target_booth'] = "Kabin #%s Gir",
    ['target_aimlab'] = "Aim Challenge Başlat (Kabin #3)",
    ['scoreboard_reset_success'] = "Scoreboard başarıyla sıfırlandı!",
    ['no_permission'] = "Bu komutu kullanmak için yetkiniz yok!",
    ['no_access'] = "Atış poligonunu kullanma yetkin yok."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['tr'].archive = {
    ['blip_label']       = 'Dijital Arşiv',
    ['prompt_label']     = '~INPUT_CONTEXT~ Dijital Arşive Eriş',
    ['target_label']     = 'Dijital Arşive Eriş',
    ['no_access']        = 'Arşive erişim yetkiniz bulunmuyor.',

    ['header_title']     = 'LSPD — Dijital Arşiv Sistemi',
    ['header_subtitle']  = 'LSPD Personel Kayıt Arşivi — Hizmet Dosyası',
    ['badge_text']       = 'DOSYA AKTİF DEĞİL',
    ['label_rank']       = 'RÜTBE',
    ['label_name']       = 'AD SOYAD',
    ['label_badge']      = 'ROZET NO',
    ['label_service']    = 'HİZMET',
    ['label_status']     = 'DURUM',
    ['footer_copy']      = '© Los Santos Polis Departmanı',
    ['footer_close']     = '[X] Kapat',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Yıl',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

14 Ekim gecesi, Los Santos Polis Departmanı yalnızca bir çavuşunu kaybetmedi.Departman; bir koruyucuyu, bir mentoru ve hayatının on sekiz yılını rozetine ve halkına adamış bir adamı kaybetti. Sergeant II Troy Bolo, Mission Row Polis Departmanı’nda sarsılmaz bir sadakat, cesaret ve onurla görev yaptı. Sakin liderliği ve hem memurlara hem de sivillere duyduğu derin sorumlulukla tanınan Bolo, birlikte çalıştığı her birimin saygısını kazandı.Genç memurlar için bir öğretmen, diğer çavuşlar için güvenilir bir dayanak, Los Santos halkı için ise şehrin en değerli koruyucularından biriydi.

Hayatını kaybettiği akşam, Little Seoul’da faaliyet gösteren bir çetenin bir aileyi kaçırarak rehin tuttuğuna dair ihbar alındı. Operasyonu normalde daha genç bir çavuş yönetecekti. Ancak Sergeant Bolo, durumun tehlikeli olabileceğini düşünerek çavuşunu bu riske atmak istemedi ve operasyonun komutasını gönüllü olarak devraldı. Olay yerindeki tanıklar ve memurlar, Bolo’nun operasyon boyunca soğukkanlılığını koruduğunu ve her şeyden önce rehinelerin güvenliğini ön planda tuttuğunu belirtti. Yürütülen görüşmeler ve taktiksel koordinasyon sonucunda aile zarar görmeden kurtarıldı.

Rehineler güvenli alana alındıktan kısa bir süre sonra, yerde yaralı halde yatan ve fark edilmeyen bir çete üyesi aniden ateş açtı. Sergeant Troy Bolo, çevredeki memurları ve sivilleri koruduğu sırada vuruldu. Olay yerinde yapılan tüm acil müdahalelere rağmen Sergeant Bolo, görev başında aldığı yaralar sonucunda hayatını kaybetti. Son anlarında yaptığı fedakârlık, onun her zaman olduğu adamı yansıtıyordu: özverili, korkusuz ve başkalarını korumaya kendi hayatı pahasına bağlı bir polis.

Mission Row Polis Departmanı’nın koridorları hâlâ onun anısını taşımaktadır. Dolabı olduğu gibi korunmaktadır. Adı gururla anılmaya devam etmektedir. Ve yetiştirdiği memurlar, onun bıraktığı örnekten ilham alarak görev yapmayı sürdürmektedir.

Sergeant II Troy Bolo, kendisini asla unutmayacak bir departmanın kalbinde yaşamaya devam etmektedir.

End of Watch
Sergeant II Troy Bolo
18 Yıllık Hizmet
"Şehir daha güvenli uyuyor, çünkü onun gibi adamlar nöbetteydi."
]]
}

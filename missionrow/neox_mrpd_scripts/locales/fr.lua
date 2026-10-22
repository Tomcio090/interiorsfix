--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — LOCALE: Français (fr)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['fr'] = Locales['fr'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['fr'].cctv = {
    -- ===== Textes en jeu (invitations / notifications) =====
    help_open     = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au système CCTV.',
    help_exit     = 'Appuyez sur ~INPUT_FRONTEND_PAUSE_ALTERNATE~ pour quitter.',
    no_access     = 'Vous n\'avez pas accès à ce système.',
    in_use        = '~r~Cette console est actuellement utilisée par un autre agent.',
    target_label  = 'Accéder au Système CCTV',
    cam_no_coords = '~r~Les coordonnées de la caméra ne sont pas définies !',
    cmd_setup_no_perm   = '~r~Vous n\'avez pas la permission d\'utiliser cette commande.',
    setup_started       = '~g~Mode de Configuration des Caméras CCTV Démarré.~w~',
    setup_cancelled     = '~y~Configuration de la caméra CCTV annulée.',
    setup_saved         = '~g~Caméra CCTV créée avec succès ! (ID : %s)',
    setup_deleted       = '~g~Caméra CCTV supprimée. (ID : %s)',
    setup_not_found     = '~r~Caméra personnalisée avec cet ID introuvable.',
    setup_list_header   = '^3--- Liste des Caméras Personnalisées CCTV ---^7',
    setup_prompt_label  = 'Étiquette de la caméra (ex. MRPD CAM 05)',
    setup_prompt_name   = 'Nom de l\'emplacement (ex. Hall Principal)',
    setup_prompt_district = 'District (ex. MRPD / Banques / Centre-ville)',

    -- ===== Textes de l\'interface (envoyés au DUI/NUI) =====
    ui = {
        -- Fenêtre / bureau
        title_bar      = 'DÉPARTEMENT DE POLICE DE MISSION ROW - SYSTÈME CCTV',
        icon_disk      = 'Disque',
        icon_recycle   = 'Corbeille',
        icon_files     = 'Fichiers Principaux',
        min            = 'Réduire',
        max            = 'Agrandir',
        close          = 'Fermer',
        live           = 'DIRECT',
        rec            = 'ENR',

        -- Barre latérale
        system_status  = 'État du Système',
        operational    = 'OPÉRATIONNEL',
        search         = 'Rechercher',
        bookmarks      = 'Favoris',
        all_cameras    = 'Toutes les Caméras',

        -- Panneau de télémétrie
        telemetry      = 'TÉLÉMÉTRIE DU POSTE',
        station        = 'POSTE :',
        sys_time       = 'HEURE SYS :',
        operator       = 'OPÉRATEUR :',
        on_duty        = 'EN SERVICE',
        net_link       = 'LIAISON RÉSEAU :',
        secured        = 'SÉCURISÉ',
        active_feeds   = 'FLUX ACTIFS :',
        disk_cap       = 'CAPACITÉ DISQUE :',

        -- Panneau principal
        camera_network = 'RÉSEAU DE CAMÉRAS',
        bookmarks_title= 'FAVORIS',
        sort           = 'Trier :',
        sort_default   = 'Par Défaut',
        sort_name      = 'Nom (A-Z)',
        sort_location  = 'Emplacement',
        search_ph      = 'Rechercher des caméras...',
        no_cameras     = 'Aucune caméra trouvée',
        no_in_district = 'Aucune caméra dans ce secteur',
        no_bookmarks   = 'Aucune caméra en favoris',

        -- CCTV HUD (caméra plein écran)
        disconnect     = '[ RETOUR ] DÉCONNECTER',

        -- Lignes de journal de télémétrie
        log_lines = {
            'Liaison sécurisée vérifiée',
            'Liaison montante établie',
            'Vérification du disque OK',
            'Canal synchronisé',
            'Paquet de données routé',
            'Signal de flux stable',
            'Mémoire tampon vidée',
            'Chiffrement renouvelé',
            'Port en écoute...',
            'Cache d\'images réinitialisé',
            'Ping télémétrie : 12ms',
            'Niveau de signal : nominal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['fr'].hygiene = {
    ['shower_prompt']   = '[E] Prendre une douche',
    ['poop_prompt']     = '[E] Faire caca',
    ['pee_prompt']      = '[G] Faire pipi',
    ['toilet_prompt']   = '[E] Faire caca  |  [G] Faire pipi',

    ['shower_target']   = 'Prendre une douche',
    ['poop_target']     = 'Faire caca',
    ['pee_target']      = 'Faire pipi',
    ['wash_target']     = 'Se laver les mains',

    ['shower_start']    = 'Vous prenez une douche...',
    ['shower_done']     = 'Douche terminée !',
    ['poop_start']      = 'Vous êtes aux toilettes...',
    ['poop_done']       = 'Toilettes terminées !',
    ['pee_start']       = 'Vous êtes aux toilettes...',
    ['pee_done']        = 'Toilettes terminées !',
    ['wash_start']      = 'Vous vous lavez les mains...',
    ['wash_done']       = 'Vous avez lavé vos mains !',
    ['busy']            = 'Vous êtes occupé pour le moment !',
    
    ['shower_exit']     = 'Appuyez sur ~INPUT_VEH_DUCK~ pour sortir de la douche',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['fr'].killhouse = {
    ['training_started'] = "Entraînement Kill House commencé ! Touchez autant de cibles que possible.",
    ['training_finished'] = "Entraînement terminé ! Temps : %s | Score : %s/%s",
    ['training_canceled'] = "Entraînement annulé ! Vous avez quitté la zone d'entraînement.",
    ['training_failed'] = "Civil touché ! Entraînement échoué.",
    ['menu_header'] = "Kill House - Sélection de l'Arme",
    ['menu_desc'] = "Sélectionnez cette arme et commencez l'entraînement.",
    ['menu_cancel'] = "Annuler",
    ['menu_cancel_desc'] = "Annuler l'entraînement",
    ['ui_title'] = "ENTRAÎNEMENT KILL HOUSE",
    ['ui_time'] = "TEMPS",
    ['ui_targets'] = "CIBLES",
    ['ui_footer'] = "TIRER SUR DES CIVILS ENTRAÎNE UN ÉCHEC",
    ['weapon_given'] = "Arme équipée.",
    ['weapon_removed'] = "Arme restituée.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ pour sélectionner une arme",
    ['troll_warning'] = "Vous avez quitté la zone d'entraînement ! Arme confisquée.",
    ['operator_inside'] = "Un autre agent est actuellement à l'intérieur !",
    ['target_weapon_menu'] = "Sélectionner une Arme",
    ['target_killhouse_start'] = "Démarrer l'Entraînement Kill House",
    ['scoreboard_reset_success'] = "Tableau des scores réinitialisé avec succès !",
    ['no_permission'] = "Vous n'avez pas la permission d'utiliser cette commande !",
    ['no_access'] = "Vous n'êtes pas autorisé à utiliser le Kill House."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['fr'].projector = {
    -- ===== Textes en jeu =====
    help_open    = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au système de projection.',
    target_label = 'Ouvrir la Console de Présentation',
    no_access    = 'Vous n\'avez pas accès à cette console.',
    in_use       = '~r~Un autre utilisateur utilise actuellement la console.',

    -- ===== Textes de l\'interface (envoyés au DUI/NUI) =====
    ui = {
        -- Statut / affichage
        ready        = 'PRÊT',
        live         = 'EN DIRECT',
        live_edit    = 'ÉDITION EN DIRECT',
        no_signal    = 'PAS DE SIGNAL.',
        input_video  = 'ENTRÉE : VIDÉO',

        -- Menu application (décoratif)
        menu_file   = 'Fichier',   menu_edit   = 'Édition',   menu_image  = 'Image',
        menu_layer  = 'Calque',    menu_type   = 'Texte',     menu_select = 'Sélection',
        menu_filter = 'Filtre',    menu_view   = 'Affichage', menu_window = 'Fenêtre',
        menu_help   = 'Aide',

        -- Vue URL / médias
        no_content     = 'AUCUN CONTENU INTÉGRÉ',
        no_content_sub = 'Chargez une image externe, une vidéo ou une URL de flux',
        load           = 'CHARGER',
        remove         = 'SUPPRIMER',
        url_hint       = 'Extensions supportées : .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Panneaux
        canvas_bg     = 'FOND DU CANEVAS',
        bg_dark       = 'Sombre',
        bg_white      = 'Blanc',
        bg_grid       = 'Grille',
        bg_dots       = 'Points',
        board_presets = 'PRÉRÉGLAGES DE TABLEAU',
        save          = 'ENREGISTRER',
        preset_ph     = 'Nom du préréglage...',
        no_presets    = 'Aucun préréglage enregistré.',
        character     = 'CARACTÈRE',
        font_family   = 'Police',
        font_size     = 'Taille de Police',
        styles        = 'Styles',
        swatches      = 'Nuancier',
        actions       = 'ACTIONS',
        undo          = 'Annuler Action',
        delete_sel    = 'Supprimer Sélection',
        clear_canvas  = 'Effacer Canevas',
        drop_signal   = 'COUPER EN PAS DE SIGNAL',
        transmit      = 'DIFFUSER EN DIRECT',

        -- Modale d\'image
        place_image = 'PLACER UNE IMAGE INTÉGRÉE',
        place_hint  = 'Liens directs : .png .jpg .jpeg .webp .gif (HTTPS uniquement)',
        cancel      = 'Annuler',
        place       = 'Placer',

        -- Panneau autonome
        media_link      = 'LIEN MÉDIA PROJECTEUR',
        url_cast        = 'Diffuser URL',
        supported_short = 'Supporté : .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'RÉCUPÉRER DE L\'ÉCRAN',
        presets         = 'Préréglages',
        save_preset     = 'ENREGISTRER PRÉRÉGLAGE',
        sa_preset_ph    = 'Entrez un nom pour enregistrer l\'URL actuelle...',

        -- Icônes du bureau
        icon_disk    = 'Disque',
        icon_recycle = 'Corbeille',
        icon_drafts  = 'Brouillons',

        -- Info-bulles des outils
        tool_move   = 'Outil Déplacement (V)',
        tool_brush  = 'Outil Pinceau (B)',
        tool_eraser = 'Outil Gomme (E)',
        tool_type   = 'Outil Texte Horizontal (T)',
        tool_place  = 'Placer Image Intégrée',
        fg_color    = 'Couleur de Premier Plan',
        bg_color    = 'Couleur d\'Arrière-Plan',
        bold        = 'Gras',
        italic      = 'Italique',

        -- Statuts dynamiques (JS)
        invalid_url   = 'URL invalide — autorisés : .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Média chargé localement. Appuyez sur DIFFUSER EN DIRECT.',
        transmitting  = 'Transmission en cours...',
        synced        = 'Synchronisé avec le projecteur ✓',
        local_changes = 'Modifications locales jusqu\'à la synchronisation',
        all_synced    = 'Toutes les modifications sont synchronisées.',
        delete_preset = 'Supprimer Préréglage',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['fr'].range = {
    ['booth_entered'] = "Entré dans le Stand #%s ! Visez la cible et tirez.",
    ['booth_controls'] = "Utilisez ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ pour déplacer la cible.",
    ['training_finished'] = "Session terminée ! Score : %s | Temps : %s",
    ['menu_header'] = "Stand de Tir - Sélection de l'Arme",
    ['menu_desc'] = "Sélectionnez cette arme pour l'entraînement au tir.",
    ['menu_cancel'] = "Annuler",
    ['menu_cancel_desc'] = "Fermer le menu",
    ['ui_title'] = "STAND DE TIR",
    ['ui_time'] = "TEMPS",
    ['ui_score'] = "SCORE",
    ['weapon_given'] = "Arme équipée.",
    ['weapon_removed'] = "Arme restituée.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ pour sélectionner une arme",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ pour ouvrir l'ordinateur (Défi de Visée)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ pour entrer dans le Stand #%s",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ pour lancer le Défi de Visée (Stand #3)",
    ['select_weapon_first'] = "Veuillez d'abord sélectionner une arme pour le Défi de Visée !",
    ['equip_weapon_first'] = "Veuillez d'abord équiper votre arme pour le Défi de Visée !",
    ['booth_occupied'] = "Le Stand #%s est actuellement occupé !",
    ['range_busy_aimlab'] = "Des joueurs utilisent actuellement le stand ! Tous les stands doivent être vides pour lancer le Défi de Visée.",
    ['aimlab_in_progress'] = "Un Défi de Visée est actuellement en cours par %s !",
    ['aimlab_goto_booth'] = "Défi de Visée initié ! Rendez-vous au Stand #3 et appuyez sur [E].",
    ['aimlab_finished'] = "Défi de Visée terminé ! Cibles touchées : %s | Arme : %s",
    ['aimlab_canceled'] = "Défi de Visée annulé car vous avez quitté le stand !",
    ['target_weapon_menu'] = "Sélectionner une Arme",
    ['target_laptop'] = "Ouvrir l'Ordinateur (Défi de Visée)",
    ['target_booth'] = "Entrer dans le Stand #%s",
    ['target_aimlab'] = "Lancer le Défi de Visée (Stand #3)",
    ['scoreboard_reset_success'] = "Tableau des scores réinitialisé avec succès !",
    ['no_permission'] = "Vous n'avez pas la permission d'utiliser cette commande !",
    ['no_access'] = "Vous n'êtes pas autorisé à utiliser le stand de tir."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['fr'].archive = {
    ['blip_label']       = 'Archive Numérique',
    ['prompt_label']     = '~INPUT_CONTEXT~ Accéder à l\'Archive Numérique',
    ['target_label']     = 'Accéder à l\'Archive Numérique',
    ['no_access']        = 'Vous n\'avez pas accès aux archives.',

    ['header_title']     = 'LSPD — Archive Numérique',
    ['header_subtitle']  = 'Archive des Dossiers du Personnel du LSPD',
    ['badge_text']       = 'DOSSIER INACTIF',
    ['label_rank']       = 'GRADE',
    ['label_name']       = 'NOM COMPLET',
    ['label_badge']      = 'Nº DE MATRICULE',
    ['label_service']    = 'SERVICE',
    ['label_status']     = 'STATUT',
    ['footer_copy']      = '© Département de Police de Los Santos',
    ['footer_close']     = '[X] Fermer',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Ans',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

Dans la nuit du 14 octobre, le Département de Police de Los Santos a perdu bien plus qu'un Sergent.
Le département a perdu un protecteur, un mentor et un homme qui a consacré dix-huit ans de sa vie à l'insigne et aux personnes derrière lui. Le Sergent II Troy Bolo a servi le Département de Police de Mission Row avec une loyauté, un courage et un honneur inébranlables. Connu dans tout le département pour son leadership calme et sa profonde compassion pour les officiers et les civils, Bolo a gagné le respect de toutes les divisions avec lesquelles il a travaillé. Pour les jeunes officiers, il était un mentor. Pour ses collègues Sergents, il était quelqu'un sur qui ils pouvaient toujours compter. Pour la ville de Los Santos, il était l'un de ses meilleurs gardiens.

Le soir de son décès, les officiers ont reçu des rapports faisant état d'un enlèvement à main armée impliquant une famille retenue en otage par un gang opérant depuis Little Seoul. En raison de la nature dangereuse de la situation, un Sergent plus jeune avait initialement été désigné pour commander l'intervention. Le Sergent Bolo, estimant que l'opération comportait un risque inacceptable pour le jeune superviseur, a volontairement pris le commandement lui-même. Des témoins et des officiers sur les lieux ont par la suite déclaré que Bolo était resté calme tout au long de l'opération, donnant la priorité à la sécurité des otages avant tout. Grâce à la négociation et à la coordination tactique, la famille a été secourue avec succès et sans encombre.

Quelques secondes après que les otages eurent été mis en sécurité, un membre du gang blessé qui était passé inaperçu sur les lieux a ouvert le feu sans avertissement. Le Sergent Troy Bolo a été touché alors qu'il protégeait les officiers et les civils à proximité. Malgré les efforts d'intervention médicale immédiate, le Sergent Bolo a succombé à ses blessures dans l'exercice de ses fonctions. Ses dernières actions reflétaient l'homme qu'il avait toujours été — altruiste, intrépide et dévoué à la protection des autres, même au péril de sa propre vie.

Les couloirs du Département de Police de Mission Row portent encore sa mémoire. Son casier reste intact. Son nom continue d'être prononcé avec fierté. Et les officiers qu'il a formés continuent de servir inspirés par l'exemple qu'il a laissé derrière lui. Le Sergent II Troy Bolo laisse dans le deuil un département qui ne l'oubliera jamais.

End of Watch
Sergeant II Troy Bolo
18 Années de Service
"La ville dort plus en sécurité parce que des hommes comme lui montaient la garde."
]]
}

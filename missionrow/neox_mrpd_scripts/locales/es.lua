--[[
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
]]

-- =========================================================
-- NEOX MRPD — LOCALE: Español (es)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['es'] = Locales['es'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['es'].cctv = {
    -- ===== Textos en el juego (avisos de ayuda / notificaciones) =====
    help_open     = 'Presiona ~INPUT_CONTEXT~ para acceder al sistema CCTV.',
    help_exit     = 'Presiona ~INPUT_FRONTEND_PAUSE_ALTERNATE~ para salir.',
    no_access     = 'No tienes acceso a este sistema.',
    in_use        = '~r~Esta consola está siendo utilizada por otro oficial.',
    target_label  = 'Acceder al Sistema CCTV',
    cam_no_coords = '~r~¡Las coordenadas de la cámara no están configuradas!',
    cmd_setup_no_perm   = '~r~No tienes permiso para usar este comando.',
    setup_started       = '~g~Modo de Configuración de Cámara CCTV Iniciado.~w~',
    setup_cancelled     = '~y~Configuración de cámara CCTV cancelada.',
    setup_saved         = '~g~¡Cámara CCTV creada con éxito! (ID: %s)',
    setup_deleted       = '~g~Cámara CCTV eliminada. (ID: %s)',
    setup_not_found     = '~r~No se encontró la cámara personalizada con este ID.',
    setup_list_header   = '^3--- Lista de Cámaras Personalizadas de CCTV ---^7',
    setup_prompt_label  = 'Etiqueta de la Cámara (ej. MRPD CAM 05)',
    setup_prompt_name   = 'Nombre de la Ubicación (ej. Pasillo Principal)',
    setup_prompt_district = 'Distrito (ej. MRPD / Bancos / Centro)',

    -- ===== Textos de interfaz (enviados a DUI/NUI) =====
    ui = {
        -- Ventana / escritorio
        title_bar      = 'DEPARTAMENTO DE POLICÍA DE MISSION ROW - SISTEMA CCTV',
        icon_disk      = 'Disco',
        icon_recycle   = 'Papelera',
        icon_files     = 'Archivos Principales',
        min            = 'Minimizar',
        max            = 'Maximizar',
        close          = 'Cerrar',
        live           = 'EN VIVO',
        rec            = 'GRAB',

        -- Barra lateral
        system_status  = 'Estado del Sistema',
        operational    = 'OPERATIVO',
        search         = 'Buscar',
        bookmarks      = 'Marcadores',
        all_cameras    = 'Todas las Cámaras',

        -- Panel de telemetría
        telemetry      = 'TELEMETRÍA DE LA ESTACIÓN',
        station        = 'ESTACIÓN:',
        sys_time       = 'HORA SIS:',
        operator       = 'OPERADOR:',
        on_duty        = 'EN SERVICIO',
        net_link       = 'ENLACE DE RED:',
        secured        = 'SEGURO',
        active_feeds   = 'TRANSMISIONES ACTIVAS:',
        disk_cap       = 'CAPACIDAD DISCO:',

        -- Panel principal
        camera_network = 'RED DE CÁMARAS',
        bookmarks_title= 'MARCADORES',
        sort           = 'Ordenar:',
        sort_default   = 'Por Defecto',
        sort_name      = 'Nombre (A-Z)',
        sort_location  = 'Ubicación',
        search_ph      = 'Buscar cámaras...',
        no_cameras     = 'No se encontraron cámaras',
        no_in_district = 'No hay cámaras en este distrito',
        no_bookmarks   = 'No hay cámaras en marcadores',

        -- CCTV HUD (cámara en pantalla completa)
        disconnect     = '[ RETROCESO ] DESCONECTAR',

        -- Líneas de registro de telemetría
        log_lines = {
            'Enlace seguro verificado',
            'Conexión ascendente establecida',
            'Comprobación de disco correcta',
            'Canal sincronizado',
            'Paquete de datos enrutado',
            'Señal de transmisión correcta',
            'Búfer borrado',
            'Cifrado renovado',
            'Puerto escuchando...',
            'Caché de fotogramas restablecida',
            'Ping de telemetría: 12ms',
            'Nivel de señal: nominal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['es'].hygiene = {
    ['shower_prompt']   = '[E] Tomar una ducha',
    ['poop_prompt']     = '[E] Hacer caca',
    ['pee_prompt']      = '[G] Hacer pis',
    ['toilet_prompt']   = '[E] Hacer caca  |  [G] Hacer pis',

    ['shower_target']   = 'Tomar una ducha',
    ['poop_target']     = 'Hacer caca',
    ['pee_target']      = 'Hacer pis',
    ['wash_target']     = 'Lavarse las manos',

    ['shower_start']    = 'Te estás dando una ducha...',
    ['shower_done']     = '¡Ducha completada!',
    ['poop_start']      = 'Estás usando el baño...',
    ['poop_done']       = '¡Baño completado!',
    ['pee_start']       = 'Estás usando el baño...',
    ['pee_done']        = '¡Baño completado!',
    ['wash_start']      = 'Te estás lavando las manos...',
    ['wash_done']       = '¡Te has lavado las manos!',
    ['busy']            = '¡Estás ocupado en este momento!',
    
    ['shower_exit']     = 'Presiona ~INPUT_VEH_DUCK~ para salir de la ducha',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['es'].killhouse = {
    ['training_started'] = "¡Entrenamiento Kill House iniciado! Acierta a tantos objetivos como sea posible.",
    ['training_finished'] = "¡Entrenamiento completado! Tiempo: %s | Puntuación: %s/%s",
    ['training_canceled'] = "¡Entrenamiento cancelado! Saliste del área de entrenamiento.",
    ['training_failed'] = "¡Civil alcanzado! Entrenamiento fallido.",
    ['menu_header'] = "Kill House - Selección de Arma",
    ['menu_desc'] = "Selecciona esta arma y comienza el entrenamiento.",
    ['menu_cancel'] = "Cancelar",
    ['menu_cancel_desc'] = "Cancelar entrenamiento",
    ['ui_title'] = "ENTRENAMIENTO KILL HOUSE",
    ['ui_time'] = "TIEMPO",
    ['ui_targets'] = "OBJETIVOS",
    ['ui_footer'] = "DISPARAR A CIVILES RESULTA EN FALLO",
    ['weapon_given'] = "Arma equipada.",
    ['weapon_removed'] = "Arma devuelta.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ para seleccionar arma",
    ['troll_warning'] = "¡Saliste del área de entrenamiento! Arma confiscada.",
    ['operator_inside'] = "¡Otro operador está dentro actualmente!",
    ['target_weapon_menu'] = "Seleccionar Arma",
    ['target_killhouse_start'] = "Iniciar Entrenamiento Kill House",
    ['scoreboard_reset_success'] = "¡Tabla de puntuaciones restablecida con éxito!",
    ['no_permission'] = "¡No tienes permiso para usar este comando!",
    ['no_access'] = "No tienes autorización para usar el Kill House."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['es'].projector = {
    -- ===== Textos en el juego =====
    help_open    = 'Presiona ~INPUT_CONTEXT~ para acceder al sistema de proyector.',
    target_label = 'Abrir Consola de Presentación',
    no_access    = 'No tienes acceso a esta consola.',
    in_use       = '~r~Otro usuario está usando la consola actualmente.',

    -- ===== Textos de interfaz (enviados a DUI/NUI) =====
    ui = {
        -- Estado / visualización
        ready        = 'LISTO',
        live         = 'EN VIVO',
        live_edit    = 'EDICIÓN EN VIVO',
        no_signal    = 'SIN SEÑAL.',
        input_video  = 'ENTRADA: VÍDEO',

        -- Menú de la app (decorativo)
        menu_file   = 'Archivo',   menu_edit   = 'Editar',    menu_image  = 'Imagen',
        menu_layer  = 'Capa',      menu_type   = 'Texto',     menu_select = 'Seleccionar',
        menu_filter = 'Filtro',    menu_view   = 'Ver',       menu_window = 'Ventana',
        menu_help   = 'Ayuda',

        -- Vista de URL / medios
        no_content     = 'SIN CONTENIDO INCRUSTADO',
        no_content_sub = 'Carga una imagen externa, vídeo o URL de transmisión',
        load           = 'CARGAR',
        remove         = 'ELIMINAR',
        url_hint       = 'Extensiones compatibles: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Paneles
        canvas_bg     = 'FONDO DEL LIENZO',
        bg_dark       = 'Oscuro',
        bg_white      = 'Blanco',
        bg_grid       = 'Cuadrícula',
        bg_dots       = 'Puntos',
        board_presets = 'PREAJUSTES DE PIZARRA',
        save          = 'GUARDAR',
        preset_ph     = 'Nombre del Preajuste...',
        no_presets    = 'No hay preajustes guardados.',
        character     = 'CARÁCTER',
        font_family   = 'Fuente',
        font_size     = 'Tamaño de Fuente',
        styles        = 'Estilos',
        swatches      = 'Muestras',
        actions       = 'ACCIONES',
        undo          = 'Deshacer Acción',
        delete_sel    = 'Eliminar Selección',
        clear_canvas  = 'Limpiar Lienzo',
        drop_signal   = 'CORTAR A SIN SEÑAL',
        transmit      = 'TRANSMITIR EN VIVO',

        -- Modal de imagen
        place_image = 'COLOCAR IMAGEN INCRUSTADA',
        place_hint  = 'Enlaces directos: .png .jpg .jpeg .webp .gif (solo HTTPS)',
        cancel      = 'Cancelar',
        place       = 'Colocar',

        -- Panel independiente
        media_link      = 'ENLACE MULTIMEDIA DEL PROYECTOR',
        url_cast        = 'Transmitir URL',
        supported_short = 'Compatible: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'EXTRAER DE PANTALLA',
        presets         = 'Preajustes',
        save_preset     = 'GUARDAR PREAJUSTE',
        sa_preset_ph    = 'Introduce nombre para guardar la URL actual...',

        -- Iconos de escritorio
        icon_disk    = 'Disco',
        icon_recycle = 'Papelera',
        icon_drafts  = 'Borradores',

        -- Descripciones de herramientas
        tool_move   = 'Herramienta Mover (V)',
        tool_brush  = 'Herramienta Pincel (B)',
        tool_eraser = 'Herramienta Borrador (E)',
        tool_type   = 'Herramienta Texto Horizontal (T)',
        tool_place  = 'Colocar Imagen Incrustada',
        fg_color    = 'Color Frontal',
        bg_color    = 'Color de Fondo',
        bold        = 'Negrita',
        italic      = 'Cursiva',

        -- Estados dinámicos (JS)
        invalid_url   = 'URL no válida — permitido: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Contenido cargado localmente. Presiona TRANSMITIR EN VIVO.',
        transmitting  = 'Transmitiendo...',
        synced        = 'Sincronizado con proyector ✓',
        local_changes = 'Los cambios son locales hasta sincronizar',
        all_synced    = 'Todas las ediciones sincronizadas.',
        delete_preset = 'Eliminar Preajuste',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['es'].range = {
    ['booth_entered'] = "¡Entraste a la Cabina #%s! Apunta al objetivo y dispara.",
    ['booth_controls'] = "Usa ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ para mover el objetivo.",
    ['training_finished'] = "¡Sesión Finalizada! Puntuación: %s | Tiempo: %s",
    ['menu_header'] = "Galería de Tiro - Selección de Arma",
    ['menu_desc'] = "Selecciona esta arma para la práctica de tiro.",
    ['menu_cancel'] = "Cancelar",
    ['menu_cancel_desc'] = "Cerrar menú",
    ['ui_title'] = "GALERÍA DE TIRO",
    ['ui_time'] = "TIEMPO",
    ['ui_score'] = "PUNTUACIÓN",
    ['weapon_given'] = "Arma equipada.",
    ['weapon_removed'] = "Arma devuelta.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ para seleccionar arma",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ para abrir ordenador (Desafío de Puntería)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ para entrar a la Cabina #%s",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ para iniciar Desafío de Puntería (Cabina #3)",
    ['select_weapon_first'] = "¡Por favor selecciona un arma primero para el Desafío de Puntería!",
    ['equip_weapon_first'] = "¡Por favor equipa tu arma primero para el Desafío de Puntería!",
    ['booth_occupied'] = "¡La Cabina #%s está ocupada actualmente!",
    ['range_busy_aimlab'] = "¡Hay jugadores usando la galería! Todas las cabinas deben estar vacías para iniciar el Desafío de Puntería.",
    ['aimlab_in_progress'] = "¡Un Desafío de Puntería está en curso por %s!",
    ['aimlab_goto_booth'] = "¡Desafío de Puntería iniciado! Ve a la Cabina #3 y presiona [E].",
    ['aimlab_finished'] = "¡Desafío de Puntería completado! Objetivos acertados: %s | Arma: %s",
    ['aimlab_canceled'] = "¡Desafío de Puntería cancelado porque saliste de la cabina!",
    ['target_weapon_menu'] = "Seleccionar Arma",
    ['target_laptop'] = "Abrir Ordenador (Desafío de Puntería)",
    ['target_booth'] = "Entrar a la Cabina #%s",
    ['target_aimlab'] = "Iniciar Desafío de Puntería (Cabina #3)",
    ['scoreboard_reset_success'] = "¡Tabla de puntuaciones restablecida con éxito!",
    ['no_permission'] = "¡No tienes permiso para usar este comando!",
    ['no_access'] = "No tienes autorización para usar la galería de tiro."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['es'].archive = {
    ['blip_label']       = 'Archivo Digital',
    ['prompt_label']     = '~INPUT_CONTEXT~ Acceder al Archivo Digital',
    ['target_label']     = 'Acceder al Archivo Digital',
    ['no_access']        = 'No tienes acceso al archivo.',

    ['header_title']     = 'LSPD — Archivo Digital',
    ['header_subtitle']  = 'Archivo de Registros del Personal de LSPD',
    ['badge_text']       = 'ARCHIVO INACTIVO',
    ['label_rank']       = 'RANGO',
    ['label_name']       = 'NOMBRE COMPLETO',
    ['label_badge']      = 'Nº DE PLACA',
    ['label_service']    = 'SERVICIO',
    ['label_status']     = 'ESTADO',
    ['footer_copy']      = '© Departamento de Policía de Los Santos',
    ['footer_close']     = '[X] Cerrar',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Años',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

En la noche del 14 de octubre, el Departamento de Policía de Los Santos perdió más que a un Sargento.
El departamento perdió a un protector, a un mentor y a un hombre que dedicó dieciocho años de su vida a la placa y a las personas que hay detrás de ella. El Sargento II Troy Bolo sirvió al Departamento de Policía de Mission Row con lealtad, valor y honor inquebrantables. Conocido en todo el departamento por su liderazgo tranquilo y su profunda compasión tanto por los oficiales como por los civiles, Bolo se ganó el respeto de todas las divisiones con las que trabajó. Para los oficiales más jóvenes, era un mentor. Para sus compañeros Sargentos, era alguien en quien siempre podían confiar. Para la ciudad de Los Santos, era uno de sus mejores guardianes.

En la noche de su fallecimiento, los oficiales recibieron informes de un secuestro a mano armada en el que una familia estaba siendo retenida como rehén por una pandilla que operaba desde Little Seoul. Debido a la naturaleza peligrosa de la situación, originalmente se había asignado a un Sargento más joven para comandar la respuesta. El Sargento Bolo, creyendo que la operación conllevaba un riesgo inaceptable para el supervisor más joven, asumió el mando voluntariamente. Los testigos y los oficiales en el lugar declararon más tarde que Bolo se mantuvo sereno durante toda la operación, priorizando la seguridad de los rehenes por encima de todo. A través de la negociación y la coordinación táctica, la familia fue rescatada con éxito y sin daños.

Segundos después de que los rehenes fueran asegurados, un miembro herido de la pandilla que había estado tendido desapercibido en la escena abrió fuego sin previo aviso. El Sargento Troy Bolo fue alcanzado mientras protegía a los oficiales y civiles cercanos. A pesar de los esfuerzos de respuesta médica inmediata, el Sargento Bolo sucumbió a sus heridas en el cumplimiento de su deber. Sus acciones finales reflejaron el hombre que siempre había sido — desinteresado, valiente y dedicado a proteger a los demás, incluso a costa de su propia vida.

Los pasillos del Departamento de Policía de Mission Row aún conservan su memoria. Su casillero permanece intacto. Su nombre se sigue pronunciando con orgullo. Y los oficiales a los que entrenó continúan sirviendo inspirados por el ejemplo que dejó atrás. Al Sargento II Troy Bolo le sobrevive un departamento que nunca lo olvidará.

End of Watch
Sergeant II Troy Bolo
18 Años de Servicio
"La ciudad duerme más segura porque hombres como él montaron guardia."
]]
}

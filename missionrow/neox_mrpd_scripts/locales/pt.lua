-- =========================================================
-- NEOX MRPD — LOCALE: Português (pt)
-- =========================================================
-- Any key missing here falls back to locales/en.lua.
-- =========================================================

Locales = Locales or {}
Locales['pt'] = Locales['pt'] or {}

-- ---------------------------------------------------------
-- CCTV
-- ---------------------------------------------------------
Locales['pt'].cctv = {
    -- ===== Textos no jogo (avisos de ajuda / notificações) =====
    help_open     = 'Pressione ~INPUT_CONTEXT~ para aceder ao sistema CCTV.',
    help_exit     = 'Pressione ~INPUT_FRONTEND_PAUSE_ALTERNATE~ para sair.',
    no_access     = 'Não tem acesso a este sistema.',
    in_use        = '~r~Esta consola está a ser utilizada por outro agente.',
    target_label  = 'Aceder ao Sistema CCTV',
    cam_no_coords = '~r~As coordenadas da câmara não estão configuradas!',
    cmd_setup_no_perm   = '~r~Não tens permissão para usar este comando.',
    setup_started       = '~g~Modo de Configuração de Câmara CCTV Iniciado.~w~',
    setup_cancelled     = '~y~Configuração da câmara CCTV cancelada.',
    setup_saved         = '~g~Câmara CCTV criada com sucesso! (ID: %s)',
    setup_deleted       = '~g~Câmara CCTV eliminada. (ID: %s)',
    setup_not_found     = '~r~Câmara personalizada com este ID não encontrada.',
    setup_list_header   = '^3--- Lista de Câmaras Personalizadas CCTV ---^7',
    setup_prompt_label  = 'Etiqueta da Câmara (ex: MRPD CAM 05)',
    setup_prompt_name   = 'Nome da Localização (ex: Corredor Principal)',
    setup_prompt_district = 'Distrito (ex: MRPD / Bancos / Centro)',

    -- ===== Textos da interface (enviados para DUI/NUI) =====
    ui = {
        -- Janela / ambiente de trabalho
        title_bar      = 'DEPARTAMENTO DE POLÍCIA DE MISSION ROW - SISTEMA CCTV',
        icon_disk      = 'Disco',
        icon_recycle   = 'Reciclagem',
        icon_files     = 'Ficheiros Principais',
        min            = 'Minimizar',
        max            = 'Maximizar',
        close          = 'Fechar',
        live           = 'DIRETO',
        rec            = 'GRAV',

        -- Barra lateral
        system_status  = 'Estado do Sistema',
        operational    = 'OPERACIONAL',
        search         = 'Procurar',
        bookmarks      = 'Marcadores',
        all_cameras    = 'Todas as Câmaras',

        -- Painel de telemetria
        telemetry      = 'TELEMETRIA DA ESQUADRA',
        station        = 'ESQUADRA:',
        sys_time       = 'HORA SIS:',
        operator       = 'OPERADOR:',
        on_duty        = 'EM SERVIÇO',
        net_link       = 'LIGAÇÃO DE REDE:',
        secured        = 'PROTEGIDO',
        active_feeds   = 'TRANSMISSÕES ATIVAS:',
        disk_cap       = 'CAPACIDADE DISCO:',

        -- Painel principal
        camera_network = 'REDE DE CÂMARAS',
        bookmarks_title= 'MARCADORES',
        sort           = 'Ordenar:',
        sort_default   = 'Padrão',
        sort_name      = 'Nome (A-Z)',
        sort_location  = 'Localização',
        search_ph      = 'Procurar câmaras...',
        no_cameras     = 'Nenhuma câmara encontrada',
        no_in_district = 'Nenhuma câmara neste distrito',
        no_bookmarks   = 'Nenhuma câmara nos marcadores',

        -- CCTV HUD (câmara em ecrã inteiro)
        disconnect     = '[ RETROCESSO ] DESLIGAR',

        -- Linhas de registo da telemetria
        log_lines = {
            'Ligação segura verificada',
            'Uplink estabelecido',
            'Verificação de disco OK',
            'Canal sincronizado',
            'Pacote de dados encaminhado',
            'Sinal de transmissão estável',
            'Memória temporária limpa',
            'Encriptação renovada',
            'Porta em escuta...',
            'Cache de fotogramas reposta',
            'Ping de telemetria: 12ms',
            'Nível de sinal: nominal',
        },
    },
}

-- ---------------------------------------------------------
-- HYGIENE
-- ---------------------------------------------------------
Locales['pt'].hygiene = {
    ['shower_prompt']   = '[E] Tomar banho',
    ['poop_prompt']     = '[E] Fazer cocó',
    ['pee_prompt']      = '[G] Fazer chichi',
    ['toilet_prompt']   = '[E] Fazer cocó  |  [G] Fazer chichi',

    ['shower_target']   = 'Tomar banho',
    ['poop_target']     = 'Fazer cocó',
    ['pee_target']      = 'Fazer chichi',
    ['wash_target']     = 'Lavar as mãos',

    ['shower_start']    = 'Estás a tomar banho...',
    ['shower_done']     = 'Banho concluído!',
    ['poop_start']      = 'Estás a usar a casa de banho...',
    ['poop_done']       = 'Visita concluída!',
    ['pee_start']       = 'Estás a usar a casa de banho...',
    ['pee_done']        = 'Visita concluída!',
    ['wash_start']      = 'Estás a lavar as mãos...',
    ['wash_done']       = 'Lavaste as mãos!',
    ['busy']            = 'Estás ocupado de momento!',
    
    ['shower_exit']     = 'Pressiona ~INPUT_VEH_DUCK~ para sair do banho',
}

-- ---------------------------------------------------------
-- KILLHOUSE
-- ---------------------------------------------------------
Locales['pt'].killhouse = {
    ['training_started'] = "Treino Kill House iniciado! Atinge o maior número de alvos possível.",
    ['training_finished'] = "Treino concluído! Tempo: %s | Pontuação: %s/%s",
    ['training_canceled'] = "Treino cancelado! Saíste da área de treino.",
    ['training_failed'] = "Civil atingido! Treino falhado.",
    ['menu_header'] = "Kill House - Seleção de Arma",
    ['menu_desc'] = "Seleciona esta arma e inicia o treino.",
    ['menu_cancel'] = "Cancelar",
    ['menu_cancel_desc'] = "Cancelar treino",
    ['ui_title'] = "TREINO KILL HOUSE",
    ['ui_time'] = "TEMPO",
    ['ui_targets'] = "ALVOS",
    ['ui_footer'] = "DISPARAR CONTRA CIVIS RESULTA EM DERROTA",
    ['weapon_given'] = "Arma equipada.",
    ['weapon_removed'] = "Arma devolvida.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ para selecionar arma",
    ['troll_warning'] = "Saíste da área de treino! Arma confiscada.",
    ['operator_inside'] = "Outro agente está no interior de momento!",
    ['target_weapon_menu'] = "Selecionar Arma",
    ['target_killhouse_start'] = "Iniciar Treino Kill House",
    ['scoreboard_reset_success'] = "Tabela de pontuações reposta com sucesso!",
    ['no_permission'] = "Não tens permissão para usar este comando!",
    ['no_access'] = "Não tens autorização para usar a Kill House."
}

-- ---------------------------------------------------------
-- PROJECTOR
-- ---------------------------------------------------------
Locales['pt'].projector = {
    -- ===== Textos no jogo =====
    help_open    = 'Pressione ~INPUT_CONTEXT~ para aceder ao projetor.',
    target_label = 'Abrir Consola de Apresentação',
    no_access    = 'Não tem acesso a esta consola.',
    in_use       = '~r~Outro utilizador está a usar a consola de momento.',

    -- ===== Textos da interface (enviados para DUI/NUI) =====
    ui = {
        -- Estado / exibição
        ready        = 'PRONTO',
        live         = 'DIRETO',
        live_edit    = 'EDIÇÃO EM DIRETO',
        no_signal    = 'SEM SINAL.',
        input_video  = 'ENTRADA: VÍDEO',

        -- Menu da aplicação (decorativo)
        menu_file   = 'Ficheiro',  menu_edit   = 'Editar',    menu_image  = 'Imagem',
        menu_layer  = 'Camada',    menu_type   = 'Texto',     menu_select = 'Selecionar',
        menu_filter = 'Filtro',    menu_view   = 'Ver',       menu_window = 'Janela',
        menu_help   = 'Ajuda',

        -- Vista de URL / multimédia
        no_content     = 'SEM CONTEÚDO INCORPORADO',
        no_content_sub = 'Carrega uma imagem externa, vídeo ou URL de transmissão',
        load           = 'CARREGAR',
        remove         = 'REMOVER',
        url_hint       = 'Formatos suportados: .png .jpg .jpeg .webp .gif .mp4 .webm',

        -- Painéis
        canvas_bg     = 'FUNDO DA TELA',
        bg_dark       = 'Escuro',
        bg_white      = 'Branco',
        bg_grid       = 'Grelha',
        bg_dots       = 'Pontos',
        board_presets = 'PREDEFINIÇÕES DO QUADRO',
        save          = 'GUARDAR',
        preset_ph     = 'Nome da predefinição...',
        no_presets    = 'Nenhuma predefinição guardada.',
        character     = 'CARÁTER',
        font_family   = 'Fonte',
        font_size     = 'Tamanho da Fonte',
        styles        = 'Estilos',
        swatches      = 'Amostras',
        actions       = 'AÇÕES',
        undo          = 'Anular Ação',
        delete_sel    = 'Eliminar Seleção',
        clear_canvas  = 'Limpar Tela',
        drop_signal   = 'CORTAR PARA SEM SINAL',
        transmit      = 'TRANSMITIR EM DIRETO',

        -- Janela de imagem
        place_image = 'COLOCAR IMAGEM INCORPORADA',
        place_hint  = 'Ligações diretas: .png .jpg .jpeg .webp .gif (apenas HTTPS)',
        cancel      = 'Cancelar',
        place       = 'Colocar',

        -- Painel autónomo
        media_link      = 'LIGAÇÃO MULTIMÉDIA DO PROJETOR',
        url_cast        = 'Transmitir URL',
        supported_short = 'Suportado: .png .jpg .jpeg .webp .gif .mp4 .webm',
        pull            = 'EXTRAIR DO ECRÃ',
        presets         = 'Predefinições',
        save_preset     = 'GUARDAR PREDEFINIÇÃO',
        sa_preset_ph    = 'Insere um nome para guardar o URL atual...',

        -- Ícones do ambiente de trabalho
        icon_disk    = 'Disco',
        icon_recycle = 'Reciclagem',
        icon_drafts  = 'Rascunhos',

        -- Dicas de ferramentas
        tool_move   = 'Ferramenta Mover (V)',
        tool_brush  = 'Ferramenta Pincel (B)',
        tool_eraser = 'Ferramenta Borracha (E)',
        tool_type   = 'Ferramenta Texto Horizontal (T)',
        tool_place  = 'Colocar Imagem Incorporada',
        fg_color    = 'Cor de Primeiro Plano',
        bg_color    = 'Cor de Fundo',
        bold        = 'Negrito',
        italic      = 'Itálico',

        -- Estados dinâmicos (JS)
        invalid_url   = 'URL inválido — permitido: .png .jpg .jpeg .webp .gif .mp4 .webm (https)',
        media_loaded  = 'Multimédia carregada localmente. Pressiona TRANSMITIR EM DIRETO.',
        transmitting  = 'A transmitir...',
        synced        = 'Sincronizado com o projetor ✓',
        local_changes = 'As alterações são locais até serem sincronizadas',
        all_synced    = 'Todas as edições sincronizadas.',
        delete_preset = 'Eliminar Predefinição',
    },
}

-- ---------------------------------------------------------
-- RANGE
-- ---------------------------------------------------------
Locales['pt'].range = {
    ['booth_entered'] = "Entraste na Cabine #%s! Aponta ao alvo e dispara.",
    ['booth_controls'] = "Usa ~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ para mover o alvo.",
    ['training_finished'] = "Sessão Concluída! Pontuação: %s | Tempo: %s",
    ['menu_header'] = "Carreira de Tiro - Seleção de Arma",
    ['menu_desc'] = "Seleciona esta arma para a prática de tiro.",
    ['menu_cancel'] = "Cancelar",
    ['menu_cancel_desc'] = "Fechar menu",
    ['ui_title'] = "CARREIRA DE TIRO",
    ['ui_time'] = "TEMPO",
    ['ui_score'] = "PONTUAÇÃO",
    ['weapon_given'] = "Arma equipada.",
    ['weapon_removed'] = "Arma devolvida.",
    ['press_e_weapon'] = "~INPUT_CONTEXT~ para selecionar arma",
    ['press_e_laptop'] = "~INPUT_CONTEXT~ para abrir computador (Desafio de Pontaria)",
    ['press_e_booth'] = "~INPUT_CONTEXT~ para entrar na Cabine #%s",
    ['press_e_aimlab'] = "~INPUT_CONTEXT~ para iniciar Desafio de Pontaria (Cabine #3)",
    ['select_weapon_first'] = "Por favor seleciona uma arma primeiro para o Desafio de Pontaria!",
    ['equip_weapon_first'] = "Por favor equipa a tua arma primeiro para o Desafio de Pontaria!",
    ['booth_occupied'] = "A Cabine #%s está ocupada de momento!",
    ['range_busy_aimlab'] = "Há jogadores na carreira de tiro! Todas as cabines devem estar vazias para iniciar o Desafio de Pontaria.",
    ['aimlab_in_progress'] = "Um Desafio de Pontaria está a ser disputado por %s!",
    ['aimlab_goto_booth'] = "Desafio de Pontaria iniciado! Dirige-te à Cabine #3 e pressiona [E].",
    ['aimlab_finished'] = "Desafio de Pontaria concluído! Alvos Atingidos: %s | Arma: %s",
    ['aimlab_canceled'] = "Desafio de Pontaria cancelado porque saíste da cabine!",
    ['target_weapon_menu'] = "Selecionar Arma",
    ['target_laptop'] = "Abrir Computador (Desafio de Pontaria)",
    ['target_booth'] = "Entrar na Cabine #%s",
    ['target_aimlab'] = "Iniciar Desafio de Pontaria (Cabine #3)",
    ['scoreboard_reset_success'] = "Tabela de pontuações reposta com sucesso!",
    ['no_permission'] = "Não tens permissão para usar este comando!",
    ['no_access'] = "Não tens autorização para usar a carreira de tiro."
}

-- ---------------------------------------------------------
-- ARCHIVE
-- ---------------------------------------------------------
Locales['pt'].archive = {
    ['blip_label']       = 'Arquivo Digital',
    ['prompt_label']     = '~INPUT_CONTEXT~ Acessar Arquivo Digital',
    ['target_label']     = 'Acessar Arquivo Digital',
    ['no_access']        = 'Não tens acesso ao arquivo.',

    ['header_title']     = 'LSPD — Arquivo Digital',
    ['header_subtitle']  = 'Arquivo de Registros de Pessoal do LSPD',
    ['badge_text']       = 'ARQUIVO INATIVO',
    ['label_rank']       = 'PATENTE',
    ['label_name']       = 'NOME COMPLETO',
    ['label_badge']      = 'Nº DO DISTINTIVO',
    ['label_service']    = 'SERVIÇO',
    ['label_status']     = 'STATUS',
    ['footer_copy']      = '© Departamento de Polícia de Los Santos',
    ['footer_close']     = '[X] Fechar',

    ['val_rank']         = 'Sergeant II',
    ['val_name']         = 'Troy Bolo',
    ['val_badge']        = '#4471',
    ['val_service']      = '18 Anos',
    ['val_status']       = 'End of Watch',

    ['story']            = [[
SERGEANT II - TROY BOLO

Na noite de 14 de outubro, o Departamento de Polícia de Los Santos perdeu mais do que um Sargento.
O departamento perdeu um protetor, um mentor e um homem que dedicou dezoito anos de sua vida ao distintivo e às pessoas por trás dele. O Sargento II Troy Bolo serviu ao Departamento de Polícia de Mission Row com lealdade, coragem e honra inabaláveis. Conhecido em todo o departamento por sua liderança calma e profunda compaixão tanto pelos policiais quanto pelos civis, Bolo ganhou o respeito de todas as divisões com as quais trabalhou. Para os oficiais mais jovens, ele era um mentor. Para seus colegas Sargentos, ele era alguém em quem sempre podiam confiar. Para a cidade de Los Santos, ele era um de seus melhores guardiões.

Na noite de seu falecimento, os oficiais receberam relatos de um sequestro armado envolvendo uma família mantida como refém por uma gangue operando em Little Seoul. Devido à natureza perigosa da situação, um Sargento mais jovem havia sido originalmente designado para comandar a resposta. O Sargento Bolo, acreditando que a operação acarretava um risco inaceitável para o supervisor mais jovem, assumiu voluntariamente o comando. Testemunhas e policiais no local declararam mais tarde que Bolo permaneceu sereno durante toda a operação, priorizando a segurança dos reféns acima de tudo. Através de negociação e coordenação tática, a família foi resgatada com sucesso sem danos.

Segundos depois de os reféns terem sido resgatados, um membro de gangue ferido que passara despercebido no local abriu fogo sem aviso. O Sargento Troy Bolo foi atingido enquanto protegia os oficiais e civis próximos. Apesar dos esforços imediatos de resposta médica, o Sargento Bolo sucumbiu aos ferimentos no cumprimento do dever. Suas ações finais refletiram o homem que ele sempre foi — altruísta, destemido e dedicado a proteger os outros, mesmo à custa de sua própria vida.

Os corredores do Departamento de Polícia de Mission Row ainda carregam sua memória. Seu armário permanece intocado. Seu nome continua a ser falado com orgulho. E os oficiais que ele treinou continuam a servir inspirados pelo exemplo que ele deixou para trás. O Sargento II Troy Bolo deixa um departamento que nunca o esquecerá.

End of Watch
Sergeant II Troy Bolo
18 Anos de Serviço
"A cidade dorme mais segura porque homens como ele montaram guarda."
]]
}

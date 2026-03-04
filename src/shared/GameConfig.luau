local ConfiguracoesJogo = {
    MAX_PLAYERS = 4,
    COUNTDOWN_TIME = 5,
    CUT_TIME_LIMIT = 10, -- Tempo para o jogador realizar o corte

    -- Estados internos mantidos em Inglês para não quebrar mensagens de rede
    States = {
        WAITING = "WAITING",
        COUNTDOWN = "COUNTDOWN",
        SHUFFLING = "SHUFFLING",
        CUTTING = "CUTTING",
        DEALING = "DEALING",
        PLAYING = "PLAYING",
    },

    -- Nomes que aparecerão de fato na tela do jogador (Já formatados)
    StateDisplayNames = {
        WAITING = "Aguardando jogadores...",
        COUNTDOWN = "O jogo começa em:",
        SHUFFLING = "Embaralhando...",
        CUTTING = "Aguardando corte...",
        DEALING = "Distribuindo cartas...",
        PLAYING = "Partida em andamento",
    },

    -- Mapeamento das duplas no sentido Cruzado (1 e 3) contra (2 e 4)
    TEAMS = { TeamA = {1, 3}, TeamB = {2, 4} }
}

return ConfiguracoesJogo
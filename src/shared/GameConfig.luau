local GameConfig = {
    MAX_PLAYERS = 4,
    COUNTDOWN_TIME = 5,
    CUT_TIME_LIMIT = 10, -- 10 segundos para cortar

    States = {
        WAITING = "WAITING",
        COUNTDOWN = "COUNTDOWN",
        SHUFFLING = "SHUFFLING",
        CUTTING = "CUTTING",
        DEALING = "DEALING",
        PLAYING = "PLAYING",
    },

    -- Nomes para exibição na UI
    StateDisplayNames = {
        WAITING = "Aguardando jogadores...",
        COUNTDOWN = "O jogo começa em:",
        SHUFFLING = "Embaralhando...",
        CUTTING = "Aguardando corte...",
        DEALING = "Distribuindo cartas...",
        PLAYING = "Partida em andamento",
    },

    TEAMS = { TeamA = {1, 3}, TeamB = {2, 4} }
}

return GameConfig
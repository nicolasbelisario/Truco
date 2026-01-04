local GameConfig = {
    MAX_PLAYERS = 4,
    COUNTDOWN_TIME = 5,
    CUT_TIME_LIMIT = 10, -- Tempo para o jogador realizar o corte

    -- Estados da máquina de estados do jogo
    States = {
        WAITING = "WAITING",
        COUNTDOWN = "COUNTDOWN",
        SHUFFLING = "SHUFFLING",
        CUTTING = "CUTTING",
        DEALING = "DEALING",
        PLAYING = "PLAYING",
    },

    -- Mensagens visuais para o cliente
    StateDisplayNames = {
        WAITING = "Aguardando jogadores...",
        COUNTDOWN = "O jogo começa em:",
        SHUFFLING = "Embaralhando...",
        CUTTING = "Aguardando corte...",
        DEALING = "Distribuindo cartas...",
        PLAYING = "Partida em andamento",
    },

    -- Definição das duplas baseada nos índices das cadeiras
    TEAMS = { TeamA = {1, 3}, TeamB = {2, 4} }
}

return GameConfig
--[[
    GameRulesConfig.luau
    Constantes e parâmetros temporais e numéricos de regras de negócio do Truco Paulista.
]]

local GameRulesConfig = {
    -- Estrutura de jogadores e time
    MAX_PLAYERS = 4,
    CARTAS_POR_JOGADOR = 3,
    CARTAS_NO_BARALHO = 40,
    PONTOS_VITORIA_PARTIDA = 12,

    -- Tempos e limites (em segundos)
    Tempos = {
        CountdownInicio = 5,
        LimiteCorteBaralho = 10,
        LimiteRespostaTruco = 15,
        EsperaFinalizacaoMao = 3,
        EsperaFinalizacaoPartida = 8,
        DelayLimpezaMesa = 1.5,
    },

    -- Escala de valores possíveis para a Mão
    ValoresMao = {
        Base = 1,
        Truco = 3,
        Seis = 6,
        Nove = 9,
        Doze = 12,
    },

    -- Mão de Onze e Mão de Ferro
    Especiais = {
        PontosGatilhoMaoDeOnze = 11,
        ValorMaoDeOnze = 3,
        ValorMaoDeFerro = 3,
        PenalidadeCorrerMaoDeOnze = 1,
    },

    -- Estados da partida (Identificadores de Rede)
    States = {
        WAITING = "WAITING",
        COUNTDOWN = "COUNTDOWN",
        SHUFFLING = "SHUFFLING",
        CUTTING = "CUTTING",
        DEALING = "DEALING",
        PLAYING = "PLAYING",
        SCORING = "SCORING",
        ELEVEN_DECISION = "ELEVEN_DECISION",
    },

    -- Textos exibidos aos jogadores para cada estado
    StateDisplayNames = {
        WAITING = "Aguardando jogadores...",
        COUNTDOWN = "O jogo começa em:",
        SHUFFLING = "Embaralhando...",
        CUTTING = "Aguardando corte...",
        DEALING = "Distribuindo cartas...",
        PLAYING = "Partida em andamento",
        SCORING = "Pontuando rodada...",
        ELEVEN_DECISION = "Decisão da Mão de Onze...",
    },

    -- Formato dos times cruzados (Cadeiras 1 e 3 vs 2 e 4)
    TEAMS = {
        TeamA = {1, 3},
        TeamB = {2, 4}
    }
}

return GameRulesConfig

--[[
    BotConfig.luau
    Variáveis de balanceamento e parâmetros comportamentais dos Bots IA.
    Permite calibrar tempo de reação, agressividade e blefe sem alterar a lógica de execução.
]]

local BotConfig = {
    -- Tempo de "pensamento" simulado antes do Bot jogar uma carta
    TempoPensamento = {
        MinSegundos = 1.5,
        MaxSegundos = 3.0,
    },

    -- Tempo de resposta simulado para aceitar/recusar Truco
    TempoRespostaTruco = {
        MinSegundos = 1.0,
        MaxSegundos = 3.0,
    },

    -- Tempo de resposta na decisão da Mão de Onze
    TempoDecisaoMaoDeOnzeSegundos = 2.0,

    -- Quantidade padrão de cortes do baralho pelo Bot
    CortePadrao = 1,

    -- Dificuldade padrão ativa nas mesas PvE
    DificuldadeAtiva = "Normal",

    -- Calibração por nível de dificuldade
    Dificuldades = {
        Facil = {
            ChanceTrucoMaoBase = 0.05,        -- 5% de chance de pedir truco na mão de 1
            ChanceEsconderCarta = 0.02,       -- 2% de chance de carta virada
            ChanceAceitarTruco = 0.40,        -- 40% aceita, 60% corre
            MinManilhaStrengthMaoDeOnze = 4,  -- Só joga com Zap (Paus)
        },
        Normal = {
            ChanceTrucoMaoBase = 0.10,        -- 10% de chance de pedir truco na mão de 1
            ChanceEsconderCarta = 0.05,       -- 5% de chance de carta virada
            ChanceAceitarTruco = 0.60,        -- 60% aceita, 40% corre
            MinManilhaStrengthMaoDeOnze = 3,  -- Joga se tiver Copas ou Zap
        },
        Dificil = {
            ChanceTrucoMaoBase = 0.20,        -- Mais agressivo
            ChanceEsconderCarta = 0.10,       -- Usa mais cartas cobertas estrategicamente
            ChanceAceitarTruco = 0.70,        -- Mais corajoso
            MinManilhaStrengthMaoDeOnze = 2,  -- Joga se tiver Espadas, Copas ou Zap
        }
    }
}

return BotConfig

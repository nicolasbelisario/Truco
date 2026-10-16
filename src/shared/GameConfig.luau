--[[
    GameConfig.luau
    Mantido para retrocompatibilidade com código existente.
    Redireciona e agrega as configurações do GameRulesConfig.
]]

local GameRulesConfig = require(script.Parent.Configs.GameRulesConfig)

local ConfiguracoesJogo = {
    MAX_PLAYERS = GameRulesConfig.MAX_PLAYERS,
    COUNTDOWN_TIME = GameRulesConfig.Tempos.CountdownInicio,
    CUT_TIME_LIMIT = GameRulesConfig.Tempos.LimiteCorteBaralho,

    States = GameRulesConfig.States,
    StateDisplayNames = GameRulesConfig.StateDisplayNames,
    TEAMS = GameRulesConfig.TEAMS,

    -- Atalho para acesso aos submódulos
    Rules = GameRulesConfig,
}

return ConfiguracoesJogo
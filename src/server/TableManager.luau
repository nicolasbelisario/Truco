local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local Match = require(script.Parent.Classes:WaitForChild("Match"))

local TableManager = {}
local matches = {} -- [Model] = MatchInstance
local playerToMatch = {} -- [Player] = MatchInstance

-- CONFIGURAÇÃO DOS BOTS POR NOME DA MESA
-- Define quais cadeiras serão ocupadas por BOTS.
-- As cadeiras que não estiverem na lista ficam livres para humanos.
local BOT_CONFIGS = {
    ["MesaPvE_Solo"] = {2, 3, 4}, -- 1 Humano vs 3 Bots (Padrão)
    ["MesaPvE_Dupla"] = {2, 4},   -- 2 Humanos (1 e 3) vs 2 Bots (2 e 4)
    ["MesaPvE_Trio"] = {4},       -- 3 Humanos (1, 2, 3) vs 1 Bot (4)
}

function TableManager.Init(folder)
    for _, mesaModel in ipairs(folder:GetChildren()) do
        
        -- Verifica se o nome da mesa existe na nossa configuração
        local botSeats = BOT_CONFIGS[mesaModel.Name]
        
        -- Se botSeats não for nil, é uma mesa PvE. Se for nil, é PvP normal (lista vazia).
        local configToPass = botSeats or {}
        
        -- Cria a partida passando a lista de cadeiras de bot
        local match = Match.new(mesaModel, configToPass)
        matches[mesaModel] = match
        
        match.OnPlayerJoin = function(player)
            playerToMatch[player] = match
        end
        
        match.OnPlayerLeave = function(player)
            playerToMatch[player] = nil
        end
    end
    
    TableManager.SetupNetwork()
end

-- Roteamento de Eventos: O cliente manda o evento, o TableManager descobre de qual mesa ele é
function TableManager.SetupNetwork()
    -- Jogar Carta
    Events.PlayCardEvent.OnServerEvent:Connect(function(player, val, suit, hidden)
        local match = playerToMatch[player]
        if match then match:PlayerPlayCard(player, val, suit, hidden) end
    end)

    -- Ações de Truco (Pedir, Aceitar, Correr)
    Events.TrucoEvent.OnServerEvent:Connect(function(player, action, subAction)
        local match = playerToMatch[player]
        if match then match:HandleTrucoAction(player, action, subAction) end
    end)
    
    -- Ação de Corte
    Events.GameStatusEvent.OnServerEvent:Connect(function(player, action, value)
        local match = playerToMatch[player]
        if match and action == "CutAction" then
            match:PlayerCutDeck(player, value)
        end
    end)
    
    -- Sinais (Emotes)
    Events.SignalEvent.OnServerEvent:Connect(function(player, signalType)
        local match = playerToMatch[player]
        if match then match:BroadcastSignal(player, signalType) end
    end)
end

return TableManager
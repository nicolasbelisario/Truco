local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local Match = require(script.Parent.Classes:WaitForChild("Match"))

local TableManager = {}
local matches = {} -- [Model] = MatchInstance
local playerToMatch = {} -- [Player] = MatchInstance

function TableManager.Init(folder)
    for _, mesaModel in ipairs(folder:GetChildren()) do
        -- Verifica se é a mesa de bots pelo nome
        local isBotTable = (mesaModel.Name == "MesaBots")
        
        -- Cria uma nova instância de partida para esta mesa
        local match = Match.new(mesaModel, isBotTable)
        matches[mesaModel] = match
        
        -- Escuta quando jogadores sentam/levantam (Delegado para a classe Match)
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
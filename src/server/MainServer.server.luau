local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local DeckManager = require(script.Parent:WaitForChild("DeckManager"))
local GameManager = require(script.Parent:WaitForChild("GameManager"))

-- Inicializa o sistema de assentos
SeatManager.Init()

-- Monitora a mesa para iniciar o jogo automaticamente
task.spawn(function()
    while task.wait(1) do
        local count, _ = SeatManager.GetSeatedPlayers()
        if count == 4 and GameManager.GetState() == "WAITING" then
            GameManager.StartCountdown()
        end
    end
end)

-- Listener para Sinais (Emotes/Sinais de Truco)
Events.SignalEvent.OnServerEvent:Connect(function(player, signalType)
    print(player.Name .. " enviou sinal: " .. signalType)
    -- Replica para todos os clientes (o UIManager do cliente cuidará do visual)
    Events.SignalEvent:FireAllClients(player, signalType)
end)

SeatManager.Init(function()
    local state = GameManager.GetState()
    -- Envia o estado atual do jogo para todos os que estão sentados
    GameManager.NotifySeatedPlayers(state, 0)
end)
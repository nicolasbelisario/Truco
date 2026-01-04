local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local GameManager = require(script.Parent:WaitForChild("GameManager"))

-- Inicializa o sistema de assentos
-- Passamos um callback para notificar jogadores se o estado mudar enquanto sentam
SeatManager.Init(function()
    local state = GameManager.GetState()
    GameManager.NotifySeatedPlayers(state, 0)
end)

-- Loop principal de monitoramento da sala
task.spawn(function()
    while task.wait(1) do
        local count, _ = SeatManager.GetSeatedPlayers()
        -- Inicia o jogo apenas se estiver em WAITING e tiver 4 jogadores
        if count == 4 and GameManager.GetState() == "WAITING" then
            GameManager.StartCountdown()
        end
    end
end)

-- Listener de Sinais (Replica para todos os clientes)
Events.SignalEvent.OnServerEvent:Connect(function(player, signalType)
    Events.SignalEvent:FireAllClients(player, signalType)
end)
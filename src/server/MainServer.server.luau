local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local GameManager = require(script.Parent:WaitForChild("GameManager"))

SeatManager.Init(function()
    local state = GameManager.GetState()
    GameManager.NotifySeatedPlayers(state, 0)
end)

task.spawn(function()
    while task.wait(1) do
        local count, _ = SeatManager.GetSeatedPlayers()
        if count == 4 and GameManager.GetState() == "WAITING" then
            GameManager.StartCountdown()
        end
    end
end)

-- CONTROLE UNIFICADO DE SINAIS (COOLDOWN + REPLICAÇÃO)
local lastEmoteTimes = {}
local COOLDOWN = 2.5

Events.SignalEvent.OnServerEvent:Connect(function(player, signalType)
    local now = os.clock()
    local last = lastEmoteTimes[player] or 0
    
    -- Só replica se passar no teste de tempo
    if now - last >= COOLDOWN then
        lastEmoteTimes[player] = now
        -- print(player.Name .. " enviou sinal: " .. signalType)
        Events.SignalEvent:FireAllClients(player, signalType)
    end
end)    
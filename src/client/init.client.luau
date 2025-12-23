local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local currentPartner = "Ninguém"
local myTeam = "A"

local UIManager = require(script:WaitForChild("UIManager"))
local Events = ReplicatedStorage:WaitForChild("Events")

UIManager.Init()

local function updateSitStatus(isSitting)
    UIManager.SetSeated(isSitting)
    if isSitting then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            local seatName = char.Humanoid.SeatPart.Parent.Name
            UIManager.SetMySeat(seatName)
            -- Define o time: Cadeiras 1 e 3 são Time A, 2 e 4 são Time B
            local seatNum = tonumber(seatName:match("%d+"))
            myTeam = (seatNum % 2 == 1) and "A" or "B"
        end
    end
end

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("Sit"):Connect(function() updateSitStatus(hum.Sit) end)
end)

if player.Character and player.Character:FindFirstChild("Humanoid") then
    updateSitStatus(player.Character.Humanoid.Sit)
end

-- LISTENERS ÚNICOS
Events.RequestAction.OnClientEvent:Connect(function(actionType, value)
    if actionType == "EscolhaOCorte" then UIManager.ShowCutOptions(value) end
end)

Events.GameStatusEvent.OnClientEvent:Connect(function(message, data)
    if message == "CLEAR_TABLE" then
        -- Organiza o placar baseado no meu time
        local myTricks = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyTricks = (myTeam == "A") and data.TeamB or data.TeamA
        
        UIManager.UpdateRoundStats(currentPartner, myTricks, enemyTricks)
        
        -- Delay para ver as cartas antes de limpar
        task.delay(2, function() UIManager.ClearTable() end)
        
    elseif message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        local teamResult = (message == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        UIManager.ShowRoundWinner(teamResult)
        task.delay(3, function() UIManager.ClearTable() end)
    else
        UIManager.UpdateStatus(message, data)
    end
end)

Events.DealCards.OnClientEvent:Connect(function(mao, vira, partner)
    if partner then currentPartner = partner end
    UIManager.ClearHand() 
    UIManager.ClearTable()
    UIManager.SetVira(vira.Value, vira.Suit)
    UIManager.UpdateRoundStats(currentPartner, 0, 0)
    
    for _, card in ipairs(mao) do
        UIManager.AddCardToHand(card.Value, card.Suit)
    end
end)

Events.UpdateTurnEvent.OnClientEvent:Connect(function(playerName)
    UIManager.UpdateTurn(playerName)
end)

Events.CardPlayedOnTable.OnClientEvent:Connect(function(playerName, value, suit)
    UIManager.AddPlayedCardUI(playerName, value, suit)
end)

-- Sinais e Emotes
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q then Events.SignalEvent:FireServer("Sinal_Mao")
    elseif input.KeyCode == Enum.KeyCode.E then Events.SignalEvent:FireServer("Sinal_Olhar") end
end)

Events.SignalEvent.OnClientEvent:Connect(function(sender, signalType)
    UIManager.ShowSignal(sender, signalType)
end)
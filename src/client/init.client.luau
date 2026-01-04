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
            
            -- Cadeiras 1 e 3 (Ímpares) = Time A
            -- Cadeiras 2 e 4 (Pares) = Time B
            local seatNum = tonumber(seatName:match("%d+"))
            myTeam = (seatNum % 2 == 1) and "A" or "B"
        end
    end
end

-- Listener de sentar/levantar
player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("Sit"):Connect(function() updateSitStatus(hum.Sit) end)
end)

if player.Character and player.Character:FindFirstChild("Humanoid") then
    updateSitStatus(player.Character.Humanoid.Sit)
end

-- RECEBIMENTO DE AÇÕES DO SERVIDOR (Corte e Desafios)
Events.RequestAction.OnClientEvent:Connect(function(actionType, data)
    if actionType == "EscolhaOCorte" then 
        UIManager.ShowCutOptions(data) 
    elseif actionType == "TrucoChallenge" then
        -- data: {Value, Caller, NextRaise}
        UIManager.ShowTrucoChallenge(data.Value, data.Caller)
    end
end)

-- GERENCIADOR PRINCIPAL DE ESTADO
Events.GameStatusEvent.OnClientEvent:Connect(function(message, data)
    -- 1. Controle de Botão de Truco
    if message == "HIDE_TRUCO_BTN" then
        UIManager.SetCanTruco(false)
        return
    elseif message == "SHOW_TRUCO_BTN" then
        UIManager.SetCanTruco(true)
        return
    elseif message == "DEALING" then
        UIManager.HideCutMenu()
        return
    end

    -- 2. Limpeza de Interface e Efeitos
    if message == "TRUCO_ACEITO" or message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        UIManager.HideTrucoChallenge()
        UIManager.ResetCamera()
    end

    -- 3. Atualizações de Jogo
    if message == "CLEAR_TABLE" then
        local myTricks = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyTricks = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateRoundStats(currentPartner, myTricks, enemyTricks)
        UIManager.ClearTable()

    elseif message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        local teamResult = (message == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        UIManager.ShowRoundWinner(teamResult)

    elseif message == "UPDATE_SCORE" then
        local myScore = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyScore = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateGameScore(myScore, enemyScore)
        
    elseif message == "UPDATE_ROUND_VALUE" then
        UIManager.UpdateRoundValue(data)

    elseif message == "TRUCO_ACEITO" then
        UIManager.UpdateStatus("TRUCO ACEITO! Vale " .. data, 0)

    elseif message == "TRUCO_CALLED" then
        UIManager.UpdateStatus("TRUCO! Vale " .. data, 0)

    elseif message == "SHOW_SCOREBOARD" then
        UIManager.ShowScoreboard()

    elseif message == "HIDE_SCOREBOARD" then
        UIManager.HideScoreboard()
        
    elseif message == "HIDE_GAME_UI" then
        UIManager.SetGameplayUIVisibility(false)

    elseif message == "SHOW_GAME_UI" then
        UIManager.SetGameplayUIVisibility(true)
        
    else
        UIManager.UpdateStatus(message, data)
    end
end)

-- DEALER: Recebe mão inicial
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

Events.SignalEvent.OnClientEvent:Connect(function(sender, signalType)
    UIManager.ShowSignal(sender, signalType)
end)

-- CONTROLE DE INPUTS (Sinais e Truco)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Q then 
        Events.SignalEvent:FireServer("Sinal_Mao")
    elseif input.KeyCode == Enum.KeyCode.E then 
        Events.SignalEvent:FireServer("Sinal_Olhar") 
    end
end)
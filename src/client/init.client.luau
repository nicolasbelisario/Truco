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
Events.RequestAction.OnClientEvent:Connect(function(actionType, data)
    if actionType == "EscolhaOCorte" then 
        UIManager.ShowCutOptions(data) 
    elseif actionType == "TrucoChallenge" then
        -- 'data' contém {Value = 3, Caller = "Nome"}
        UIManager.ShowTrucoChallenge(data.Value, data.Caller)
    end
end)

Events.GameStatusEvent.OnClientEvent:Connect(function(message, data)
    -- 1. Limpeza de UI: Se o truco foi aceito ou a mão acabou, fecha o menu de decisão em todos os clientes
    if message == "TRUCO_ACEITO" or message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        UIManager.HideTrucoChallenge() -- Garante que o menu suma para você e seu parceiro
    end

    -- 2. Estrutura Principal de Eventos
    if message == "CLEAR_TABLE" then
        -- Organiza o placar baseado no meu time
        local myTricks = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyTricks = (myTeam == "A") and data.TeamB or data.TeamA
        
        UIManager.UpdateRoundStats(currentPartner, myTricks, enemyTricks)
        -- task.delay(0.5, function()
        --     UIManager.ClearTable()
        -- end)
        UIManager.ClearTable()

    elseif message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        local teamResult = (message == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        UIManager.ShowRoundWinner(teamResult)

    elseif message == "UPDATE_SCORE" then
        local myScore = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyScore = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateGameScore(myScore, enemyScore)
    
    elseif message == "UPDATE_ROUND_VALUE" then
        -- Atualiza apenas o pequeno selo "VALE: X" e não o texto central
        UIManager.UpdateRoundValue(data)

    elseif message == "TRUCO_ACEITO" then
        -- Mostra a confirmação no centro da tela temporariamente
        UIManager.UpdateStatus("TRUCO ACEITO! Vale " .. data, 0)

    elseif message == "TRUCO_CALLED" then
        UIManager.UpdateStatus("TRUCO! Vale " .. data, 0)

    elseif message == "SHOW_SCOREBOARD" then
        UIManager.ShowScoreboard()

    elseif message == "HIDE_SCOREBOARD" then
        UIManager.HideScoreboard()
    
    elseif message == "HIDE_GAME_UI" then
        UIManager.SetGameplayUIVisibility(false)
    
    else
        -- Só cai aqui se for uma mensagem de texto comum (Vez de fulano, Contagem, etc.)
        -- Isso evita que nomes técnicos como "UPDATE_ROUND_VALUE" apareçam no centro da tela
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
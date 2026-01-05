local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local currentPartner = "Ninguém"
local myTeam = "A"
local lastEmoteTime = 0
local EMOTE_COOLDOWN = 3

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

Events.RequestAction.OnClientEvent:Connect(function(actionType, data)
    if actionType == "EscolhaOCorte" then 
        UIManager.ShowCutOptions(data) 
    elseif actionType == "TrucoChallenge" then
        -- data: {Value, Caller, TimeLimit}
        UIManager.ShowTrucoChallenge(data.Value, data.Caller, data.TimeLimit)
    end
end)

Events.GameStatusEvent.OnClientEvent:Connect(function(message, data)
    -- 1. SISTEMA DE VOTAÇÃO E TRUCO
    if message == "PARTNER_VOTED" then
        UIManager.UpdateChallengeStatus("Parceiro quer: " .. string.upper(data))
    
    elseif message == "WAITING_PARTNER" then
        UIManager.UpdateChallengeStatus("Aguardando seu parceiro...")
        
    elseif message == "TRUCO_TIMEOUT" then
        UIManager.HideTrucoChallenge()

    -- 2. CONTROLES DE UI
    elseif message == "HIDE_TRUCO_BTN" then
        UIManager.SetCanTruco(false)
        -- SE O BOTÃO DE TRUCO SUMIU (PQ VC OU PARCEIRO AUMENTARAM), O MENU DEVE SUMIR TAMBÉM
        UIManager.HideTrucoChallenge()
        
    elseif message == "SHOW_TRUCO_BTN" then
        UIManager.SetCanTruco(true)
        
    elseif message == "DEALING" then
        UIManager.HideCutMenu()
        UIManager.PlaySound("Shuffle")

    -- 3. EVENTOS DE VITÓRIA E ESTADO
    elseif message == "TRUCO_ACEITO" then
        UIManager.HideTrucoChallenge()
        if UIManager.ResetCamera then UIManager.ResetCamera() end
        UIManager.UpdateStatus("TRUCO ACEITO! Vale " .. data, 0)

    elseif message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        UIManager.HideTrucoChallenge()
        if UIManager.ResetCamera then UIManager.ResetCamera() end
        
        local teamResult = (message == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        UIManager.ShowRoundWinner(teamResult)

    -- 4. ATUALIZAÇÕES GERAIS
    elseif message == "CLEAR_TABLE" then
        local myTricks = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyTricks = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateRoundStats(currentPartner, myTricks, enemyTricks)
        UIManager.ClearTable()

    elseif message == "UPDATE_SCORE" then
        local myScore = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyScore = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateGameScore(myScore, enemyScore)
        
    elseif message == "UPDATE_ROUND_VALUE" then
        UIManager.UpdateRoundValue(data)

    elseif message == "TRUCO_CALLED" then
        -- IMPORTANTE: Se o Truco foi pedido/aumentado, fecha o menu anterior imediatamente
        UIManager.HideTrucoChallenge() 
        UIManager.UpdateStatus("TRUCO! Vale " .. data, 0)
        UIManager.PlaySound("Truco")

    elseif message == "SHOW_SCOREBOARD" then
        UIManager.ShowScoreboard()

    elseif message == "HIDE_SCOREBOARD" then
        UIManager.HideScoreboard()
        
    elseif message == "HIDE_GAME_UI" then
        UIManager.FullReset()

    elseif message == "SHOW_GAME_UI" then
        UIManager.SetGameplayUIVisibility(true)
        
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

Events.UpdateTurnEvent.OnClientEvent:Connect(function(playerName, trickNumber)
    UIManager.UpdateTurn(playerName, trickNumber)
end)

Events.CardPlayedOnTable.OnClientEvent:Connect(function(playerName, value, suit, isHidden)
    UIManager.AddPlayedCardUI(playerName, value, suit, isHidden)
    UIManager.PlaySound("CardPlay")
end)

local function trySendSignal(signalType)
    local now = tick()
    if now - lastEmoteTime >= EMOTE_COOLDOWN then
        lastEmoteTime = now
        Events.SignalEvent:FireServer(signalType)
        
        -- Feedback visual de cooldown (opcional)
        -- print("Sinal enviado: " .. signalType)
    else
        -- print("Aguarde para enviar outro sinal...")
    end
end

UIManager.SetEmoteCallback(trySendSignal)

Events.SignalEvent.OnClientEvent:Connect(function(sender, signalType)
    UIManager.ShowSignal(sender, signalType)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q then 
        trySendSignal("Sinal_Mao")
    elseif input.KeyCode == Enum.KeyCode.E then 
        trySendSignal("Sinal_Olhar") 
    end
end)
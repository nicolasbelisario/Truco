local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local UIManager = require(script:WaitForChild("UIManager"))
local TableVisuals = require(script:WaitForChild("TableVisuals"))
local Events = ReplicatedStorage:WaitForChild("Events")

local currentPartner = "Ninguém"
local myTeam = "A"
local lastEmoteTime = 0
local EMOTE_COOLDOWN = 3
local isTrucoPending = false

UIManager.Init()

-- Identifica em qual cadeira o jogador local está sentado
-- No init.client.luau

local function updateSitStatus(isSitting)
    UIManager.SetSeated(isSitting)
    if isSitting then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            local seatPart = char.Humanoid.SeatPart
            local seatName = seatPart.Parent.Name -- Ex: Cadeira1
            
            local tableModel = seatPart.Parent.Parent.Parent 
            
            -- Debug opcional para verificar se pegou o Model certo
            print("Sentei na mesa:", tableModel.Name) 

            TableVisuals.SetCurrentTable(tableModel)
            
            UIManager.SetMySeat(seatName)
            
            local seatNum = tonumber(seatName:match("%d+"))
            if seatNum then
                myTeam = (seatNum % 2 == 1) and "A" or "B"
            end
        end
    else
        -- Se levantar, limpa a referência da mesa
        TableVisuals.SetCurrentTable(nil)
    end
end

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("Sit"):Connect(function() updateSitStatus(hum.Sit) end)
end)

if player.Character and player.Character:FindFirstChild("Humanoid") then
    updateSitStatus(player.Character.Humanoid.Sit)
end

-- --- EVENTOS DE JOGO ---

Events.RequestAction.OnClientEvent:Connect(function(actionType, data)
    if actionType == "EscolhaOCorte" then 
        UIManager.ShowCutOptions(data) 
    elseif actionType == "TrucoChallenge" then
        -- data: {Value, Caller (string), TimeLimit}
        UIManager.ShowTrucoChallenge(data.Value, data.Caller, data.TimeLimit)
    end
end)

Events.GameStatusEvent.OnClientEvent:Connect(function(message, data)
    
    -- --- BLOCO DE TRUCO E INTERAÇÃO ---

    if message == "TRUCO_CALLED" then
        -- BLOQUEIA
        isTrucoPending = true 
        UIManager.HideTrucoChallenge() 
        UIManager.UpdateStatus("TRUCO! Vale " .. data, 0)
        UIManager.PlaySound("Truco")

    elseif message == "TRUCO_TIMEOUT" then
        -- DESBLOQUEIA E AVISA
        isTrucoPending = false
        UIManager.HideTrucoChallenge()
        UIManager.UpdateStatus("Tempo esgotado!", 0)

    elseif message == "TRUCO_ACEITO" then
        -- DESBLOQUEIA E ATUALIZA UI
        isTrucoPending = false
        UIManager.HideTrucoChallenge()
        UIManager.ResetCamera()
        UIManager.UpdateStatus("TRUCO ACEITO! Vale " .. data, 0)

    elseif message == "PARTNER_VOTED" then
        UIManager.UpdateChallengeStatus("Parceiro quer: " .. string.upper(data))
    
    elseif message == "WAITING_PARTNER" then
        UIManager.UpdateChallengeStatus("Aguardando seu parceiro...")
        
    elseif message == "HIDE_TRUCO_BTN" then
        UIManager.SetCanTruco(false)
        UIManager.HideTrucoChallenge()
        
    elseif message == "SHOW_TRUCO_BTN" then
        UIManager.SetCanTruco(true)

    -- --- BLOCO DE RODADA E VITÓRIA ---

    elseif message == "DEALING" then
        UIManager.HideCutMenu()
        UIManager.PlaySound("Shuffle")

    elseif message == "TEAM_A_WON_HAND" or message == "TEAM_B_WON_HAND" then
        -- DESBLOQUEIA O JOGO
        isTrucoPending = false 
        
        UIManager.HideTrucoChallenge()
        UIManager.ResetCamera()
        
        local winnerText = ""
        
        -- LÓGICA DE NOMES DOS JOGADORES
        if type(data) == "table" and data.Names then
            winnerText = data.Names .. " ganharam a mão!"
        else
            -- Fallback para garantir que não quebre
            local teamResult = (message == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
            winnerText = teamResult
        end
        
        UIManager.ShowRoundWinner(winnerText)

    -- --- ATUALIZAÇÕES DE STATUS E UI GERAL ---

    elseif message == "CLEAR_TABLE" then
        local myTricks = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyTricks = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateRoundStats(currentPartner, myTricks, enemyTricks)
        
        UIManager.ClearTable()
        TableVisuals.ClearTable()

    elseif message == "UPDATE_SCORE" then
        local myScore = (myTeam == "A") and data.TeamA or data.TeamB
        local enemyScore = (myTeam == "A") and data.TeamB or data.TeamA
        UIManager.UpdateGameScore(myScore, enemyScore)
        
    elseif message == "UPDATE_ROUND_VALUE" then
        UIManager.UpdateRoundValue(data)

    elseif message == "SHOW_SCOREBOARD" then
        UIManager.ShowScoreboard()

    elseif message == "HIDE_SCOREBOARD" then
        UIManager.HideScoreboard()
        
    elseif message == "HIDE_GAME_UI" then
        UIManager.FullReset()

    elseif message == "SHOW_GAME_UI" then
        UIManager.SetGameplayUIVisibility(true)

    elseif message == "MATCH_WON" then
        UIManager.ShowMatchWinner(data)
        UIManager.PlaySound("Victory")
        
    elseif message == "CUTTING" then
        UIManager.UpdateStatus("Aguardando corte...", 0)
        
    else
        UIManager.UpdateStatus(message, data)
    end
end)

Events.DealCards.OnClientEvent:Connect(function(mao, vira, partnerName)
    if partnerName then currentPartner = partnerName end
    
    UIManager.ClearHand() 
    UIManager.ClearTable()
    TableVisuals.ClearTable()
    
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
    -- Atualiza UI 2D (Isso já funcionava)
    UIManager.AddPlayedCardUI(playerName, value, suit, isHidden)
    UIManager.PlaySound("CardPlay")
    
    -- Atualiza Visual 3D
    local p = Players:FindFirstChild(playerName)
    
    if p then
        -- É um jogador real
        TableVisuals.SpawnCard(p, value, suit, isHidden)
    else
        -- >>> ALTERAÇÃO AQUI <<<
        -- Se não achou em Players, assume que é um BOT e passa a String (nome)
        TableVisuals.SpawnCard(playerName, value, suit, isHidden)
    end
end)

-- --- SINAIS ---

local function trySendSignal(signalType)
    local now = tick()
    if now - lastEmoteTime >= EMOTE_COOLDOWN then
        lastEmoteTime = now
        Events.SignalEvent:FireServer(signalType)
    end
end

UIManager.SetEmoteCallback(trySendSignal)

Events.SignalEvent.OnClientEvent:Connect(function(sender, signalType)
    -- Sender pode ser um Player ou uma String (se vier modificado do servidor para bots)
    -- Mas no nosso Match atual, bots não mandam emotes.
    if typeof(sender) == "Instance" and sender:IsA("Player") then
        UIManager.ShowSignal(sender, signalType)
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q then 
        trySendSignal("Sinal_Mao")
    elseif input.KeyCode == Enum.KeyCode.E then 
        trySendSignal("Sinal_Olhar") 
    end
end)

-- ... (seu código existente no init.client.luau) ...

-- --- SISTEMA DE MÚSICA DE FUNDO (BGM) ---
local SoundService = game:GetService("SoundService")

-- Lista de IDs (Instrumentais/Relax/Jazz para não atrapalhar o Truco)
local musicPlaylist = {
    "rbxassetid://1845341094", -- Chill Jazz    https://create.roblox.com/store/asset/1845341094/
    "rbxassetid://1848354536", -- Relaxed Scene https://create.roblox.com/store/asset/1848354536/
    "rbxassetid://1837429944", -- Soft Music    https://create.roblox.com/store/asset/1837429944/
    "rbxassetid://9043887091", -- Lo-Fi Chill A https://create.roblox.com/store/asset/9043887091/
    "rbxassetid://1838457617", -- Clair de Lune https://create.roblox.com/store/asset/1838457617/
}

local bgmObj = Instance.new("Sound")
bgmObj.Name = "BackgroundMusic"
bgmObj.Parent = SoundService
bgmObj.Volume = 0.3 -- Volume baixinho para não atrapalhar os efeitos de carta
bgmObj.Looped = false -- Deixe false para podermos trocar de música quando acabar

local function playNextSong()
    -- Escolhe uma música aleatória da lista
    local randomId = musicPlaylist[math.random(1, #musicPlaylist)]
    bgmObj.SoundId = randomId
    
    if not bgmObj.IsLoaded then
        bgmObj.Loaded:Wait()
    end
    bgmObj:Play()
end

-- Quando a música acabar, toca a próxima
bgmObj.Ended:Connect(playNextSong)

-- Começa a tocar a primeira
task.spawn(playNextSong)
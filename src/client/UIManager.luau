local UIManager = {}

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

-- Componentes da UI
local screenGui, handFrame, countdownLabel, cutFrame, timerBar, viraDisplay
local tableCenter, trucoBtn, statsLabel, statsFrame, challengeFrame, roundValueLabel, gameScoreLabel

local isSeated = false
local isMyTurn = false
local canITruco = true

-- --- INICIALIZAÇÃO ---

function UIManager.Init()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TrucoGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- Frame da Mesa (Cartas jogadas)
    tableCenter = Instance.new("Frame")
    tableCenter.Name = "TableCenter"
    tableCenter.Size = UDim2.new(0.5, 0, 0.4, 0)
    tableCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
    tableCenter.AnchorPoint = Vector2.new(0.5, 0.5)
    tableCenter.BackgroundTransparency = 1
    tableCenter.Parent = screenGui

    local grid = Instance.new("UIGridLayout", tableCenter)
    grid.CellSize = UDim2.new(0, 110, 0, 150)
    grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
    grid.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Mão do Jogador
    handFrame = Instance.new("Frame")
    handFrame.Name = "HandFrame"
    handFrame.Size = UDim2.new(0.6, 0, 0.2, 0)
    handFrame.Position = UDim2.new(0.5, 0, 0.98, 0)
    handFrame.AnchorPoint = Vector2.new(0.5, 1)
    handFrame.BackgroundTransparency = 1
    handFrame.Parent = screenGui
    
    local handLayout = Instance.new("UIListLayout", handFrame)
    handLayout.FillDirection = Enum.FillDirection.Horizontal
    handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    handLayout.Padding = UDim.new(0, 15)

    -- Labels de Status e Pontuação
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    countdownLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
    countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.new(1, 1, 1)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBlack
    countdownLabel.Text = ""
    countdownLabel.Parent = screenGui

    viraDisplay = Instance.new("TextLabel")
    viraDisplay.Size = UDim2.new(0, 180, 0, 90)
    viraDisplay.Position = UDim2.new(0.95, 0, 0.05, 0)
    viraDisplay.AnchorPoint = Vector2.new(1, 0)
    viraDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    viraDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
    viraDisplay.TextSize = 22
    viraDisplay.Font = Enum.Font.GothamBold
    viraDisplay.Visible = false
    viraDisplay.Parent = screenGui
    Instance.new("UICorner", viraDisplay)

    -- Botão de Truco
    trucoBtn = Instance.new("TextButton")
    trucoBtn.Size = UDim2.new(0, 180, 0, 80)
    trucoBtn.Position = UDim2.new(0.85, 0, 0.85, 0)
    trucoBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    trucoBtn.Text = "TRUCO!"
    trucoBtn.TextColor3 = Color3.new(1,1,1)
    trucoBtn.Font = Enum.Font.GothamBlack
    trucoBtn.TextSize = 35
    trucoBtn.Visible = false
    trucoBtn.Parent = screenGui
    Instance.new("UICorner", trucoBtn)
    
    trucoBtn.Activated:Connect(function()
        Events.TrucoEvent:FireServer("Request")
        UIManager.SetCanTruco(false)
    end)

    -- Stats Frame
    statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0, 200, 0, 100)
    statsFrame.Position = UDim2.new(0.02, 0, 0.05, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.Visible = false
    statsFrame.Parent = screenGui
    Instance.new("UICorner", statsFrame)

    statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.9, 0, 0.9, 0)
    statsLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    statsLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextColor3 = Color3.new(1, 1, 1)
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextSize = 18
    statsLabel.Text = "Dupla: ...\nNós: 0 Quedas\nEles: 0 Quedas"
    statsLabel.Parent = statsFrame

    gameScoreLabel = Instance.new("TextLabel")
    gameScoreLabel.Size = UDim2.new(0, 220, 0, 60)
    gameScoreLabel.Position = UDim2.new(0.02, 0, 0.18, 0)
    gameScoreLabel.BackgroundTransparency = 0.4
    gameScoreLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    gameScoreLabel.TextColor3 = Color3.new(1,1,1)
    gameScoreLabel.Font = Enum.Font.GothamBlack
    gameScoreLabel.TextSize = 22
    gameScoreLabel.Text = "JOGO: 0 x 0"
    gameScoreLabel.Visible = false
    gameScoreLabel.Parent = screenGui
    Instance.new("UICorner", gameScoreLabel)

    roundValueLabel = Instance.new("TextLabel")
    roundValueLabel.Size = UDim2.new(0, 150, 0, 40)
    roundValueLabel.Position = UDim2.new(0.5, 0, 0.22, 0)
    roundValueLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    roundValueLabel.BackgroundTransparency = 1
    roundValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    roundValueLabel.Font = Enum.Font.GothamBold
    roundValueLabel.TextSize = 24
    roundValueLabel.Text = "VALE: 1"
    roundValueLabel.Visible = false
    roundValueLabel.Parent = screenGui

    UIManager.CreateCutMenu()
    UIManager.CreateChallengeUI()
end

-- --- CRIAÇÃO DE MENUS AUXILIARES ---

function UIManager.CreateCutMenu()
    cutFrame = Instance.new("Frame")
    cutFrame.Size = UDim2.new(0, 400, 0, 220)
    cutFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
    cutFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    cutFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    cutFrame.Visible = false
    cutFrame.Parent = screenGui
    Instance.new("UICorner", cutFrame).CornerRadius = UDim.new(0, 15)
    
    local timerBg = Instance.new("Frame")
    timerBg.Size = UDim2.new(1, 0, 0, 6)
    timerBg.Position = UDim2.new(0, 0, 1, 0)
    timerBg.AnchorPoint = Vector2.new(0, 1)
    timerBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    timerBg.Parent = cutFrame
    
    timerBar = Instance.new("Frame")
    timerBar.Size = UDim2.new(1, 0, 1, 0)
    timerBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    timerBar.BorderSizePixel = 0
    timerBar.Parent = timerBg

    local cutTitle = Instance.new("TextLabel")
    cutTitle.Text = "SUA VEZ DE CORTAR"
    cutTitle.Size = UDim2.new(1, 0, 0.4, 0)
    cutTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cutTitle.Font = Enum.Font.GothamBold
    cutTitle.TextSize = 24
    cutTitle.BackgroundTransparency = 1
    cutTitle.Parent = cutFrame

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.9, 0, 0.4, 0)
    btnContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
    btnContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = cutFrame

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    btnLayout.Padding = UDim.new(0, 20)
    btnLayout.Parent = btnContainer

    local function createBtn(text)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Size = UDim2.new(0, 90, 0, 70)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 22
        btn.Parent = btnContainer
        Instance.new("UICorner", btn)
        
        btn.Activated:Connect(function()
            cutFrame.Visible = false
            Events.GameStatusEvent:FireServer("CutAction", tonumber(string.sub(text, 1, 1)))
        end)
    end

    createBtn("1x")
    createBtn("2x")
    createBtn("3x")
end

function UIManager.CreateChallengeUI()
    challengeFrame = Instance.new("Frame")
    challengeFrame.Name = "TrucoChallengeFrame"
    challengeFrame.Size = UDim2.new(0, 350, 0, 200)
    challengeFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
    challengeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    challengeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    challengeFrame.Visible = false
    challengeFrame.Parent = screenGui
    Instance.new("UICorner", challengeFrame)

    local txt = Instance.new("TextLabel")
    txt.Name = "Title"
    txt.Size = UDim2.new(1, 0, 0.4, 0)
    txt.TextScaled = true
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.BackgroundTransparency = 1
    txt.Parent = challengeFrame

    local function createBtn(text, color, xPos, response, btnName)
        local b = Instance.new("TextButton")
        b.Name = btnName
        b.Text = text
        b.Size = UDim2.new(0.28, 0, 0.35, 0)
        b.Position = UDim2.new(xPos, 0, 0.55, 0)
        b.BackgroundColor3 = color
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 20
        b.Parent = challengeFrame
        Instance.new("UICorner", b)
        
        b.Activated:Connect(function()
            challengeFrame.Visible = false
            UIManager.ResetCamera()
            Events.TrucoEvent:FireServer("Response", response)
        end)
    end

    createBtn("DESCER", Color3.fromRGB(0, 150, 0), 0.04, "Aceitar", "AceitarBtn")
    createBtn("FUGIR", Color3.fromRGB(150, 0, 0), 0.36, "Correr", "CorrerBtn")
    createBtn("AUMENTAR", Color3.fromRGB(200, 150, 0), 0.68, "Aumentar", "AumentarBtn")
end

-- --- FUNÇÕES VISUAIS DE JOGO ---

function UIManager.ShowCutOptions(timeLimit)
    if cutFrame then
        cutFrame.Visible = true
        timerBar.Size = UDim2.new(1, 0, 1, 0)
        local tween = TweenService:Create(timerBar, TweenInfo.new(timeLimit), {Size = UDim2.new(0, 0, 1, 0)})
        tween:Play()
        
        task.delay(timeLimit + 0.5, function()
            cutFrame.Visible = false
        end)
    end
end

function UIManager.HideCutMenu()
    if cutFrame then cutFrame.Visible = false end
end

function UIManager.AddCardToHand(val, suit)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 160)
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.Text = val .. "\n" .. suit
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Parent = handFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    btn.Activated:Connect(function()
        if isMyTurn then
            isMyTurn = false 
            Events.PlayCardEvent:FireServer(val, suit)
            btn:Destroy()
        end
    end)
end

function UIManager.AddPlayedCardUI(playerName, val, suit)
    local card = Instance.new("TextLabel")
    card.Size = UDim2.new(0, 120, 0, 170)
    card.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    card.TextColor3 = Color3.new(0, 0, 0)
    card.Font = Enum.Font.GothamBold
    card.Text = playerName .. "\n" .. val .. " " .. suit
    card.TextScaled = true
    
    card.Parent = tableCenter
    Instance.new("UICorner", card)
end

function UIManager.UpdateRoundStats(partnerName, myTeamPoints, enemyTeamPoints)
    if not statsFrame then return end
    statsFrame.Visible = isSeated
    
    local pName = partnerName or "Ninguém"
    statsLabel.Text = string.format("Sua Dupla: %s\nNós: %d Quedas\nEles: %d Quedas", pName, myTeamPoints or 0, enemyTeamPoints or 0)
end

function UIManager.ClearTable()
    for _, child in ipairs(tableCenter:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end

function UIManager.ClearHand()
    if handFrame then
        handFrame:ClearAllChildren()
        local handLayout = Instance.new("UIListLayout", handFrame)
        handLayout.FillDirection = Enum.FillDirection.Horizontal
        handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        handLayout.Padding = UDim.new(0, 15)
    end
    UIManager.HideCutMenu()
    UIManager.SetCanTruco(true)
end

-- --- CONTROLE DE ESTADO E CÂMERA ---

function UIManager.UpdateStatus(msg, val)
    if not isSeated or not countdownLabel then return end
    local display = GameConfig.StateDisplayNames[msg] or msg
    countdownLabel.Text = (val and val > 0) and (display .. " " .. val) or display
end

function UIManager.UpdateTurn(playerName)
    isMyTurn = (playerName == player.Name)
    trucoBtn.Visible = isMyTurn and canITruco
    
    local currentVal = 1
    if roundValueLabel and roundValueLabel.Text then
        currentVal = tonumber(roundValueLabel.Text:match("%d+")) or 1
    end

    if currentVal == 1 then trucoBtn.Text = "TRUCO!"
    elseif currentVal == 3 then trucoBtn.Text = "SEIS!"
    elseif currentVal == 6 then trucoBtn.Text = "NOVE!"
    elseif currentVal == 9 then trucoBtn.Text = "DOZE!"
    else trucoBtn.Visible = false end

    UIManager.UpdateStatus(isMyTurn and "SUA VEZ!" or "Vez de: " .. playerName, 0)
end

function UIManager.SetSeated(s)
    isSeated = s
    if not s then
        UIManager.ClearHand()
        UIManager.ClearTable()
        UIManager.SetGameplayUIVisibility(false)
        countdownLabel.Text = ""
    end
end

function UIManager.ShowTrucoChallenge(value, requester)
    if not challengeFrame then UIManager.CreateChallengeUI() end
    
    local title = challengeFrame:FindFirstChild("Title")
    if title then title.Text = requester .. " PEDIU " .. value .. "!" end
    
    challengeFrame.Visible = true
    
    local raiseBtn = challengeFrame:FindFirstChild("AumentarBtn")
    if raiseBtn then
        local nextVal = (value < 12) and (value + 3) or 12
        raiseBtn.Text = nextVal .. "!"
        raiseBtn.Visible = (value < 12)
    end

    UIManager.ApplyTensionCamera(requester)
end

function UIManager.HideTrucoChallenge()
    if challengeFrame then challengeFrame.Visible = false end
    UIManager.ResetCamera()
end

function UIManager.SetGameplayUIVisibility(visible)
    if statsFrame then statsFrame.Visible = visible end
    if gameScoreLabel then gameScoreLabel.Visible = visible end
    if viraDisplay then viraDisplay.Visible = visible end
    if trucoBtn then trucoBtn.Visible = false end
    if cutFrame then cutFrame.Visible = false end
end

-- --- CAMERA FX ---

function UIManager.ApplyTensionCamera(targetPlayerName)
    local targetPlayer = game.Players:FindFirstChild(targetPlayerName)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then return end

    Camera.CameraType = Enum.CameraType.Scriptable
    local targetPos = targetPlayer.Character.Head.Position + (targetPlayer.Character.Head.CFrame.LookVector * 5) + Vector3.new(0, 1, 0)
    local lookAt = targetPlayer.Character.Head.Position

    local tween = TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(targetPos, lookAt)
    })
    tween:Play()
end

function UIManager.ResetCamera()
    Camera.CameraType = Enum.CameraType.Custom
end

-- --- UTILIDADES DE SETTERS ---

function UIManager.SetMySeat(n) 
    -- mySeatName = n (variável local não usada, mas mantida caso precise no futuro)
end

function UIManager.SetCanTruco(allowed)
    canITruco = allowed
    if trucoBtn then trucoBtn.Visible = isMyTurn and canITruco end
end

function UIManager.SetVira(v, s)
    viraDisplay.Text = "VIRA:\n" .. v .. " de " .. s
    viraDisplay.Visible = isSeated
end

function UIManager.UpdateGameScore(my, enemy)
    gameScoreLabel.Text = "JOGO: "..my.." x "..enemy
end

function UIManager.UpdateRoundValue(val)
    if roundValueLabel then
        roundValueLabel.Text = "VALE: " .. tostring(val)
        roundValueLabel.Visible = isSeated
    end
end

function UIManager.ShowRoundWinner(teamName)
    local winnerLabel = Instance.new("TextLabel")
    winnerLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    winnerLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
    winnerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    winnerLabel.BackgroundTransparency = 1
    winnerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    winnerLabel.TextStrokeTransparency = 0
    winnerLabel.Font = Enum.Font.GothamBlack
    winnerLabel.TextScaled = true
    winnerLabel.Text = teamName .. " GANHOU A MÃO!"
    winnerLabel.Parent = screenGui

    task.delay(3, function()
        if winnerLabel then
            local tween = TweenService:Create(winnerLabel, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() winnerLabel:Destroy() end)
        end
    end)
end

function UIManager.ShowScoreboard()
    if isSeated and gameScoreLabel then gameScoreLabel.Visible = true end
end

function UIManager.HideScoreboard()
    if gameScoreLabel then gameScoreLabel.Visible = false end
end

function UIManager.ShowSignal(sender, signalType)
    if not sender.Character or not sender.Character:FindFirstChild("Head") then return end

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 100, 0, 100)
    bg.Adornee = sender.Character.Head
    bg.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = (signalType == "Sinal_Mao" or signalType == "LevantarMao") and "🖐️" or "👀"
    lbl.TextSize = 50
    bg.Parent = sender.Character.Head
    
    -- Efeito de Highlight temporário
    local highlight = Instance.new("Highlight")
    highlight.Adornee = sender.Character
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.new(1,1,0)
    highlight.Parent = sender.Character

    task.delay(2, function() 
        bg:Destroy() 
        highlight:Destroy()
    end)
end

return UIManager
local UIManager = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local SoundService = game:GetService("SoundService")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CardSettings = require(Shared:WaitForChild("CardSettings"))
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local GameSounds = {
    ["Shuffle"] = "rbxassetid://128706455708345", 
    ["Truco"] = "rbxassetid://7152989885", 
    ["CardPlay"] = "rbxassetid://3456145589",
    ["Victory"] = "rbxassetid://12222253",
}

-- Variáveis Globais de UI
local screenGui, handFrame, countdownLabel, cutFrame, timerBar, viraDisplay
local tableCenter, trucoBtn, statsLabel, statsFrame, challengeFrame, roundValueLabel, gameScoreLabel
local challengeTimerBar
local playOptionsFrame

local isSeated = false
local isMyTurn = false
local canITruco = true
local isTrucoPending = false
local emoteFrame
local currentTrickNumber = 1
local onEmoteRequestCallback = nil

-- --- INICIALIZAÇÃO ---

function UIManager.Init()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TrucoGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- CONTAINER DE INFORMAÇÕES
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Position = UDim2.new(0.02, 0, 0, 60) 
    infoContainer.Size = UDim2.new(0, 250, 0.5, 0)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = screenGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = infoContainer
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    -- 1. Frame da Mesa (Centro)
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

    -- 2. Mão do Jogador
    handFrame = Instance.new("Frame")
    handFrame.Name = "HandFrame"
    handFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
    handFrame.Position = UDim2.new(0.5, 0, 0.98, 0)
    handFrame.AnchorPoint = Vector2.new(0.5, 1)
    handFrame.BackgroundTransparency = 1
    handFrame.ClipsDescendants = false
    handFrame.Parent = screenGui
    
    local handLayout = Instance.new("UIListLayout", handFrame)
    handLayout.FillDirection = Enum.FillDirection.Horizontal
    handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    handLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    handLayout.Padding = UDim.new(0, 15)

    -- 3. Labels e Status
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    countdownLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
    countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.new(1, 1, 1)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBlack
    countdownLabel.Text = ""
    countdownLabel.ZIndex = 100
    countdownLabel.Parent = screenGui

    -- VIRA DISPLAY
    viraDisplay = Instance.new("Frame")
    viraDisplay.Name = "ViraDisplayFrame"
    viraDisplay.Size = UDim2.new(0, 140, 0, 220)
    viraDisplay.Position = UDim2.new(0.95, 0, 0.05, 0)
    viraDisplay.AnchorPoint = Vector2.new(1, 0)
    viraDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    viraDisplay.Visible = false
    viraDisplay.Parent = screenGui
    Instance.new("UICorner", viraDisplay)

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
    statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    statsFrame.BackgroundTransparency = 0.5
    statsFrame.Visible = false
    statsFrame.LayoutOrder = 1 
    statsFrame.Parent = infoContainer 
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

    -- Game Score Label
    gameScoreLabel = Instance.new("TextLabel")
    gameScoreLabel.Size = UDim2.new(0, 220, 0, 60)
    gameScoreLabel.BackgroundTransparency = 0.4
    gameScoreLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
    gameScoreLabel.TextColor3 = Color3.new(1,1,1)
    gameScoreLabel.Font = Enum.Font.GothamBlack
    gameScoreLabel.TextSize = 22
    gameScoreLabel.Text = "JOGO: 0 x 0"
    gameScoreLabel.Visible = false
    gameScoreLabel.LayoutOrder = 2 
    gameScoreLabel.Parent = infoContainer 
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

	local musicBtn = Instance.new("TextButton")
    musicBtn.Size = UDim2.new(0, 40, 0, 40)
    musicBtn.Position = UDim2.new(0.02, 0, 0.9, 0) -- Canto inferior esquerdo
    musicBtn.AnchorPoint = Vector2.new(0, 1)
    musicBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    musicBtn.Text = "🎵"
    musicBtn.TextSize = 20
    musicBtn.Parent = screenGui
    Instance.new("UICorner", musicBtn).CornerRadius = UDim.new(1, 0) -- Redondo

    local isMuted = false
    musicBtn.Activated:Connect(function()
        isMuted = not isMuted
        local bgm = game.SoundService:FindFirstChild("BackgroundMusic")
        if bgm then
            bgm.Volume = isMuted and 0 or 0.3
            musicBtn.Text = isMuted and "🔇" or "🎵"
            musicBtn.BackgroundColor3 = isMuted and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(40, 40, 40)
        end
    end)

    UIManager.CreateCutMenu()
    UIManager.CreateChallengeUI()
    UIManager.CreateEmoteButtons()
end

-- --- UI CREATION FUNCTIONS ---

function UIManager.SetEmoteCallback(callback)
    onEmoteRequestCallback = callback
end

function UIManager.CreateEmoteButtons()
    emoteFrame = Instance.new("Frame")
    emoteFrame.Name = "EmoteButtons"
    emoteFrame.Size = UDim2.new(0, 120, 0, 60)
    emoteFrame.Position = UDim2.new(0.98, 0, 0.85, 0)
    emoteFrame.AnchorPoint = Vector2.new(1, 1)
    emoteFrame.BackgroundTransparency = 1
    emoteFrame.Parent = screenGui
    
    local layout = Instance.new("UIListLayout", emoteFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)

    local function makeBtn(icon, signalName)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.Text = icon
        btn.TextSize = 30
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = emoteFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
        
        btn.Activated:Connect(function()
            if onEmoteRequestCallback then
                onEmoteRequestCallback(signalName)
            end
        end)
    end
    
    makeBtn("🖐️", "Sinal_Mao")
    makeBtn("👀", "Sinal_Olhar")
end

function UIManager.CreateCutMenu()
    cutFrame = Instance.new("Frame")
    cutFrame.Name = "CutFrame"
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
    challengeFrame.Size = UDim2.new(0, 350, 0, 220)
    challengeFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
    challengeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    challengeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    challengeFrame.Visible = false
    challengeFrame.Parent = screenGui
    Instance.new("UICorner", challengeFrame)

    local timerBg = Instance.new("Frame")
    timerBg.Name = "TimerBG"
    timerBg.Size = UDim2.new(1, 0, 0, 8)
    timerBg.Position = UDim2.new(0,0,1,0)
    timerBg.AnchorPoint = Vector2.new(0,1)
    timerBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    timerBg.Parent = challengeFrame
    
    challengeTimerBar = Instance.new("Frame")
    challengeTimerBar.Name = "TimerBar"
    challengeTimerBar.Size = UDim2.new(1, 0, 1, 0)
    challengeTimerBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    challengeTimerBar.BorderSizePixel = 0
    challengeTimerBar.Parent = timerBg

    local txt = Instance.new("TextLabel")
    txt.Name = "Title"
    txt.Size = UDim2.new(1, 0, 0.3, 0)
    txt.TextScaled = true
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.BackgroundTransparency = 1
    txt.Parent = challengeFrame
    
    local statusTxt = Instance.new("TextLabel")
    statusTxt.Name = "Status"
    statusTxt.Text = ""
    statusTxt.Size = UDim2.new(1, 0, 0.15, 0)
    statusTxt.Position = UDim2.new(0, 0, 0.3, 0)
    statusTxt.TextColor3 = Color3.fromRGB(255, 200, 0)
    statusTxt.BackgroundTransparency = 1
    statusTxt.Parent = challengeFrame

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
            statusTxt.Text = "Aguardando Parceiro..."
            b.BackgroundColor3 = Color3.fromRGB(100, 100, 100) 
            Events.TrucoEvent:FireServer("Response", response)
        end)
    end

    createBtn("DESCER", Color3.fromRGB(0, 150, 0), 0.04, "Aceitar", "AceitarBtn")
    createBtn("FUGIR", Color3.fromRGB(150, 0, 0), 0.36, "Correr", "CorrerBtn")
    createBtn("AUMENTAR", Color3.fromRGB(200, 150, 0), 0.68, "Aumentar", "AumentarBtn")
end

-- --- EXPOSED FUNCTIONS ---

function UIManager.UpdateChallengeStatus(msg)
    if challengeFrame and challengeFrame.Visible then
        local status = challengeFrame:FindFirstChild("Status")
        if status then status.Text = msg end
    end
end

function UIManager.ShowTrucoChallenge(value, requester, timeLimit)
    if not challengeFrame then UIManager.CreateChallengeUI() end
    
    local title = challengeFrame:FindFirstChild("Title")
    local status = challengeFrame:FindFirstChild("Status")
    
    -- Se o requester for bot, o nome já vem como string (ex: "Bot_2")
    if title then title.Text = requester .. " PEDIU " .. value .. "!" end
    if status then status.Text = "Decidam juntos!" end
    
    local acceptBtn = challengeFrame:FindFirstChild("AceitarBtn")
    local runBtn = challengeFrame:FindFirstChild("CorrerBtn")
    local raiseBtn = challengeFrame:FindFirstChild("AumentarBtn")
    
    if acceptBtn then acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0) end
    if runBtn then runBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0) end
    if raiseBtn then 
        raiseBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        local nextVal = (value < 12) and (value + 3) or 12
        raiseBtn.Text = nextVal .. "!"
        raiseBtn.Visible = (value < 12)
    end

    challengeFrame.Visible = true
    UIManager.ApplyTensionCamera(requester)
    
    if challengeTimerBar then
        challengeTimerBar.Size = UDim2.new(1, 0, 1, 0)
        if timeLimit and timeLimit > 0 then
            local tweenInfo = TweenInfo.new(timeLimit, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(challengeTimerBar, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
            tween:Play()
        end
    end
end

function UIManager.HideTrucoChallenge()
    if challengeFrame then challengeFrame.Visible = false end
    UIManager.ResetCamera()
end

function UIManager.ShowCutOptions(timeLimit)
    if cutFrame then
        cutFrame.Visible = true
        timerBar.Size = UDim2.new(1, 0, 1, 0)
        local tweenInfo = TweenInfo.new(timeLimit, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(timerBar, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
        tween:Play()
        
        task.delay(timeLimit + 0.5, function()
            if cutFrame.Visible then cutFrame.Visible = false end
        end)
    end
end

function UIManager.HideCutMenu()
    if cutFrame then cutFrame.Visible = false end
end

function UIManager.FullReset()
    UIManager.ClearHand()
    UIManager.ClearTable()
    UIManager.SetGameplayUIVisibility(false)
    UIManager.HideScoreboard()
    UIManager.HideTrucoChallenge()
    if countdownLabel then countdownLabel.Text = "" end
end

-- --- GAMEPLAY UI ---

function UIManager.AddCardToHand(val, suit)
    local wrapper = Instance.new("Frame")
    wrapper.Name = "CardWrapper"
    wrapper.ClipsDescendants = false
    wrapper.Size = UDim2.new(0, 110, 0, 160)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = handFrame

    local btn = Instance.new("ImageButton")
    btn.Name = val .. "_" .. suit
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    
    local key = val .. "_" .. suit
    btn.Image = CardSettings.Images[key] or ""
    btn.Parent = wrapper
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        wrapper.ZIndex = 10 
        btn:TweenPosition(UDim2.new(0, 0, -0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)

    btn.MouseLeave:Connect(function()
        wrapper.ZIndex = 1 
        btn:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)

    btn.Activated:Connect(function()
        if not isMyTurn then return end

		if isTrucoPending then return end
        
        if currentTrickNumber >= 2 then 
            wrapper.ZIndex = 20 
            UIManager.ShowPlayOptions(btn, val, suit, wrapper)
        else
            isMyTurn = false 
            Events.PlayCardEvent:FireServer(val, suit, false)
            wrapper:Destroy()
            UIManager.HidePlayOptions()
        end
    end)
end

function UIManager.ShowPlayOptions(cardBtn, val, suit, wrapper)
    if playOptionsFrame then playOptionsFrame:Destroy() end
    
    local menuWidth = 160
    local menuHeight = 110

    playOptionsFrame = Instance.new("Frame")
    playOptionsFrame.Name = "OpcoesJogada"
    playOptionsFrame.Size = UDim2.new(0, menuWidth, 0, menuHeight)
    playOptionsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35) 
    playOptionsFrame.BackgroundTransparency = 0.05
    playOptionsFrame.ZIndex = 100
    playOptionsFrame.AnchorPoint = Vector2.new(0.5, 1) 
    
    local absPos = cardBtn.AbsolutePosition
    local absSize = cardBtn.AbsoluteSize
    playOptionsFrame.Position = UDim2.new(0, absPos.X + (absSize.X / 2), 0, absPos.Y + 50)
    playOptionsFrame.Parent = screenGui 
    
    Instance.new("UICorner", playOptionsFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", playOptionsFrame)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    
    local padding = Instance.new("UIPadding", playOptionsFrame)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    
    local layout = Instance.new("UIListLayout", playOptionsFrame)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function makeOptBtn(txt, color, hidden)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0.5, -4)
        b.BackgroundColor3 = color
        b.Text = txt
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.ZIndex = 101
        b.AutoButtonColor = false
        b.Parent = playOptionsFrame
        
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        end)
        
        b.Activated:Connect(function()
            isMyTurn = false
            Events.PlayCardEvent:FireServer(val, suit, hidden)
            wrapper:Destroy()
            playOptionsFrame:Destroy()
        end)
    end
    
    makeOptBtn("JOGAR ABERTA", Color3.fromRGB(39, 174, 96), false)
    makeOptBtn("JOGAR COBERTA", Color3.fromRGB(90, 90, 90), true)
end

function UIManager.HidePlayOptions()
    if playOptionsFrame then playOptionsFrame:Destroy() end
end

function UIManager.AddPlayedCardUI(playerName, val, suit, isHidden)
    local card = Instance.new("ImageLabel")
    card.Size = UDim2.new(0, 110, 0, 160)
    card.BackgroundTransparency = 1
    
    if isHidden then
        card.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"
    else
        local key = val .. "_" .. suit
        card.Image = CardSettings.Images[key] or ""
    end
    
    local tag = Instance.new("TextLabel")
    tag.Text = playerName
    tag.Size = UDim2.new(1.2, 0, 0.2, 0)
    tag.Position = UDim2.new(0.5, 0, 0, -5)
    tag.AnchorPoint = Vector2.new(0.5, 1)
    tag.BackgroundTransparency = 1
    tag.TextColor3 = Color3.new(1, 1, 1)
    tag.Font = Enum.Font.GothamBlack
    tag.TextScaled = true
    tag.Parent = card
    
    local constraint = Instance.new("UITextSizeConstraint", tag)
    constraint.MaxTextSize = 18
    local stroke = Instance.new("UIStroke", tag)
    stroke.Thickness = 2
    
    card.Parent = tableCenter
end

function UIManager.UpdateRoundStats(partnerName, myTeamPoints, enemyTeamPoints)
    if not statsFrame then return end
    statsFrame.Visible = isSeated
    local pName = partnerName or "Ninguém"
    statsLabel.Text = string.format("Sua Dupla: %s\nNós: %d Quedas\nEles: %d Quedas", pName, myTeamPoints or 0, enemyTeamPoints or 0)
end

function UIManager.ClearTable()
    for _, child in ipairs(tableCenter:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end

function UIManager.ClearHand()
    if handFrame then
        handFrame:ClearAllChildren()
        local handLayout = Instance.new("UIListLayout", handFrame)
        handLayout.FillDirection = Enum.FillDirection.Horizontal
        handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        handLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        handLayout.Padding = UDim.new(0, 15)
    end
    UIManager.HideCutMenu()
    UIManager.SetCanTruco(true)
end

function UIManager.UpdateStatus(msg, val)
    if not countdownLabel then return end
    
    local display = GameConfig.StateDisplayNames[msg] or msg
    
    -- Correção de segurança: Garante que 'val' seja tratado como número
    local numeroVal = tonumber(val)
    
    if numeroVal and numeroVal > 0 then
        countdownLabel.Text = display .. " " .. numeroVal
    else
        countdownLabel.Text = display
    end
    
    countdownLabel.Visible = true
    countdownLabel.ZIndex = 100 
end

function UIManager.UpdateTurn(playerName, trickNumber) 
    isMyTurn = (playerName == player.Name)
    currentTrickNumber = trickNumber or 1 
    
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

    if isMyTurn then
        UIManager.UpdateStatus("SUA VEZ!", 0)
        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        UIManager.UpdateStatus("Vez de: " .. playerName, 0)
        countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

function UIManager.SetSeated(s)
    isSeated = s
    if not s then UIManager.FullReset() end
end

function UIManager.SetGameplayUIVisibility(visible)
    if statsFrame then statsFrame.Visible = visible end
    if gameScoreLabel then gameScoreLabel.Visible = visible end
    if viraDisplay then viraDisplay.Visible = visible end
    if roundValueLabel then roundValueLabel.Visible = visible end
    if trucoBtn then trucoBtn.Visible = false end
    if cutFrame then cutFrame.Visible = false end
end

function UIManager.SetMySeat(n) end

function UIManager.SetCanTruco(allowed)
    canITruco = allowed
    if trucoBtn then trucoBtn.Visible = isMyTurn and canITruco end
end

function UIManager.SetVira(val, suit)
    for _, child in ipairs(viraDisplay:GetChildren()) do
        if not child:IsA("UICorner") then child:Destroy() end
    end
    
    viraDisplay.Visible = isSeated
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = "VIRA"
    titleLbl.Size = UDim2.new(1, 0, 0.2, 0)
    titleLbl.Position = UDim2.new(0, 0, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextScaled = true
    titleLbl.Parent = viraDisplay

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 80, 0, 115) 
    img.Position = UDim2.new(0.5, 0, 0.5, 0)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.BackgroundTransparency = 1
    img.Parent = viraDisplay
    
    local key = val .. "_" .. suit
    if CardSettings.Images[key] then
        img.Image = CardSettings.Images[key]
    end

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text = val .. " " .. suit
    nameLbl.Size = UDim2.new(1, 0, 0.2, 0)
    nameLbl.Position = UDim2.new(0, 0, 0.8, 0) 
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.new(1, 1, 1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 18
    nameLbl.Parent = viraDisplay
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
    -- Verificação de segurança: Sender precisa ter Character e Head
    if not sender or not sender.Character or not sender.Character:FindFirstChild("Head") then return end

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

-- --- CAMERA FX ---

function UIManager.ApplyTensionCamera(targetPlayerName)
    local targetPlayer = Players:FindFirstChild(targetPlayerName)
    -- Se for Bot ou jogador não encontrado, não faz o efeito de câmera
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

function UIManager.PlaySound(soundName)
    local soundId = GameSounds[soundName]
    if not soundId then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1
    sound.Parent = SoundService
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    
    sound:Play()
end

function UIManager.ShowMatchWinner(text)
    local darkenBG = Instance.new("Frame")
    darkenBG.Name = "VictoryDarkenBG"
    darkenBG.Size = UDim2.new(1, 0, 1, 0)
    darkenBG.BackgroundColor3 = Color3.new(0, 0, 0)
    darkenBG.BackgroundTransparency = 1 
    darkenBG.ZIndex = 200 
    darkenBG.Parent = screenGui
    
    local lbl = Instance.new("TextLabel")
    lbl.Name = "VictoryLabel"
    lbl.Text = text
    lbl.Size = UDim2.new(0.9, 0, 0.2, 0)
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextScaled = true
    lbl.TextTransparency = 1 
    lbl.ZIndex = 201 
    lbl.Parent = screenGui 
    
    local stroke = Instance.new("UIStroke", lbl)
    stroke.Thickness = 3
    stroke.Color = Color3.new(1, 1, 1) 
    stroke.Transparency = 1
    
    TweenService:Create(darkenBG, TweenInfo.new(1), {BackgroundTransparency = 0.3}):Play()
    
    local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    TweenService:Create(lbl, tweenInfo, {TextTransparency = 0, Size = UDim2.new(0.95, 0, 0.25, 0)}):Play()
    TweenService:Create(stroke, TweenInfo.new(1), {Transparency = 0}):Play()
    
    task.delay(9, function()
        TweenService:Create(darkenBG, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
        local textFadeOut = TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1})
        TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
        textFadeOut:Play()
        
        textFadeOut.Completed:Connect(function()
            darkenBG:Destroy()
            lbl:Destroy()
        end)
    end)
end

function UIManager.SetInteractionLock(locked)
    isLocked = locked
end

return UIManager
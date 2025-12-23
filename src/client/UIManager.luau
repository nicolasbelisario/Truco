local UIManager = {}

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TweenService = game:GetService("TweenService")

-- Referencias globais da UI
local screenGui
local handFrame
local countdownLabel
local cutFrame
local timerBar
local viraDisplay
local tableCenter
local trucoBtn
local statsLabel
local statsFrame

local isSeated = false
local isMyTurn = false
local mySeatName = ""

function UIManager.Init()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TrucoGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    -- Frame para as Cartas na Mesa (Centro)
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

    -- Frame da Mão do Jogador
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

    -- Status Central (Corrigido para não aparecer "Label")
    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Name = "CountdownLabel"
    countdownLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
    countdownLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
    countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.new(1, 1, 1)
    countdownLabel.TextScaled = true
    countdownLabel.Font = Enum.Font.GothamBlack
    countdownLabel.Text = "" -- Crucial para evitar o bug da imagem
    countdownLabel.Parent = screenGui

    -- Vira Display (Estilo Escuro/Dourado)
    viraDisplay = Instance.new("TextLabel")
    viraDisplay.Name = "ViraDisplay"
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
    trucoBtn.Name = "TrucoBtn"
    trucoBtn.Size = UDim2.new(0, 140, 0, 60)
    trucoBtn.Position = UDim2.new(0.85, 0, 0.85, 0)
    trucoBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    trucoBtn.Text = "TRUCO!"
    trucoBtn.TextColor3 = Color3.new(1,1,1)
    trucoBtn.Font = Enum.Font.GothamBlack
    trucoBtn.Visible = false
    trucoBtn.Parent = screenGui
    Instance.new("UICorner", trucoBtn)
    
    trucoBtn.Activated:Connect(function()
        Events.TrucoEvent:FireServer("Request")
        trucoBtn.Visible = false
    end)

    -- Menu de Corte
    UIManager.CreateCutMenu()

    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
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
end

function UIManager.UpdateRoundStats(partnerName, myTeamPoints, enemyTeamPoints)
    if not statsFrame then return end
    
    statsFrame.Visible = isSeated -- Só aparece se estiver sentado
    
    local pName = partnerName or "Ninguém"
    local mPoints = myTeamPoints or 0
    local ePoints = enemyTeamPoints or 0

    statsLabel.Text = string.format(
        "Sua Dupla: %s\nNós: %d Quedas\nEles: %d Quedas",
        pName, mPoints, ePoints
    )
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

function UIManager.ShowCutOptions(timeLimit)
    if cutFrame then
        cutFrame.Visible = true
        timerBar.Size = UDim2.new(1, 0, 1, 0)
        local tweenInfo = TweenInfo.new(timeLimit, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(timerBar, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
        tween:Play()
    end
end

function UIManager.UpdateStatus(msg, val)
    if not isSeated or not countdownLabel then return end
    local display = GameConfig.StateDisplayNames[msg] or msg
    countdownLabel.Text = val > 0 and (display .. " " .. val) or display
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
            Events.PlayCardEvent:FireServer(val, suit)
            btn:Destroy()
            isMyTurn = false
        end
    end)
end

function UIManager.AddPlayedCardUI(playerName, val, suit)
    -- REMOVIDO: A limpeza automática que causava o bug de aparecer só 1 carta
    -- Agora a limpeza é feita apenas pelo evento CLEAR_TABLE do servidor
    
    local card = Instance.new("TextLabel")
    card.Size = UDim2.new(0, 120, 0, 170)
    card.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    card.TextColor3 = Color3.new(0, 0, 0)
    card.Font = Enum.Font.GothamBold
    card.Text = playerName .. "\n" .. val .. " " .. suit
    card.TextScaled = true
    
    local padding = Instance.new("UIPadding", card)
    padding.PaddingTop = UDim.new(0.1, 0)
    
    card.Parent = tableCenter
    Instance.new("UICorner", card)
end

function UIManager.ShowRoundWinner(teamName)
    local winnerLabel = Instance.new("TextLabel")
    winnerLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    winnerLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
    winnerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    winnerLabel.BackgroundTransparency = 1
    winnerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado para vitória
    winnerLabel.TextStrokeTransparency = 0 -- Borda preta para ler melhor
    winnerLabel.Font = Enum.Font.GothamBlack
    winnerLabel.TextScaled = true
    winnerLabel.Text = teamName .. " VENCEU A MÃO!"
    winnerLabel.ZIndex = 10 -- Garante que fique por cima das cartas
    winnerLabel.Parent = screenGui

    task.delay(3, function()
        local tween = TweenService:Create(winnerLabel, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function() winnerLabel:Destroy() end)
    end)
end

function UIManager.ClearTable()
    for _, child in ipairs(tableCenter:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end

function UIManager.UpdateTurn(playerName)
    -- Se o nome recebido for igual ao seu nome no Roblox
    isMyTurn = (playerName == player.Name)
    
    local displayName = isMyTurn and "SUA VEZ!" or "Vez de: " .. playerName
    trucoBtn.Visible = isMyTurn
    UIManager.UpdateStatus(displayName, 0)
end

function UIManager.SetVira(v, s)
    viraDisplay.Text = "VIRA:\n" .. v .. " de " .. s
    viraDisplay.Visible = isSeated
end

function UIManager.SetSeated(s)
    isSeated = s
    if not s then
        handFrame:ClearAllChildren()
        tableCenter:ClearAllChildren()
        viraDisplay.Visible = false
        countdownLabel.Text = ""
        cutFrame.Visible = false
        if statsFrame then statsFrame.Visible = false end
    end
end

function UIManager.SetMySeat(n) 
    mySeatName = n 
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
    task.delay(2, function() bg:Destroy() end)
end

function UIManager.ClearHand()
    if handFrame then
        handFrame:ClearAllChildren()
        -- Recria o layout se necessário (já que ClearAllChildren apaga o UIListLayout)
        local handLayout = Instance.new("UIListLayout", handFrame)
        handLayout.FillDirection = Enum.FillDirection.Horizontal
        handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        handLayout.Padding = UDim.new(0, 15)
    end
end

function UIManager.ShowRoundWinner(teamName)
    local winnerLabel = Instance.new("TextLabel")
    winnerLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
    winnerLabel.Position = UDim2.new(0.5, 0, 0.4, 0)
    winnerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    winnerLabel.BackgroundTransparency = 1
    winnerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    winnerLabel.TextStrokeTransparency = 0
    winnerLabel.Font = Enum.Font.GothamBlack
    winnerLabel.TextScaled = true
    winnerLabel.Text = teamName .. " GANHOU A MÃO!"
    winnerLabel.Parent = screenGui

    -- Animação simples de fade out
    task.delay(3, function()
        local tween = TweenService:Create(winnerLabel, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function() winnerLabel:Destroy() end)
    end)
end

return UIManager

-- local UIManager = {}

-- local player = game.Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local Events = ReplicatedStorage:WaitForChild("Events")
-- local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- local screenGui, handFrame, countdownLabel, cutFrame, timerBar, viraDisplay, tableCenter
-- local isSeated, isMyTurn = false, false
-- local mySeatName = ""

-- function UIManager.Init()
--     screenGui = Instance.new("ScreenGui")
--     screenGui.Name = "TrucoGui"
--     screenGui.ResetOnSpawn = false
--     screenGui.Parent = playerGui

--     -- Frame da Mão (Jogador)
--     handFrame = Instance.new("Frame")
--     handFrame.Name = "HandFrame"
--     handFrame.Size = UDim2.new(0.5, 0, 0.2, 0)
--     handFrame.Position = UDim2.new(0.5, 0, 0.98, 0)
--     handFrame.AnchorPoint = Vector2.new(0.5, 1)
--     handFrame.BackgroundTransparency = 1
--     handFrame.Parent = screenGui
    
--     local handLayout = Instance.new("UIListLayout", handFrame)
--     handLayout.FillDirection = Enum.FillDirection.Horizontal
--     handLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     handLayout.Padding = UDim.new(0, 15)

--     -- Centro da Mesa (Cartas Jogadas)
--     tableCenter = Instance.new("Frame")
--     tableCenter.Name = "TableCenter"
--     tableCenter.Size = UDim2.new(0.4, 0, 0.3, 0)
--     tableCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
--     tableCenter.AnchorPoint = Vector2.new(0.5, 0.5)
--     tableCenter.BackgroundTransparency = 1
--     tableCenter.Parent = screenGui

--     local tableLayout = Instance.new("UIGridLayout", tableCenter)
--     tableLayout.CellSize = UDim2.new(0, 110, 0, 150)
--     tableLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     tableLayout.VerticalAlignment = Enum.VerticalAlignment.Center

--     -- Botão de Truco
--     trucoBtn = Instance.new("TextButton")
--     trucoBtn.Size = UDim2.new(0, 120, 0, 50)
--     trucoBtn.Position = UDim2.new(0.85, 0, 0.8, 0)
--     trucoBtn.Text = "TRUCO!"
--     trucoBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
--     trucoBtn.Font = Enum.Font.GothamBlack
--     trucoBtn.TextColor3 = Color3.new(1,1,1)
--     trucoBtn.Visible = false
--     trucoBtn.Parent = screenGui
--     Instance.new("UICorner", trucoBtn)
--     trucoBtn.Activated:Connect(function() Events.TrucoEvent:FireServer("Request") end)

--     -- Status e Vira
--     countdownLabel = Instance.new("TextLabel")
--     countdownLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
--     countdownLabel.Position = UDim2.new(0.5, 0, 0.15, 0)
--     countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
--     countdownLabel.BackgroundTransparency = 1
--     countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
--     countdownLabel.TextScaled = true
--     countdownLabel.Font = Enum.Font.GothamBlack
--     countdownLabel.Parent = screenGui

--     viraDisplay = Instance.new("TextLabel")
--     viraDisplay.Size = UDim2.new(0, 200, 0, 100)
--     viraDisplay.Position = UDim2.new(0.95, 0, 0.05, 0)
--     viraDisplay.AnchorPoint = Vector2.new(1, 0)
--     viraDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
--     viraDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
--     viraDisplay.TextSize = 24
--     viraDisplay.Visible = false
--     viraDisplay.Parent = screenGui
--     Instance.new("UICorner", viraDisplay)

--     -- Menu de Corte
--     cutFrame = Instance.new("Frame")
--     cutFrame.Size = UDim2.new(0, 500, 0, 300) -- Menu maior
--     cutFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
--     cutFrame.AnchorPoint = Vector2.new(0.5, 0.5)
--     cutFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
--     cutFrame.Visible = false
--     cutFrame.Parent = screenGui
--     Instance.new("UICorner", cutFrame).CornerRadius = UDim.new(0, 20)

--     local cutTitle = Instance.new("TextLabel")
--     cutTitle.Text = "SUA VEZ DE CORTAR"
--     cutTitle.Size = UDim2.new(1, 0, 0.3, 0)
--     cutTitle.TextSize = 40
--     cutTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
--     cutTitle.Font = Enum.Font.GothamBold
--     cutTitle.BackgroundTransparency = 1
--     cutTitle.Parent = cutFrame

--     local timerBg = Instance.new("Frame")
--     timerBg.Size = UDim2.new(1, 0, 0, 10)
--     timerBg.Position = UDim2.new(0, 0, 1, 0)
--     timerBg.AnchorPoint = Vector2.new(0, 1)
--     timerBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
--     timerBg.Parent = cutFrame
    
--     timerBar = Instance.new("Frame")
--     timerBar.Size = UDim2.new(1, 0, 1, 0)
--     timerBar.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
--     timerBar.BorderSizePixel = 0
--     timerBar.Parent = timerBg

--     local btnContainer = Instance.new("Frame")
--     btnContainer.Size = UDim2.new(0.9, 0, 0.5, 0)
--     btnContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
--     btnContainer.AnchorPoint = Vector2.new(0.5, 0.5)
--     btnContainer.BackgroundTransparency = 1
--     btnContainer.Parent = cutFrame
--     local layout = Instance.new("UIListLayout", btnContainer)
--     layout.FillDirection = Enum.FillDirection.Horizontal
--     layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     layout.Padding = UDim.new(0, 25)

--     local function createBtn(txt)
--         local b = Instance.new("TextButton")
--         b.Text = txt
--         b.Size = UDim2.new(0, 120, 0, 100) -- Botões de corte maiores
--         b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
--         b.TextColor3 = Color3.fromRGB(255, 255, 255)
--         b.TextSize = 35
--         b.Font = Enum.Font.GothamBold
--         b.Parent = btnContainer
--         Instance.new("UICorner", b)
--         b.Activated:Connect(function()
--             cutFrame.Visible = false
--             Events.GameStatusEvent:FireServer("CutAction", tonumber(string.sub(txt, 1, 1)))
--         end)
--     end
--     createBtn("1x"); createBtn("2x"); createBtn("3x")

--     local tableFrame = Instance.new("Frame")
--     tableFrame.Name = "TableCenter"
--     tableFrame.Size = UDim2.new(0.4, 0, 0.4, 0)
--     tableFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
--     tableFrame.AnchorPoint = Vector2.new(0.5, 0.5)
--     tableFrame.BackgroundTransparency = 1
--     tableFrame.Parent = screenGui

--     -- Função para mostrar sinal (ex: levantar a mão)
--     function UIManager.ShowSignal(player, signalType)
--         local billboard = Instance.new("BillboardGui")
--         billboard.Size = UDim2.new(0, 50, 0, 50)
--         billboard.Adornee = player.Character.Head
--         -- Adicione um ícone ou emoji de acordo com o signalType
--         billboard.Parent = player.Character.Head
--         task.delay(2, function() billboard:Destroy() end)
--     end

--     function UIManager.AddPlayedCardUI(playerName, value, suit)
--         local card = Instance.new("TextLabel")
--         card.Size = UDim2.new(0, 100, 0, 140)
--         card.Text = value .. "\n" .. suit
--         -- Lógica para posicionar a carta em círculo ou cruz no centro baseado no seat do jogador
--         card.Parent = tableFrame
        
--         -- Som de carta jogada
--         local sound = Instance.new("Sound", game.SoundService)
--         sound.SoundId = "rbxassetid://3456145589"
--         sound:Play()
--     end

--     UserInputService.InputBegan:Connect(function(input, gpe)
--         if gpe then return end
--         if input.KeyCode == Enum.KeyCode.Q then Events.SignalEvent:FireServer("Sinal_Mao")
--         elseif input.KeyCode == Enum.KeyCode.E then Events.SignalEvent:FireServer("Sinal_Olhar") end
--     end)
    
-- end

-- function UIManager.UpdateStatus(message, value)
--     if not isSeated then return end
--     local displayName = GameConfig.StateDisplayNames[message] or message
--     countdownLabel.Text = value > 0 and (displayName .. " " .. value) or displayName
-- end

-- function UIManager.AddCardToHand(cardValue, cardSuit)
--     local btn = Instance.new("TextButton")
--     btn.Size = UDim2.new(0, 120, 0, 180)
--     btn.Text = cardValue .. "\n" .. cardSuit
--     btn.Font = Enum.Font.GothamBold
--     btn.Parent = handFrame
--     Instance.new("UICorner", btn)

--     btn.Activated:Connect(function()
--         if isMyTurn then
--             Events.PlayCardEvent:FireServer(cardValue, cardSuit)
--             btn:Destroy()
--             isMyTurn = false
--         end
--     end)
-- end

-- function UIManager.AddPlayedCardUI(playerName, value, suit)
--     local card = Instance.new("TextLabel")
--     card.Size = UDim2.new(0, 110, 0, 150)
--     card.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
--     card.Text = playerName .. "\n" .. value .. " " .. suit
--     card.TextColor3 = Color3.fromRGB(0, 0, 0)
--     card.Font = Enum.Font.GothamBold
--     card.Parent = tableCenter
--     Instance.new("UICorner", card)

--     -- Se já temos 4 cartas, limpa após um tempo
--     if #tableCenter:GetChildren() > 4 then
--         task.delay(3, function()
--             for _, c in ipairs(tableCenter:GetChildren()) do
--                 if c:IsA("TextLabel") then c:Destroy() end
--             end
--         end)
--     end
-- end

-- function UIManager.SetVira(value, suit)
--     viraDisplay.Text = "VIRA:\n" .. value .. " de " .. suit
--     viraDisplay.Visible = isSeated
-- end

-- function UIManager.UpdateTurn(activeSeatName)
--     isMyTurn = (mySeatName == activeSeatName)
--     UIManager.UpdateStatus(isMyTurn and "SUA VEZ!" or "Vez de: " .. activeSeatName, 0)
-- end

-- function UIManager.SetSeated(status)
--     isSeated = status
--     if not status then 
--         handFrame:ClearAllChildren()
--         viraDisplay.Visible = false
--     end
-- end

-- function UIManager.SetMySeat(seatName) mySeatName = seatName end

-- return UIManager

-- local UIManager = {}

-- local player = game.Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local Events = ReplicatedStorage:WaitForChild("Events")
-- local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- -- Referencias globais da UI
-- local screenGui
-- local handFrame
-- local countdownLabel
-- local cutFrame
-- local timerBar
-- local viraDisplay
-- local playedCardsFrame 
-- local isSeated = false
-- local isMyTurn = false
-- local mySeatName = ""

-- function UIManager.Init()
--     screenGui = Instance.new("ScreenGui")
--     screenGui.Name = "TrucoGui"
--     screenGui.ResetOnSpawn = false
--     screenGui.IgnoreGuiInset = true
--     screenGui.Parent = playerGui

--     -- Frame da Mão
--     handFrame = Instance.new("Frame")
--     handFrame.Name = "HandFrame"
--     handFrame.Size = UDim2.new(0.5, 0, 0.2, 0)
--     handFrame.Position = UDim2.new(0.5, 0, 0.95, 0)
--     handFrame.AnchorPoint = Vector2.new(0.5, 1)
--     handFrame.BackgroundTransparency = 1
--     handFrame.Parent = screenGui

--     local layout = Instance.new("UIListLayout")
--     layout.FillDirection = Enum.FillDirection.Horizontal
--     layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     layout.VerticalAlignment = Enum.VerticalAlignment.Center
--     layout.Padding = UDim.new(0, 20)
--     layout.Parent = handFrame

--     -- Status/Countdown
--     countdownLabel = Instance.new("TextLabel")
--     countdownLabel.Name = "CountdownLabel"
--     countdownLabel.Size = UDim2.new(1, 0, 0.1, 0)
--     countdownLabel.Position = UDim2.new(0, 0, 0.25, 0)
--     countdownLabel.BackgroundTransparency = 1
--     countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
--     countdownLabel.TextSize = 45
--     countdownLabel.Font = Enum.Font.GothamBlack
--     countdownLabel.Text = "" 
--     countdownLabel.Parent = screenGui

--     -- Vira Display (Correção: Sem texto inicial e invisível)
--     viraDisplay = Instance.new("TextLabel")
--     viraDisplay.Name = "ViraDisplay"
--     viraDisplay.Size = UDim2.new(0, 150, 0, 80)
--     viraDisplay.Position = UDim2.new(0.98, 0, 0.02, 0)
--     viraDisplay.AnchorPoint = Vector2.new(1, 0)
--     viraDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
--     viraDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
--     viraDisplay.Font = Enum.Font.GothamBold
--     viraDisplay.TextSize = 18
--     viraDisplay.Text = "" 
--     viraDisplay.Visible = false 
--     viraDisplay.Parent = screenGui
--     Instance.new("UICorner", viraDisplay)

--     -- Frame para Cartas Jogadas na Mesa
--     playedCardsFrame = Instance.new("Frame")
--     playedCardsFrame.Name = "PlayedCardsUI"
--     playedCardsFrame.Size = UDim2.new(0.6, 0, 0.2, 0)
--     playedCardsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
--     playedCardsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
--     playedCardsFrame.BackgroundTransparency = 1
--     playedCardsFrame.Parent = screenGui
    
--     local pLayout = Instance.new("UIListLayout")
--     pLayout.FillDirection = Enum.FillDirection.Horizontal
--     pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     pLayout.Padding = UDim.new(0, 15)
--     pLayout.Parent = playedCardsFrame

--     -- RECUPERADO: Criação do cutFrame
--     cutFrame = Instance.new("Frame")
--     cutFrame.Name = "CutFrame"
--     cutFrame.Size = UDim2.new(0, 380, 0, 200)
--     cutFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
--     cutFrame.AnchorPoint = Vector2.new(0.5, 0.5)
--     cutFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
--     cutFrame.Visible = false
--     cutFrame.Parent = screenGui
--     Instance.new("UICorner", cutFrame).CornerRadius = UDim.new(0, 15)
    
--     local timerBg = Instance.new("Frame")
--     timerBg.Size = UDim2.new(1, 0, 0, 5)
--     timerBg.Position = UDim2.new(0, 0, 1, 0)
--     timerBg.AnchorPoint = Vector2.new(0, 1)
--     timerBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
--     timerBg.Parent = cutFrame
    
--     timerBar = Instance.new("Frame")
--     timerBar.Size = UDim2.new(1, 0, 1, 0)
--     timerBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
--     timerBar.Parent = timerBg

--     local cutTitle = Instance.new("TextLabel")
--     cutTitle.Text = "SUA VEZ DE CORTAR"
--     cutTitle.Size = UDim2.new(1, 0, 0.4, 0)
--     cutTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
--     cutTitle.BackgroundTransparency = 1
--     cutTitle.Parent = cutFrame

--     local btnContainer = Instance.new("Frame")
--     btnContainer.Size = UDim2.new(0.9, 0, 0.4, 0)
--     btnContainer.Position = UDim2.new(0.5, 0, 0.7, 0)
--     btnContainer.AnchorPoint = Vector2.new(0.5, 0.5)
--     btnContainer.BackgroundTransparency = 1
--     btnContainer.Parent = cutFrame

--     local btnLayout = Instance.new("UIListLayout")
--     btnLayout.FillDirection = Enum.FillDirection.Horizontal
--     btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
--     btnLayout.Padding = UDim.new(0, 20)
--     btnLayout.Parent = btnContainer

--     local function createModernButton(text)
--         local btn = Instance.new("TextButton")
--         btn.Text = text
--         btn.Size = UDim2.new(0, 90, 0, 70)
--         btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
--         btn.TextColor3 = Color3.fromRGB(255, 255, 255)
--         btn.Font = Enum.Font.GothamBold
--         btn.Parent = btnContainer
--         Instance.new("UICorner", btn)
--         btn.Activated:Connect(function()
--             cutFrame.Visible = false
--             Events.GameStatusEvent:FireServer("CutAction", tonumber(string.sub(text, 1, 1)))
--         end)
--     end

--     createModernButton("1x")
--     createModernButton("2x")
--     createModernButton("3x")
-- end

-- function UIManager.ShowCutOptions(timeLimit)
--     if cutFrame then
--         cutFrame.Visible = true
--         timerBar.Size = UDim2.new(1, 0, 1, 0)
--         timerBar:TweenSize(UDim2.new(0, 0, 1, 0), "Linear", "Quad", timeLimit, true)
--     end
-- end

-- function UIManager.SetSeated(status)
--     isSeated = status
--     if not status then
--         countdownLabel.Text = ""
--         viraDisplay.Visible = false
--         handFrame:ClearAllChildren()
--         playedCardsFrame:ClearAllChildren()
--     end
-- end

-- function UIManager.SetVira(value, suit)
--     viraDisplay.Text = "VIRA:\n" .. value .. " de " .. suit
--     viraDisplay.Visible = isSeated 
-- end

-- function UIManager.AddCardToHand(cardValue, cardSuit)
--     local cardButton = Instance.new("TextButton")
--     cardButton.Name = cardValue .. "_" .. cardSuit
--     cardButton.Size = UDim2.new(0, 110, 0, 160)
--     cardButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
--     cardButton.Text = cardValue .. "\n" .. cardSuit
--     cardButton.TextSize = 20
--     cardButton.Font = Enum.Font.GothamBold
--     cardButton.Parent = handFrame
--     Instance.new("UICorner", cardButton).CornerRadius = UDim.new(0, 12)

--     cardButton.Activated:Connect(function()
--         if isMyTurn then
--             Events.PlayCardEvent:FireServer(cardValue, cardSuit)
--             cardButton:Destroy()
--             isMyTurn = false
--         else
--             print("Não é sua vez!")
--         end
--     end)
-- end

-- function UIManager.AddPlayedCardUI(playerName, value, suit)
--     local cardLabel = Instance.new("TextLabel")
--     cardLabel.Size = UDim2.new(0, 80, 0, 110)
--     cardLabel.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
--     cardLabel.Text = playerName .. "\n" .. value .. "_" .. suit
--     cardLabel.TextSize = 12
--     cardLabel.Font = Enum.Font.GothamBold
--     cardLabel.Parent = playedCardsFrame
--     Instance.new("UICorner", cardLabel)
    
--     -- Limpa a mesa após 4 segundos se houver 4 cartas (fim da rodada visual)
--     if #playedCardsFrame:GetChildren() > 4 then
--         task.delay(4, function() playedCardsFrame:ClearAllChildren() end)
--     end
-- end

-- function UIManager.UpdateTurn(activeSeatName)
--     if mySeatName == activeSeatName then
--         isMyTurn = true
--         UIManager.UpdateStatus("É A SUA VEZ!", 0)
--     else
--         isMyTurn = false
--         UIManager.UpdateStatus("Vez de: " .. activeSeatName, 0)
--     end
-- end

-- function UIManager.SetMySeat(seatName)
--     mySeatName = seatName
-- end

-- function UIManager.UpdateStatus(message, value)
--     if not isSeated or not countdownLabel then return end
--     local displayName = GameConfig.StateDisplayNames[message] or message
--     countdownLabel.Text = value > 0 and (displayName .. " " .. value) or displayName
-- end

-- return UIManager
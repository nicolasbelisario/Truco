local TweenService = game:GetService("TweenService")
local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local TrucoUI = {}
local CameraManager -- injetado

local painelDesafio, barraTempoDesafio

-- (D) Inversão de dependência: CameraManager é injetado, não instanciado aqui
function TrucoUI.Inicializar(painelTela, camManager)
    CameraManager = camManager
    TrucoUI._CriarPainel(painelTela)
end

function TrucoUI._CriarPainel(pai)
    painelDesafio = Instance.new("Frame")
    painelDesafio.Name = "TrucoChallengeFrame"
    painelDesafio.Size = UDim2.new(0, 350, 0, 220)
    painelDesafio.Position = UDim2.new(0.5, 0, 0.4, 0)
    painelDesafio.AnchorPoint = Vector2.new(0.5, 0.5)
    painelDesafio.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    painelDesafio.Visible = false
    painelDesafio.ZIndex = 150
    painelDesafio.Parent = pai
    Instance.new("UICorner", painelDesafio)

    local trilho = Instance.new("Frame")
    trilho.Size = UDim2.new(1, 0, 0, 8)
    trilho.Position = UDim2.new(0, 0, 1, 0)
    trilho.AnchorPoint = Vector2.new(0, 1)
    trilho.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    trilho.Parent = painelDesafio

    barraTempoDesafio = Instance.new("Frame")
    barraTempoDesafio.Size = UDim2.new(1, 0, 1, 0)
    barraTempoDesafio.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    barraTempoDesafio.BorderSizePixel = 0
    barraTempoDesafio.Parent = trilho

    -- Título e status
    local titulo = Instance.new("TextLabel")
    titulo.Name = "Title"
    titulo.Size = UDim2.new(1, 0, 0.3, 0)
    titulo.TextScaled = true
    titulo.TextColor3 = Color3.new(1, 1, 1)
    titulo.BackgroundTransparency = 1
    titulo.Parent = painelDesafio

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Text = ""
    status.Size = UDim2.new(1, 0, 0.15, 0)
    status.Position = UDim2.new(0, 0, 0.3, 0)
    status.TextColor3 = Color3.fromRGB(255, 200, 0)
    status.BackgroundTransparency = 1
    status.Parent = painelDesafio

    -- Botões
    local function criarBotao(texto, cor, posX, resposta, nome)
        local btn = Instance.new("TextButton")
        btn.Name = nome
        btn.Text = texto
        btn.Size = UDim2.new(0.28, 0, 0.35, 0)
        btn.Position = UDim2.new(posX, 0, 0.55, 0)
        btn.BackgroundColor3 = cor
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 20
        btn.Parent = painelDesafio
        Instance.new("UICorner", btn)

        btn.Activated:Connect(function()
            status.Text = "Aguardando Parceiro..."
            btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            Eventos.TrucoEvent:FireServer("Response", resposta)
        end)
    end

    criarBotao("DESCER",   Color3.fromRGB(0, 150, 0),    0.04, "Aceitar",  "AceitarBtn")
    criarBotao("FUGIR",    Color3.fromRGB(150, 0, 0),    0.36, "Correr",   "CorrerBtn")
    criarBotao("AUMENTAR", Color3.fromRGB(200, 150, 0),  0.68, "Aumentar", "AumentarBtn")
end

function TrucoUI.Mostrar(valor, quemPediu, tempoLimite)
    local titulo   = painelDesafio:FindFirstChild("Title")
    local status   = painelDesafio:FindFirstChild("Status")
    local btnAceit = painelDesafio:FindFirstChild("AceitarBtn")
    local btnCorr  = painelDesafio:FindFirstChild("CorrerBtn")
    local btnAum   = painelDesafio:FindFirstChild("AumentarBtn")

    if titulo then titulo.Text = quemPediu .. " PEDIU " .. valor .. "!" end
    if status then status.Text = "Decidam juntos!" end
    if btnAceit then btnAceit.BackgroundColor3 = Color3.fromRGB(0, 150, 0) end
    if btnCorr  then btnCorr.BackgroundColor3  = Color3.fromRGB(150, 0, 0) end
    if btnAum   then
        btnAum.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        local prox = (valor < 12) and (valor + 3) or 12
        btnAum.Text = prox .. "!"
        btnAum.Visible = (valor < 12)
    end

    painelDesafio.Visible = true
    CameraManager.AplicarTensao(quemPediu)

    if barraTempoDesafio and tempoLimite and tempoLimite > 0 then
        barraTempoDesafio.Size = UDim2.new(1, 0, 1, 0)
        TweenService:Create(barraTempoDesafio, TweenInfo.new(tempoLimite, Enum.EasingStyle.Linear),
            {Size = UDim2.new(0, 0, 1, 0)}):Play()
    end
end

function TrucoUI.Ocultar()
    if painelDesafio then painelDesafio.Visible = false end
    CameraManager.Resetar()
end

function TrucoUI.AtualizarStatus(msg)
    if painelDesafio and painelDesafio.Visible then
        local s = painelDesafio:FindFirstChild("Status")
        if s then s.Text = msg end
    end
end

return TrucoUI
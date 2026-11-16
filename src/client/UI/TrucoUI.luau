local TweenService = game:GetService("TweenService")
local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local TrucoUI = {}
local CameraManager -- injetado

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local VERDE      = Color3.fromRGB(39, 174, 96)
local VERMELHO   = Color3.fromRGB(200, 50, 50)
local AMARELO    = Color3.fromRGB(220, 160, 0)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(180, 180, 190)

local painelDesafio, barraTempoDesafio

-- (D) Inversão de dependência: CameraManager é injetado, não instanciado aqui
function TrucoUI.Inicializar(painelTela, camManager)
    CameraManager = camManager
    TrucoUI._CriarPainel(painelTela)
end

function TrucoUI._CriarPainel(pai)
    painelDesafio = Instance.new("Frame")
    painelDesafio.Name        = "TrucoChallengeFrame"
    -- Posicionado no topo para deixar o personagem em destaque no centro
    painelDesafio.Size        = UDim2.new(0.85, 0, 0, 0)
    painelDesafio.AutomaticSize = Enum.AutomaticSize.Y
    painelDesafio.Position    = UDim2.new(0.5, 0, 0, 56)
    painelDesafio.AnchorPoint = Vector2.new(0.5, 0)
    painelDesafio.BackgroundColor3 = BG_ESCURO
    painelDesafio.Visible     = false
    painelDesafio.ZIndex      = 150
    painelDesafio.Parent      = pai
    Instance.new("UICorner", painelDesafio).CornerRadius = UDim.new(0, 14)

    local bordaDesafio = Instance.new("UIStroke", painelDesafio)
    bordaDesafio.Thickness = 1.5
    bordaDesafio.Color     = Color3.fromRGB(55, 55, 70)

    -- Tamanho máximo para telas grandes
    local sizeCons = Instance.new("UISizeConstraint", painelDesafio)
    sizeCons.MaxSize = Vector2.new(400, 240)

    -- Padding interno
    local pad = Instance.new("UIPadding", painelDesafio)
    pad.PaddingTop    = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft   = UDim.new(0, 12)
    pad.PaddingRight  = UDim.new(0, 12)

    -- Layout vertical para organizar os filhos
    local listaInterna = Instance.new("UIListLayout", painelDesafio)
    listaInterna.SortOrder  = Enum.SortOrder.LayoutOrder
    listaInterna.Padding    = UDim.new(0, 8)
    listaInterna.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Name               = "Title"
    titulo.Size               = UDim2.new(1, 0, 0, 36)
    titulo.TextScaled         = true
    titulo.TextColor3         = TEXTO_PRIM
    titulo.BackgroundTransparency = 1
    titulo.Font               = Enum.Font.GothamBlack
    titulo.LayoutOrder        = 1
    titulo.ZIndex             = 151
    titulo.Parent             = painelDesafio

    -- Status
    local status = Instance.new("TextLabel")
    status.Name               = "Status"
    status.Text               = ""
    status.Size               = UDim2.new(1, 0, 0, 20)
    status.TextColor3         = TEXTO_SEC
    status.BackgroundTransparency = 1
    status.Font               = Enum.Font.GothamMedium
    status.TextScaled         = false
    status.TextSize           = 14
    status.LayoutOrder        = 2
    status.ZIndex             = 151
    status.Parent             = painelDesafio

    -- Container dos botões (horizontal)
    local containerBotoes = Instance.new("Frame")
    containerBotoes.Size               = UDim2.new(1, 0, 0, 44)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.LayoutOrder        = 3
    containerBotoes.ZIndex             = 151
    containerBotoes.Parent             = painelDesafio

    local layoutH = Instance.new("UIListLayout", containerBotoes)
    layoutH.FillDirection       = Enum.FillDirection.Horizontal
    layoutH.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutH.Padding             = UDim.new(0, 8)

    -- Barra de tempo (trilho)
    local trilho = Instance.new("Frame")
    trilho.Size          = UDim2.new(1, 0, 0, 6)
    trilho.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    trilho.LayoutOrder   = 4
    trilho.ZIndex        = 151
    trilho.Parent        = painelDesafio
    Instance.new("UICorner", trilho).CornerRadius = UDim.new(1, 0)

    barraTempoDesafio = Instance.new("Frame")
    barraTempoDesafio.Size          = UDim2.new(1, 0, 1, 0)
    barraTempoDesafio.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    barraTempoDesafio.BorderSizePixel  = 0
    barraTempoDesafio.ZIndex          = 152
    barraTempoDesafio.Parent          = trilho
    Instance.new("UICorner", barraTempoDesafio).CornerRadius = UDim.new(1, 0)

    -- Botões DESCER / FUGIR / AUMENTAR
    local function criarBotao(texto, cor, resposta, nome)
        local btn = Instance.new("TextButton")
        btn.Name            = nome
        btn.Text            = texto
        btn.Size            = UDim2.new(0.3, 0, 1, 0)
        btn.BackgroundColor3 = cor
        btn.TextColor3      = TEXTO_PRIM
        btn.Font            = Enum.Font.GothamBold
        btn.TextScaled      = false
        btn.TextSize        = 15
        btn.AutoButtonColor = true
        btn.ZIndex          = 152
        btn.Parent          = containerBotoes
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

        local tsConstraint = Instance.new("UITextSizeConstraint", btn)
        tsConstraint.MaxTextSize = 18

        btn.Activated:Connect(function()
            status.Text         = "Aguardando Parceiro..."
            btn.BackgroundColor3 = BG_BOTAO
            Eventos.TrucoEvent:FireServer("Response", resposta)
        end)
    end

    criarBotao("DESCER",   VERDE,    "Aceitar",  "AceitarBtn")
    criarBotao("FUGIR",    VERMELHO, "Correr",   "CorrerBtn")
    criarBotao("AUMENTAR", AMARELO,  "Aumentar", "AumentarBtn")
end

function TrucoUI.Mostrar(valor, quemPediu, tempoLimite)
    local titulo   = painelDesafio:FindFirstChild("Title")
    local status   = painelDesafio:FindFirstChild("Status")
    local btnAceit = painelDesafio:FindFirstChild("AceitarBtn")
    local btnCorr  = painelDesafio:FindFirstChild("CorrerBtn")
    local btnAum   = painelDesafio:FindFirstChild("AumentarBtn")

    if titulo   then titulo.Text  = quemPediu .. " PEDIU " .. valor .. "!" end
    if status   then status.Text  = "Decidam juntos!" end
    if btnAceit then btnAceit.BackgroundColor3 = VERDE    end
    if btnCorr  then btnCorr.BackgroundColor3  = VERMELHO end
    if btnAum   then
        btnAum.BackgroundColor3 = AMARELO
        local prox = (valor < 12) and (valor + 3) or 12
        btnAum.Text    = prox .. "!"
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

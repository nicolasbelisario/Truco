local UIManager = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CardSettings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardSettings"))

-- Sub-módulos (I)
local HandUI      = require(script.Parent.HandUI)
local TableUI     = require(script.Parent.TableUI)
local TrucoUI     = require(script.Parent.TrucoUI)
local ShopUI      = require(script.Parent.ShopUI)
local TutorialUI  = require(script.Parent.TutorialUI)
local ScoreUI     = require(script.Parent.ScoreUI)
local SoundManager = require(script.Parent.SoundManager)
local CameraManager = require(script.Parent.CameraManager)

local Eventos = ReplicatedStorage:WaitForChild("Events")
local jogadorLocal = game:GetService("Players").LocalPlayer

local painelTela
local estaSentado = false
local eMinhaVez = false
local possoPedirTruco = true
local trucoPendente = false
local btnTruco

-- Variáveis locais resgatadas
local painelCorte, barraTempoCorte
local painelEmotes, callbackEmote
local painelVira
local painelOpcoesJogada

-- VARIÁVEIS RESTAURADAS DO CÓDIGO ANTIGO
local textoCronometro
local valorRodadaAtual = 1

function UIManager.Inicializar()
    painelTela = Instance.new("ScreenGui")
    painelTela.Name = "TrucoGui"
    painelTela.ResetOnSpawn = false
    painelTela.IgnoreGuiInset = true
    painelTela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    painelTela.Parent = jogadorLocal:WaitForChild("PlayerGui")

    -- CORREÇÃO DA ORDEM DE RENDERIZAÇÃO: TableUI inicializa primeiro!
    TableUI.Inicializar(painelTela)
    
    HandUI.Inicializar(painelTela, {
        onJogarCarta = function(v, n, e) Eventos.PlayCardEvent:FireServer(v, n, e) end,
        onPedirOpcoes = function(btn, v, n, c, cbJogar) UIManager.MostrarOpcoesJogada(btn, v, n, c, cbJogar) end,
        onOcultarOpcoes = function() UIManager.OcultarOpcoesJogada() end
    })
    
    ScoreUI.Inicializar(UIManager._CriarElementosScore())
    ShopUI.Inicializar(painelTela)
    TutorialUI.Inicializar(painelTela)
    
    -- Inicializado depois das cartas para garantir que o pop-up fique por cima
    TrucoUI.Inicializar(painelTela, CameraManager)

    UIManager._CriarBtnTruco()
    UIManager._CriarMenuAdmin()
    UIManager._CriarMenuCorte()
    UIManager._CriarBotoesEmote()
end

-- ==========================================
-- OPÇÕES DE JOGADA (MENU ABERTA/COBERTA)
-- ==========================================

function UIManager.MostrarOpcoesJogada(botaoCarta, valor, naipe, container, onJogarCartaCallback)
    if painelOpcoesJogada then painelOpcoesJogada:Destroy() end
    
    local larguraMenu = 160
    local alturaMenu = 110

    painelOpcoesJogada = Instance.new("Frame")
    painelOpcoesJogada.Name = "OpcoesJogada"
    painelOpcoesJogada.Size = UDim2.new(0, larguraMenu, 0, alturaMenu)
    painelOpcoesJogada.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    painelOpcoesJogada.BackgroundTransparency = 0.05
    painelOpcoesJogada.ZIndex = 150 -- Garante que fique acima de TUDO
    painelOpcoesJogada.AnchorPoint = Vector2.new(0.5, 1)
    
    local absPos = botaoCarta.AbsolutePosition
    local absSize = botaoCarta.AbsoluteSize
    painelOpcoesJogada.Position = UDim2.new(0, absPos.X + (absSize.X / 2), 0, absPos.Y + 50)
    painelOpcoesJogada.Parent = painelTela 
    
    Instance.new("UICorner", painelOpcoesJogada).CornerRadius = UDim.new(0, 12)
    local borda = Instance.new("UIStroke", painelOpcoesJogada)
    borda.Color = Color3.new(1, 1, 1)
    borda.Transparency = 0.8
    borda.Thickness = 1
    
    local margem = Instance.new("UIPadding", painelOpcoesJogada)
    margem.PaddingTop = UDim.new(0, 8); margem.PaddingBottom = UDim.new(0, 8)
    margem.PaddingLeft = UDim.new(0, 8); margem.PaddingRight = UDim.new(0, 8)
    
    local layoutOpcoes = Instance.new("UIListLayout", painelOpcoesJogada)
    layoutOpcoes.Padding = UDim.new(0, 8)
    layoutOpcoes.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function criarBotaoOpcao(texto, cor, escondida)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0.5, -4)
        btn.BackgroundColor3 = cor
        btn.Text = texto
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.ZIndex = 151
        btn.AutoButtonColor = false
        btn.Parent = painelOpcoesJogada
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
        
        btn.Activated:Connect(function()
            eMinhaVez = false
            HandUI.DefinirEstado(eMinhaVez, nil, nil, nil)
            if onJogarCartaCallback then onJogarCartaCallback(valor, naipe, escondida) end
            container:Destroy()
            painelOpcoesJogada:Destroy()
        end)
    end
    
    criarBotaoOpcao("JOGAR ABERTA", Color3.fromRGB(39, 174, 96), false)
    criarBotaoOpcao("JOGAR COBERTA", Color3.fromRGB(90, 90, 90), true)
end

function UIManager.OcultarOpcoesJogada()
    if painelOpcoesJogada then painelOpcoesJogada:Destroy() end
end

-- ==========================================
-- DELEGAÇÕES E ATUALIZAÇÕES GERAIS
-- ==========================================

function UIManager.AtualizarStatus(msg, val)       ScoreUI.AtualizarStatus(msg, val) end
function UIManager.AtualizarPlacar(m, i)           ScoreUI.AtualizarPlacar(m, i) end

-- Restaura o rastreamento do valor da rodada para o botão de truco
function UIManager.AtualizarValorRodada(v)         
    valorRodadaAtual = tonumber(v) or 1
    ScoreUI.AtualizarValorRodada(v, estaSentado) 
end

function UIManager.AtualizarEstatisticasRodada(p, n, e) ScoreUI.AtualizarEstatisticas(p, n, e, estaSentado) end
function UIManager.LimparMao()                     HandUI.Limpar(); UIManager.OcultarOpcoesJogada() end
function UIManager.AdicionarCartaMao(v, n)         HandUI.AdicionarCarta(v, n) end
function UIManager.AdicionarCartaJogadaUI(...)     TableUI.AdicionarCarta(...) end
function UIManager.LimparMesa()                    TableUI.Limpar() end
function UIManager.TocarSom(nome)                  SoundManager.Tocar(nome) end
function UIManager.ResetarCamera()                 CameraManager.Resetar() end
function UIManager.MostrarDesafioTruco(v, q, t)    TrucoUI.Mostrar(v, q, t) end
function UIManager.OcultarDesafioTruco()           TrucoUI.Ocultar() end
function UIManager.AtualizarStatusDesafio(msg)     TrucoUI.AtualizarStatus(msg) end
function UIManager.MostrarTutorial(abrir)          TutorialUI.Mostrar(abrir) end
function UIManager.AtualizarDadosJogador(dados)    ShopUI.AtualizarDados(dados); HandUI.DefinirEstado(eMinhaVez, nil, nil, dados) end
function UIManager.MostrarPlacar()                 ScoreUI.MostrarPlacar(estaSentado) end
function UIManager.OcultarPlacar()                 ScoreUI.OcultarPlacar() end

-- ==========================================
-- CRIAÇÃO DE COMPONENTES DE TELA
-- ==========================================

function UIManager._CriarElementosScore()
    local containerInfo = Instance.new("Frame")
    containerInfo.Name = "InfoContainer"
    containerInfo.Position = UDim2.new(0.02, 0, 0, 60)
    containerInfo.Size = UDim2.new(0, 250, 0.5, 0)
    containerInfo.BackgroundTransparency = 1
    containerInfo.Parent = painelTela

    local layoutLista = Instance.new("UIListLayout", containerInfo)
    layoutLista.SortOrder = Enum.SortOrder.LayoutOrder
    layoutLista.Padding = UDim.new(0, 10)

    textoCronometro = Instance.new("TextLabel")
    textoCronometro.Size = UDim2.new(0.8, 0, 0.1, 0)
    textoCronometro.Position = UDim2.new(0.5, 0, 0.15, 0)
    textoCronometro.AnchorPoint = Vector2.new(0.5, 0.5)
    textoCronometro.BackgroundTransparency = 1
    textoCronometro.TextColor3 = Color3.new(1, 1, 1)
    textoCronometro.TextScaled = true
    textoCronometro.Font = Enum.Font.GothamBlack
    textoCronometro.Text = ""
    textoCronometro.ZIndex = 100
    textoCronometro.Parent = painelTela

    local painelEstatisticas = Instance.new("Frame")
    painelEstatisticas.Size = UDim2.new(0, 200, 0, 100)
    painelEstatisticas.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    painelEstatisticas.BackgroundTransparency = 0.5
    painelEstatisticas.Visible = false
    painelEstatisticas.LayoutOrder = 1
    painelEstatisticas.Parent = containerInfo
    Instance.new("UICorner", painelEstatisticas)

    local textoEstatisticas = Instance.new("TextLabel")
    textoEstatisticas.Size = UDim2.new(0.9, 0, 0.9, 0)
    textoEstatisticas.Position = UDim2.new(0.5, 0, 0.5, 0)
    textoEstatisticas.AnchorPoint = Vector2.new(0.5, 0.5)
    textoEstatisticas.BackgroundTransparency = 1
    textoEstatisticas.TextColor3 = Color3.new(1, 1, 1)
    textoEstatisticas.TextXAlignment = Enum.TextXAlignment.Left
    textoEstatisticas.Font = Enum.Font.GothamMedium
    textoEstatisticas.TextSize = 18
    textoEstatisticas.Parent = painelEstatisticas

    local textoPlacarJogo = Instance.new("TextLabel")
    textoPlacarJogo.Size = UDim2.new(0, 220, 0, 60)
    textoPlacarJogo.BackgroundTransparency = 0.4
    textoPlacarJogo.BackgroundColor3 = Color3.fromRGB(20,20,20)
    textoPlacarJogo.TextColor3 = Color3.new(1,1,1)
    textoPlacarJogo.Font = Enum.Font.GothamBlack
    textoPlacarJogo.TextSize = 22
    textoPlacarJogo.Visible = false
    textoPlacarJogo.LayoutOrder = 2
    textoPlacarJogo.Parent = containerInfo
    Instance.new("UICorner", textoPlacarJogo)

    local textoValorRodada = Instance.new("TextLabel")
    textoValorRodada.Size = UDim2.new(0, 150, 0, 40)
    textoValorRodada.Position = UDim2.new(0.5, 0, 0.22, 0)
    textoValorRodada.AnchorPoint = Vector2.new(0.5, 0.5)
    textoValorRodada.BackgroundTransparency = 1
    textoValorRodada.TextColor3 = Color3.fromRGB(255, 255, 255)
    textoValorRodada.Font = Enum.Font.GothamBold
    textoValorRodada.TextSize = 24
    textoValorRodada.Visible = false
    textoValorRodada.Parent = painelTela

    painelVira = Instance.new("Frame")
    painelVira.Name = "ViraDisplayFrame"
    painelVira.Size = UDim2.new(0, 140, 0, 220)
    painelVira.Position = UDim2.new(0.95, 0, 0.05, 0)
    painelVira.AnchorPoint = Vector2.new(1, 0)
    painelVira.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    painelVira.Visible = false
    painelVira.Parent = painelTela
    Instance.new("UICorner", painelVira)

    return {
        textoCronometro = textoCronometro,
        textoPlacarJogo = textoPlacarJogo,
        textoValorRodada = textoValorRodada,
        textoEstatisticas = textoEstatisticas,
        painelEstatisticas = painelEstatisticas,
        painelVira = painelVira
    }
end

function UIManager._CriarBtnTruco()
    btnTruco = Instance.new("TextButton")
    btnTruco.Size = UDim2.new(0, 180, 0, 80)
    btnTruco.Position = UDim2.new(0.85, 0, 0.85, 0)
    btnTruco.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    btnTruco.Text = "TRUCO!"
    btnTruco.TextColor3 = Color3.new(1,1,1)
    btnTruco.Font = Enum.Font.GothamBlack
    btnTruco.TextSize = 35
    btnTruco.Visible = false
    btnTruco.Parent = painelTela
    Instance.new("UICorner", btnTruco)

    btnTruco.Activated:Connect(function()
        Eventos.TrucoEvent:FireServer("Request")
        UIManager.PermitirTruco(false)
    end)
end

function UIManager._CriarMenuAdmin()
    if jogadorLocal.Name ~= "Nick0369me" then return end

    local painelAdmin = Instance.new("Frame")
    painelAdmin.Size = UDim2.new(0, 260, 0, 170)
    painelAdmin.Position = UDim2.new(0.5, 0, 0, 10)
    painelAdmin.AnchorPoint = Vector2.new(0.5, 0)
    painelAdmin.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    painelAdmin.Visible = false
    painelAdmin.ZIndex = 200
    painelAdmin.Parent = painelTela
    Instance.new("UICorner", painelAdmin).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", painelAdmin).Color = Color3.new(1, 0.8, 0)

    local titulo = Instance.new("TextLabel", painelAdmin)
    titulo.Size = UDim2.new(1, 0, 0, 30)
    titulo.Text = "🛡️ PAINEL ADMIN (F4)"
    titulo.TextColor3 = Color3.new(1, 0.8, 0)
    titulo.Font = Enum.Font.GothamBlack
    titulo.BackgroundTransparency = 1

    local inputNome = Instance.new("TextBox", painelAdmin)
    inputNome.Size = UDim2.new(0.9, 0, 0, 35)
    inputNome.Position = UDim2.new(0.05, 0, 0, 40)
    inputNome.PlaceholderText = "Nome do Jogador"
    inputNome.Text = jogadorLocal.Name 
    inputNome.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputNome.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", inputNome)

    local inputValor = Instance.new("TextBox", painelAdmin)
    inputValor.Size = UDim2.new(0.9, 0, 0, 35)
    inputValor.Position = UDim2.new(0.05, 0, 0, 85)
    inputValor.PlaceholderText = "Quantidade"
    inputValor.Text = "300"
    inputValor.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputValor.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", inputValor)

    local btnAdd = Instance.new("TextButton", painelAdmin)
    btnAdd.Size = UDim2.new(0.42, 0, 0, 35)
    btnAdd.Position = UDim2.new(0.05, 0, 0, 125)
    btnAdd.BackgroundColor3 = Color3.fromRGB(0, 150, 60)
    btnAdd.Text = "+ DAR PTS"
    btnAdd.TextColor3 = Color3.new(1, 1, 1)
    btnAdd.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnAdd)

    local btnRem = Instance.new("TextButton", painelAdmin)
    btnRem.Size = UDim2.new(0.42, 0, 0, 35)
    btnRem.Position = UDim2.new(0.53, 0, 0, 125)
    btnRem.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnRem.Text = "- TIRAR PTS"
    btnRem.TextColor3 = Color3.new(1, 1, 1)
    btnRem.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btnRem)

    btnAdd.Activated:Connect(function()
        Eventos.AdminActionEvent:FireServer("Adicionar", inputNome.Text, inputValor.Text)
    end)
    btnRem.Activated:Connect(function()
        Eventos.AdminActionEvent:FireServer("Remover", inputNome.Text, inputValor.Text)
    end)

    UserInputService.InputBegan:Connect(function(input, emChat)
        if not emChat and input.KeyCode == Enum.KeyCode.F4 then
            painelAdmin.Visible = not painelAdmin.Visible
        end
    end)
end

function UIManager._CriarMenuCorte()
    painelCorte = Instance.new("Frame")
    painelCorte.Size = UDim2.new(0, 400, 0, 220)
    painelCorte.Position = UDim2.new(0.5, 0, 0.45, 0)
    painelCorte.AnchorPoint = Vector2.new(0.5, 0.5)
    painelCorte.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    painelCorte.Visible = false
    painelCorte.ZIndex = 110 -- Garante ficar por cima da mesa
    painelCorte.Parent = painelTela
    Instance.new("UICorner", painelCorte).CornerRadius = UDim.new(0, 15)
    
    local fundoBarraTimer = Instance.new("Frame")
    fundoBarraTimer.Size = UDim2.new(1, 0, 0, 6)
    fundoBarraTimer.Position = UDim2.new(0, 0, 1, 0)
    fundoBarraTimer.AnchorPoint = Vector2.new(0, 1)
    fundoBarraTimer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    fundoBarraTimer.Parent = painelCorte
    
    barraTempoCorte = Instance.new("Frame")
    barraTempoCorte.Size = UDim2.new(1, 0, 1, 0)
    barraTempoCorte.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    barraTempoCorte.BorderSizePixel = 0
    barraTempoCorte.Parent = fundoBarraTimer

    local tituloCorte = Instance.new("TextLabel")
    tituloCorte.Text = "SUA VEZ DE CORTAR"
    tituloCorte.Size = UDim2.new(1, 0, 0.4, 0)
    tituloCorte.TextColor3 = Color3.fromRGB(255, 255, 255)
    tituloCorte.Font = Enum.Font.GothamBold
    tituloCorte.TextSize = 24
    tituloCorte.BackgroundTransparency = 1
    tituloCorte.Parent = painelCorte

    local containerBotoes = Instance.new("Frame")
    containerBotoes.Size = UDim2.new(0.9, 0, 0.4, 0)
    containerBotoes.Position = UDim2.new(0.5, 0, 0.7, 0)
    containerBotoes.AnchorPoint = Vector2.new(0.5, 0.5)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.Parent = painelCorte

    local layoutBotoes = Instance.new("UIListLayout")
    layoutBotoes.FillDirection = Enum.FillDirection.Horizontal
    layoutBotoes.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutBotoes.Padding = UDim.new(0, 20)
    layoutBotoes.Parent = containerBotoes

    local function criarBotaoCorte(texto)
        local btn = Instance.new("TextButton")
        btn.Text = texto
        btn.Size = UDim2.new(0, 90, 0, 70)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 22
        btn.Parent = containerBotoes
        Instance.new("UICorner", btn)
        
        btn.Activated:Connect(function()
            painelCorte.Visible = false
            Eventos.GameStatusEvent:FireServer("CutAction", tonumber(string.sub(texto, 1, 1)))
        end)
    end

    criarBotaoCorte("1x")
    criarBotaoCorte("2x")
    criarBotaoCorte("3x")
end

function UIManager._CriarBotoesEmote()
    painelEmotes = Instance.new("Frame")
    painelEmotes.Size = UDim2.new(0, 120, 0, 60)
    painelEmotes.Position = UDim2.new(0.98, 0, 0.85, 0)
    painelEmotes.AnchorPoint = Vector2.new(1, 1)
    painelEmotes.BackgroundTransparency = 1
    painelEmotes.Visible = false
    painelEmotes.Parent = painelTela
    
    local layout = Instance.new("UIListLayout", painelEmotes)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)

    local function criarBotaoEmote(icone, nomeSinal)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.Text = icone
        btn.TextSize = 30
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = painelEmotes
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
        
        btn.Activated:Connect(function()
            if callbackEmote then callbackEmote(nomeSinal) end
        end)
    end
    
    criarBotaoEmote("🖐️", "Sinal_Mao")
    criarBotaoEmote("👀", "Sinal_Olhar")
end

function UIManager.PermitirTruco(permitido)
    possoPedirTruco = permitido
    if btnTruco then btnTruco.Visible = eMinhaVez and possoPedirTruco end
end

function UIManager.DefinirVira(val, naipe)
    if not painelVira then return end
    for _, filho in ipairs(painelVira:GetChildren()) do
        if not filho:IsA("UICorner") then filho:Destroy() end
    end
    
    painelVira.Visible = estaSentado
    local tituloLbl = Instance.new("TextLabel")
    tituloLbl.Text = "VIRA"
    tituloLbl.Size = UDim2.new(1, 0, 0.2, 0)
    tituloLbl.BackgroundTransparency = 1
    tituloLbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
    tituloLbl.Font = Enum.Font.GothamBlack
    tituloLbl.TextScaled = true
    tituloLbl.Parent = painelVira

    local imgVira = Instance.new("ImageLabel")
    imgVira.Size = UDim2.new(0, 80, 0, 115) 
    imgVira.Position = UDim2.new(0.5, 0, 0.5, 0)
    imgVira.AnchorPoint = Vector2.new(0.5, 0.5)
    imgVira.BackgroundTransparency = 1
    imgVira.Parent = painelVira
    
    CardSettings.AplicarSkinCarta(imgVira, val, naipe, false, "Padrao")

    local textoCarta = Instance.new("TextLabel")
    textoCarta.Text = val .. " " .. naipe
    textoCarta.Size = UDim2.new(1, 0, 0.2, 0)
    textoCarta.Position = UDim2.new(0, 0, 0.8, 0) 
    textoCarta.BackgroundTransparency = 1
    textoCarta.TextColor3 = Color3.new(1, 1, 1)
    textoCarta.Font = Enum.Font.GothamBold
    textoCarta.TextSize = 18
    textoCarta.Parent = painelVira
end

function UIManager.MostrarOpcoesCorte(tempoLimite)
    if painelCorte then
        painelCorte.Visible = true
        barraTempoCorte.Size = UDim2.new(1, 0, 1, 0)
        local tweenInfo = TweenInfo.new(tempoLimite, Enum.EasingStyle.Linear)
        TweenService:Create(barraTempoCorte, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)}):Play()
        
        task.delay(tempoLimite + 0.5, function()
            if painelCorte.Visible then painelCorte.Visible = false end
        end)
    end
end

function UIManager.OcultarMenuCorte()
    if painelCorte then painelCorte.Visible = false end
end

function UIManager.MostrarAvisoFuga(texto)
    local lblFuga = Instance.new("TextLabel")
    lblFuga.Size = UDim2.new(0.8, 0, 0.2, 0)
    lblFuga.Position = UDim2.new(0.5, 0, 0.35, 0)
    lblFuga.AnchorPoint = Vector2.new(0.5, 0.5)
    lblFuga.BackgroundTransparency = 1
    lblFuga.TextColor3 = Color3.fromRGB(255, 60, 60)
    lblFuga.TextStrokeTransparency = 0
    lblFuga.Font = Enum.Font.GothamBlack
    lblFuga.TextScaled = true
    lblFuga.Text = texto
    lblFuga.Parent = painelTela

    task.delay(2.5, function()
        if lblFuga then
            local tween = TweenService:Create(lblFuga, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() lblFuga:Destroy() end)
        end
    end)
end

function UIManager.MostrarVencedorRodada(nomeEquipe)
    local lblVencedor = Instance.new("TextLabel")
    lblVencedor.Size = UDim2.new(0.8, 0, 0.2, 0)
    lblVencedor.Position = UDim2.new(0.5, 0, 0.4, 0)
    lblVencedor.AnchorPoint = Vector2.new(0.5, 0.5)
    lblVencedor.BackgroundTransparency = 1
    lblVencedor.TextColor3 = Color3.fromRGB(255, 215, 0)
    lblVencedor.TextStrokeTransparency = 0
    lblVencedor.Font = Enum.Font.GothamBlack
    lblVencedor.TextScaled = true
    lblVencedor.Text = nomeEquipe
    lblVencedor.Parent = painelTela

    task.delay(3, function()
        if lblVencedor then
            local tween = TweenService:Create(lblVencedor, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() lblVencedor:Destroy() end)
        end
    end)
end

function UIManager.MostrarVencedorPartida(texto)
    local fundoEscuro = Instance.new("Frame")
    fundoEscuro.Size = UDim2.new(1, 0, 1, 0)
    fundoEscuro.BackgroundColor3 = Color3.new(0, 0, 0)
    fundoEscuro.BackgroundTransparency = 1
    fundoEscuro.ZIndex = 200
    fundoEscuro.Parent = painelTela
    
    local lbl = Instance.new("TextLabel")
    lbl.Text = texto
    lbl.Size = UDim2.new(0.9, 0, 0.2, 0)
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextScaled = true
    lbl.TextTransparency = 1
    lbl.ZIndex = 201
    lbl.Parent = painelTela 
    
    local bordaLetra = Instance.new("UIStroke", lbl)
    bordaLetra.Thickness = 3
    bordaLetra.Color = Color3.new(1, 1, 1) 
    bordaLetra.Transparency = 1
    
    TweenService:Create(fundoEscuro, TweenInfo.new(1), {BackgroundTransparency = 0.3}):Play()
    local configTween = TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    TweenService:Create(lbl, configTween, {TextTransparency = 0, Size = UDim2.new(0.95, 0, 0.25, 0)}):Play()
    TweenService:Create(bordaLetra, TweenInfo.new(1), {Transparency = 0}):Play()
    
    task.delay(9, function()
        TweenService:Create(fundoEscuro, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
        local fadeOutText = TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1})
        TweenService:Create(bordaLetra, TweenInfo.new(0.5), {Transparency = 1}):Play()
        fadeOutText:Play()
        
        fadeOutText.Completed:Connect(function()
            fundoEscuro:Destroy()
            lbl:Destroy()
        end)
    end)
end

function UIManager.DefinirVisibilidadeUIJogo(visivel)
    ScoreUI.DefinirVisibilidade(visivel)
    if btnTruco then btnTruco.Visible = false end
    if painelCorte then painelCorte.Visible = false end
end

function UIManager.DefinirMeuAssento(nomeAssento) end

function UIManager.DefinirCallbackEmote(callback)
    callbackEmote = callback
end

function UIManager.MostrarSinal(remetente, tipoSinal)
    if not remetente or not remetente.Character or not remetente.Character:FindFirstChild("Head") then return end

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 100, 0, 100)
    bg.Adornee = remetente.Character.Head
    bg.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = (tipoSinal == "Sinal_Mao" or tipoSinal == "LevantarMao") and "🖐️" or "👀"
    lbl.TextSize = 50
    bg.Parent = remetente.Character.Head
    
    local destaque = Instance.new("Highlight")
    destaque.Adornee = remetente.Character
    destaque.FillTransparency = 1
    destaque.OutlineColor = Color3.new(1,1,0)
    destaque.Parent = remetente.Character

    task.delay(2, function() 
        bg:Destroy() 
        destaque:Destroy()
    end)
end

function UIManager.DefinirSentado(s)
    estaSentado = s
    ShopUI.DefinirVisibilidade(not s)
    if painelEmotes then painelEmotes.Visible = s end
    if not s then UIManager.ResetTotal() end
end

function UIManager.ResetTotal()
    HandUI.Limpar()
    TableUI.Limpar()
    ScoreUI.DefinirVisibilidade(false)
    ScoreUI.OcultarPlacar() 
    ScoreUI.AtualizarStatus("", 0)
    TrucoUI.Ocultar()
    UIManager.OcultarOpcoesJogada()
    UIManager.OcultarMenuCorte()
end

function UIManager.AtualizarTurno(nomeJogador, numQueda)
    eMinhaVez = (nomeJogador == jogadorLocal.Name)
    HandUI.DefinirEstado(eMinhaVez, numQueda, trucoPendente, nil)
    
    if btnTruco then
        btnTruco.Visible = eMinhaVez and possoPedirTruco
        
        if valorRodadaAtual == 1 then btnTruco.Text = "TRUCO!"
        elseif valorRodadaAtual == 3 then btnTruco.Text = "SEIS!"
        elseif valorRodadaAtual == 6 then btnTruco.Text = "NOVE!"
        elseif valorRodadaAtual == 9 then btnTruco.Text = "DOZE!"
        else btnTruco.Visible = false end
    end

    if eMinhaVez then
        UIManager.AtualizarStatus("SUA VEZ!", 0)
        if textoCronometro then textoCronometro.TextColor3 = Color3.fromRGB(255, 255, 0) end
    else
        UIManager.AtualizarStatus("Vez de: " .. nomeJogador, 0)
        if textoCronometro then textoCronometro.TextColor3 = Color3.fromRGB(255, 255, 255) end
    end
end

return UIManager
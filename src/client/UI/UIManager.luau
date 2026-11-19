local UIManager = {}

local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CardSettings     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardSettings"))

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local VERDE      = Color3.fromRGB(39, 174, 96)
local VERMELHO   = Color3.fromRGB(200, 50, 50)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(180, 180, 190)

-- Sub-módulos (I)
local HandUI       = require(script.Parent.HandUI)
local TableUI      = require(script.Parent.TableUI)
local TrucoUI      = require(script.Parent.TrucoUI)
local ShopUI       = require(script.Parent.ShopUI)
local TutorialUI   = require(script.Parent.TutorialUI)
local ScoreUI      = require(script.Parent.ScoreUI)
local SoundManager = require(script.Parent.SoundManager)
local AudioUI      = require(script.Parent.AudioUI)
local CameraManager = require(script.Parent.CameraManager)
local LeaderboardUI = require(script.Parent.LeaderboardUI)
local LobbyUI       = require(script.Parent.LobbyUI)

local Eventos      = ReplicatedStorage:WaitForChild("Events")
local jogadorLocal = game:GetService("Players").LocalPlayer

local painelTela
local estaSentado    = false
local eMinhaVez      = false
local possoPedirTruco = true
local trucoPendente  = false
local btnTruco
local mesaAtualRef   = nil
local assentoAtualRef = nil

-- Variáveis locais resgatadas
local painelCorte, barraTempoCorte
local painelEmotes, callbackEmote
local painelControlesMesa, btnCamera, btnGrade2D, atualizarVisualGrade2D
local painelVira, containerInfoScore
local marcadoresQuedas = {}
local painelOpcoesJogada
local painelMaoDeOnze
local containerCartasParceiro, statusLabelMaoDeOnze, btnJogarMaoDeOnze, btnCorrerMaoDeOnze

-- VARIÁVEIS RESTAURADAS DO CÓDIGO ANTIGO
local textoCronometro
local valorRodadaAtual = 1
local dadosJogador = { SkinEquipada = "Padrao" }
local viraAtual = nil
local imgViraAtual = nil
local layoutResponsivoCallbacks = {}

-- Barra de menu principal (topo-esquerdo: 🏆 Ranking, 🛒 Loja, ❓ Ajuda, 🔊 Áudio)
local barraMenuPrincipal

local function registrarLayoutResponsivo(fn)
    table.insert(layoutResponsivoCallbacks, fn)
    fn()
end

local function atualizarLayoutsResponsivos()
    for _, fn in ipairs(layoutResponsivoCallbacks) do
        fn()
    end
end

function UIManager.Inicializar()
    local GuiService = game:GetService("GuiService")

    painelTela = Instance.new("ScreenGui")
    painelTela.Name           = "TrucoGui"
    painelTela.ResetOnSpawn   = false
    painelTela.IgnoreGuiInset = true
    painelTela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    painelTela.Parent         = jogadorLocal:WaitForChild("PlayerGui")

    -- Barra de navegação unificada no canto superior esquerdo (sempre acessível)
    barraMenuPrincipal = Instance.new("Frame")
    barraMenuPrincipal.Name               = "BarraMenuPrincipal"
    barraMenuPrincipal.Size               = UDim2.new(0, 46, 0, 0)
    barraMenuPrincipal.AutomaticSize      = Enum.AutomaticSize.Y
    barraMenuPrincipal.BackgroundTransparency = 1
    barraMenuPrincipal.ZIndex             = 40
    barraMenuPrincipal.Parent             = painelTela

    local layoutMenu = Instance.new("UIListLayout", barraMenuPrincipal)
    layoutMenu.FillDirection       = Enum.FillDirection.Vertical
    layoutMenu.Padding             = UDim.new(0, 8)
    layoutMenu.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutMenu.SortOrder           = Enum.SortOrder.LayoutOrder

    local function atualizarPosicaoBarraMenu()
        local inset = GuiService:GetGuiInset()
        local alturaTopbar = math.max(inset.Y, 54)
        barraMenuPrincipal.Position = UDim2.new(0, 16, 0, alturaTopbar + 12)
    end
    atualizarPosicaoBarraMenu()
    GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(atualizarPosicaoBarraMenu)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            atualizarPosicaoBarraMenu()
            atualizarLayoutsResponsivos()
        end)
    end

    -- CORREÇÃO DA ORDEM DE RENDERIZAÇÃO: TableUI inicializa primeiro!
    TableUI.Inicializar(painelTela)

    HandUI.Inicializar(painelTela, {
        onJogarCarta   = function(cardId, escondida) Eventos.PlayCardEvent:FireServer(cardId, escondida) end,
        onPedirOpcoes  = function(btn, card, container, cbJogar) UIManager.MostrarOpcoesJogada(btn, card, container, cbJogar) end,
        onOcultarOpcoes = function() UIManager.OcultarOpcoesJogada() end
    })

    ScoreUI.Inicializar(UIManager._CriarElementosScore())

    -- Inicializa módulos de áudio e menu dentro da barra unificada
    SoundManager.Inicializar()
    LeaderboardUI.Inicializar(painelTela, barraMenuPrincipal)
    ShopUI.Inicializar(painelTela, barraMenuPrincipal)
    TutorialUI.Inicializar(painelTela, barraMenuPrincipal)
    AudioUI.Inicializar(painelTela, barraMenuPrincipal, SoundManager)
    LobbyUI.Inicializar(painelTela)

    UIManager.LeaderboardUI = LeaderboardUI
    UIManager.LobbyUI = LobbyUI

    -- Inicializado depois das cartas para garantir que o pop-up fique por cima
    TrucoUI.Inicializar(painelTela, CameraManager)

    UIManager._CriarBtnTruco()
    UIManager._CriarMenuAdmin()
    UIManager._CriarMenuCorte()
    UIManager._CriarBotoesEmote()
    UIManager._CriarControlesMesa()
    UIManager._CriarMenuMaoDeOnze()
end

-- ==========================================
-- OPÇÕES DE JOGADA (MENU ABERTA/COBERTA)
-- ==========================================

function UIManager.MostrarOpcoesJogada(botaoCarta, card, container, onJogarCartaCallback)
    if painelOpcoesJogada then painelOpcoesJogada:Destroy() end

    local larguraMenu = 160
    local alturaMenu  = 110

    painelOpcoesJogada = Instance.new("Frame")
    painelOpcoesJogada.Name               = "OpcoesJogada"
    painelOpcoesJogada.Size               = UDim2.new(0, larguraMenu, 0, alturaMenu)
    painelOpcoesJogada.BackgroundColor3   = Color3.fromRGB(35, 35, 35)
    painelOpcoesJogada.BackgroundTransparency = 0.05
    painelOpcoesJogada.ZIndex             = 150 -- Garante que fique acima de TUDO
    painelOpcoesJogada.AnchorPoint        = Vector2.new(0.5, 1)

    local absPos  = botaoCarta.AbsolutePosition
    local absSize = botaoCarta.AbsoluteSize
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local posX = math.clamp(absPos.X + (absSize.X / 2), (larguraMenu / 2) + 8, math.max(vp.X - (larguraMenu / 2) - 8, (larguraMenu / 2) + 8))
    local posY = math.max(alturaMenu + 12, absPos.Y - 8)
    painelOpcoesJogada.Position = UDim2.new(0, posX, 0, posY)
    painelOpcoesJogada.Parent   = painelTela

    Instance.new("UICorner", painelOpcoesJogada).CornerRadius = UDim.new(0, 12)
    local borda = Instance.new("UIStroke", painelOpcoesJogada)
    borda.Color       = Color3.new(1, 1, 1)
    borda.Transparency = 0.8
    borda.Thickness   = 1

    local margem = Instance.new("UIPadding", painelOpcoesJogada)
    margem.PaddingTop    = UDim.new(0, 8); margem.PaddingBottom = UDim.new(0, 8)
    margem.PaddingLeft   = UDim.new(0, 8); margem.PaddingRight  = UDim.new(0, 8)

    local layoutOpcoes = Instance.new("UIListLayout", painelOpcoesJogada)
    layoutOpcoes.Padding             = UDim.new(0, 8)
    layoutOpcoes.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function criarBotaoOpcao(texto, cor, escondida)
        local btn = Instance.new("TextButton")
        btn.Size            = UDim2.new(1, 0, 0.5, -4)
        btn.BackgroundColor3 = cor
        btn.Text            = texto
        btn.TextColor3      = Color3.new(1,1,1)
        btn.Font            = Enum.Font.GothamBold
        btn.TextSize        = 14
        btn.ZIndex          = 151
        btn.AutoButtonColor = false
        btn.Parent          = painelOpcoesJogada
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)

        btn.Activated:Connect(function()
            eMinhaVez = false
            HandUI.DefinirEstado(eMinhaVez, nil, nil, nil)
            if onJogarCartaCallback then onJogarCartaCallback(card.idUnico, escondida) end
            container:Destroy()
            painelOpcoesJogada:Destroy()
        end)
    end

    criarBotaoOpcao("JOGAR ABERTA",  Color3.fromRGB(39, 174, 96), false)
    criarBotaoOpcao("JOGAR COBERTA", Color3.fromRGB(90, 90, 90),  true)
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

function UIManager.AtualizarEstatisticasRodada(p, n, e, historico)
    ScoreUI.AtualizarEstatisticas(p, n, e, estaSentado, historico)
end
function UIManager.LimparMao()                     HandUI.Limpar(); UIManager.OcultarOpcoesJogada() end
function UIManager.AdicionarCartaMao(card)         HandUI.AdicionarCarta(card) end
function UIManager.AdicionarCartaJogadaUI(...)     TableUI.AdicionarCarta(...) end
function UIManager.LimparMesa()                    TableUI.Limpar() end
function UIManager.TocarSom(nome)                  SoundManager.Tocar(nome) end
function UIManager.DefinirModoTensao(ativo)        SoundManager.DefinirModoTensao(ativo) end
function UIManager.DefinirMesaAtual(modeloMesa)
    mesaAtualRef = modeloMesa
    CameraManager.DefinirMesaAtual(modeloMesa, assentoAtualRef)
    if estaSentado and mesaAtualRef and assentoAtualRef then
        CameraManager.AtivarModoMesa(mesaAtualRef, assentoAtualRef)
    end
end
function UIManager.FocarCameraMesa()               CameraManager.FocarMesaSeAtivo() end
function UIManager.AoMudarModoCamera(cb)           CameraManager.AoMudarModoCamera(cb) end
function UIManager.ResetarCamera()                 CameraManager.Resetar() end
function UIManager.MostrarDesafioTruco(v, q, t)   TableUI.DefinirModoLateral(true); TrucoUI.Mostrar(v, q, t) end
function UIManager.OcultarDesafioTruco()           TrucoUI.Ocultar(); TableUI.DefinirModoLateral(false) end
function UIManager.AtualizarStatusDesafio(msg)     TrucoUI.AtualizarStatus(msg) end
function UIManager.MostrarTutorial(abrir)          TutorialUI.Mostrar(abrir) end
function UIManager.AtualizarDadosJogador(dados)
    if dados then dadosJogador = dados end
    ShopUI.AtualizarDados(dados)
    HandUI.DefinirEstado(eMinhaVez, nil, nil, dados)
    if imgViraAtual and imgViraAtual.Parent and viraAtual then
        CardSettings.AplicarSkinCarta(imgViraAtual, viraAtual.valor, viraAtual.naipe, false, dadosJogador.SkinEquipada or "Padrao")
    end
end
function UIManager.MostrarPlacar()                 ScoreUI.MostrarPlacar(estaSentado) end
function UIManager.OcultarPlacar()                 ScoreUI.OcultarPlacar() end

-- ==========================================
-- CRIAÇÃO DE COMPONENTES DE TELA
-- ==========================================

function UIManager._CriarElementosScore()
    containerInfoScore = Instance.new("Frame")
    containerInfoScore.Name                 = "InfoContainer"
    containerInfoScore.Position             = UDim2.new(0, 72, 0, 60)
    containerInfoScore.Size                 = UDim2.new(0, 210, 0.5, 0)
    containerInfoScore.BackgroundTransparency = 1
    containerInfoScore.Parent               = painelTela

    local layoutLista = Instance.new("UIListLayout", containerInfoScore)
    layoutLista.SortOrder = Enum.SortOrder.LayoutOrder
    layoutLista.Padding   = UDim.new(0, 8)

    -- Cronômetro: topo-centro, legível com UIStroke
    textoCronometro = Instance.new("TextLabel")
    textoCronometro.Name        = "TextoCronometro"
    textoCronometro.Size        = UDim2.new(0.6, 0, 0, 36)
    textoCronometro.Position    = UDim2.new(0.5, 0, 0, 12)
    textoCronometro.AnchorPoint = Vector2.new(0.5, 0)
    textoCronometro.BackgroundTransparency = 1
    textoCronometro.TextColor3  = Color3.new(1, 1, 1)
    textoCronometro.TextScaled  = false
    textoCronometro.TextSize    = 20
    textoCronometro.Font        = Enum.Font.GothamBlack
    textoCronometro.Text        = ""
    textoCronometro.ZIndex      = 100
    textoCronometro.Parent      = painelTela

    local bordaCronometro = Instance.new("UIStroke", textoCronometro)
    bordaCronometro.Color     = Color3.new(0, 0, 0)
    bordaCronometro.Thickness = 2

    local painelEstatisticas = Instance.new("Frame")
    painelEstatisticas.Name                 = "PainelEstatisticas"
    painelEstatisticas.Size                 = UDim2.new(0, 200, 0, 74)
    painelEstatisticas.BackgroundColor3     = BG_PAINEL
    painelEstatisticas.BackgroundTransparency = 0.25
    painelEstatisticas.Visible              = false
    painelEstatisticas.LayoutOrder          = 1
    painelEstatisticas.Parent               = containerInfoScore
    Instance.new("UICorner", painelEstatisticas).CornerRadius = UDim.new(0, 10)
    local bordaEstat = Instance.new("UIStroke", painelEstatisticas)
    bordaEstat.Thickness = 1
    bordaEstat.Color     = Color3.fromRGB(55, 55, 70)

    local padEstat = Instance.new("UIPadding", painelEstatisticas)
    padEstat.PaddingTop    = UDim.new(0, 8)
    padEstat.PaddingBottom = UDim.new(0, 8)
    padEstat.PaddingLeft   = UDim.new(0, 10)
    padEstat.PaddingRight  = UDim.new(0, 10)

    local textoEstatisticas = Instance.new("TextLabel")
    textoEstatisticas.Name                 = "TextoDupla"
    textoEstatisticas.Size                 = UDim2.new(1, 0, 0, 22)
    textoEstatisticas.Position             = UDim2.new(0, 0, 0, 0)
    textoEstatisticas.BackgroundTransparency = 1
    textoEstatisticas.TextColor3           = TEXTO_PRIM
    textoEstatisticas.TextXAlignment       = Enum.TextXAlignment.Left
    textoEstatisticas.Font                 = Enum.Font.GothamBold
    textoEstatisticas.TextSize             = 14
    textoEstatisticas.TextTruncate         = Enum.TextTruncate.AtEnd
    textoEstatisticas.Text                 = "Dupla: Ninguém"
    textoEstatisticas.Parent               = painelEstatisticas

    local linhaQuedas = Instance.new("Frame")
    linhaQuedas.Name                 = "LinhaQuedas"
    linhaQuedas.Size                 = UDim2.new(1, 0, 0, 28)
    linhaQuedas.Position             = UDim2.new(0, 0, 1, 0)
    linhaQuedas.AnchorPoint          = Vector2.new(0, 1)
    linhaQuedas.BackgroundTransparency = 1
    linhaQuedas.Parent               = painelEstatisticas

    local lblQuedas = Instance.new("TextLabel")
    lblQuedas.Name                 = "LabelQuedas"
    lblQuedas.Size                 = UDim2.new(0, 68, 1, 0)
    lblQuedas.BackgroundTransparency = 1
    lblQuedas.Text                 = "QUEDAS:"
    lblQuedas.TextColor3           = TEXTO_SEC
    lblQuedas.Font                 = Enum.Font.GothamBold
    lblQuedas.TextSize             = 12
    lblQuedas.TextXAlignment       = Enum.TextXAlignment.Left
    lblQuedas.Parent               = linhaQuedas

    local containerCirculos = Instance.new("Frame")
    containerCirculos.Name                 = "CirculosQuedas"
    containerCirculos.Size                 = UDim2.new(1, -70, 1, 0)
    containerCirculos.Position             = UDim2.new(0, 70, 0, 0)
    containerCirculos.BackgroundTransparency = 1
    containerCirculos.Parent               = linhaQuedas

    local layoutCirculos = Instance.new("UIListLayout", containerCirculos)
    layoutCirculos.FillDirection       = Enum.FillDirection.Horizontal
    layoutCirculos.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layoutCirculos.VerticalAlignment   = Enum.VerticalAlignment.Center
    layoutCirculos.Padding             = UDim.new(0, 10)

    table.clear(marcadoresQuedas)
    for i = 1, 3 do
        local circulo = Instance.new("Frame")
        circulo.Name             = "MarcadorQueda" .. i
        circulo.Size             = UDim2.new(0, 20, 0, 20)
        circulo.BackgroundColor3 = Color3.fromRGB(68, 72, 85)
        circulo.BorderSizePixel  = 0
        circulo.LayoutOrder      = i
        circulo.Parent           = containerCirculos
        Instance.new("UICorner", circulo).CornerRadius = UDim.new(1, 0)

        local bordaCirculo = Instance.new("UIStroke", circulo)
        bordaCirculo.Thickness    = 1.5
        bordaCirculo.Color        = Color3.fromRGB(95, 100, 115)
        bordaCirculo.Transparency = 0.55

        table.insert(marcadoresQuedas, circulo)
    end

    local textoPlacarJogo = Instance.new("TextLabel")
    textoPlacarJogo.Size               = UDim2.new(0, 200, 0, 46)
    textoPlacarJogo.BackgroundColor3   = BG_PAINEL
    textoPlacarJogo.BackgroundTransparency = 0.2
    textoPlacarJogo.TextColor3         = TEXTO_PRIM
    textoPlacarJogo.Font               = Enum.Font.GothamBlack
    textoPlacarJogo.TextScaled         = false
    textoPlacarJogo.TextSize           = 20
    textoPlacarJogo.Visible            = false
    textoPlacarJogo.LayoutOrder        = 2
    textoPlacarJogo.Parent             = containerInfoScore
    Instance.new("UICorner", textoPlacarJogo)
    local bordaPlacar = Instance.new("UIStroke", textoPlacarJogo)
    bordaPlacar.Thickness = 1
    bordaPlacar.Color     = Color3.fromRGB(55, 55, 70)

    local textoValorRodada = Instance.new("TextLabel")
    textoValorRodada.Size               = UDim2.new(0, 140, 0, 34)
    textoValorRodada.BackgroundColor3   = BG_PAINEL
    textoValorRodada.BackgroundTransparency = 0.2
    textoValorRodada.TextColor3         = TEXTO_PRIM
    textoValorRodada.Font               = Enum.Font.GothamBold
    textoValorRodada.TextScaled         = false
    textoValorRodada.TextSize           = 18
    textoValorRodada.Visible            = false
    textoValorRodada.LayoutOrder        = 3
    textoValorRodada.Parent             = containerInfoScore
    Instance.new("UICorner", textoValorRodada)

    painelVira = Instance.new("Frame")
    painelVira.Name            = "ViraDisplayFrame"
    painelVira.Size            = UDim2.new(0, 98, 0, 140)
    painelVira.Position        = UDim2.new(1, -16, 0, 60)
    painelVira.AnchorPoint     = Vector2.new(1, 0)
    painelVira.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    painelVira.BackgroundTransparency = 0.2
    painelVira.Visible         = false
    painelVira.Parent          = painelTela
    Instance.new("UICorner", painelVira).CornerRadius = UDim.new(0, 12)
    local bordaVira = Instance.new("UIStroke", painelVira)
    bordaVira.Thickness = 1
    bordaVira.Color     = Color3.fromRGB(55, 55, 70)

    registrarLayoutResponsivo(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local ehMobile = (vp.Y < 520 or vp.X < 600)

        local larguraInfo = ehMobile and 172 or 200
        containerInfoScore.Size = UDim2.new(0, larguraInfo + 10, 0.5, 0)
        painelEstatisticas.Size = UDim2.new(0, larguraInfo, 0, ehMobile and 64 or 74)
        textoEstatisticas.TextSize = ehMobile and 13 or 14
        textoPlacarJogo.Size = UDim2.new(0, larguraInfo, 0, ehMobile and 38 or 46)
        textoPlacarJogo.TextSize = ehMobile and 17 or 20
        textoValorRodada.Size = UDim2.new(0, ehMobile and 116 or 140, 0, ehMobile and 28 or 34)
        textoValorRodada.TextSize = ehMobile and 15 or 18

        if ehMobile then
            painelVira.Size = UDim2.new(0, 74, 0, 102)
            painelVira.Position = UDim2.new(1, -14, 0, 52)
        else
            painelVira.Size = UDim2.new(0, 98, 0, 140)
            painelVira.Position = UDim2.new(1, -16, 0, 60)
        end
    end)

    return {
        textoCronometro    = textoCronometro,
        textoPlacarJogo    = textoPlacarJogo,
        textoValorRodada   = textoValorRodada,
        textoEstatisticas  = textoEstatisticas,
        painelEstatisticas = painelEstatisticas,
        painelVira         = painelVira,
        marcadoresQuedas   = marcadoresQuedas,
    }
end

-- ==========================================
-- BOTÃO TRUCO (LATERAL DIREITA DA MÃO)
-- ==========================================

function UIManager._CriarBtnTruco()
    btnTruco = Instance.new("TextButton")
    btnTruco.Name            = "BtnTruco"
    btnTruco.Size            = UDim2.new(0, 106, 0, 52)
    btnTruco.Position        = UDim2.new(1, -22, 1, -24)
    btnTruco.AnchorPoint     = Vector2.new(1, 1)
    btnTruco.BackgroundColor3 = Color3.fromRGB(210, 35, 35)
    btnTruco.Text            = "TRUCO!"
    btnTruco.TextColor3      = TEXTO_PRIM
    btnTruco.Font            = Enum.Font.GothamBlack
    btnTruco.TextScaled      = true
    btnTruco.AutoButtonColor = true
    btnTruco.Visible         = false
    btnTruco.ZIndex          = 25
    btnTruco.Parent          = painelTela
    Instance.new("UICorner", btnTruco).CornerRadius = UDim.new(0, 14)

    local bordaTruco = Instance.new("UIStroke", btnTruco)
    bordaTruco.Thickness = 2
    bordaTruco.Color     = Color3.fromRGB(255, 90, 90)

    local tsConstraint = Instance.new("UITextSizeConstraint", btnTruco)
    tsConstraint.MaxTextSize = 20

    registrarLayoutResponsivo(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if vp.X < 520 then
            btnTruco.Size = UDim2.new(0, 96, 0, 44)
            btnTruco.Position = UDim2.new(1, -12, 1, -150)
        elseif vp.Y < 520 then
            btnTruco.Size = UDim2.new(0, 94, 0, 44)
            btnTruco.Position = UDim2.new(1, -14, 1, -64)
        else
            btnTruco.Size = UDim2.new(0, 108, 0, 52)
            btnTruco.Position = UDim2.new(1, -24, 1, -76)
        end
    end)

    btnTruco.Activated:Connect(function()
        Eventos.TrucoEvent:FireServer("Request")
        UIManager.PermitirTruco(false)
    end)
end

-- ==========================================
-- CONTROLES DE CÂMERA E GRADE 2D OPCIONAL
-- ==========================================

function UIManager._CriarControlesMesa()
    painelControlesMesa = Instance.new("Frame")
    painelControlesMesa.Name                 = "PainelControlesMesa"
    painelControlesMesa.Size                 = UDim2.new(0, 96, 0, 42)
    painelControlesMesa.Position             = UDim2.new(1, -124, 0, 60)
    painelControlesMesa.AnchorPoint          = Vector2.new(1, 0)
    painelControlesMesa.BackgroundTransparency = 1
    painelControlesMesa.Visible              = false
    painelControlesMesa.ZIndex               = 25
    painelControlesMesa.Parent               = painelTela

    local layout = Instance.new("UIListLayout", painelControlesMesa)
    layout.FillDirection       = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment   = Enum.VerticalAlignment.Top
    layout.Padding             = UDim.new(0, 8)

    local function criarBotaoControle(nome, icone, layoutOrder, largura)
        local btn = Instance.new("TextButton")
        btn.Name                   = nome
        btn.Size                   = UDim2.new(0, largura or 42, 0, 38)
        btn.BackgroundColor3       = Color3.fromRGB(28, 28, 36)
        btn.BackgroundTransparency = 0.18
        btn.Text                   = icone
        btn.TextSize               = 14
        btn.TextColor3             = TEXTO_PRIM
        btn.Font                   = Enum.Font.GothamBold
        btn.AutoButtonColor        = true
        btn.LayoutOrder            = layoutOrder
        btn.ZIndex                 = 26
        btn.Parent                 = painelControlesMesa
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local borda = Instance.new("UIStroke", btn)
        borda.Thickness    = 1.4
        borda.Color        = Color3.new(1, 1, 1)
        borda.Transparency = 0.72
        return btn, borda
    end

    local bordaCam
    btnCamera, bordaCam = criarBotaoControle("BtnCameraLivre", "📷 Livre", 1, 92)
    local borda2D
    btnGrade2D, borda2D = criarBotaoControle("BtnGrade2DOpcional", "🃏", 2, 38)
    btnGrade2D.TextSize = 18

    local function sincronizarBotaoCamera(cameraLivre)
        if not btnCamera then return end
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if vp.X < 520 then
            btnCamera.Size = UDim2.new(0, 38, 0, 38)
            btnCamera.Text = cameraLivre and "🎯" or "📷"
            btnCamera.TextSize = 18
        else
            btnCamera.Size = UDim2.new(0, 92, 0, 38)
            btnCamera.Text = cameraLivre and "🎯 Mesa" or "📷 Livre"
            btnCamera.TextSize = 13
        end
        btnCamera.BackgroundColor3 = cameraLivre and Color3.fromRGB(52, 42, 22) or Color3.fromRGB(28, 28, 36)
        if bordaCam then
            bordaCam.Color = cameraLivre and ACENTO or Color3.new(1, 1, 1)
            bordaCam.Transparency = cameraLivre and 0.15 or 0.72
        end
    end

    local function sincronizarBotao2D(ativo)
        if not btnGrade2D then return end
        btnGrade2D.BackgroundColor3 = ativo and Color3.fromRGB(28, 56, 42) or Color3.fromRGB(28, 28, 36)
        if borda2D then
            borda2D.Color = ativo and VERDE or Color3.new(1, 1, 1)
            borda2D.Transparency = ativo and 0.15 or 0.72
        end
    end
    atualizarVisualGrade2D = sincronizarBotao2D

    btnCamera.Activated:Connect(function()
        CameraManager.AlternarCameraLivre()
    end)

    btnGrade2D.Activated:Connect(function()
        local ativo = TableUI.AlternarVisivel()
        sincronizarBotao2D(ativo)
    end)

    CameraManager.AoMudarModoCamera(function(cameraLivre)
        sincronizarBotaoCamera(cameraLivre)
    end)
    sincronizarBotaoCamera(false)
    sincronizarBotao2D(TableUI.EstaVisivel())

    registrarLayoutResponsivo(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        sincronizarBotaoCamera(CameraManager.EstaCameraLivre())
        if vp.X < 520 then
            layout.FillDirection = Enum.FillDirection.Vertical
            painelControlesMesa.Size = UDim2.new(0, 42, 0, 86)
            painelControlesMesa.Position = UDim2.new(1, -14, 0, 162)
        elseif vp.Y < 520 then
            layout.FillDirection = Enum.FillDirection.Horizontal
            painelControlesMesa.Size = UDim2.new(0, 140, 0, 40)
            painelControlesMesa.Position = UDim2.new(1, -96, 0, 52)
        else
            layout.FillDirection = Enum.FillDirection.Horizontal
            painelControlesMesa.Size = UDim2.new(0, 140, 0, 40)
            painelControlesMesa.Position = UDim2.new(1, -124, 0, 60)
        end
    end)
end

-- ==========================================
-- BOTÕES DE EMOTE / SINAIS (NA MESA)
-- ==========================================

function UIManager._CriarBotoesEmote()
    painelEmotes = Instance.new("Frame")
    painelEmotes.Name               = "PainelEmotes"
    painelEmotes.Size               = UDim2.new(0, 50, 0, 104)
    painelEmotes.Position           = UDim2.new(1, -16, 0.58, 0)
    painelEmotes.AnchorPoint        = Vector2.new(1, 0.5)
    painelEmotes.BackgroundTransparency = 1
    painelEmotes.Visible            = false
    painelEmotes.ZIndex             = 20
    painelEmotes.Parent             = painelTela

    local layout = Instance.new("UIListLayout", painelEmotes)
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.Padding             = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local function criarBotaoEmote(icone, nomeSinal)
        local btn = Instance.new("TextButton")
        btn.Size            = UDim2.new(0, 44, 0, 44)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        btn.BackgroundTransparency = 0.25
        btn.Text            = icone
        btn.TextSize        = 22
        btn.TextColor3      = TEXTO_PRIM
        btn.AutoButtonColor = true
        btn.Parent          = painelEmotes
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local borda = Instance.new("UIStroke", btn)
        borda.Thickness    = 1.2
        borda.Color        = Color3.new(1, 1, 1)
        borda.Transparency = 0.8

        btn.Activated:Connect(function()
            if callbackEmote then callbackEmote(nomeSinal) end
        end)
    end

    criarBotaoEmote("🖐️", "Sinal_Mao")
    criarBotaoEmote("👀", "Sinal_Olhar")

    registrarLayoutResponsivo(function()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if vp.X < 520 then
            painelEmotes.Position = UDim2.new(1, -14, 0, 266)
            painelEmotes.AnchorPoint = Vector2.new(1, 0)
        elseif vp.Y < 520 then
            painelEmotes.Position = UDim2.new(1, -14, 0.58, 0)
            painelEmotes.AnchorPoint = Vector2.new(1, 0.5)
        else
            painelEmotes.Position = UDim2.new(1, -16, 0.58, 0)
            painelEmotes.AnchorPoint = Vector2.new(1, 0.5)
        end
    end)
end

function UIManager.PermitirTruco(permitido)
    possoPedirTruco = permitido
    if btnTruco then btnTruco.Visible = eMinhaVez and possoPedirTruco end
end

function UIManager.DefinirVira(val, naipe)
    if not painelVira then return end
    for _, filho in ipairs(painelVira:GetChildren()) do
        if not filho:IsA("UICorner") and not filho:IsA("UIStroke") then filho:Destroy() end
    end

    viraAtual = { valor = val, naipe = naipe }
    painelVira.Visible = estaSentado
    local tituloLbl = Instance.new("TextLabel")
    tituloLbl.Text               = "VIRA"
    tituloLbl.Size               = UDim2.new(1, 0, 0.18, 0)
    tituloLbl.BackgroundTransparency = 1
    tituloLbl.TextColor3         = Color3.fromRGB(255, 215, 0)
    tituloLbl.Font               = Enum.Font.GothamBlack
    tituloLbl.TextScaled         = true
    tituloLbl.Parent             = painelVira

    local imgVira = Instance.new("ImageLabel")
    imgVira.Size             = UDim2.new(0.72, 0, 0.62, 0)
    imgVira.Position         = UDim2.new(0.5, 0, 0.5, 0)
    imgVira.AnchorPoint      = Vector2.new(0.5, 0.5)
    imgVira.BackgroundTransparency = 1
    imgVira.Parent           = painelVira
    local ratio = Instance.new("UIAspectRatioConstraint", imgVira)
    ratio.AspectRatio = 93 / 133
    imgViraAtual             = imgVira

    CardSettings.AplicarSkinCarta(imgVira, val, naipe, false, dadosJogador.SkinEquipada or "Padrao")

    local textoCarta = Instance.new("TextLabel")
    textoCarta.Text               = val .. " " .. naipe
    textoCarta.Size               = UDim2.new(1, 0, 0.18, 0)
    textoCarta.Position           = UDim2.new(0, 0, 0.82, 0)
    textoCarta.BackgroundTransparency = 1
    textoCarta.TextColor3         = TEXTO_PRIM
    textoCarta.Font               = Enum.Font.GothamBold
    textoCarta.TextScaled         = true
    textoCarta.Parent             = painelVira
    local constraintCarta = Instance.new("UITextSizeConstraint", textoCarta)
    constraintCarta.MaxTextSize = 16
end

function UIManager._CriarMenuAdmin()
    if jogadorLocal.Name ~= "Nick0369me" then return end

    local painelAdmin = Instance.new("Frame")
    painelAdmin.Size            = UDim2.new(0, 260, 0, 170)
    painelAdmin.Position        = UDim2.new(0.5, 0, 0, 10)
    painelAdmin.AnchorPoint     = Vector2.new(0.5, 0)
    painelAdmin.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    painelAdmin.Visible         = false
    painelAdmin.ZIndex          = 200
    painelAdmin.Parent          = painelTela
    Instance.new("UICorner", painelAdmin).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", painelAdmin).Color = Color3.new(1, 0.8, 0)

    local titulo = Instance.new("TextLabel", painelAdmin)
    titulo.Size               = UDim2.new(1, 0, 0, 30)
    titulo.Text               = "🛡️ PAINEL ADMIN (F4)"
    titulo.TextColor3         = Color3.new(1, 0.8, 0)
    titulo.Font               = Enum.Font.GothamBlack
    titulo.BackgroundTransparency = 1

    local inputNome = Instance.new("TextBox", painelAdmin)
    inputNome.Size            = UDim2.new(0.9, 0, 0, 35)
    inputNome.Position        = UDim2.new(0.05, 0, 0, 40)
    inputNome.PlaceholderText = "Nome do Jogador"
    inputNome.Text            = jogadorLocal.Name
    inputNome.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputNome.TextColor3      = Color3.new(1, 1, 1)
    Instance.new("UICorner", inputNome)

    local inputValor = Instance.new("TextBox", painelAdmin)
    inputValor.Size            = UDim2.new(0.9, 0, 0, 35)
    inputValor.Position        = UDim2.new(0.05, 0, 0, 85)
    inputValor.PlaceholderText = "Quantidade"
    inputValor.Text            = "300"
    inputValor.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputValor.TextColor3      = Color3.new(1, 1, 1)
    Instance.new("UICorner", inputValor)

    local btnAdd = Instance.new("TextButton", painelAdmin)
    btnAdd.Size            = UDim2.new(0.42, 0, 0, 35)
    btnAdd.Position        = UDim2.new(0.05, 0, 0, 125)
    btnAdd.BackgroundColor3 = Color3.fromRGB(0, 150, 60)
    btnAdd.Text            = "+ DAR PTS"
    btnAdd.TextColor3      = Color3.new(1, 1, 1)
    btnAdd.Font            = Enum.Font.GothamBold
    Instance.new("UICorner", btnAdd)

    local btnRem = Instance.new("TextButton", painelAdmin)
    btnRem.Size            = UDim2.new(0.42, 0, 0, 35)
    btnRem.Position        = UDim2.new(0.53, 0, 0, 125)
    btnRem.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnRem.Text            = "- TIRAR PTS"
    btnRem.TextColor3      = Color3.new(1, 1, 1)
    btnRem.Font            = Enum.Font.GothamBold
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
    painelCorte.Size            = UDim2.new(0, 400, 0, 220)
    painelCorte.Position        = UDim2.new(0.5, 0, 0.45, 0)
    painelCorte.AnchorPoint     = Vector2.new(0.5, 0.5)
    painelCorte.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    painelCorte.Visible         = false
    painelCorte.ZIndex          = 110 -- Garante ficar por cima da mesa
    painelCorte.Parent          = painelTela
    Instance.new("UICorner", painelCorte).CornerRadius = UDim.new(0, 15)

    local fundoBarraTimer = Instance.new("Frame")
    fundoBarraTimer.Size            = UDim2.new(1, 0, 0, 6)
    fundoBarraTimer.Position        = UDim2.new(0, 0, 1, 0)
    fundoBarraTimer.AnchorPoint     = Vector2.new(0, 1)
    fundoBarraTimer.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    fundoBarraTimer.Parent          = painelCorte

    barraTempoCorte = Instance.new("Frame")
    barraTempoCorte.Size            = UDim2.new(1, 0, 1, 0)
    barraTempoCorte.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    barraTempoCorte.BorderSizePixel = 0
    barraTempoCorte.Parent          = fundoBarraTimer

    local tituloCorte = Instance.new("TextLabel")
    tituloCorte.Text               = "SUA VEZ DE CORTAR"
    tituloCorte.Size               = UDim2.new(1, 0, 0.4, 0)
    tituloCorte.TextColor3         = Color3.fromRGB(255, 255, 255)
    tituloCorte.Font               = Enum.Font.GothamBold
    tituloCorte.TextSize           = 24
    tituloCorte.BackgroundTransparency = 1
    tituloCorte.Parent             = painelCorte

    local containerBotoes = Instance.new("Frame")
    containerBotoes.Size               = UDim2.new(0.9, 0, 0.4, 0)
    containerBotoes.Position           = UDim2.new(0.5, 0, 0.7, 0)
    containerBotoes.AnchorPoint        = Vector2.new(0.5, 0.5)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.Parent             = painelCorte

    local layoutBotoes = Instance.new("UIListLayout")
    layoutBotoes.FillDirection       = Enum.FillDirection.Horizontal
    layoutBotoes.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutBotoes.Padding             = UDim.new(0, 20)
    layoutBotoes.Parent              = containerBotoes

    local function criarBotaoCorte(texto)
        local btn = Instance.new("TextButton")
        btn.Text            = texto
        btn.Size            = UDim2.new(0, 90, 0, 70)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.TextColor3      = Color3.fromRGB(255, 255, 255)
        btn.Font            = Enum.Font.GothamBold
        btn.TextSize        = 22
        btn.Parent          = containerBotoes
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

function UIManager.MostrarOpcoesCorte(tempoLimite)
    if painelCorte then
        painelCorte.Visible     = true
        barraTempoCorte.Size    = UDim2.new(1, 0, 1, 0)
        local tweenInfo         = TweenInfo.new(tempoLimite, Enum.EasingStyle.Linear)
        TweenService:Create(barraTempoCorte, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)}):Play()

        task.delay(tempoLimite + 0.5, function()
            if painelCorte.Visible then painelCorte.Visible = false end
        end)
    end
end

function UIManager.OcultarMenuCorte()
    if painelCorte then painelCorte.Visible = false end
end

-- ==========================================
-- MENU / MODAL MÃO DE ONZE
-- ==========================================

function UIManager._CriarMenuMaoDeOnze()
    painelMaoDeOnze = Instance.new("Frame")
    painelMaoDeOnze.Name                   = "PainelMaoDeOnze"
    painelMaoDeOnze.Position               = UDim2.new(0.5, 0, 0.44, 0)
    painelMaoDeOnze.AnchorPoint            = Vector2.new(0.5, 0.5)
    painelMaoDeOnze.Size                   = UDim2.new(0.9, 0, 0, 0)
    painelMaoDeOnze.AutomaticSize          = Enum.AutomaticSize.Y
    painelMaoDeOnze.ZIndex                 = 160
    painelMaoDeOnze.BackgroundColor3       = BG_ESCURO
    painelMaoDeOnze.Visible                = false
    painelMaoDeOnze.Parent                 = painelTela

    local corner = Instance.new("UICorner", painelMaoDeOnze)
    corner.CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", painelMaoDeOnze)
    stroke.Color     = ACENTO
    stroke.Thickness = 2

    local constraint = Instance.new("UISizeConstraint", painelMaoDeOnze)
    constraint.MaxSize = Vector2.new(440, 310)

    local padding = Instance.new("UIPadding", painelMaoDeOnze)
    padding.PaddingTop    = UDim.new(0, 14)
    padding.PaddingBottom = UDim.new(0, 14)
    padding.PaddingLeft   = UDim.new(0, 14)
    padding.PaddingRight  = UDim.new(0, 14)

    local layout = Instance.new("UIListLayout", painelMaoDeOnze)
    layout.FillDirection       = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Padding             = UDim.new(0, 10)

    -- Título (LayoutOrder = 1)
    local titulo = Instance.new("TextLabel")
    titulo.Name                   = "Titulo"
    titulo.LayoutOrder            = 1
    titulo.Size                   = UDim2.new(1, 0, 0, 26)
    titulo.BackgroundTransparency = 1
    titulo.Text                   = "🔥 MÃO DE ONZE (VALE 3 PONTOS)"
    titulo.TextColor3             = ACENTO
    titulo.Font                   = Enum.Font.GothamBlack
    titulo.TextSize               = 18
    titulo.Parent                 = painelMaoDeOnze

    -- Subtítulo (LayoutOrder = 2)
    local subtitulo = Instance.new("TextLabel")
    subtitulo.Name                   = "Subtitulo"
    subtitulo.LayoutOrder            = 2
    subtitulo.Size                   = UDim2.new(1, 0, 0, 18)
    subtitulo.BackgroundTransparency = 1
    subtitulo.Text                   = "Cartas do seu Parceiro:"
    subtitulo.TextColor3             = TEXTO_PRIM
    subtitulo.Font                   = Enum.Font.GothamBold
    subtitulo.TextSize               = 14
    subtitulo.Parent                 = painelMaoDeOnze

    -- Container Cartas Parceiro (LayoutOrder = 3)
    containerCartasParceiro = Instance.new("Frame")
    containerCartasParceiro.Name                   = "ContainerCartasParceiro"
    containerCartasParceiro.LayoutOrder            = 3
    containerCartasParceiro.Size                   = UDim2.new(1, 0, 0, 120)
    containerCartasParceiro.BackgroundTransparency = 1
    containerCartasParceiro.Parent                 = painelMaoDeOnze

    local layoutCartas = Instance.new("UIListLayout", containerCartasParceiro)
    layoutCartas.FillDirection       = Enum.FillDirection.Horizontal
    layoutCartas.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutCartas.VerticalAlignment   = Enum.VerticalAlignment.Center
    layoutCartas.Padding             = UDim.new(0, 10)

    -- StatusLabel (LayoutOrder = 4)
    statusLabelMaoDeOnze = Instance.new("TextLabel")
    statusLabelMaoDeOnze.Name                   = "StatusLabel"
    statusLabelMaoDeOnze.LayoutOrder            = 4
    statusLabelMaoDeOnze.Size                   = UDim2.new(1, 0, 0, 20)
    statusLabelMaoDeOnze.BackgroundTransparency = 1
    statusLabelMaoDeOnze.Text                   = "Analise o jogo e decida com sua dupla!"
    statusLabelMaoDeOnze.TextColor3             = TEXTO_SEC
    statusLabelMaoDeOnze.Font                   = Enum.Font.GothamMedium
    statusLabelMaoDeOnze.TextSize               = 14
    statusLabelMaoDeOnze.Parent                 = painelMaoDeOnze

    -- Container de Botões (LayoutOrder = 5)
    local containerBotoes = Instance.new("Frame")
    containerBotoes.Name                   = "ContainerBotoes"
    containerBotoes.LayoutOrder            = 5
    containerBotoes.Size                   = UDim2.new(1, 0, 0, 44)
    containerBotoes.BackgroundTransparency = 1
    containerBotoes.Parent                 = painelMaoDeOnze

    local layoutBotoes = Instance.new("UIListLayout", containerBotoes)
    layoutBotoes.FillDirection       = Enum.FillDirection.Horizontal
    layoutBotoes.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutBotoes.VerticalAlignment   = Enum.VerticalAlignment.Center
    layoutBotoes.Padding             = UDim.new(0, 12)

    -- Botão JOGAR
    btnJogarMaoDeOnze = Instance.new("TextButton")
    btnJogarMaoDeOnze.Name            = "BtnJogar"
    btnJogarMaoDeOnze.Size            = UDim2.new(0.48, 0, 1, 0)
    btnJogarMaoDeOnze.BackgroundColor3 = VERDE
    btnJogarMaoDeOnze.Text            = "JOGAR (VALE 3)"
    btnJogarMaoDeOnze.TextColor3      = TEXTO_PRIM
    btnJogarMaoDeOnze.Font            = Enum.Font.GothamBold
    btnJogarMaoDeOnze.TextSize        = 14
    btnJogarMaoDeOnze.AutoButtonColor = true
    btnJogarMaoDeOnze.Parent          = containerBotoes
    Instance.new("UICorner", btnJogarMaoDeOnze).CornerRadius = UDim.new(0, 8)

    btnJogarMaoDeOnze.Activated:Connect(function()
        if statusLabelMaoDeOnze then statusLabelMaoDeOnze.Text = "Decisão enviada..." end
        btnJogarMaoDeOnze.Active = false
        btnCorrerMaoDeOnze.Active = false
        Eventos.GameStatusEvent:FireServer("HandOfElevenDecision", "JOGAR")
    end)

    -- Botão CORRER
    btnCorrerMaoDeOnze = Instance.new("TextButton")
    btnCorrerMaoDeOnze.Name            = "BtnCorrer"
    btnCorrerMaoDeOnze.Size            = UDim2.new(0.48, 0, 1, 0)
    btnCorrerMaoDeOnze.BackgroundColor3 = VERMELHO
    btnCorrerMaoDeOnze.Text            = "CORRER (-1 PT)"
    btnCorrerMaoDeOnze.TextColor3      = TEXTO_PRIM
    btnCorrerMaoDeOnze.Font            = Enum.Font.GothamBold
    btnCorrerMaoDeOnze.TextSize        = 14
    btnCorrerMaoDeOnze.AutoButtonColor = true
    btnCorrerMaoDeOnze.Parent          = containerBotoes
    Instance.new("UICorner", btnCorrerMaoDeOnze).CornerRadius = UDim.new(0, 8)

    btnCorrerMaoDeOnze.Activated:Connect(function()
        if statusLabelMaoDeOnze then statusLabelMaoDeOnze.Text = "Decisão enviada..." end
        btnJogarMaoDeOnze.Active = false
        btnCorrerMaoDeOnze.Active = false
        Eventos.GameStatusEvent:FireServer("HandOfElevenDecision", "CORRER")
    end)
end

function UIManager.MostrarDecisaoMaoDeOnze(dados)
    if not painelMaoDeOnze or not containerCartasParceiro then return end

    -- Limpa as cartas anteriores mantendo o UIListLayout
    for _, filho in ipairs(containerCartasParceiro:GetChildren()) do
        if not filho:IsA("UIListLayout") then
            filho:Destroy()
        end
    end

    local cartasParceiro = (type(dados) == "table" and dados.MaoParceiro) or dados

    if type(cartasParceiro) == "table" then
        for _, carta in ipairs(cartasParceiro) do
            if type(carta) == "table" and carta.Value and carta.Suit then
                local img = Instance.new("ImageLabel")
                img.Size                   = UDim2.new(0, 80, 0, 115)
                img.BackgroundTransparency = 1
                local c = Instance.new("UICorner", img)
                c.CornerRadius             = UDim.new(0, 6)
                img.Parent                 = containerCartasParceiro

                CardSettings.AplicarSkinCarta(img, carta.Value, carta.Suit, false, "Padrao")
            end
        end
    end

    if statusLabelMaoDeOnze then
        statusLabelMaoDeOnze.Text = "Analise o jogo e decida com sua dupla!"
    end
    if btnJogarMaoDeOnze then
        btnJogarMaoDeOnze.Active = true
    end
    if btnCorrerMaoDeOnze then
        btnCorrerMaoDeOnze.Active = true
    end

    painelMaoDeOnze.Visible = true
end

function UIManager.OcultarDecisaoMaoDeOnze()
    if painelMaoDeOnze then
        painelMaoDeOnze.Visible = false
    end
end

function UIManager.MostrarAvisoFuga(texto)
    local lblFuga = Instance.new("TextLabel")
    lblFuga.Size               = UDim2.new(0.8, 0, 0.2, 0)
    lblFuga.Position           = UDim2.new(0.5, 0, 0.35, 0)
    lblFuga.AnchorPoint        = Vector2.new(0.5, 0.5)
    lblFuga.BackgroundTransparency = 1
    lblFuga.TextColor3         = Color3.fromRGB(255, 60, 60)
    lblFuga.TextStrokeTransparency = 0
    lblFuga.Font               = Enum.Font.GothamBlack
    lblFuga.TextScaled         = true
    lblFuga.Text               = texto
    lblFuga.Parent             = painelTela

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
    lblVencedor.Size               = UDim2.new(0.8, 0, 0.2, 0)
    lblVencedor.Position           = UDim2.new(0.5, 0, 0.4, 0)
    lblVencedor.AnchorPoint        = Vector2.new(0.5, 0.5)
    lblVencedor.BackgroundTransparency = 1
    lblVencedor.TextColor3         = Color3.fromRGB(255, 215, 0)
    lblVencedor.TextStrokeTransparency = 0
    lblVencedor.Font               = Enum.Font.GothamBlack
    lblVencedor.TextScaled         = true
    lblVencedor.Text               = nomeEquipe
    lblVencedor.Parent             = painelTela

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
    fundoEscuro.Size               = UDim2.new(1, 0, 1, 0)
    fundoEscuro.BackgroundColor3   = Color3.new(0, 0, 0)
    fundoEscuro.BackgroundTransparency = 1
    fundoEscuro.ZIndex             = 200
    fundoEscuro.Parent             = painelTela

    local lbl = Instance.new("TextLabel")
    lbl.Text               = texto
    lbl.Size               = UDim2.new(0.9, 0, 0.2, 0)
    lbl.Position           = UDim2.new(0.5, 0, 0.5, 0)
    lbl.AnchorPoint        = Vector2.new(0.5, 0.5)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3         = Color3.fromRGB(255, 215, 0)
    lbl.Font               = Enum.Font.GothamBlack
    lbl.TextScaled         = true
    lbl.TextTransparency   = 1
    lbl.ZIndex             = 201
    lbl.Parent             = painelTela

    local bordaLetra = Instance.new("UIStroke", lbl)
    bordaLetra.Thickness    = 3
    bordaLetra.Color        = Color3.new(1, 1, 1)
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
    if visivel then LobbyUI.OcultarCodigoPrivado() end
    if btnTruco then btnTruco.Visible = false end
    if painelCorte then painelCorte.Visible = false end
    if not visivel then
        UIManager.OcultarDecisaoMaoDeOnze()
    end
end

function UIManager.DefinirMeuAssento(nomeAssento)
    assentoAtualRef = nomeAssento
    CameraManager.DefinirMeuAssento(nomeAssento)
    if estaSentado and mesaAtualRef and nomeAssento then
        CameraManager.AtivarModoMesa(mesaAtualRef, nomeAssento)
    end
end

function UIManager.DefinirCallbackEmote(callback)
    callbackEmote = callback
end

function UIManager.MostrarSinal(remetente, tipoSinal)
    if not remetente or not remetente.Character or not remetente.Character:FindFirstChild("Head") then return end

    local bg = Instance.new("BillboardGui")
    bg.Size      = UDim2.new(0, 100, 0, 100)
    bg.Adornee   = remetente.Character.Head
    bg.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size               = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = (tipoSinal == "Sinal_Mao" or tipoSinal == "LevantarMao") and "🖐️" or "👀"
    lbl.TextSize           = 50
    bg.Parent = remetente.Character.Head

    local destaque = Instance.new("Highlight")
    destaque.Adornee         = remetente.Character
    destaque.FillTransparency = 1
    destaque.OutlineColor    = Color3.new(1, 1, 0)
    destaque.Parent          = remetente.Character

    task.delay(2, function()
        bg:Destroy()
        destaque:Destroy()
    end)
end

-- ==========================================
-- SENTAR / LEVANTAR
-- ==========================================

function UIManager.DefinirSentado(s)
    estaSentado = s
    LobbyUI.DefinirSentado(s)
    if s then LeaderboardUI.Fechar() end
    if painelEmotes then painelEmotes.Visible = s end
    if painelControlesMesa then painelControlesMesa.Visible = s end
    if btnTruco    then btnTruco.Visible    = s and eMinhaVez and possoPedirTruco end
    if s then
        TableUI.DefinirVisivel(true)
        if atualizarVisualGrade2D then atualizarVisualGrade2D(true) end
        if mesaAtualRef and assentoAtualRef then
            CameraManager.AtivarModoMesa(mesaAtualRef, assentoAtualRef)
        end
    else
        assentoAtualRef = nil
        CameraManager.DesativarModoMesa()
        TableUI.DefinirVisivel(false)
        if atualizarVisualGrade2D then atualizarVisualGrade2D(false) end
        UIManager.ResetTotal()
    end
end

function UIManager.ResetTotal()
    viraAtual = nil
    imgViraAtual = nil
    SoundManager.DefinirModoTensao(false)
    TableUI.DefinirModoLateral(false)
    HandUI.Limpar()
    TableUI.Limpar()
    ScoreUI.DefinirVisibilidade(false)
    ScoreUI.OcultarPlacar()
    ScoreUI.AtualizarStatus("", 0)
    ScoreUI.AtualizarEstatisticas("Ninguém", 0, 0, false, nil)
    TrucoUI.Ocultar()
    UIManager.OcultarOpcoesJogada()
    UIManager.OcultarMenuCorte()
    UIManager.OcultarDecisaoMaoDeOnze()
end

function UIManager.AtualizarTurno(nomeJogador, numQueda)
    eMinhaVez = (nomeJogador == jogadorLocal.Name)
    HandUI.DefinirEstado(eMinhaVez, numQueda, trucoPendente, nil)

    if btnTruco then
        btnTruco.Visible = eMinhaVez and possoPedirTruco

        if     valorRodadaAtual == 1  then btnTruco.Text = "TRUCO!"
        elseif valorRodadaAtual == 3  then btnTruco.Text = "SEIS!"
        elseif valorRodadaAtual == 6  then btnTruco.Text = "NOVE!"
        elseif valorRodadaAtual == 9  then btnTruco.Text = "DOZE!"
        else   btnTruco.Visible = false end
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

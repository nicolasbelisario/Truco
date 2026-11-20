local TweenService = game:GetService("TweenService")
local GuideAvatar = require(script.Parent:WaitForChild("GuideAvatar"))

local TutorialUI = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local OURO_VIVO  = Color3.fromRGB(255, 222, 72)
local VERDE      = Color3.fromRGB(39, 174, 96)
local AZUL       = Color3.fromRGB(45, 138, 220)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(185, 188, 202)

-- Referências de Slides
local menuTutorial, imgTutorial, textoTutorial, tituloTutorial, indicadorSlide
local btnAnteriorTut, btnProximoTut, btnTestarSoloSlide, btnInterativoSlide
local retratoSlide = nil
local slideAtualTutorial = 1

-- Referências de Boas-Vindas (1ª sessão / Barraca)
local backdropBoasVindas, modalBoasVindas, tituloBoasVindas, textoBoasVindas
local btnPularBoasVindas = nil
local retratoBoasVindas = nil

local btnTutorialAbrir = nil
local estaSentado = false

-- Callbacks injetados pelo UIManager
local callbacksConfig = {
    onIniciarPartidaTutorial = nil,
    onIrMesaSolo = nil,
    onMarcarVisto = nil,
}

local SLIDES_TUTORIAL = {
    {
        Titulo = "O OBJETIVO",
        Texto  = "Bem-vindo ao Truco! O jogo é disputado em duplas (2 contra 2). O objetivo da sua equipe é alcançar 12 pontos antes dos adversários.",
        Imagem = "rbxassetid://94577408525560",
    },
    {
        Titulo = "A RODADA",
        Texto  = "Cada rodada (Mão) vale 1 ponto. Para ganhar, sua dupla precisa vencer 2 de 3 quedas. Cada jogador joga uma carta por queda, a mais forte vence.",
        Imagem = "rbxassetid://117539543208859",
    },
    {
        Titulo = "A FORÇA",
        Texto  = "A força das cartas normais, da mais fraca para a mais forte, é: 4, 5, 6, 7, Q, J, K, A, 2, 3. Naipe não importa aqui, apenas o número!",
        Imagem = "rbxassetid://73972302411191",
    },
    {
        Titulo = "AS MANILHAS",
        Texto  = "A Manilha é a carta logo acima da Vira (ex: Vira 5 → Manilha 6). Suas Manilhas brilham em dourado na mão: ZAP ♣️ > COPAS ♥️ > ESPADAS ♠️ > OUROS ♦️!",
        Imagem = "rbxassetid://109233300765686",
    },
    {
        Titulo = "TRUCO!",
        Texto  = "Acha que tem cartas boas? Clique em TRUCO! Isso aumenta o valor da Mão para 3 pontos. Os adversários podem Aceitar (Descer), Fugir ou puxar SEIS (6)!",
        Imagem = "rbxassetid://86983343730484",
    },
    {
        Titulo = "PRONTO PARA JOGAR!",
        Texto  = "Jogue cartas Cobertas a partir da 2ª queda para esconder seu jogo e use os Sinais (Q / E) com seu parceiro. Teste agora na Mesa Solo contra Bots!",
        Imagem = "rbxassetid://75845041324394",
    },
}

local function notificarTutorialVisto()
    if callbacksConfig.onMarcarVisto then
        callbacksConfig.onMarcarVisto()
    end
end

local function atualizarSlideTutorial()
    if not menuTutorial then return end
    local dados = SLIDES_TUTORIAL[slideAtualTutorial]
    tituloTutorial.Text = dados.Titulo
    textoTutorial.Text  = dados.Texto
    if indicadorSlide then
        indicadorSlide.Text = string.format("%d / %d", slideAtualTutorial, #SLIDES_TUTORIAL)
    end

    if dados.Imagem ~= "" then
        imgTutorial.Image = dados.Imagem
        imgTutorial.BackgroundTransparency = 1
    else
        imgTutorial.Image = ""
        imgTutorial.BackgroundTransparency = 0
    end

    local ehUltimo = (slideAtualTutorial == #SLIDES_TUTORIAL)
    btnAnteriorTut.Visible = (slideAtualTutorial > 1)

    if btnInterativoSlide then
        btnInterativoSlide.Visible = (not estaSentado) and (not ehUltimo)
    end

    if ehUltimo then
        if btnTestarSoloSlide then
            btnTestarSoloSlide.Visible = not estaSentado
        end
        if not estaSentado then
            btnAnteriorTut.Size     = UDim2.new(0.24, 0, 0, 42)
            btnAnteriorTut.Position = UDim2.new(0.05, 0, 1, -52)
            btnAnteriorTut.Text     = "< VOLTAR"

            btnProximoTut.Size             = UDim2.new(0.24, 0, 0, 42)
            btnProximoTut.Position         = UDim2.new(0.71, 0, 1, -52)
            btnProximoTut.Text             = "FECHAR"
            btnProximoTut.BackgroundColor3 = BG_BOTAO
        else
            btnAnteriorTut.Size     = UDim2.new(0.4, 0, 0, 44)
            btnAnteriorTut.Position = UDim2.new(0.07, 0, 1, -54)
            btnAnteriorTut.Text     = "< ANTERIOR"

            btnProximoTut.Size             = UDim2.new(0.4, 0, 0, 44)
            btnProximoTut.Position         = UDim2.new(0.53, 0, 1, -54)
            btnProximoTut.Text             = "ENTENDI!"
            btnProximoTut.BackgroundColor3 = AZUL
        end
    else
        if btnTestarSoloSlide then
            btnTestarSoloSlide.Visible = false
        end
        btnAnteriorTut.Size     = UDim2.new(0.36, 0, 0, 42)
        btnAnteriorTut.Position = UDim2.new(0.06, 0, 1, -52)
        btnAnteriorTut.Text     = "< ANTERIOR"

        btnProximoTut.Size             = UDim2.new(0.36, 0, 0, 42)
        btnProximoTut.Position         = UDim2.new(0.58, 0, 1, -52)
        btnProximoTut.Text             = "PRÓXIMO >"
        btnProximoTut.BackgroundColor3 = VERDE
    end

    if retratoSlide then
        retratoSlide:PulsarFala()
    end
end

local function criarModalBoasVindas(pai)
    backdropBoasVindas = Instance.new("Frame")
    backdropBoasVindas.Name = "BackdropBoasVindasTutorial"
    backdropBoasVindas.Size = UDim2.new(1, 0, 1, 0)
    backdropBoasVindas.BackgroundColor3 = Color3.new(0, 0, 0)
    backdropBoasVindas.BackgroundTransparency = 0.45
    backdropBoasVindas.Visible = false
    backdropBoasVindas.Active = true
    backdropBoasVindas.ZIndex = 135
    backdropBoasVindas.Parent = pai

    modalBoasVindas = Instance.new("Frame")
    modalBoasVindas.Name = "ModalBoasVindasTutorial"
    modalBoasVindas.Size = UDim2.new(0.92, 0, 0, 355)
    modalBoasVindas.Position = UDim2.new(0.5, 0, 0.5, 0)
    modalBoasVindas.AnchorPoint = Vector2.new(0.5, 0.5)
    modalBoasVindas.BackgroundColor3 = BG_ESCURO
    modalBoasVindas.BorderSizePixel = 0
    modalBoasVindas.ZIndex = 136
    modalBoasVindas.Parent = backdropBoasVindas
    Instance.new("UICorner", modalBoasVindas).CornerRadius = UDim.new(0, 18)

    local sizeCons = Instance.new("UISizeConstraint", modalBoasVindas)
    sizeCons.MaxSize = Vector2.new(515, 375)

    local strokeModal = Instance.new("UIStroke", modalBoasVindas)
    strokeModal.Thickness = 2
    strokeModal.Color = ACENTO
    strokeModal.Transparency = 0.1

    -- Botão X discreto no canto superior direito
    local btnFecharX = Instance.new("TextButton", modalBoasVindas)
    btnFecharX.Name = "BtnFecharBoasVindas"
    btnFecharX.Size = UDim2.new(0, 32, 0, 32)
    btnFecharX.Position = UDim2.new(1, -12, 0, 12)
    btnFecharX.AnchorPoint = Vector2.new(1, 0)
    btnFecharX.BackgroundColor3 = BG_BOTAO
    btnFecharX.Text = "X"
    btnFecharX.TextColor3 = TEXTO_PRIM
    btnFecharX.Font = Enum.Font.GothamBlack
    btnFecharX.TextSize = 15
    btnFecharX.ZIndex = 138
    Instance.new("UICorner", btnFecharX).CornerRadius = UDim.new(1, 0)
    btnFecharX.Activated:Connect(function()
        TutorialUI.FecharBoasVindas(true)
    end)

    -- Personagem guia da barraca do tutorial (copinhodecocacola) no cantinho esquerdo
    retratoBoasVindas = GuideAvatar.CriarRetrato(modalBoasVindas, {
        Name = "RetratoBoasVindasGuia",
        Size = UDim2.new(0, 118, 0, 142),
        Position = UDim2.new(0, 18, 0, 22),
        AnchorPoint = Vector2.new(0, 0),
        ZIndex = 137,
        MostrarTag = true,
        DistanciaCamera = 3.85,
        FieldOfView = 36,
    })

    tituloBoasVindas = Instance.new("TextLabel", modalBoasVindas)
    tituloBoasVindas.Name = "TituloBoasVindas"
    tituloBoasVindas.Size = UDim2.new(1, -184, 0, 34)
    tituloBoasVindas.Position = UDim2.new(0, 148, 0, 22)
    tituloBoasVindas.BackgroundTransparency = 1
    tituloBoasVindas.Text = "GOSTARIA DE APRENDER A JOGAR?"
    tituloBoasVindas.TextColor3 = OURO_VIVO
    tituloBoasVindas.Font = Enum.Font.GothamBlack
    tituloBoasVindas.TextScaled = true
    tituloBoasVindas.TextXAlignment = Enum.TextXAlignment.Left
    tituloBoasVindas.ZIndex = 137
    Instance.new("UITextSizeConstraint", tituloBoasVindas).MaxTextSize = 19

    textoBoasVindas = Instance.new("TextLabel", modalBoasVindas)
    textoBoasVindas.Name = "TextoBoasVindas"
    textoBoasVindas.Size = UDim2.new(1, -166, 0, 102)
    textoBoasVindas.Position = UDim2.new(0, 148, 0, 62)
    textoBoasVindas.BackgroundTransparency = 1
    textoBoasVindas.Text = "Oi! Eu sou a guia do Truco Paulista.\n\nQuer fazer uma partida rápida guiada contra bots para aprender Manilhas, TRUCO e SEIS em 1 minuto?"
    textoBoasVindas.TextColor3 = TEXTO_PRIM
    textoBoasVindas.Font = Enum.Font.GothamMedium
    textoBoasVindas.TextSize = 16
    textoBoasVindas.TextWrapped = true
    textoBoasVindas.TextXAlignment = Enum.TextXAlignment.Left
    textoBoasVindas.TextYAlignment = Enum.TextYAlignment.Top
    textoBoasVindas.ZIndex = 137

    -- Botão Principal: Partida Tutorial Scriptada
    local btnAprender = Instance.new("TextButton", modalBoasVindas)
    btnAprender.Name = "BtnIniciarTutorialInterativo"
    btnAprender.Size = UDim2.new(1, -36, 0, 46)
    btnAprender.Position = UDim2.new(0.5, 0, 1, -158)
    btnAprender.AnchorPoint = Vector2.new(0.5, 0)
    btnAprender.BackgroundColor3 = VERDE
    btnAprender.Text = "🎮 SIM, QUERO APRENDER! (PARTIDA GUIADA)"
    btnAprender.TextColor3 = TEXTO_PRIM
    btnAprender.Font = Enum.Font.GothamBlack
    btnAprender.TextSize = 15
    btnAprender.AutoButtonColor = true
    btnAprender.ZIndex = 138
    Instance.new("UICorner", btnAprender).CornerRadius = UDim.new(0, 11)
    local strokeAprender = Instance.new("UIStroke", btnAprender)
    strokeAprender.Color = Color3.fromRGB(145, 255, 185)
    strokeAprender.Thickness = 1.6
    strokeAprender.Transparency = 0.3

    btnAprender.Activated:Connect(function()
        TutorialUI.FecharBoasVindas(false)
        notificarTutorialVisto()
        if callbacksConfig.onIniciarPartidaTutorial then
            callbacksConfig.onIniciarPartidaTutorial()
        end
    end)

    -- Linha Secundária: Guia em Slides + Ir para Mesa Solo
    local btnSlides = Instance.new("TextButton", modalBoasVindas)
    btnSlides.Name = "BtnAbrirSlides"
    btnSlides.Size = UDim2.new(0.48, -14, 0, 40)
    btnSlides.Position = UDim2.new(0, 18, 1, -102)
    btnSlides.BackgroundColor3 = BG_PAINEL
    btnSlides.Text = "📖 VER SLIDES"
    btnSlides.TextColor3 = TEXTO_PRIM
    btnSlides.Font = Enum.Font.GothamBold
    btnSlides.TextSize = 13
    btnSlides.AutoButtonColor = true
    btnSlides.ZIndex = 138
    Instance.new("UICorner", btnSlides).CornerRadius = UDim.new(0, 10)
    local strokeSlides = Instance.new("UIStroke", btnSlides)
    strokeSlides.Color = Color3.fromRGB(75, 78, 98)
    strokeSlides.Thickness = 1.2

    btnSlides.Activated:Connect(function()
        TutorialUI.FecharBoasVindas(true)
        TutorialUI.Mostrar(true)
    end)

    local btnMesaSolo = Instance.new("TextButton", modalBoasVindas)
    btnMesaSolo.Name = "BtnIrMesaSoloBoasVindas"
    btnMesaSolo.Size = UDim2.new(0.48, -14, 0, 40)
    btnMesaSolo.Position = UDim2.new(1, -18, 1, -102)
    btnMesaSolo.AnchorPoint = Vector2.new(1, 0)
    btnMesaSolo.BackgroundColor3 = BG_PAINEL
    btnMesaSolo.Text = "🤖 IR PARA MESA SOLO"
    btnMesaSolo.TextColor3 = OURO_VIVO
    btnMesaSolo.Font = Enum.Font.GothamBold
    btnMesaSolo.TextSize = 13
    btnMesaSolo.AutoButtonColor = true
    btnMesaSolo.ZIndex = 138
    Instance.new("UICorner", btnMesaSolo).CornerRadius = UDim.new(0, 10)
    local strokeSolo = Instance.new("UIStroke", btnMesaSolo)
    strokeSolo.Color = ACENTO
    strokeSolo.Thickness = 1.3
    strokeSolo.Transparency = 0.25

    btnMesaSolo.Activated:Connect(function()
        TutorialUI.FecharBoasVindas(true)
        if callbacksConfig.onIrMesaSolo then
            callbacksConfig.onIrMesaSolo()
        end
    end)

    -- Botão Discreto: Pular Tutorial (nunca intrusivo para veteranos)
    btnPularBoasVindas = Instance.new("TextButton", modalBoasVindas)
    btnPularBoasVindas.Name = "BtnPularTutorial"
    btnPularBoasVindas.Size = UDim2.new(1, -36, 0, 34)
    btnPularBoasVindas.Position = UDim2.new(0.5, 0, 1, -48)
    btnPularBoasVindas.AnchorPoint = Vector2.new(0.5, 0)
    btnPularBoasVindas.BackgroundColor3 = BG_BOTAO
    btnPularBoasVindas.BackgroundTransparency = 0.35
    btnPularBoasVindas.Text = "Pular Tutorial (Já sei jogar)"
    btnPularBoasVindas.TextColor3 = TEXTO_SEC
    btnPularBoasVindas.Font = Enum.Font.GothamMedium
    btnPularBoasVindas.TextSize = 13
    btnPularBoasVindas.AutoButtonColor = true
    btnPularBoasVindas.ZIndex = 138
    Instance.new("UICorner", btnPularBoasVindas).CornerRadius = UDim.new(0, 9)

    btnPularBoasVindas.Activated:Connect(function()
        TutorialUI.FecharBoasVindas(true)
    end)
end

function TutorialUI.Inicializar(pai, containerMenu, callbacks)
    if type(callbacks) == "table" then
        callbacksConfig.onIniciarPartidaTutorial = callbacks.onIniciarPartidaTutorial
        callbacksConfig.onIrMesaSolo = callbacks.onIrMesaSolo
        callbacksConfig.onMarcarVisto = callbacks.onMarcarVisto
    end

    if containerMenu then
        btnTutorialAbrir = Instance.new("TextButton", containerMenu)
        btnTutorialAbrir.Name            = "BtnTutorial"
        btnTutorialAbrir.Size            = UDim2.new(0, 46, 0, 46)
        btnTutorialAbrir.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        btnTutorialAbrir.BackgroundTransparency = 0.25
        btnTutorialAbrir.Text            = "❓"
        btnTutorialAbrir.TextSize        = 22
        btnTutorialAbrir.TextColor3      = TEXTO_PRIM
        btnTutorialAbrir.Font            = Enum.Font.GothamBlack
        btnTutorialAbrir.AutoButtonColor = true
        btnTutorialAbrir.LayoutOrder     = 3
        btnTutorialAbrir.ZIndex          = 41
        Instance.new("UICorner", btnTutorialAbrir).CornerRadius = UDim.new(1, 0)

        local bordaBtn = Instance.new("UIStroke", btnTutorialAbrir)
        bordaBtn.Thickness    = 1.5
        bordaBtn.Color        = Color3.new(1, 1, 1)
        bordaBtn.Transparency = 0.8

        btnTutorialAbrir.MouseEnter:Connect(function()
            TweenService:Create(btnTutorialAbrir, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.05,
                BackgroundColor3 = Color3.fromRGB(38, 38, 46)
            }):Play()
        end)
        btnTutorialAbrir.MouseLeave:Connect(function()
            TweenService:Create(btnTutorialAbrir, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.25,
                BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            }):Play()
        end)

        btnTutorialAbrir.Activated:Connect(function()
            TutorialUI.Alternar()
        end)
    end

    -- Modal de boas-vindas (1ª sessão + barraca do tutorial)
    criarModalBoasVindas(pai)

    -- Modal principal de slides
    menuTutorial = Instance.new("Frame")
    menuTutorial.Name            = "MenuTutorial"
    menuTutorial.Size            = UDim2.new(0.92, 0, 0.86, 0)
    menuTutorial.Position        = UDim2.new(0.5, 0, 0.5, 0)
    menuTutorial.AnchorPoint     = Vector2.new(0.5, 0.5)
    menuTutorial.BackgroundColor3 = BG_ESCURO
    menuTutorial.Visible         = false
    menuTutorial.ZIndex          = 60
    menuTutorial.Parent          = pai
    Instance.new("UICorner", menuTutorial).CornerRadius = UDim.new(0, 16)

    local bordaModal = Instance.new("UIStroke", menuTutorial)
    bordaModal.Thickness = 1.5
    bordaModal.Color     = Color3.fromRGB(55, 55, 70)

    local sizeCons = Instance.new("UISizeConstraint", menuTutorial)
    sizeCons.MaxSize = Vector2.new(560, 520)

    -- Mini retrato da personagem guia no cantinho superior esquerdo do modal
    retratoSlide = GuideAvatar.CriarRetrato(menuTutorial, {
        Name = "RetratoSlideGuia",
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 14, 0, 10),
        AnchorPoint = Vector2.new(0, 0),
        ZIndex = 62,
        CornerRadius = UDim.new(1, 0),
        MostrarTag = false,
        DistanciaCamera = 3.6,
        FieldOfView = 35,
    })

    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Name            = "BtnFechar"
    btnFechar.Size            = UDim2.new(0, 36, 0, 36)
    btnFechar.Position        = UDim2.new(1, -12, 0, 12)
    btnFechar.AnchorPoint     = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = BG_BOTAO
    btnFechar.Text            = "X"
    btnFechar.TextColor3      = TEXTO_PRIM
    btnFechar.Font            = Enum.Font.GothamBlack
    btnFechar.TextScaled      = false
    btnFechar.TextSize        = 18
    btnFechar.AutoButtonColor = true
    btnFechar.ZIndex          = 62
    btnFechar.Parent          = menuTutorial
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)

    btnFechar.Activated:Connect(function()
        notificarTutorialVisto()
        TutorialUI.Mostrar(false)
    end)

    -- Título do slide
    tituloTutorial = Instance.new("TextLabel", menuTutorial)
    tituloTutorial.Size               = UDim2.new(0.68, 0, 0, 36)
    tituloTutorial.Position           = UDim2.new(0.5, 6, 0, 12)
    tituloTutorial.AnchorPoint        = Vector2.new(0.5, 0)
    tituloTutorial.BackgroundTransparency = 1
    tituloTutorial.TextColor3         = ACENTO
    tituloTutorial.Font               = Enum.Font.GothamBlack
    tituloTutorial.TextScaled         = true
    tituloTutorial.ZIndex             = 61
    Instance.new("UITextSizeConstraint", tituloTutorial).MaxTextSize = 24

    indicadorSlide = Instance.new("TextLabel", menuTutorial)
    indicadorSlide.Size               = UDim2.new(0.4, 0, 0, 16)
    indicadorSlide.Position           = UDim2.new(0.5, 6, 0, 48)
    indicadorSlide.AnchorPoint        = Vector2.new(0.5, 0)
    indicadorSlide.BackgroundTransparency = 1
    indicadorSlide.TextColor3         = TEXTO_SEC
    indicadorSlide.Font               = Enum.Font.GothamBold
    indicadorSlide.TextSize           = 12
    indicadorSlide.Text               = "1 / 6"
    indicadorSlide.ZIndex             = 61

    -- Imagem do slide
    imgTutorial = Instance.new("ImageLabel", menuTutorial)
    imgTutorial.Size             = UDim2.new(0.86, 0, 0.36, 0)
    imgTutorial.Position         = UDim2.new(0.5, 0, 0.145, 0)
    imgTutorial.AnchorPoint      = Vector2.new(0.5, 0)
    imgTutorial.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    imgTutorial.ScaleType        = Enum.ScaleType.Fit
    imgTutorial.ZIndex           = 61
    Instance.new("UICorner", imgTutorial).CornerRadius = UDim.new(0, 10)

    -- Texto do slide
    textoTutorial = Instance.new("TextLabel", menuTutorial)
    textoTutorial.Size               = UDim2.new(0.88, 0, 0.26, 0)
    textoTutorial.Position           = UDim2.new(0.5, 0, 0.535, 0)
    textoTutorial.AnchorPoint        = Vector2.new(0.5, 0)
    textoTutorial.BackgroundTransparency = 1
    textoTutorial.TextColor3         = TEXTO_PRIM
    textoTutorial.Font               = Enum.Font.GothamMedium
    textoTutorial.TextScaled         = false
    textoTutorial.TextSize           = 17
    textoTutorial.TextWrapped        = true
    textoTutorial.ZIndex             = 61

    -- Botão opcional para abrir a Partida Tutorial Interativa a partir dos slides
    btnInterativoSlide = Instance.new("TextButton", menuTutorial)
    btnInterativoSlide.Name = "BtnPartidaInterativaSlide"
    btnInterativoSlide.Size = UDim2.new(0.62, 0, 0, 32)
    btnInterativoSlide.Position = UDim2.new(0.5, 0, 1, -94)
    btnInterativoSlide.AnchorPoint = Vector2.new(0.5, 0)
    btnInterativoSlide.BackgroundColor3 = BG_PAINEL
    btnInterativoSlide.Text = "🎮 FAZER PARTIDA TUTORIAL INTERATIVA"
    btnInterativoSlide.TextColor3 = OURO_VIVO
    btnInterativoSlide.Font = Enum.Font.GothamBold
    btnInterativoSlide.TextSize = 12
    btnInterativoSlide.AutoButtonColor = true
    btnInterativoSlide.ZIndex = 62
    Instance.new("UICorner", btnInterativoSlide).CornerRadius = UDim.new(1, 0)
    local strokeInt = Instance.new("UIStroke", btnInterativoSlide)
    strokeInt.Color = ACENTO
    strokeInt.Thickness = 1.2
    strokeInt.Transparency = 0.25

    btnInterativoSlide.Activated:Connect(function()
        TutorialUI.Mostrar(false)
        notificarTutorialVisto()
        if callbacksConfig.onIniciarPartidaTutorial then
            callbacksConfig.onIniciarPartidaTutorial()
        end
    end)

    -- Botão ANTERIOR
    btnAnteriorTut = Instance.new("TextButton", menuTutorial)
    btnAnteriorTut.Name            = "BtnAnterior"
    btnAnteriorTut.Size            = UDim2.new(0.36, 0, 0, 42)
    btnAnteriorTut.Position        = UDim2.new(0.06, 0, 1, -52)
    btnAnteriorTut.AnchorPoint     = Vector2.new(0, 0)
    btnAnteriorTut.BackgroundColor3 = BG_PAINEL
    btnAnteriorTut.Text            = "< ANTERIOR"
    btnAnteriorTut.TextColor3      = TEXTO_PRIM
    btnAnteriorTut.Font            = Enum.Font.GothamBold
    btnAnteriorTut.TextScaled      = false
    btnAnteriorTut.TextSize        = 13
    btnAnteriorTut.AutoButtonColor = true
    btnAnteriorTut.ZIndex          = 62
    Instance.new("UICorner", btnAnteriorTut).CornerRadius = UDim.new(0.5, 0)

    -- Botão central no último slide: Testar na Mesa Solo (MesaPvE_Solo)
    btnTestarSoloSlide = Instance.new("TextButton", menuTutorial)
    btnTestarSoloSlide.Name            = "BtnTestarMesaSolo"
    btnTestarSoloSlide.Size            = UDim2.new(0.38, 0, 0, 42)
    btnTestarSoloSlide.Position        = UDim2.new(0.5, 0, 1, -52)
    btnTestarSoloSlide.AnchorPoint     = Vector2.new(0.5, 0)
    btnTestarSoloSlide.BackgroundColor3 = VERDE
    btnTestarSoloSlide.Text            = "🤖 TESTAR NA MESA SOLO"
    btnTestarSoloSlide.TextColor3      = TEXTO_PRIM
    btnTestarSoloSlide.Font            = Enum.Font.GothamBlack
    btnTestarSoloSlide.TextScaled      = true
    btnTestarSoloSlide.AutoButtonColor = true
    btnTestarSoloSlide.Visible         = false
    btnTestarSoloSlide.ZIndex          = 62
    Instance.new("UICorner", btnTestarSoloSlide).CornerRadius = UDim.new(0.5, 0)
    local padSolo = Instance.new("UIPadding", btnTestarSoloSlide)
    padSolo.PaddingLeft = UDim.new(0, 10)
    padSolo.PaddingRight = UDim.new(0, 10)
    Instance.new("UITextSizeConstraint", btnTestarSoloSlide).MaxTextSize = 13

    btnTestarSoloSlide.Activated:Connect(function()
        notificarTutorialVisto()
        TutorialUI.Mostrar(false)
        if callbacksConfig.onIrMesaSolo then
            callbacksConfig.onIrMesaSolo()
        end
    end)

    -- Botão PRÓXIMO / FECHAR
    btnProximoTut = Instance.new("TextButton", menuTutorial)
    btnProximoTut.Name            = "BtnProximo"
    btnProximoTut.Size            = UDim2.new(0.36, 0, 0, 42)
    btnProximoTut.Position        = UDim2.new(0.58, 0, 1, -52)
    btnProximoTut.AnchorPoint     = Vector2.new(0, 0)
    btnProximoTut.BackgroundColor3 = VERDE
    btnProximoTut.Text            = "PRÓXIMO >"
    btnProximoTut.TextColor3      = TEXTO_PRIM
    btnProximoTut.Font            = Enum.Font.GothamBold
    btnProximoTut.TextScaled      = false
    btnProximoTut.TextSize        = 13
    btnProximoTut.AutoButtonColor = true
    btnProximoTut.ZIndex          = 62
    Instance.new("UICorner", btnProximoTut).CornerRadius = UDim.new(0.5, 0)

    btnAnteriorTut.Activated:Connect(function()
        if slideAtualTutorial > 1 then
            slideAtualTutorial -= 1
            atualizarSlideTutorial()
        end
    end)

    btnProximoTut.Activated:Connect(function()
        if slideAtualTutorial < #SLIDES_TUTORIAL then
            slideAtualTutorial += 1
            atualizarSlideTutorial()
        else
            notificarTutorialVisto()
            TutorialUI.Mostrar(false)
        end
    end)
end

function TutorialUI.MostrarBoasVindas(ehReabertura)
    if not backdropBoasVindas or estaSentado then return end
    if menuTutorial then menuTutorial.Visible = false end

    if ehReabertura then
        tituloBoasVindas.Text = "QUIOSQUE DO TUTORIAL"
        textoBoasVindas.Text = "Oi de novo! Quer treinar na partida guiada contra bots, revisar os slides de regras ou ir direto para a Mesa Solo?"
        if btnPularBoasVindas then
            btnPularBoasVindas.Text = "Fechar"
        end
    else
        tituloBoasVindas.Text = "GOSTARIA DE APRENDER A JOGAR?"
        textoBoasVindas.Text = "Oi! Eu sou a guia do Truco Paulista.\n\nQuer fazer uma partida rápida guiada contra bots para aprender Manilhas, TRUCO e SEIS em 1 minuto?"
        if btnPularBoasVindas then
            btnPularBoasVindas.Text = "Pular Tutorial (Já sei jogar)"
        end
    end

    backdropBoasVindas.Visible = true
    if retratoBoasVindas then
        retratoBoasVindas:PulsarFala()
    end
end

function TutorialUI.FecharBoasVindas(marcarVisto)
    if backdropBoasVindas then
        backdropBoasVindas.Visible = false
    end
    if marcarVisto then
        notificarTutorialVisto()
    end
end

function TutorialUI.DefinirSentado(sentado)
    estaSentado = (sentado == true)
    if estaSentado then
        TutorialUI.FecharBoasVindas(false)
    end
    if menuTutorial and menuTutorial.Visible then
        atualizarSlideTutorial()
    end
end

function TutorialUI.Mostrar(abrir)
    if not menuTutorial then return end
    if abrir then
        TutorialUI.FecharBoasVindas(false)
        slideAtualTutorial = 1
        atualizarSlideTutorial()
        menuTutorial.Visible = true
    else
        menuTutorial.Visible = false
    end
end

function TutorialUI.Alternar()
    if not menuTutorial then return end
    TutorialUI.Mostrar(not menuTutorial.Visible)
end

return TutorialUI

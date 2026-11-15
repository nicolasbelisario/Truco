local TutorialUI = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local VERDE      = Color3.fromRGB(39, 174, 96)
local TEXTO_PRIM = Color3.new(1, 1, 1)

local menuTutorial, imgTutorial, textoTutorial, tituloTutorial
local btnAnteriorTut, btnProximoTut
local slideAtualTutorial = 1

local SLIDES_TUTORIAL = {
    { Titulo = "O OBJETIVO",   Texto = "Bem-vindo ao Truco! O jogo é disputado em duplas (2 contra 2). O objetivo da sua equipe é alcançar 12 pontos antes dos adversários.",                                                                               Imagem = "rbxassetid://94577408525560"  },
    { Titulo = "A RODADA",     Texto = "Cada rodada (Mão) vale 1 ponto. Para ganhar, sua dupla precisa vencer 2 de 3 quedas. Cada jogador joga uma carta por queda, a mais forte vence.",                                                                     Imagem = "rbxassetid://117539543208859" },
    { Titulo = "A FORÇA",      Texto = "A força das cartas normais, da mais fraca para a mais forte, é: 4, 5, 6, 7, Q, J, K, A, 2, 3. Naipe não importa aqui, apenas o número!",                                                                              Imagem = "rbxassetid://73972302411191"  },
    { Titulo = "AS MANILHAS",  Texto = "No início, uma carta é virada (O Vira). A Manilha é a carta logo acima dele. Ex: Se o Vira for 5, todos os 6 viram Manilhas, as mais fortes do jogo!",                                                                Imagem = "rbxassetid://109233300765686" },
    { Titulo = "TRUCO!",       Texto = "Acha que tem cartas boas? Clique em TRUCO! Isso aumenta o valor da Mão para 3 pontos. Os adversários podem Aceitar, Fugir ou Aumentar para 6!",                                                                      Imagem = "rbxassetid://86983343730484"  },
    { Titulo = "DICAS",        Texto = "Jogue cartas Cobertas para esconder seu jogo e use os Sinais (Olhar/Mão) para se comunicar com seu parceiro. Boa sorte!",                                                                                             Imagem = "rbxassetid://75845041324394"  },
}

local function atualizarSlideTutorial()
    local dados = SLIDES_TUTORIAL[slideAtualTutorial]
    tituloTutorial.Text = dados.Titulo
    textoTutorial.Text  = dados.Texto

    if dados.Imagem ~= "" then
        imgTutorial.Image = dados.Imagem
        imgTutorial.BackgroundTransparency = 1
    else
        imgTutorial.Image = ""
        imgTutorial.BackgroundTransparency = 0
    end

    btnAnteriorTut.Visible = (slideAtualTutorial > 1)

    if slideAtualTutorial == #SLIDES_TUTORIAL then
        btnProximoTut.Text             = "ENTENDI!"
        btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    else
        btnProximoTut.Text             = "PRÓXIMO >"
        btnProximoTut.BackgroundColor3 = VERDE
    end
end

local btnTutorialAbrir = nil

function TutorialUI.Inicializar(pai, containerMenu)
    local TweenService = game:GetService("TweenService")

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
            TutorialUI.Mostrar(true)
        end)
    end

    -- Modal principal
    menuTutorial = Instance.new("Frame")
    menuTutorial.Name            = "MenuTutorial"
    menuTutorial.Size            = UDim2.new(0.9, 0, 0.85, 0)
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

    -- Tamanho máximo para não esticar demais em telas grandes
    local sizeCons = Instance.new("UISizeConstraint", menuTutorial)
    sizeCons.MaxSize = Vector2.new(540, 500)

    -- Botão fechar
    local btnFechar = Instance.new("TextButton")
    btnFechar.Name            = "BtnFechar"
    btnFechar.Size            = UDim2.new(0, 36, 0, 36)
    btnFechar.Position        = UDim2.new(1, -10, 0, 10)
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

    btnFechar.Activated:Connect(function() TutorialUI.Mostrar(false) end)

    -- Título do slide
    tituloTutorial = Instance.new("TextLabel", menuTutorial)
    tituloTutorial.Size               = UDim2.new(0.85, 0, 0, 50)
    tituloTutorial.Position           = UDim2.new(0.5, 0, 0, 10)
    tituloTutorial.AnchorPoint        = Vector2.new(0.5, 0)
    tituloTutorial.BackgroundTransparency = 1
    tituloTutorial.TextColor3         = ACENTO
    tituloTutorial.Font               = Enum.Font.GothamBlack
    tituloTutorial.TextScaled         = true
    tituloTutorial.ZIndex             = 61

    -- Imagem do slide
    imgTutorial = Instance.new("ImageLabel", menuTutorial)
    imgTutorial.Size             = UDim2.new(0.85, 0, 0.38, 0)
    imgTutorial.Position         = UDim2.new(0.5, 0, 0.14, 0)
    imgTutorial.AnchorPoint      = Vector2.new(0.5, 0)
    imgTutorial.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    imgTutorial.ScaleType        = Enum.ScaleType.Fit
    imgTutorial.ZIndex           = 61
    Instance.new("UICorner", imgTutorial).CornerRadius = UDim.new(0, 10)

    -- Texto do slide
    textoTutorial = Instance.new("TextLabel", menuTutorial)
    textoTutorial.Size               = UDim2.new(0.9, 0, 0.3, 0)
    textoTutorial.Position           = UDim2.new(0.5, 0, 0.56, 0)
    textoTutorial.AnchorPoint        = Vector2.new(0.5, 0)
    textoTutorial.BackgroundTransparency = 1
    textoTutorial.TextColor3         = TEXTO_PRIM
    textoTutorial.Font               = Enum.Font.GothamMedium
    textoTutorial.TextScaled         = false
    textoTutorial.TextSize           = 16
    textoTutorial.TextWrapped        = true
    textoTutorial.ZIndex             = 61

    -- Botão ANTERIOR
    btnAnteriorTut = Instance.new("TextButton", menuTutorial)
    btnAnteriorTut.Name            = "BtnAnterior"
    btnAnteriorTut.Size            = UDim2.new(0.4, 0, 0, 44)
    btnAnteriorTut.Position        = UDim2.new(0.07, 0, 1, -54)
    btnAnteriorTut.AnchorPoint     = Vector2.new(0, 0)
    btnAnteriorTut.BackgroundColor3 = BG_PAINEL
    btnAnteriorTut.Text            = "< ANTERIOR"
    btnAnteriorTut.TextColor3      = TEXTO_PRIM
    btnAnteriorTut.Font            = Enum.Font.GothamBold
    btnAnteriorTut.TextScaled      = false
    btnAnteriorTut.TextSize        = 14
    btnAnteriorTut.AutoButtonColor = true
    btnAnteriorTut.ZIndex          = 62
    Instance.new("UICorner", btnAnteriorTut).CornerRadius = UDim.new(0.5, 0)

    -- Botão PRÓXIMO
    btnProximoTut = Instance.new("TextButton", menuTutorial)
    btnProximoTut.Name            = "BtnProximo"
    btnProximoTut.Size            = UDim2.new(0.4, 0, 0, 44)
    btnProximoTut.Position        = UDim2.new(0.53, 0, 1, -54)
    btnProximoTut.AnchorPoint     = Vector2.new(0, 0)
    btnProximoTut.BackgroundColor3 = VERDE
    btnProximoTut.Text            = "PRÓXIMO >"
    btnProximoTut.TextColor3      = TEXTO_PRIM
    btnProximoTut.Font            = Enum.Font.GothamBold
    btnProximoTut.TextScaled      = false
    btnProximoTut.TextSize        = 14
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
            TutorialUI.Mostrar(false)
        end
    end)
end

function TutorialUI.Mostrar(abrir)
    if not menuTutorial then return end
    if abrir then
        slideAtualTutorial = 1
        atualizarSlideTutorial()
        menuTutorial.Visible = true
    else
        menuTutorial.Visible = false
    end
end

return TutorialUI

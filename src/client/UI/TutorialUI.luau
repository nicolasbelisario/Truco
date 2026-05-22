local TutorialUI = {}

local menuTutorial, imgTutorial, textoTutorial, tituloTutorial
local btnAnteriorTut, btnProximoTut
local slideAtualTutorial = 1

local SLIDES_TUTORIAL = {
    { Titulo = "O OBJETIVO", Texto = "Bem-vindo ao Truco! O jogo é disputado em duplas (2 contra 2). O objetivo da sua equipe é alcançar 12 pontos antes dos adversários.", Imagem = "rbxassetid://94577408525560" },
    { Titulo = "A RODADA", Texto = "Cada rodada (Mão) vale 1 ponto. Para ganhar, sua dupla precisa vencer 2 de 3 quedas. Cada jogador joga uma carta por queda, a mais forte vence.", Imagem = "rbxassetid://117539543208859" },
    { Titulo = "A FORÇA", Texto = "A força das cartas normais, da mais fraca para a mais forte, é: 4, 5, 6, 7, Q, J, K, A, 2, 3. Naipe não importa aqui, apenas o número!", Imagem = "rbxassetid://73972302411191" },
    { Titulo = "AS MANILHAS", Texto = "No início, uma carta é virada (O Vira). A Manilha é a carta logo acima dele. Ex: Se o Vira for 5, todos os 6 viram Manilhas, as mais fortes do jogo!", Imagem = "rbxassetid://109233300765686" },
    { Titulo = "TRUCO!", Texto = "Acha que tem cartas boas? Clique em TRUCO! Isso aumenta o valor da Mão para 3 pontos. Os adversários podem Aceitar, Fugir ou Aumentar para 6!", Imagem = "rbxassetid://86983343730484" },
    { Titulo = "DICAS", Texto = "Jogue cartas Cobertas para esconder seu jogo e use os Sinais (Olhar/Mão) para se comunicar com seu parceiro. Boa sorte!", Imagem = "rbxassetid://75845041324394" }
}

local function atualizarSlideTutorial()
    local dados = SLIDES_TUTORIAL[slideAtualTutorial]
    tituloTutorial.Text = dados.Titulo
    textoTutorial.Text = dados.Texto
    
    if dados.Imagem ~= "" then
        imgTutorial.Image = dados.Imagem
        imgTutorial.BackgroundTransparency = 1
    else
        imgTutorial.Image = ""
        imgTutorial.BackgroundTransparency = 0
    end

    btnAnteriorTut.Visible = (slideAtualTutorial > 1)
    
    if slideAtualTutorial == #SLIDES_TUTORIAL then
        btnProximoTut.Text = "ENTENDI!"
        btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    else
        btnProximoTut.Text = "PRÓXIMO >"
        btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 196, 39)
    end
end

function TutorialUI.Inicializar(pai)
    menuTutorial = Instance.new("Frame")
    menuTutorial.Name = "MenuTutorial"
    menuTutorial.Size = UDim2.new(0, 500, 0, 450)
    menuTutorial.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuTutorial.AnchorPoint = Vector2.new(0.5, 0.5)
    menuTutorial.BackgroundColor3 = Color3.fromRGB(175, 175, 175) 
    menuTutorial.Visible = false
    menuTutorial.ZIndex = 60
    menuTutorial.Parent = pai
    Instance.new("UICorner", menuTutorial).CornerRadius = UDim.new(0, 20)

    local btnFechar = Instance.new("TextButton")
    btnFechar.Size = UDim2.new(0, 40, 0, 40)
    btnFechar.Position = UDim2.new(1, -15, 0, 15)
    btnFechar.AnchorPoint = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnFechar.Text = "X"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.Font = Enum.Font.GothamBlack
    btnFechar.ZIndex = 62
    btnFechar.Parent = menuTutorial
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    
    btnFechar.Activated:Connect(function() TutorialUI.Mostrar(false) end)

    tituloTutorial = Instance.new("TextLabel", menuTutorial)
    tituloTutorial.Size = UDim2.new(1, 0, 0, 50)
    tituloTutorial.Position = UDim2.new(0, 0, 0, 10)
    tituloTutorial.BackgroundTransparency = 1
    tituloTutorial.TextColor3 = Color3.new(1, 1, 1)
    tituloTutorial.Font = Enum.Font.GothamBlack
    tituloTutorial.TextSize = 35
    tituloTutorial.ZIndex = 61

    imgTutorial = Instance.new("ImageLabel", menuTutorial)
    imgTutorial.Size = UDim2.new(0.85, 0, 0.4, 0)
    imgTutorial.Position = UDim2.new(0.5, 0, 0.15, 0)
    imgTutorial.AnchorPoint = Vector2.new(0.5, 0)
    imgTutorial.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    imgTutorial.ScaleType = Enum.ScaleType.Fit
    imgTutorial.ZIndex = 61
    Instance.new("UICorner", imgTutorial).CornerRadius = UDim.new(0, 10)

    textoTutorial = Instance.new("TextLabel", menuTutorial)
    textoTutorial.Size = UDim2.new(0.9, 0, 0.3, 0)
    textoTutorial.Position = UDim2.new(0.5, 0, 0.6, 0)
    textoTutorial.AnchorPoint = Vector2.new(0.5, 0)
    textoTutorial.BackgroundTransparency = 1
    textoTutorial.TextColor3 = Color3.new(1, 1, 1)
    textoTutorial.Font = Enum.Font.GothamMedium
    textoTutorial.TextSize = 18
    textoTutorial.TextWrapped = true
    textoTutorial.ZIndex = 61

    btnAnteriorTut = Instance.new("TextButton", menuTutorial)
    btnAnteriorTut.Size = UDim2.new(0, 150, 0, 45)
    btnAnteriorTut.Position = UDim2.new(0.25, 0, 0.95, 0)
    btnAnteriorTut.AnchorPoint = Vector2.new(0.5, 1)
    btnAnteriorTut.Text = "< ANTERIOR"
    btnAnteriorTut.TextColor3 = Color3.new(1, 1, 1)
    btnAnteriorTut.Font = Enum.Font.GothamBlack
    btnAnteriorTut.ZIndex = 62
    Instance.new("UICorner", btnAnteriorTut).CornerRadius = UDim.new(0.5, 0)

    btnProximoTut = Instance.new("TextButton", menuTutorial)
    btnProximoTut.Size = UDim2.new(0, 150, 0, 45)
    btnProximoTut.Position = UDim2.new(0.75, 0, 0.95, 0)
    btnProximoTut.AnchorPoint = Vector2.new(0.5, 1)
    btnProximoTut.Text = "PRÓXIMO >"
    btnProximoTut.TextColor3 = Color3.new(1, 1, 1)
    btnProximoTut.Font = Enum.Font.GothamBlack
    btnProximoTut.ZIndex = 62
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
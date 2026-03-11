local GerenciadorUI = {}

local Players = game:GetService("Players")
local jogadorLocal = Players.LocalPlayer
local guiJogador = jogadorLocal:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Eventos = ReplicatedStorage:WaitForChild("Events")
local SoundService = game:GetService("SoundService")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CardSettings = require(Shared:WaitForChild("CardSettings"))
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local SonsJogo = {
    ["Shuffle"] = "rbxassetid://128706455708345", 
    ["Truco"] = "rbxassetid://7152989885", 
    ["CardPlay"] = "rbxassetid://3456145589",
    ["Victory"] = "rbxassetid://12222253",
}

-- Variáveis da Interface
local painelTela, painelMao, textoCronometro, painelCorte, barraTempoCorte, painelVira
local centroMesa, btnTruco, textoEstatisticas, painelEstatisticas, painelDesafio, textoValorRodada, textoPlacarJogo
local barraTempoDesafio, painelOpcoesJogada, painelEmotes
local btnLoja, menuLoja, paginaPontos, paginaRobux
local btnAbaPontos, btnAbaRobux
-- Variáveis do Tutorial
local menuTutorial, imgTutorial, textoTutorial, tituloTutorial, btnAnteriorTut, btnProximoTut
local slideAtualTutorial = 1
local dadosJogador = { Pontos = 0, SkinsCompradas = {"Padrao"}, SkinEquipada = "Padrao" }
local textoMeusPontos -- Para mostrar quantos pontos o cara tem na loja

local naZonaTutorial = false -- Impede que o menu fique reabrindo sozinho
local estaSentado = false
local eMinhaVez = false
local possoPedirTruco = true
local trucoPendente = false
local numeroQuedaAtual = 1
local callbackEmote = nil

-- [MÉTODO] Atualiza as informações locais quando o servidor manda dados novos
function GerenciadorUI.AtualizarDadosJogador(dados)
    dadosJogador = dados
    if textoMeusPontos then
        textoMeusPontos.Text = "MEUS PONTOS: " .. tostring(dadosJogador.Pontos)
    end
    GerenciadorUI.RenderizarSkinsPontos() -- Recarrega a loja para atualizar os botões
end

-- [MÉTODO] Inicializa toda a interface do zero
function GerenciadorUI.Inicializar()
    painelTela = Instance.new("ScreenGui")
    painelTela.Name = "TrucoGui" -- Define o nome da GUI
    painelTela.ResetOnSpawn = false -- Evita que a interface suma ao morrer
    painelTela.IgnoreGuiInset = true -- Ignora as bordas padrão do Roblox
    painelTela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    painelTela.Parent = guiJogador -- Anexa à interface do jogador

    -- Container principal das informações da esquerda
    local containerInfo = Instance.new("Frame")
    containerInfo.Name = "InfoContainer" -- Nome do container
    containerInfo.Position = UDim2.new(0.02, 0, 0, 60) -- Posiciona no canto superior esquerdo
    containerInfo.Size = UDim2.new(0, 250, 0.5, 0) -- Define a largura fixa de 250 e altura relativa
    containerInfo.BackgroundTransparency = 1 -- Torna o fundo invisível
    containerInfo.Parent = painelTela -- Anexa à tela principal

    local layoutLista = Instance.new("UIListLayout")
    layoutLista.Parent = containerInfo -- Anexa ao container
    layoutLista.SortOrder = Enum.SortOrder.LayoutOrder -- Organiza pela ordem de layout
    layoutLista.Padding = UDim.new(0, 10) -- Espaçamento de 10 pixels entre itens

    -- 1. Mesa Central (Onde as cartas são jogadas visualmente em 2D)
    centroMesa = Instance.new("Frame")
    centroMesa.Name = "TableCenter" -- Nome do elemento
    centroMesa.Size = UDim2.new(0.5, 0, 0.4, 0) -- Ocupa 50% da largura e 40% da altura da tela
    centroMesa.Position = UDim2.new(0.5, 0, 0.5, 0) -- Posiciona exatamente no centro (50%, 50%)
    centroMesa.AnchorPoint = Vector2.new(0.5, 0.5) -- Centraliza o ponto de âncora
    centroMesa.BackgroundTransparency = 1 -- Fundo invisível
    centroMesa.Parent = painelTela -- Anexa à tela principal

    local gradeCartas = Instance.new("UIGridLayout", centroMesa)
    gradeCartas.CellSize = UDim2.new(0, 110, 0, 150) -- Tamanho individual de cada carta jogada
    gradeCartas.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Centraliza horizontalmente
    gradeCartas.VerticalAlignment = Enum.VerticalAlignment.Center -- Centraliza verticalmente

    -- 2. Mão do Jogador (Cartas embaixo)
    painelMao = Instance.new("Frame")
    painelMao.Name = "HandFrame" -- Nome do painel
    painelMao.Size = UDim2.new(0.6, 0, 0.25, 0) -- Largura de 60%, altura de 25% da tela
    painelMao.Position = UDim2.new(0.5, 0, 0.98, 0) -- Posiciona quase no fundo (98% da altura)
    painelMao.AnchorPoint = Vector2.new(0.5, 1) -- Âncora no centro inferior
    painelMao.BackgroundTransparency = 1 -- Fundo invisível
    painelMao.ClipsDescendants = false -- Permite que as cartas 'pulem' para fora do painel ao passar o mouse
    painelMao.Parent = painelTela -- Anexa à tela principal
    
    local layoutMao = Instance.new("UIListLayout", painelMao)
    layoutMao.FillDirection = Enum.FillDirection.Horizontal -- Organiza as cartas lado a lado
    layoutMao.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Centraliza as cartas
    layoutMao.VerticalAlignment = Enum.VerticalAlignment.Bottom -- Alinha as cartas por baixo
    layoutMao.Padding = UDim.new(0, 15) -- Espaçamento de 15px entre cartas

    -- 3. Mensagens e Status Central
    textoCronometro = Instance.new("TextLabel")
    textoCronometro.Size = UDim2.new(0.8, 0, 0.1, 0) -- 80% da largura, 10% da altura
    textoCronometro.Position = UDim2.new(0.5, 0, 0.15, 0) -- Próximo ao topo (15% da altura)
    textoCronometro.AnchorPoint = Vector2.new(0.5, 0.5) -- Âncora central
    textoCronometro.BackgroundTransparency = 1 -- Sem fundo
    textoCronometro.TextColor3 = Color3.new(1, 1, 1) -- Cor do texto branca
    textoCronometro.TextScaled = true -- Texto ajusta automaticamente ao tamanho
    textoCronometro.Font = Enum.Font.GothamBlack -- Fonte grossa
    textoCronometro.Text = "" -- Começa vazio
    textoCronometro.ZIndex = 100 -- Fica por cima de outras interfaces
    textoCronometro.Parent = painelTela -- Anexa à tela principal

    -- Exibição da Carta Vira
    painelVira = Instance.new("Frame")
    painelVira.Name = "ViraDisplayFrame" -- Nome do elemento
    painelVira.Size = UDim2.new(0, 140, 0, 220) -- Tamanho fixo 140x220
    painelVira.Position = UDim2.new(0.95, 0, 0.05, 0) -- Canto superior direito
    painelVira.AnchorPoint = Vector2.new(1, 0) -- Âncora pela direita
    painelVira.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Fundo cinza escuro
    painelVira.Visible = false -- Começa invisível
    painelVira.Parent = painelTela -- Anexa à tela principal
    Instance.new("UICorner", painelVira) -- Arredonda os cantos do painelVira

    -- Botão de Truco
    btnTruco = Instance.new("TextButton")
    btnTruco.Size = UDim2.new(0, 180, 0, 80) -- Tamanho fixo 180x80
    btnTruco.Position = UDim2.new(0.85, 0, 0.85, 0) -- Canto inferior direito
    btnTruco.BackgroundColor3 = Color3.fromRGB(180, 0, 0) -- Vermelho chamativo
    btnTruco.Text = "TRUCO!" -- Texto do botão
    btnTruco.TextColor3 = Color3.new(1,1,1) -- Texto branco
    btnTruco.Font = Enum.Font.GothamBlack -- Fonte grossa
    btnTruco.TextSize = 35 -- Tamanho fixo da fonte
    btnTruco.Visible = false -- Fica escondido até a hora certa
    btnTruco.Parent = painelTela -- Anexa à tela principal
    Instance.new("UICorner", btnTruco) -- Arredonda bordas do botão
    
    btnTruco.Activated:Connect(function()
        Eventos.TrucoEvent:FireServer("Request")
        GerenciadorUI.PermitirTruco(false)
    end)

    -- Estatísticas da Rodada (Quedas)
    painelEstatisticas = Instance.new("Frame")
    painelEstatisticas.Size = UDim2.new(0, 200, 0, 100) -- Tamanho fixo
    painelEstatisticas.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Fundo preto
    painelEstatisticas.BackgroundTransparency = 0.5 -- 50% transparente (Translúcido)
    painelEstatisticas.Visible = false -- Invisível no começo
    painelEstatisticas.LayoutOrder = 1 -- Fica em primeiro no layout
    painelEstatisticas.Parent = containerInfo -- Fica dentro do infoContainer da esquerda
    Instance.new("UICorner", painelEstatisticas) -- Arredonda cantos

    textoEstatisticas = Instance.new("TextLabel")
    textoEstatisticas.Size = UDim2.new(0.9, 0, 0.9, 0) -- Ocupa 90% do painel
    textoEstatisticas.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centralizado
    textoEstatisticas.AnchorPoint = Vector2.new(0.5, 0.5) -- Centro como âncora
    textoEstatisticas.BackgroundTransparency = 1 -- Sem fundo interno
    textoEstatisticas.TextColor3 = Color3.new(1, 1, 1) -- Branco
    textoEstatisticas.TextXAlignment = Enum.TextXAlignment.Left -- Alinha o texto à esquerda
    textoEstatisticas.Font = Enum.Font.GothamMedium -- Fonte média
    textoEstatisticas.TextSize = 18 -- Tamanho de fonte 18
    textoEstatisticas.Text = "Dupla: ...\nNós: 0 Quedas\nEles: 0 Quedas" -- Texto padrão
    textoEstatisticas.Parent = painelEstatisticas -- Coloca dentro do painel

    -- Placar Geral do Jogo
    textoPlacarJogo = Instance.new("TextLabel")
    textoPlacarJogo.Size = UDim2.new(0, 220, 0, 60) -- Tamanho fixo
    textoPlacarJogo.BackgroundTransparency = 0.4 -- Levemente transparente
    textoPlacarJogo.BackgroundColor3 = Color3.fromRGB(20,20,20) -- Cinza bem escuro
    textoPlacarJogo.TextColor3 = Color3.new(1,1,1) -- Branco
    textoPlacarJogo.Font = Enum.Font.GothamBlack -- Fonte grossa
    textoPlacarJogo.TextSize = 22 -- Tamanho da fonte 22
    textoPlacarJogo.Text = "JOGO: 0 x 0" -- Texto base
    textoPlacarJogo.Visible = false -- Começa invisível
    textoPlacarJogo.LayoutOrder = 2 -- Fica em segundo no layout da lista
    textoPlacarJogo.Parent = containerInfo -- Anexa ao InfoContainer
    Instance.new("UICorner", textoPlacarJogo) -- Cantos arredondados

    -- Valor Atual da Rodada (Vale 1, 3, 6)
    textoValorRodada = Instance.new("TextLabel")
    textoValorRodada.Size = UDim2.new(0, 150, 0, 40) -- Tamanho fixo
    textoValorRodada.Position = UDim2.new(0.5, 0, 0.22, 0) -- Logo abaixo do cronômetro
    textoValorRodada.AnchorPoint = Vector2.new(0.5, 0.5) -- Âncora central
    textoValorRodada.BackgroundTransparency = 1 -- Invisível
    textoValorRodada.TextColor3 = Color3.fromRGB(255, 255, 255) -- Branco
    textoValorRodada.Font = Enum.Font.GothamBold -- Fonte em negrito
    textoValorRodada.TextSize = 24 -- Tamanho 24
    textoValorRodada.Text = "VALE: 1" -- Texto padrão
    textoValorRodada.Visible = false -- Começa escondido
    textoValorRodada.Parent = painelTela -- Anexa à tela

    -- Botão Mutar Música
    local btnMusica = Instance.new("TextButton")
    btnMusica.Size = UDim2.new(0, 40, 0, 40) -- Quadrado pequeno 40x40
    btnMusica.Position = UDim2.new(0.02, 0, 0.9, 0) -- Canto inferior esquerdo
    btnMusica.AnchorPoint = Vector2.new(0, 1) -- Ancora por baixo
    btnMusica.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Cinza
    btnMusica.Text = "🎵" -- Ícone musical
    btnMusica.TextSize = 20 -- Tamanho do ícone
    btnMusica.Parent = painelTela -- Anexa à tela principal
    Instance.new("UICorner", btnMusica).CornerRadius = UDim.new(1, 0) -- Faz virar um círculo perfeito

    local mutado = false
    btnMusica.Activated:Connect(function()
        mutado = not mutado
        local bgm = game.SoundService:FindFirstChild("BackgroundMusic")
        if bgm then
            bgm.Volume = mutado and 0 or 0.3
            btnMusica.Text = mutado and "🔇" or "🎵"
            btnMusica.BackgroundColor3 = mutado and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(40, 40, 40)
        end
    end)

    btnLoja = Instance.new("TextButton")
    btnLoja.Name = "BtnLoja"
    btnLoja.Size = UDim2.new(0, 180, 0, 80)
    btnLoja.Position = UDim2.new(0.85, 0, 0.85, 0) 
    btnLoja.BackgroundColor3 = Color3.fromRGB(0, 196, 39)
    btnLoja.Text = "LOJA"
    btnLoja.TextColor3 = Color3.new(1,1,1)
    btnLoja.Font = Enum.Font.GothamBlack
    btnLoja.TextSize = 35
    btnLoja.Visible = true -- Começa visível pois o player nasce em pé
    btnLoja.Parent = painelTela
    Instance.new("UICorner", btnLoja).CornerRadius = UDim.new(0, 12)
    
    btnLoja.Activated:Connect(function()
        if menuLoja then
            menuLoja.Visible = not menuLoja.Visible
        end
    end)

    -- Chama as sub-funções para criar o resto da UI
    GerenciadorUI.CriarMenuLoja()
    GerenciadorUI.CriarMenuCorte()
    GerenciadorUI.CriarInterfaceDesafio()
    GerenciadorUI.CriarBotoesEmote()
    GerenciadorUI.CriarMenuTutorial()
    GerenciadorUI.CriarMenuAdmin()
end

-- ==========================================
-- SUB-CRIAÇÕES DE UI
-- ==========================================

-- ================= TUTORIAL =================
local SLIDES_TUTORIAL = {
    { Titulo = "O OBJETIVO", Texto = "Bem-vindo ao Truco! O jogo é disputado em duplas (2 contra 2). O objetivo da sua equipe é alcançar 12 pontos antes dos adversários.", Imagem = "rbxassetid:// 94577408525560" },
    { Titulo = "A RODADA", Texto = "Cada rodada (Mão) vale 1 ponto. Para ganhar, sua dupla precisa vencer 2 de 3 quedas. Cada jogador joga uma carta por queda, a mais forte vence.", Imagem = "rbxassetid://117539543208859" },
    { Titulo = "A FORÇA", Texto = "A força das cartas normais, da mais fraca para a mais forte, é: 4, 5, 6, 7, Q, J, K, A, 2, 3. Naipe não importa aqui, apenas o número!", Imagem = "rbxassetid://73972302411191" },
    { Titulo = "AS MANILHAS", Texto = "No início, uma carta é virada (O Vira). A Manilha é a carta logo acima dele. Ex: Se o Vira for 5, todos os 6 viram Manilhas, as mais fortes do jogo!", Imagem = "rbxassetid://109233300765686" },
    { Titulo = "TRUCO!", Texto = "Acha que tem cartas boas? Clique em TRUCO! Isso aumenta o valor da Mão para 3 pontos. Os adversários podem Aceitar, Fugir ou Aumentar para 6!", Imagem = "rbxassetid://86983343730484" },
    { Titulo = "DICAS", Texto = "Jogue cartas Cobertas para esconder seu jogo e use os Sinais (Olhar/Mão) para se comunicar com seu parceiro. Boa sorte!", Imagem = "rbxassetid://75845041324394" }
}

-- [MÉTODO INTERNO] Atualiza os textos e botões baseado no slide atual
local function atualizarSlideTutorial()
    local dados = SLIDES_TUTORIAL[slideAtualTutorial]
    tituloTutorial.Text = dados.Titulo
    textoTutorial.Text = dados.Texto
    
    -- Atualiza a imagem se houver ID. Caso contrário, fica o fundo cinza.
    if dados.Imagem ~= "" then
        imgTutorial.Image = dados.Imagem
        imgTutorial.BackgroundTransparency = 1
    else
        imgTutorial.Image = ""
        imgTutorial.BackgroundTransparency = 0
    end

    -- Esconde o botão "Anterior" se estiver na primeira página
    btnAnteriorTut.Visible = (slideAtualTutorial > 1)
    
    -- Muda o botão "Próximo" para "Entendi" na última página
    if slideAtualTutorial == #SLIDES_TUTORIAL then
        btnProximoTut.Text = "ENTENDI!"
        btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Azul para o botão final
    else
        btnProximoTut.Text = "PRÓXIMO >"
        btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 196, 39) -- Verde
    end
end

function GerenciadorUI.CriarMenuTutorial()
    menuTutorial = Instance.new("Frame")
    menuTutorial.Name = "MenuTutorial"
    menuTutorial.Size = UDim2.new(0, 500, 0, 450)
    menuTutorial.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuTutorial.AnchorPoint = Vector2.new(0.5, 0.5)
    menuTutorial.BackgroundColor3 = Color3.fromRGB(175, 175, 175) 
    menuTutorial.Visible = false
    menuTutorial.ZIndex = 60
    menuTutorial.Parent = painelTela
    Instance.new("UICorner", menuTutorial).CornerRadius = UDim.new(0, 20)

    -- Botão Fechar (X)
    local btnFechar = Instance.new("TextButton")
    btnFechar.Size = UDim2.new(0, 40, 0, 40)
    btnFechar.Position = UDim2.new(1, -15, 0, 15)
    btnFechar.AnchorPoint = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnFechar.Text = "X"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.Font = Enum.Font.GothamBlack
    btnFechar.TextSize = 20
    btnFechar.ZIndex = 62
    btnFechar.Parent = menuTutorial
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    
    btnFechar.Activated:Connect(function()
        GerenciadorUI.MostrarTutorial(false)
    end)

    tituloTutorial = Instance.new("TextLabel")
    tituloTutorial.Size = UDim2.new(1, 0, 0, 50)
    tituloTutorial.Position = UDim2.new(0, 0, 0, 10)
    tituloTutorial.BackgroundTransparency = 1
    tituloTutorial.Text = "TUTORIAL"
    tituloTutorial.TextColor3 = Color3.new(1, 1, 1)
    tituloTutorial.Font = Enum.Font.GothamBlack
    tituloTutorial.TextSize = 35
    tituloTutorial.ZIndex = 61
    tituloTutorial.Parent = menuTutorial

    -- Imagem demonstrativa (Placeholder cinza escuro)
    imgTutorial = Instance.new("ImageLabel")
    imgTutorial.Size = UDim2.new(0.85, 0, 0.4, 0)
    imgTutorial.Position = UDim2.new(0.5, 0, 0.15, 0)
    imgTutorial.AnchorPoint = Vector2.new(0.5, 0)
    imgTutorial.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    imgTutorial.ScaleType = Enum.ScaleType.Fit
    imgTutorial.ZIndex = 61
    imgTutorial.Parent = menuTutorial
    Instance.new("UICorner", imgTutorial).CornerRadius = UDim.new(0, 10)

    -- Texto Explicativo
    textoTutorial = Instance.new("TextLabel")
    textoTutorial.Size = UDim2.new(0.9, 0, 0.3, 0)
    textoTutorial.Position = UDim2.new(0.5, 0, 0.6, 0)
    textoTutorial.AnchorPoint = Vector2.new(0.5, 0)
    textoTutorial.BackgroundTransparency = 1
    textoTutorial.Text = ""
    textoTutorial.TextColor3 = Color3.new(1, 1, 1)
    textoTutorial.Font = Enum.Font.GothamMedium
    textoTutorial.TextSize = 18
    textoTutorial.TextWrapped = true
    textoTutorial.ZIndex = 61
    textoTutorial.Parent = menuTutorial

    -- Botões de Navegação
    btnAnteriorTut = Instance.new("TextButton")
    btnAnteriorTut.Size = UDim2.new(0, 150, 0, 45)
    btnAnteriorTut.Position = UDim2.new(0.25, 0, 0.95, 0)
    btnAnteriorTut.AnchorPoint = Vector2.new(0.5, 1)
    btnAnteriorTut.BackgroundColor3 = Color3.fromRGB(200, 105, 50) 
    btnAnteriorTut.Text = "< ANTERIOR"
    btnAnteriorTut.TextColor3 = Color3.new(1, 1, 1)
    btnAnteriorTut.Font = Enum.Font.GothamBlack
    btnAnteriorTut.TextSize = 18
    btnAnteriorTut.ZIndex = 62
    btnAnteriorTut.Parent = menuTutorial
    Instance.new("UICorner", btnAnteriorTut).CornerRadius = UDim.new(0.5, 0)

    btnProximoTut = Instance.new("TextButton")
    btnProximoTut.Size = UDim2.new(0, 150, 0, 45)
    btnProximoTut.Position = UDim2.new(0.75, 0, 0.95, 0)
    btnProximoTut.AnchorPoint = Vector2.new(0.5, 1)
    btnProximoTut.BackgroundColor3 = Color3.fromRGB(0, 196, 39) 
    btnProximoTut.Text = "PRÓXIMO >"
    btnProximoTut.TextColor3 = Color3.new(1, 1, 1)
    btnProximoTut.Font = Enum.Font.GothamBlack
    btnProximoTut.TextSize = 18
    btnProximoTut.ZIndex = 62
    btnProximoTut.Parent = menuTutorial
    Instance.new("UICorner", btnProximoTut).CornerRadius = UDim.new(0.5, 0)

    -- Ações dos Botões
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
            GerenciadorUI.MostrarTutorial(false) -- Clicou em "ENTENDI"
        end
    end)
end

-- [MÉTODO] Abre e fecha o tutorial e carrega o primeiro slide de forma limpa
function GerenciadorUI.MostrarTutorial(abrir)
    if not menuTutorial then return end
    
    if abrir then
        slideAtualTutorial = 1 
        atualizarSlideTutorial() -- AGORA SIM: Preenche tudo antes de mostrar!
        menuTutorial.Visible = true
    else
        menuTutorial.Visible = false
    end
end

-- E NÃO ESQUEÇA: Coloque `GerenciadorUI.CriarMenuTutorial()` dentro da sua função `GerenciadorUI.Inicializar()`!

-- [MÉTODO] Cria a interface completa da Loja
function GerenciadorUI.CriarMenuLoja()
    -- Painel Principal (Cinza)
    menuLoja = Instance.new("Frame")
    menuLoja.Name = "MenuLoja"
    menuLoja.Size = UDim2.new(0, 600, 0, 400) -- Tamanho retangular
    menuLoja.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuLoja.AnchorPoint = Vector2.new(0.5, 0.5)
    menuLoja.BackgroundColor3 = Color3.fromRGB(175, 175, 175) -- Cinza dos seus prints
    menuLoja.Visible = false
    menuLoja.ZIndex = 50
    menuLoja.Parent = painelTela
    Instance.new("UICorner", menuLoja).CornerRadius = UDim.new(0, 20)

    -- Botão Fechar (X)
    local btnFechar = Instance.new("TextButton")
    btnFechar.Size = UDim2.new(0, 40, 0, 40)
    btnFechar.Position = UDim2.new(1, -15, 0, 15)
    btnFechar.AnchorPoint = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnFechar.Text = "X"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.Font = Enum.Font.GothamBlack
    btnFechar.TextSize = 20
    btnFechar.ZIndex = 52
    btnFechar.Parent = menuLoja
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    
    btnFechar.Activated:Connect(function()
        menuLoja.Visible = false
    end)

    -- Container das Abas (Topo)
    local containerAbas = Instance.new("Frame")
    containerAbas.Size = UDim2.new(1, 0, 0, 80)
    containerAbas.BackgroundTransparency = 1
    containerAbas.Parent = menuLoja

    -- Cores baseadas nos seus prints
    local corLaranjaAtivo = Color3.fromRGB(200, 105, 50)
    local corLaranjaInativo = Color3.fromRGB(255, 145, 75)
    local corVerdeAtivo = Color3.fromRGB(0, 150, 60)
    local corVerdeInativo = Color3.fromRGB(0, 200, 80)

    -- Aba PONTOS
    btnAbaPontos = Instance.new("TextButton")
    btnAbaPontos.Size = UDim2.new(0, 200, 0, 60)
    btnAbaPontos.Position = UDim2.new(0.30, 0, 0.5, 0)
    btnAbaPontos.AnchorPoint = Vector2.new(0.5, 0.5)
    btnAbaPontos.BackgroundColor3 = corLaranjaAtivo -- Começa ativa
    btnAbaPontos.Text = "PONTOS"
    btnAbaPontos.TextColor3 = Color3.new(1, 1, 1)
    btnAbaPontos.Font = Enum.Font.GothamBlack
    btnAbaPontos.TextSize = 30
    btnAbaPontos.ZIndex = 51
    btnAbaPontos.Parent = containerAbas
    Instance.new("UICorner", btnAbaPontos).CornerRadius = UDim.new(0.5, 0)

    -- Aba ROBUX
    btnAbaRobux = Instance.new("TextButton")
    btnAbaRobux.Size = UDim2.new(0, 200, 0, 60)
    btnAbaRobux.Position = UDim2.new(0.70, 0, 0.5, 0)
    btnAbaRobux.AnchorPoint = Vector2.new(0.5, 0.5)
    btnAbaRobux.BackgroundColor3 = corVerdeInativo
    btnAbaRobux.Text = "ROBUX"
    btnAbaRobux.TextColor3 = Color3.new(1, 1, 1)
    btnAbaRobux.Font = Enum.Font.GothamBlack
    btnAbaRobux.TextSize = 30
    btnAbaRobux.ZIndex = 51
    btnAbaRobux.Parent = containerAbas
    Instance.new("UICorner", btnAbaRobux).CornerRadius = UDim.new(0.5, 0)

    -- Texto exibindo o saldo de Pontos (Colocado no topo do menu)
    textoMeusPontos = Instance.new("TextLabel")
    textoMeusPontos.Size = UDim2.new(1, 0, 0, 30)
    textoMeusPontos.Position = UDim2.new(0, 0, 0, -35)
    textoMeusPontos.BackgroundTransparency = 1
    textoMeusPontos.Text = "MEUS PONTOS: 0"
    textoMeusPontos.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    textoMeusPontos.Font = Enum.Font.GothamBlack
    textoMeusPontos.TextSize = 24
    textoMeusPontos.ZIndex = 51
    textoMeusPontos.Parent = menuLoja

    -- ================= PÁGINA: PONTOS =================
    -- Agora é um ScrollingFrame, igual a aba de Robux!
    paginaPontos = Instance.new("ScrollingFrame")
    paginaPontos.Size = UDim2.new(1, -40, 1, -110)
    paginaPontos.Position = UDim2.new(0, 20, 0, 90)
    paginaPontos.BackgroundTransparency = 1
    paginaPontos.ScrollBarThickness = 6
    paginaPontos.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    paginaPontos.Visible = true 
    paginaPontos.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    paginaPontos.CanvasSize = UDim2.new(0, 0, 0, 0)
    paginaPontos.Parent = menuLoja

    local layoutPontos = Instance.new("UIListLayout", paginaPontos)
    layoutPontos.Padding = UDim.new(0, 15)
    layoutPontos.SortOrder = Enum.SortOrder.LayoutOrder

    -- ================= PÁGINA: ROBUX =================
    paginaRobux = Instance.new("ScrollingFrame")
    paginaRobux.Size = UDim2.new(1, -40, 1, -110)
    paginaRobux.Position = UDim2.new(0, 20, 0, 90)
    paginaRobux.BackgroundTransparency = 1
    paginaRobux.ScrollBarThickness = 6
    paginaRobux.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    paginaRobux.Visible = false -- Começa oculta
    paginaRobux.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    paginaRobux.CanvasSize = UDim2.new(0, 0, 0, 0)
    paginaRobux.Parent = menuLoja

    local layoutRobux = Instance.new("UIListLayout", paginaRobux)
    layoutRobux.Padding = UDim.new(0, 15)
    layoutRobux.SortOrder = Enum.SortOrder.LayoutOrder

    -- Função auxiliar para criar itens de doação na lista
    local function criarItemLoja(nome, desc, preco, idProduto, ehGamepass)
        local frameItem = Instance.new("Frame")
        frameItem.Size = UDim2.new(1, -10, 0, 100)
        frameItem.BackgroundTransparency = 1
        frameItem.ZIndex = 51 
        frameItem.Parent = paginaRobux

        local icone = Instance.new("ImageLabel")
        icone.Size = UDim2.new(0, 80, 0, 80)
        icone.Position = UDim2.new(0, 10, 0.5, 0)
        icone.AnchorPoint = Vector2.new(0, 0.5)
        -- Mantemos a cor laranja como um "fundo de carregamento" enquanto a foto não chega
        icone.BackgroundColor3 = Color3.fromRGB(180, 100, 50)
        icone.ZIndex = 51 
        icone.Parent = frameItem
        Instance.new("UICorner", icone).CornerRadius = UDim.new(1, 0)

        -- Busca a imagem oficial do Roblox em segundo plano para não travar o jogo
        task.spawn(function()
            local sucesso, informacao = pcall(function()
                local tipoBusca = ehGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
                return MarketplaceService:GetProductInfo(idProduto, tipoBusca)
            end)

            -- Se achou o produto e ele tem uma imagem válida
            if sucesso and informacao and informacao.IconImageAssetId and informacao.IconImageAssetId > 0 then
                icone.Image = "rbxassetid://" .. informacao.IconImageAssetId
                icone.BackgroundTransparency = 1 -- Deixa o fundo laranja invisível, mostrando só a foto
            end
        end)
        -- ====================================================

        local titulo = Instance.new("TextLabel")
        titulo.Size = UDim2.new(0.6, 0, 0.3, 0)
        titulo.Position = UDim2.new(0, 110, 0, 10)
        titulo.BackgroundTransparency = 1
        titulo.Text = nome
        titulo.TextColor3 = Color3.new(1, 1, 1)
        titulo.Font = Enum.Font.GothamBlack
        titulo.TextSize = 22
        titulo.TextXAlignment = Enum.TextXAlignment.Left
        titulo.ZIndex = 51 
        titulo.Parent = frameItem

        local descricao = Instance.new("TextLabel")
        descricao.Size = UDim2.new(0.6, 0, 0.3, 0)
        descricao.Position = UDim2.new(0, 110, 0, 35)
        descricao.BackgroundTransparency = 1
        descricao.Text = desc
        descricao.TextColor3 = Color3.new(1, 1, 1)
        descricao.Font = Enum.Font.GothamMedium
        descricao.TextSize = 18
        descricao.TextXAlignment = Enum.TextXAlignment.Left
        descricao.ZIndex = 51 
        descricao.Parent = frameItem

        local btnComprar = Instance.new("TextButton")
        btnComprar.Size = UDim2.new(0, 120, 0, 35)
        btnComprar.Position = UDim2.new(0, 110, 0, 65)
        btnComprar.BackgroundColor3 = corVerdeInativo
        
        btnComprar.Text = "R$ " .. preco .. " COMPRAR" 
        btnComprar.TextColor3 = Color3.new(1, 1, 1)
        btnComprar.Font = Enum.Font.GothamBold
        btnComprar.TextSize = 14
        btnComprar.ZIndex = 52 
        btnComprar.Parent = frameItem
        Instance.new("UICorner", btnComprar).CornerRadius = UDim.new(0.5, 0)
        
        btnComprar.Activated:Connect(function()
            if ehGamepass then
                MarketplaceService:PromptGamePassPurchase(jogadorLocal, idProduto)
            else
                MarketplaceService:PromptProductPurchase(jogadorLocal, idProduto)
            end
        end)
    end

    -- Cria os itens (Substitua os números 000000 pelos IDs reais do seu jogo depois!)
    -- Os últimos dois parâmetros são: ID do produto e se é Gamepass (true ou false)
    
    -- ======== PACOTES DE PONTOS ========
    criarItemLoja("100 Pontos", "Impulsione suas compras!", "10", 3554291316, false)
    criarItemLoja("500 Pontos", "Fique rico rapidamente!", "40", 3554291580, false)
    
    -- ======== DOAÇÕES ========
    criarItemLoja("Doação 1", "Vai me ajudar a desenvolver o jogo :D", "15", 3549774213, false)
    criarItemLoja("Doação 2", "Vai me ajudar a desenvolver o jogo :D", "30", 3549774425, false)

    -- ================= LÓGICA DAS ABAS =================
    
    -- Exemplo se fosse uma Gamepass (Sinalizado com "true" no final):
    -- criarItemLoja("Passe VIP", "Dá uma coroa no seu nick!", "100", 111222333, true)

    -- ================= LÓGICA DAS ABAS =================
    btnAbaPontos.Activated:Connect(function()
        paginaPontos.Visible = true
        paginaRobux.Visible = false
        btnAbaPontos.BackgroundColor3 = corLaranjaAtivo
        btnAbaRobux.BackgroundColor3 = corVerdeInativo
    end)

    btnAbaRobux.Activated:Connect(function()
        paginaPontos.Visible = false
        paginaRobux.Visible = true
        btnAbaPontos.BackgroundColor3 = corLaranjaInativo
        btnAbaRobux.BackgroundColor3 = corVerdeAtivo
    end)
end

-- Catálogo de Skins disponíveis no jogo
local CATALOGO_SKINS = {
    { Id = "Padrao", Nome = "Baralho Clássico", Preco = 0, Desc = "O bom e velho Truco raiz." },
    { Id = "Rosa", Nome = "Baralho Rosa", Preco = 200, Desc = "Para quem gosta de um jogo fofinho." },
    { Id = "Nacional", Nome = "Baralho Nacional", Preco = 300, Desc = "Baralho 100% patriota." },
    { Id = "Estrela", Nome = "Baralho Estelar", Preco = 300, Desc = "Baralho 100% da Estrela Vermelha." },
}

-- [MÉTODO] Desenha os itens na aba de pontos baseado no que o jogador já tem
function GerenciadorUI.RenderizarSkinsPontos()
    if not paginaPontos then return end
    
    -- Limpa a lista antiga para desenhar a nova atualizada
    for _, filho in ipairs(paginaPontos:GetChildren()) do
        if filho:IsA("Frame") then filho:Destroy() end
    end

    for _, skin in ipairs(CATALOGO_SKINS) do
        local frameItem = Instance.new("Frame")
        frameItem.Size = UDim2.new(1, -10, 0, 100)
        frameItem.BackgroundTransparency = 1
        frameItem.ZIndex = 51 
        frameItem.Parent = paginaPontos

        -- Placeholder da imagem da carta (Caixa cor sólida por enquanto)
    -- Substitua o Frame do ícone antigo por este ImageLabel
        local icone = Instance.new("ImageLabel")
        icone.Size = UDim2.new(0, 60, 0, 85) -- Formato de carta
        icone.Position = UDim2.new(0, 20, 0.5, 0)
        icone.AnchorPoint = Vector2.new(0, 0.5)
        icone.BackgroundTransparency = 1 -- Fundo invisível
        icone.ZIndex = 51 
        icone.Parent = frameItem
        Instance.new("UICorner", icone).CornerRadius = UDim.new(0, 6)

        -- ======== MÁGICA AQUI: Aplica o Ás de Espadas da respectiva skin! ========
        CardSettings.AplicarSkinCarta(icone, "A", "Espadas", false, skin.Id)
        -- =========================================================================

        local titulo = Instance.new("TextLabel")
        titulo.Size = UDim2.new(0.6, 0, 0.3, 0)
        titulo.Position = UDim2.new(0, 100, 0, 10)
        titulo.BackgroundTransparency = 1
        titulo.Text = skin.Nome
        titulo.TextColor3 = Color3.new(1, 1, 1)
        titulo.Font = Enum.Font.GothamBlack
        titulo.TextSize = 22
        titulo.TextXAlignment = Enum.TextXAlignment.Left
        titulo.ZIndex = 51 
        titulo.Parent = frameItem

        local descricao = Instance.new("TextLabel")
        descricao.Size = UDim2.new(0.6, 0, 0.3, 0)
        descricao.Position = UDim2.new(0, 100, 0, 35)
        descricao.BackgroundTransparency = 1
        descricao.Text = skin.Desc
        descricao.TextColor3 = Color3.new(1, 1, 1)
        descricao.Font = Enum.Font.GothamMedium
        descricao.TextSize = 16
        descricao.TextXAlignment = Enum.TextXAlignment.Left
        descricao.ZIndex = 51 
        descricao.Parent = frameItem

        local btnAcao = Instance.new("TextButton")
        btnAcao.Size = UDim2.new(0, 140, 0, 35)
        btnAcao.Position = UDim2.new(0, 100, 0, 65)
        btnAcao.Font = Enum.Font.GothamBold
        btnAcao.TextSize = 14
        btnAcao.ZIndex = 52 
        btnAcao.Parent = frameItem
        Instance.new("UICorner", btnAcao).CornerRadius = UDim.new(0.5, 0)

        -- ======== LÓGICA DE ESTADO DO BOTÃO ========
        local jaPossui = table.find(dadosJogador.SkinsCompradas, skin.Id)
        local estaEquipado = (dadosJogador.SkinEquipada == skin.Id)

        if estaEquipado then
            btnAcao.Text = "EQUIPADO"
            btnAcao.BackgroundColor3 = Color3.fromRGB(200, 105, 50) -- Laranja
            btnAcao.TextColor3 = Color3.new(1, 1, 1)
        elseif jaPossui then
            btnAcao.Text = "EQUIPAR"
            btnAcao.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Azul
            btnAcao.TextColor3 = Color3.new(1, 1, 1)
            
            btnAcao.Activated:Connect(function()
                Eventos.ShopActionEvent:FireServer("Equipar", skin.Id)
            end)
        else
            btnAcao.Text = skin.Preco .. " PTS - COMPRAR"
            
            -- Se não tiver dinheiro, deixa o botão cinza
            if dadosJogador.Pontos >= skin.Preco then
                btnAcao.BackgroundColor3 = Color3.fromRGB(0, 196, 39) -- Verde
            else
                btnAcao.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Cinza
            end
            
            btnAcao.TextColor3 = Color3.new(1, 1, 1)
            
            btnAcao.Activated:Connect(function()
                if dadosJogador.Pontos >= skin.Preco then
                    Eventos.ShopActionEvent:FireServer("Comprar", skin.Id)
                else
                    btnAcao.Text = "PONTOS INSUFICIENTES"
                    task.delay(1.5, function()
                        if btnAcao then btnAcao.Text = skin.Preco .. " PTS - COMPRAR" end
                    end)
                end
            end)
        end
    end
end

function GerenciadorUI.DefinirCallbackEmote(callback)
    callbackEmote = callback
end

-- [MÉTODO] Cria os botões para mandar os gestos (emotes)
function GerenciadorUI.CriarBotoesEmote()
    painelEmotes = Instance.new("Frame")
    painelEmotes.Name = "EmoteButtons" -- Nome do contêiner de emotes
    painelEmotes.Size = UDim2.new(0, 120, 0, 60) -- Caixa que acomoda os botões
    painelEmotes.Position = UDim2.new(0.98, 0, 0.85, 0) -- Canto inferior direito (acima do Truco)
    painelEmotes.AnchorPoint = Vector2.new(1, 1) -- Ancora pela direita inferior
    painelEmotes.BackgroundTransparency = 1 -- Container invisível
    painelEmotes.Visible = false -- Inicia invisível
    painelEmotes.Parent = painelTela -- Anexa à tela
    
    local layout = Instance.new("UIListLayout", painelEmotes)
    layout.FillDirection = Enum.FillDirection.Horizontal -- Coloca botões lado a lado
    layout.Padding = UDim.new(0, 10) -- Espaço de 10 pixels

    local function criarBotaoEmote(icone, nomeSinal)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50) -- Quadrado 50x50
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Cinza escuro
        btn.Text = icone -- Coloca o emoji
        btn.TextSize = 30 -- Tamanho do emoji
        btn.TextColor3 = Color3.new(1,1,1) -- Cor do texto
        btn.Parent = painelEmotes -- Coloca no painel
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0) -- Transforma em círculo perfeito
        
        btn.Activated:Connect(function()
            if callbackEmote then callbackEmote(nomeSinal) end
        end)
    end
    
    criarBotaoEmote("🖐️", "Sinal_Mao")
    criarBotaoEmote("👀", "Sinal_Olhar")
end

-- [MÉTODO] Cria a interface para cortar o baralho
function GerenciadorUI.CriarMenuCorte()
    painelCorte = Instance.new("Frame")
    painelCorte.Name = "CutFrame" -- Nome do painel de corte
    painelCorte.Size = UDim2.new(0, 400, 0, 220) -- Dimensões grandes ao centro
    painelCorte.Position = UDim2.new(0.5, 0, 0.45, 0) -- Levemente acima do meio
    painelCorte.AnchorPoint = Vector2.new(0.5, 0.5) -- Centro absoluto
    painelCorte.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Cinza muito escuro
    painelCorte.Visible = false -- Oculto até ser necessário
    painelCorte.Parent = painelTela -- Anexa à tela principal
    Instance.new("UICorner", painelCorte).CornerRadius = UDim.new(0, 15) -- Bordas arredondadas suaves
    
    local fundoBarraTimer = Instance.new("Frame")
    fundoBarraTimer.Size = UDim2.new(1, 0, 0, 6) -- Barra fina embaixo (6px altura)
    fundoBarraTimer.Position = UDim2.new(0, 0, 1, 0) -- Grudado no chão da caixa
    fundoBarraTimer.AnchorPoint = Vector2.new(0, 1) -- Ancora pelo chão
    fundoBarraTimer.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Cor do trilho da barra (cinza)
    fundoBarraTimer.Parent = painelCorte
    
    barraTempoCorte = Instance.new("Frame")
    barraTempoCorte.Size = UDim2.new(1, 0, 1, 0) -- Começa cheia (100% largura)
    barraTempoCorte.BackgroundColor3 = Color3.fromRGB(0, 200, 255) -- Cor azul claro marcante
    barraTempoCorte.BorderSizePixel = 0 -- Sem contorno
    barraTempoCorte.Parent = fundoBarraTimer

    local tituloCorte = Instance.new("TextLabel")
    tituloCorte.Text = "SUA VEZ DE CORTAR" -- Texto do título
    tituloCorte.Size = UDim2.new(1, 0, 0.4, 0) -- Ocupa o topo
    tituloCorte.TextColor3 = Color3.fromRGB(255, 255, 255) -- Branco
    tituloCorte.Font = Enum.Font.GothamBold -- Fonte forte
    tituloCorte.TextSize = 24 -- Tamanho considerável
    tituloCorte.BackgroundTransparency = 1 -- Fundo invisível
    tituloCorte.Parent = painelCorte

    local containerBotoes = Instance.new("Frame")
    containerBotoes.Size = UDim2.new(0.9, 0, 0.4, 0) -- Caixa pros botões dentro do painel
    containerBotoes.Position = UDim2.new(0.5, 0, 0.7, 0) -- Colocado mais pra baixo
    containerBotoes.AnchorPoint = Vector2.new(0.5, 0.5) -- Ancorado no meio
    containerBotoes.BackgroundTransparency = 1 -- Invisível
    containerBotoes.Parent = painelCorte

    local layoutBotoes = Instance.new("UIListLayout")
    layoutBotoes.FillDirection = Enum.FillDirection.Horizontal -- Botões deitados
    layoutBotoes.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Alinhados ao centro
    layoutBotoes.Padding = UDim.new(0, 20) -- 20px de espaço
    layoutBotoes.Parent = containerBotoes

    local function criarBotaoCorte(texto)
        local btn = Instance.new("TextButton")
        btn.Text = texto -- Define texto (1x, 2x, 3x)
        btn.Size = UDim2.new(0, 90, 0, 70) -- Caixas grandes
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Cor cinza
        btn.TextColor3 = Color3.fromRGB(255, 255, 255) -- Letras brancas
        btn.Font = Enum.Font.GothamBold -- Negrito
        btn.TextSize = 22 -- Letra grande
        btn.Parent = containerBotoes -- Joga no container
        Instance.new("UICorner", btn) -- Arredonda
        
        btn.Activated:Connect(function()
            painelCorte.Visible = false
            Eventos.GameStatusEvent:FireServer("CutAction", tonumber(string.sub(texto, 1, 1)))
        end)
    end

    criarBotaoCorte("1x")
    criarBotaoCorte("2x")
    criarBotaoCorte("3x")
end

-- [MÉTODO] Cria a UI de Desafio quando alguém pede Truco
function GerenciadorUI.CriarInterfaceDesafio()
    painelDesafio = Instance.new("Frame")
    painelDesafio.Name = "TrucoChallengeFrame" -- Nome da moldura
    painelDesafio.Size = UDim2.new(0, 350, 0, 220) -- Dimensões
    painelDesafio.Position = UDim2.new(0.5, 0, 0.4, 0) -- Bem ao centro
    painelDesafio.AnchorPoint = Vector2.new(0.5, 0.5) -- Centro âncora
    painelDesafio.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Fundo escuro
    painelDesafio.Visible = false -- Começa oculto
    painelDesafio.Parent = painelTela -- Anexa à tela
    Instance.new("UICorner", painelDesafio) -- Bordas curvas

    local trilhoTimer = Instance.new("Frame")
    trilhoTimer.Name = "TimerBG" -- Trilho do timer
    trilhoTimer.Size = UDim2.new(1, 0, 0, 8) -- Fino, 8px
    trilhoTimer.Position = UDim2.new(0,0,1,0) -- Embaixo do painel
    trilhoTimer.AnchorPoint = Vector2.new(0,1) -- Ancora base
    trilhoTimer.BackgroundColor3 = Color3.fromRGB(50,50,50) -- Cor do trilho vazia
    trilhoTimer.Parent = painelDesafio
    
    barraTempoDesafio = Instance.new("Frame")
    barraTempoDesafio.Name = "TimerBar" -- Barra ativa do tempo
    barraTempoDesafio.Size = UDim2.new(1, 0, 1, 0) -- Cheia
    barraTempoDesafio.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Cor vermelha (pressão)
    barraTempoDesafio.BorderSizePixel = 0 -- Sem bordas grossas
    barraTempoDesafio.Parent = trilhoTimer

    local tituloTxt = Instance.new("TextLabel")
    tituloTxt.Name = "Title" -- Titulo do pedido
    tituloTxt.Size = UDim2.new(1, 0, 0.3, 0) -- Ocupa 30% do topo
    tituloTxt.TextScaled = true -- Texto aumenta sozinho
    tituloTxt.TextColor3 = Color3.new(1, 1, 1) -- Branco
    tituloTxt.BackgroundTransparency = 1 -- Invisível atrás
    tituloTxt.Parent = painelDesafio
    
    local estadoTxt = Instance.new("TextLabel")
    estadoTxt.Name = "Status" -- Estado da votação
    estadoTxt.Text = "" -- Começa limpo
    estadoTxt.Size = UDim2.new(1, 0, 0.15, 0) -- Tamanho fino
    estadoTxt.Position = UDim2.new(0, 0, 0.3, 0) -- Logo abaixo do titulo
    estadoTxt.TextColor3 = Color3.fromRGB(255, 200, 0) -- Amarelo para destacar
    estadoTxt.BackgroundTransparency = 1 -- Transparente
    estadoTxt.Parent = painelDesafio

    local function criarBotaoDesafio(texto, cor, posX, respostaServer, nomeBotao)
        local btn = Instance.new("TextButton")
        btn.Name = nomeBotao -- Define o nome (útil para encontrar depois)
        btn.Text = texto -- O que o botão diz (Descer, Fugir, Aumentar)
        btn.Size = UDim2.new(0.28, 0, 0.35, 0) -- Cada um pega uns 28% do tamanho
        btn.Position = UDim2.new(posX, 0, 0.55, 0) -- Posiciona conforme o parâmetro
        btn.BackgroundColor3 = cor -- Cor customizada via parametro
        btn.TextColor3 = Color3.new(1, 1, 1) -- Branco
        btn.Font = Enum.Font.GothamBold -- Negrito
        btn.TextSize = 20 -- Tamanho do texto
        btn.Parent = painelDesafio -- Põe na tela do desafio
        Instance.new("UICorner", btn) -- Curvas
        
        btn.Activated:Connect(function()
            estadoTxt.Text = "Aguardando Parceiro..."
            btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)  -- Deixa cinza após clicar
            Eventos.TrucoEvent:FireServer("Response", respostaServer)
        end)
    end

    -- Cria Verde, Vermelho e Laranja
    criarBotaoDesafio("DESCER", Color3.fromRGB(0, 150, 0), 0.04, "Aceitar", "AceitarBtn")
    criarBotaoDesafio("FUGIR", Color3.fromRGB(150, 0, 0), 0.36, "Correr", "CorrerBtn")
    criarBotaoDesafio("AUMENTAR", Color3.fromRGB(200, 150, 0), 0.68, "Aumentar", "AumentarBtn")
end

-- ==========================================
-- FUNÇÕES PÚBLICAS (MÉTODOS)
-- ==========================================

function GerenciadorUI.AtualizarStatusDesafio(msg)
    if painelDesafio and painelDesafio.Visible then
        local status = painelDesafio:FindFirstChild("Status")
        if status then status.Text = msg end
    end
end

-- [MÉTODO] Aparece o pop-up na tela pra responder a um Truco
function GerenciadorUI.MostrarDesafioTruco(valor, quemPediu, tempoLimite)
    if not painelDesafio then GerenciadorUI.CriarInterfaceDesafio() end
    
    local titulo = painelDesafio:FindFirstChild("Title")
    local status = painelDesafio:FindFirstChild("Status")
    
    if titulo then titulo.Text = quemPediu .. " PEDIU " .. valor .. "!" end
    if status then status.Text = "Decidam juntos!" end
    
    local btnAceitar = painelDesafio:FindFirstChild("AceitarBtn")
    local btnCorrer = painelDesafio:FindFirstChild("CorrerBtn")
    local btnAumentar = painelDesafio:FindFirstChild("AumentarBtn")
    
    -- Reseta as cores dos botões ao reabrir
    if btnAceitar then btnAceitar.BackgroundColor3 = Color3.fromRGB(0, 150, 0) end
    if btnCorrer then btnCorrer.BackgroundColor3 = Color3.fromRGB(150, 0, 0) end
    if btnAumentar then 
        btnAumentar.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        local proximoValor = (valor < 12) and (valor + 3) or 12
        btnAumentar.Text = proximoValor .. "!"
        btnAumentar.Visible = (valor < 12) -- Oculta o "Aumentar" se já vale 12
    end

    painelDesafio.Visible = true
    GerenciadorUI.AplicarCameraTensao(quemPediu) -- Foca a câmera em quem pediu
    
    -- Animação da barra vermelha
    if barraTempoDesafio then
        barraTempoDesafio.Size = UDim2.new(1, 0, 1, 0)
        if tempoLimite and tempoLimite > 0 then
            local tweenInfo = TweenInfo.new(tempoLimite, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(barraTempoDesafio, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
            tween:Play()
        end
    end
end

function GerenciadorUI.OcultarDesafioTruco()
    if painelDesafio then painelDesafio.Visible = false end
    GerenciadorUI.ResetarCamera()
end

-- [MÉTODO] Mostra as opções de corte 1x, 2x, 3x com timer
function GerenciadorUI.MostrarOpcoesCorte(tempoLimite)
    if painelCorte then
        painelCorte.Visible = true
        barraTempoCorte.Size = UDim2.new(1, 0, 1, 0)
        local tweenInfo = TweenInfo.new(tempoLimite, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(barraTempoCorte, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
        tween:Play()
        
        task.delay(tempoLimite + 0.5, function()
            if painelCorte.Visible then painelCorte.Visible = false end
        end)
    end
end

function GerenciadorUI.OcultarMenuCorte()
    if painelCorte then painelCorte.Visible = false end
end

-- [MÉTODO] Limpa TUDO quando sai da mesa
function GerenciadorUI.ResetTotal()
    GerenciadorUI.LimparMao()
    GerenciadorUI.LimparMesa()
    GerenciadorUI.DefinirVisibilidadeUIJogo(false)
    GerenciadorUI.OcultarPlacar()
    GerenciadorUI.OcultarDesafioTruco()
    if textoCronometro then textoCronometro.Text = "" end
end

-- ==========================================
-- UI DE GAMEPLAY (CARTAS E MESA)
-- ==========================================

-- [MÉTODO] Adiciona uma carta fisicamente clicável à mão do player
function GerenciadorUI.AdicionarCartaMao(valor, naipe)
    local conteinerCarta = Instance.new("Frame")
    conteinerCarta.Name = "CardWrapper" -- Caixa em volta da carta
    conteinerCarta.ClipsDescendants = false -- Permite sair
    conteinerCarta.Size = UDim2.new(0, 110, 0, 160) -- Tamanho
    conteinerCarta.BackgroundTransparency = 1 -- Invisivel
    conteinerCarta.Parent = painelMao

    local btnImg = Instance.new("ImageButton")
    btnImg.Name = valor .. "_" .. naipe -- Ex: 4_Ouros
    btnImg.Size = UDim2.new(1, 0, 1, 0) -- Pega 100% da caixa
    btnImg.BackgroundTransparency = 1 -- Fundo invisivel
    
    -- Lê a variável 'dadosJogador' que sincronizamos na Etapa 1
    local minhaSkin = dadosJogador.SkinEquipada or "Padrao"
    CardSettings.AplicarSkinCarta(btnImg, valor, naipe, false, minhaSkin)
    btnImg.Parent = conteinerCarta
    
    local curva = Instance.new("UICorner")
    curva.CornerRadius = UDim.new(0, 8) -- Arredonda 8px
    curva.Parent = btnImg

    -- Animação de passar o mouse por cima
    btnImg.MouseEnter:Connect(function()
        conteinerCarta.ZIndex = 10 
        btnImg:TweenPosition(UDim2.new(0, 0, -0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)

    btnImg.MouseLeave:Connect(function()
        conteinerCarta.ZIndex = 1 
        btnImg:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)

    btnImg.Activated:Connect(function()
        if not eMinhaVez then return end

        if trucoPendente then 
            GerenciadorUI.AtualizarStatus("Resolva o Truco primeiro!", 0)
            return 
        end
        
        -- Da rodada 2 em diante, abre menu pra cobrir a carta
        if numeroQuedaAtual >= 2 then 
            conteinerCarta.ZIndex = 20 
            GerenciadorUI.MostrarOpcoesJogada(btnImg, valor, naipe, conteinerCarta)
        else
            eMinhaVez = false 
            Eventos.PlayCardEvent:FireServer(valor, naipe, false)
            conteinerCarta:Destroy()
            GerenciadorUI.OcultarOpcoesJogada()
        end
    end)
end

-- [MÉTODO] Menu de jogar Aberta/Coberta flutuante
function GerenciadorUI.MostrarOpcoesJogada(botaoCarta, valor, naipe, container)
    if painelOpcoesJogada then painelOpcoesJogada:Destroy() end
    
    local larguraMenu = 160
    local alturaMenu = 110

    painelOpcoesJogada = Instance.new("Frame")
    painelOpcoesJogada.Name = "OpcoesJogada" -- Nome
    painelOpcoesJogada.Size = UDim2.new(0, larguraMenu, 0, alturaMenu) -- Medida fixada
    painelOpcoesJogada.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  -- Cinza
    painelOpcoesJogada.BackgroundTransparency = 0.05 -- Quase solido
    painelOpcoesJogada.ZIndex = 100 -- Topo de tudo
    painelOpcoesJogada.AnchorPoint = Vector2.new(0.5, 1) -- Ancora embaixo no meio
    
    -- Calcula posição pra aparecer colado na carta que clicou
    local absPos = botaoCarta.AbsolutePosition
    local absSize = botaoCarta.AbsoluteSize
    painelOpcoesJogada.Position = UDim2.new(0, absPos.X + (absSize.X / 2), 0, absPos.Y + 50)
    painelOpcoesJogada.Parent = painelTela 
    
    Instance.new("UICorner", painelOpcoesJogada).CornerRadius = UDim.new(0, 12) -- Curva 12
    local borda = Instance.new("UIStroke", painelOpcoesJogada)
    borda.Color = Color3.fromRGB(255, 255, 255) -- Linha branca fina
    borda.Transparency = 0.8 -- Transparente
    borda.Thickness = 1 -- Espessura 1
    
    local margem = Instance.new("UIPadding", painelOpcoesJogada)
    margem.PaddingTop = UDim.new(0, 8)
    margem.PaddingBottom = UDim.new(0, 8)
    margem.PaddingLeft = UDim.new(0, 8)
    margem.PaddingRight = UDim.new(0, 8)
    
    local layoutOpcoes = Instance.new("UIListLayout", painelOpcoesJogada)
    layoutOpcoes.Padding = UDim.new(0, 8) -- Separa os botões
    layoutOpcoes.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function criarBotaoOpcao(texto, cor, escondida)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0.5, -4) -- Pega metade da caixa
        btn.BackgroundColor3 = cor -- Cor
        btn.Text = texto -- "Aberto" ou "Coberto"
        btn.TextColor3 = Color3.new(1,1,1) -- Branco
        btn.Font = Enum.Font.GothamBold -- Negrito
        btn.TextSize = 14 -- Tamanho texto
        btn.ZIndex = 101 -- Topo
        btn.AutoButtonColor = false -- Bloqueia efeito feio do roblox
        btn.Parent = painelOpcoesJogada
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8) -- Cantos 8px
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        end)
        
        btn.Activated:Connect(function()
            eMinhaVez = false
            Eventos.PlayCardEvent:FireServer(valor, naipe, escondida)
            container:Destroy()
            painelOpcoesJogada:Destroy()
        end)
    end
    
    criarBotaoOpcao("JOGAR ABERTA", Color3.fromRGB(39, 174, 96), false)
    criarBotaoOpcao("JOGAR COBERTA", Color3.fromRGB(90, 90, 90), true)
end

function GerenciadorUI.OcultarOpcoesJogada()
    if painelOpcoesJogada then painelOpcoesJogada:Destroy() end
end

-- [MÉTODO] Adiciona a carta na mesa visual (centro da tela do cliente)
-- [MÉTODO] Adiciona a carta na mesa visual (centro da tela do cliente)
function GerenciadorUI.AdicionarCartaJogadaUI(nomeJogador, valor, naipe, escondida, nomeSkin)
    local cartaImg = Instance.new("ImageLabel")
    cartaImg.Size = UDim2.new(0, 110, 0, 160) -- Tamanho fixo da imagem
    cartaImg.BackgroundTransparency = 1 -- Invisível
    
    CardSettings.AplicarSkinCarta(cartaImg, valor, naipe, escondida, nomeSkin)
    
    -- ======== MUDANÇA AQUI: Adiciona cantos arredondados ========
    -- Criamos o elemento UICorner para cortar os cantos
    local curva = Instance.new("UICorner")
    curva.CornerRadius = UDim.new(0, 8) -- Arredonda 8px, exatamente como na mão para consistência
    curva.Parent = cartaImg -- Anexa à imagem da carta
    -- ============================================================
    
    local etiquetaNome = Instance.new("TextLabel")
    etiquetaNome.Text = nomeJogador -- De quem é a carta
    etiquetaNome.Size = UDim2.new(1.2, 0, 0.2, 0) -- Tamanho base do texto
    etiquetaNome.Position = UDim2.new(0.5, 0, 0, -5) -- Acima da carta
    etiquetaNome.AnchorPoint = Vector2.new(0.5, 1) -- Ancora bottom center
    etiquetaNome.BackgroundTransparency = 1 -- Transparente
    etiquetaNome.TextColor3 = Color3.new(1, 1, 1) -- Branco
    etiquetaNome.Font = Enum.Font.GothamBlack -- Negrito pesado
    etiquetaNome.TextScaled = true -- Texto ajusta
    etiquetaNome.Parent = cartaImg
    
    local limiteTexto = Instance.new("UITextSizeConstraint", etiquetaNome)
    limiteTexto.MaxTextSize = 18 -- Não deixa o texto esticar bizarramente
    local contorno = Instance.new("UIStroke", etiquetaNome)
    contorno.Thickness = 2 -- Borda preta pra leitura no fundo branco
    
    cartaImg.Parent = centroMesa
end

function GerenciadorUI.AtualizarEstatisticasRodada(nomeParceiro, ptsEquipe, ptsInimigo)
    if not painelEstatisticas then return end
    painelEstatisticas.Visible = estaSentado
    local pNome = nomeParceiro or "Ninguém"
    textoEstatisticas.Text = string.format("Sua Dupla: %s\nNós: %d Quedas\nEles: %d Quedas", pNome, ptsEquipe or 0, ptsInimigo or 0)
end

function GerenciadorUI.LimparMesa()
    for _, filho in ipairs(centroMesa:GetChildren()) do
        if filho:IsA("GuiObject") then filho:Destroy() end
    end
end

function GerenciadorUI.LimparMao()
    if painelMao then
        painelMao:ClearAllChildren()
        local layoutMao = Instance.new("UIListLayout", painelMao)
        layoutMao.FillDirection = Enum.FillDirection.Horizontal
        layoutMao.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layoutMao.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layoutMao.Padding = UDim.new(0, 15)
    end
    GerenciadorUI.OcultarMenuCorte()
    GerenciadorUI.PermitirTruco(true)
end

function GerenciadorUI.AtualizarStatus(msg, val)
    if not textoCronometro then return end
    
    local mensagemFormatada = GameConfig.StateDisplayNames[msg] or msg
    local numeroVal = tonumber(val)
    
    if numeroVal and numeroVal > 0 then
        textoCronometro.Text = mensagemFormatada .. " " .. numeroVal
    else
        textoCronometro.Text = mensagemFormatada
    end
    
    textoCronometro.Visible = true
    textoCronometro.ZIndex = 100 
end

function GerenciadorUI.AtualizarTurno(nomeJogador, numeroQueda) 
    eMinhaVez = (nomeJogador == jogadorLocal.Name)
    numeroQuedaAtual = numeroQueda or 1 
    
    btnTruco.Visible = eMinhaVez and possoPedirTruco
    
    local valorAtual = 1
    if textoValorRodada and textoValorRodada.Text then
        valorAtual = tonumber(textoValorRodada.Text:match("%d+")) or 1
    end

    if valorAtual == 1 then btnTruco.Text = "TRUCO!"
    elseif valorAtual == 3 then btnTruco.Text = "SEIS!"
    elseif valorAtual == 6 then btnTruco.Text = "NOVE!"
    elseif valorAtual == 9 then btnTruco.Text = "DOZE!"
    else btnTruco.Visible = false end

    if eMinhaVez then
        GerenciadorUI.AtualizarStatus("SUA VEZ!", 0)
        textoCronometro.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        GerenciadorUI.AtualizarStatus("Vez de: " .. nomeJogador, 0)
        textoCronometro.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

function GerenciadorUI.DefinirSentado(s)
    estaSentado = s
    
    -- O painel de emotes só aparece se estiver sentado
    if painelEmotes then
        painelEmotes.Visible = s
    end
    
    if btnLoja then
        btnLoja.Visible = not s -- Esconde o botão se sentar (s = true)
    end
    if s and menuLoja then
        menuLoja.Visible = false -- Fecha o painel da loja à força se a partida começar
    end
    
    if not s then 
        GerenciadorUI.ResetTotal() 
    end
end

function GerenciadorUI.DefinirVisibilidadeUIJogo(visivel)
    if painelEstatisticas then painelEstatisticas.Visible = visivel end
    if textoPlacarJogo then textoPlacarJogo.Visible = visivel end
    if painelVira then painelVira.Visible = visivel end
    if textoValorRodada then textoValorRodada.Visible = visivel end
    if btnTruco then btnTruco.Visible = false end
    if painelCorte then painelCorte.Visible = false end
end

function GerenciadorUI.DefinirMeuAssento(n) end

function GerenciadorUI.PermitirTruco(permitido)
    possoPedirTruco = permitido
    if btnTruco then btnTruco.Visible = eMinhaVez and possoPedirTruco end
end

function GerenciadorUI.DefinirVira(val, naipe)
    for _, filho in ipairs(painelVira:GetChildren()) do
        if not filho:IsA("UICorner") then filho:Destroy() end
    end
    
    painelVira.Visible = estaSentado
    local tituloLbl = Instance.new("TextLabel")
    tituloLbl.Text = "VIRA" -- Cabeçalho
    tituloLbl.Size = UDim2.new(1, 0, 0.2, 0) -- 20% do topo
    tituloLbl.Position = UDim2.new(0, 0, 0, 0) -- Topo
    tituloLbl.BackgroundTransparency = 1 -- Invisível
    tituloLbl.TextColor3 = Color3.fromRGB(255, 215, 0)  -- Dourado
    tituloLbl.Font = Enum.Font.GothamBlack -- Fonte negra
    tituloLbl.TextScaled = true -- Cresce a gosto
    tituloLbl.Parent = painelVira

    local imgVira = Instance.new("ImageLabel")
    imgVira.Size = UDim2.new(0, 80, 0, 115)  -- Tamanho da cartinha na caixa
    imgVira.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centro
    imgVira.AnchorPoint = Vector2.new(0.5, 0.5) -- Ancora baseada no centro
    imgVira.BackgroundTransparency = 1 -- Sem fundo
    imgVira.Parent = painelVira
    
    CardSettings.AplicarSkinCarta(imgVira, val, naipe, false, "Padrao")

    local textoCarta = Instance.new("TextLabel")
    textoCarta.Text = val .. " " .. naipe -- Texto em baixo da imagem
    textoCarta.Size = UDim2.new(1, 0, 0.2, 0) -- Espaço pequeno
    textoCarta.Position = UDim2.new(0, 0, 0.8, 0)  -- La embaixo
    textoCarta.BackgroundTransparency = 1 -- Transparente
    textoCarta.TextColor3 = Color3.new(1, 1, 1) -- Branco
    textoCarta.Font = Enum.Font.GothamBold -- Forte
    textoCarta.TextSize = 18 -- Fixa
    textoCarta.Parent = painelVira
end

function GerenciadorUI.AtualizarPlacar(meu, inimigo)
    textoPlacarJogo.Text = "JOGO: "..meu.." x "..inimigo
end

function GerenciadorUI.AtualizarValorRodada(val)
    if textoValorRodada then
        textoValorRodada.Text = "VALE: " .. tostring(val)
        textoValorRodada.Visible = estaSentado
    end
end

-- Mostra quem ganhou a rodada e desaparece
function GerenciadorUI.MostrarVencedorRodada(nomeEquipe)
    local lblVencedor = Instance.new("TextLabel")
    lblVencedor.Size = UDim2.new(0.8, 0, 0.2, 0) -- Enorme no meio da tela
    lblVencedor.Position = UDim2.new(0.5, 0, 0.4, 0) -- Um pouco pro meio topo
    lblVencedor.AnchorPoint = Vector2.new(0.5, 0.5) -- Centro absoluto
    lblVencedor.BackgroundTransparency = 1 -- Sem caixa de fundo
    lblVencedor.TextColor3 = Color3.fromRGB(255, 215, 0) -- Ouro
    lblVencedor.TextStrokeTransparency = 0 -- Borda preta ativa
    lblVencedor.Font = Enum.Font.GothamBlack -- Fonte negra e grossa
    lblVencedor.TextScaled = true -- Letra enorme
    lblVencedor.Text = nomeEquipe -- Texto que mandou
    lblVencedor.Parent = painelTela

    task.delay(3, function()
        if lblVencedor then
            local tween = TweenService:Create(lblVencedor, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() lblVencedor:Destroy() end)
        end
    end)
end

function GerenciadorUI.MostrarPlacar()
    if estaSentado and textoPlacarJogo then textoPlacarJogo.Visible = true end
end

function GerenciadorUI.OcultarPlacar()
    if textoPlacarJogo then textoPlacarJogo.Visible = false end
end

-- ==========================================
-- EFEITOS ESPECIAIS (Câmera, Sinal, Vitória)
-- ==========================================

function GerenciadorUI.MostrarSinal(remetente, tipoSinal)
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

function GerenciadorUI.AplicarCameraTensao(nomeAlvo)
    local alvo = Players:FindFirstChild(nomeAlvo)
    if not alvo or not alvo.Character or not alvo.Character:FindFirstChild("Head") then return end

    Camera.CameraType = Enum.CameraType.Scriptable
    local posicaoAlvo = alvo.Character.Head.Position + (alvo.Character.Head.CFrame.LookVector * 5) + Vector3.new(0, 1, 0)
    local olharPara = alvo.Character.Head.Position

    local tween = TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(posicaoAlvo, olharPara)
    })
    tween:Play()
end

function GerenciadorUI.ResetarCamera()
    Camera.CameraType = Enum.CameraType.Custom
end

function GerenciadorUI.TocarSom(nomeSom)
    local idSom = SonsJogo[nomeSom]
    if not idSom then return end

    local som = Instance.new("Sound")
    som.SoundId = idSom
    som.Volume = 1
    som.Parent = SoundService
    
    som.Ended:Connect(function()
        som:Destroy()
    end)
    
    som:Play()
end

-- Animação de vitória complexa da partida toda
function GerenciadorUI.MostrarVencedorPartida(texto)
    local fundoEscuro = Instance.new("Frame")
    fundoEscuro.Name = "VictoryDarkenBG" -- Escurecimento de fundo
    fundoEscuro.Size = UDim2.new(1, 0, 1, 0) -- Cobre tela
    fundoEscuro.BackgroundColor3 = Color3.new(0, 0, 0) -- Fundo Preto
    fundoEscuro.BackgroundTransparency = 1 -- Começa escondido 
    fundoEscuro.ZIndex = 200 -- Bem no topo
    fundoEscuro.Parent = painelTela
    
    local lbl = Instance.new("TextLabel")
    lbl.Name = "VictoryLabel" -- Letras
    lbl.Text = texto -- Texto Vencedores
    lbl.Size = UDim2.new(0.9, 0, 0.2, 0) -- 90% da largura
    lbl.Position = UDim2.new(0.5, 0, 0.5, 0) -- Meio tela
    lbl.AnchorPoint = Vector2.new(0.5, 0.5) -- Âncora centro
    lbl.BackgroundTransparency = 1 -- Sem fundo de caixa
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)  -- Dourado
    lbl.Font = Enum.Font.GothamBlack -- Negrito pesado
    lbl.TextScaled = true -- Texto dinâmico
    lbl.TextTransparency = 1  -- Letras começam invisiveis
    lbl.ZIndex = 201 -- Acima do fundo preto
    lbl.Parent = painelTela 
    
    local bordaLetra = Instance.new("UIStroke", lbl)
    bordaLetra.Thickness = 3 -- Borda de letra generosa (3)
    bordaLetra.Color = Color3.new(1, 1, 1)  -- Contorno branco
    bordaLetra.Transparency = 1 -- Invisivel também
    
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

-- [MÉTODO] Mostra uma mensagem vermelha no centro da tela para fugas
function GerenciadorUI.MostrarAvisoFuga(texto)
    local lblFuga = Instance.new("TextLabel")
    lblFuga.Size = UDim2.new(0.8, 0, 0.2, 0)
    lblFuga.Position = UDim2.new(0.5, 0, 0.35, 0) -- Fica um pouquinho mais alto que o aviso de vitória
    lblFuga.AnchorPoint = Vector2.new(0.5, 0.5)
    lblFuga.BackgroundTransparency = 1
    lblFuga.TextColor3 = Color3.fromRGB(255, 60, 60) -- Vermelho vivo
    lblFuga.TextStrokeTransparency = 0 -- Contorno preto
    lblFuga.Font = Enum.Font.GothamBlack
    lblFuga.TextScaled = true
    lblFuga.Text = texto
    lblFuga.Parent = painelTela

    -- Some depois de 2.5 segundos
    task.delay(2.5, function()
        if lblFuga then
            local tween = TweenService:Create(lblFuga, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() lblFuga:Destroy() end)
        end
    end)
end

-- [MÉTODO] Painel Secreto do Desenvolvedor
function GerenciadorUI.CriarMenuAdmin()
    if jogadorLocal.Name ~= "Nick0369me" then return end -- Se não for você, nem cria a interface!

    local painelAdmin = Instance.new("Frame")
    painelAdmin.Size = UDim2.new(0, 260, 0, 170)
    painelAdmin.Position = UDim2.new(0.5, 0, 0, 10)
    painelAdmin.AnchorPoint = Vector2.new(0.5, 0)
    painelAdmin.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    painelAdmin.Visible = false
    painelAdmin.ZIndex = 200
    painelAdmin.Parent = painelTela
    Instance.new("UICorner", painelAdmin).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", painelAdmin).Color = Color3.new(1, 0.8, 0) -- Borda dourada

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
    inputNome.Text = jogadorLocal.Name -- Já vem preenchido com seu nome por praticidade
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

    -- Ações dos Botões
    btnAdd.Activated:Connect(function()
        Eventos.AdminActionEvent:FireServer("Adicionar", inputNome.Text, inputValor.Text)
    end)
    btnRem.Activated:Connect(function()
        Eventos.AdminActionEvent:FireServer("Remover", inputNome.Text, inputValor.Text)
    end)

    -- Abrir e fechar com F4
    game:GetService("UserInputService").InputBegan:Connect(function(input, emChat)
        if not emChat and input.KeyCode == Enum.KeyCode.F4 then
            painelAdmin.Visible = not painelAdmin.Visible
        end
    end)
end

return GerenciadorUI
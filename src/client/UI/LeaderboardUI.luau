local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local jogadorLocal = Players.LocalPlayer
local Eventos = ReplicatedStorage:WaitForChild("Events")
local rfGetLeaderboard = Eventos:WaitForChild("GetLeaderboardData")

local LeaderboardUI = {}

local btnLeaderboard = nil
local modalLeaderboard = nil
local containerLista = nil
local containerMeuPerfil = nil
local textoStatusCarregando = nil

local btnAbaVitorias = nil
local btnAbaPontos = nil
local btnAbaRobux = nil

local abaAtual = "Vitorias"
local cacheLocalDados = {}

local COR_ABA_ATIVA = Color3.fromRGB(240, 160, 40)
local COR_ABA_INATIVA = Color3.fromRGB(45, 45, 55)

-- Helper para obter thumbnail do avatar com fallback
local function getAvatarThumbnail(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(userId) .. "&width=48&height=48&format=png"
end

local versaoRequisicao = 0

local function limparLista()
    if not containerLista then return end
    for _, filho in ipairs(containerLista:GetChildren()) do
        if not filho:IsA("UIListLayout") then
            filho:Destroy()
        end
    end
end

-- Renderiza a lista de classificação
local function renderizarLista(topList, categoria)
    if not containerLista then return end
    limparLista()

    if #topList == 0 then
        local lblVazio = Instance.new("TextLabel", containerLista)
        lblVazio.Name = "LblVazio"
        lblVazio.Size = UDim2.new(1, 0, 0, 80)
        lblVazio.BackgroundTransparency = 1
        lblVazio.Text = "Nenhum registro encontrado nesta categoria ainda.\nSeja o primeiro a pontuar!"
        lblVazio.TextColor3 = Color3.fromRGB(160, 160, 170)
        lblVazio.Font = Enum.Font.GothamMedium
        lblVazio.TextSize = 16
        lblVazio.TextWrapped = true
        return
    end

    for rank, entry in ipairs(topList) do
        local row = Instance.new("Frame", containerLista)
        row.Size = UDim2.new(1, 0, 0, 48)
        row.LayoutOrder = rank
        row.BorderSizePixel = 0

        -- Cores e destaques para o Top 3
        if rank == 1 then
            row.BackgroundColor3 = Color3.fromRGB(60, 48, 16)
        elseif rank == 2 then
            row.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
        elseif rank == 3 then
            row.BackgroundColor3 = Color3.fromRGB(50, 36, 24)
        else
            row.BackgroundColor3 = (rank % 2 == 0) and Color3.fromRGB(28, 28, 35) or Color3.fromRGB(24, 24, 30)
        end
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local borda = Instance.new("UIStroke", row)
        borda.Thickness = 1
        if rank == 1 then
            borda.Color = Color3.fromRGB(255, 215, 0)
            borda.Transparency = 0.2
        elseif rank == 2 then
            borda.Color = Color3.fromRGB(200, 200, 210)
            borda.Transparency = 0.4
        elseif rank == 3 then
            borda.Color = Color3.fromRGB(205, 127, 50)
            borda.Transparency = 0.4
        else
            borda.Color = Color3.fromRGB(255, 255, 255)
            borda.Transparency = 0.92
        end

        -- Medalha / Posição
        local posText = (rank == 1 and "🥇 1º") or (rank == 2 and "🥈 2º") or (rank == 3 and "🥉 3º") or ("#" .. tostring(rank))
        local lblRank = Instance.new("TextLabel", row)
        lblRank.Size = UDim2.new(0, 65, 1, 0)
        lblRank.Position = UDim2.new(0, 10, 0, 0)
        lblRank.BackgroundTransparency = 1
        lblRank.Text = posText
        lblRank.TextColor3 = (rank <= 3) and Color3.fromRGB(255, 230, 110) or Color3.fromRGB(200, 200, 210)
        lblRank.Font = Enum.Font.GothamBold
        lblRank.TextSize = 18
        lblRank.TextXAlignment = Enum.TextXAlignment.Left

        -- Foto do Avatar
        local imgAvatar = Instance.new("ImageLabel", row)
        imgAvatar.Size = UDim2.new(0, 34, 0, 34)
        imgAvatar.Position = UDim2.new(0, 75, 0.5, 0)
        imgAvatar.AnchorPoint = Vector2.new(0, 0.5)
        imgAvatar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        imgAvatar.Image = getAvatarThumbnail(entry.UserId)
        Instance.new("UICorner", imgAvatar).CornerRadius = UDim.new(1, 0)

        -- Nome do Jogador
        local lblNome = Instance.new("TextLabel", row)
        lblNome.Size = UDim2.new(0.5, -30, 1, 0)
        lblNome.Position = UDim2.new(0, 120, 0, 0)
        lblNome.BackgroundTransparency = 1
        lblNome.Text = entry.Nome or ("Jogador_" .. tostring(entry.UserId))
        lblNome.TextColor3 = (entry.UserId == jogadorLocal.UserId) and Color3.fromRGB(100, 220, 255) or Color3.new(1, 1, 1)
        lblNome.Font = (entry.UserId == jogadorLocal.UserId) and Enum.Font.GothamBlack or Enum.Font.GothamMedium
        lblNome.TextSize = 16
        lblNome.TextXAlignment = Enum.TextXAlignment.Left
        lblNome.TextTruncate = Enum.TextTruncate.AtEnd

        -- Sufixo da métrica
        local sufixo = "vitórias"
        if categoria == "Pontos" then
            sufixo = "pts"
        elseif categoria == "Robux" then
            sufixo = "R$"
        end

        local lblValor = Instance.new("TextLabel", row)
        lblValor.Size = UDim2.new(0.35, -20, 1, 0)
        lblValor.Position = UDim2.new(0.65, 0, 0, 0)
        lblValor.BackgroundTransparency = 1
        lblValor.Text = tostring(entry.Valor) .. " " .. sufixo
        lblValor.TextColor3 = (categoria == "Robux") and Color3.fromRGB(0, 230, 120) or Color3.fromRGB(255, 215, 0)
        lblValor.Font = Enum.Font.GothamBold
        lblValor.TextSize = 17
        lblValor.TextXAlignment = Enum.TextXAlignment.Right
    end
end

-- Renderiza o card do próprio jogador no rodapé
local function renderizarMeuPerfil(meuDado)
    if not containerMeuPerfil then return end
    
    for _, filho in ipairs(containerMeuPerfil:GetChildren()) do
        if filho:IsA("Frame") or filho:IsA("TextLabel") or filho:IsA("ImageLabel") then
            filho:Destroy()
        end
    end

    local d = meuDado or {}
    local vitorias = d.Vitorias or 0
    local derrotas = d.Derrotas or 0
    local partidas = d.PartidasJogadas or (vitorias + derrotas)
    local pontos   = d.Pontos or 0
    local robux    = d.RobuxGasto or 0

    local taxa = 0
    if partidas > 0 then
        taxa = math.floor((vitorias / partidas) * 100)
    end

    -- Foto do Jogador Local
    local imgAvatar = Instance.new("ImageLabel", containerMeuPerfil)
    imgAvatar.Size = UDim2.new(0, 42, 0, 42)
    imgAvatar.Position = UDim2.new(0, 12, 0.5, 0)
    imgAvatar.AnchorPoint = Vector2.new(0, 0.5)
    imgAvatar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    imgAvatar.Image = getAvatarThumbnail(jogadorLocal.UserId)
    Instance.new("UICorner", imgAvatar).CornerRadius = UDim.new(1, 0)
    local strokeAvatar = Instance.new("UIStroke", imgAvatar)
    strokeAvatar.Color = Color3.fromRGB(240, 160, 40)
    strokeAvatar.Thickness = 1.5

    -- Identificação
    local lblNick = Instance.new("TextLabel", containerMeuPerfil)
    lblNick.Size = UDim2.new(0.25, 0, 0, 20)
    lblNick.Position = UDim2.new(0, 62, 0, 10)
    lblNick.BackgroundTransparency = 1
    lblNick.Text = jogadorLocal.DisplayName
    lblNick.TextColor3 = Color3.fromRGB(100, 220, 255)
    lblNick.Font = Enum.Font.GothamBlack
    lblNick.TextSize = 15
    lblNick.TextXAlignment = Enum.TextXAlignment.Left

    local lblSub = Instance.new("TextLabel", containerMeuPerfil)
    lblSub.Size = UDim2.new(0.25, 0, 0, 18)
    lblSub.Position = UDim2.new(0, 62, 0, 30)
    lblSub.BackgroundTransparency = 1
    lblSub.Text = "Seu Desempenho"
    lblSub.TextColor3 = Color3.fromRGB(160, 160, 170)
    lblSub.Font = Enum.Font.GothamMedium
    lblSub.TextSize = 12
    lblSub.TextXAlignment = Enum.TextXAlignment.Left

    -- Cards de Estatísticas no Rodapé
    local colunas = {
        { Titulo = "VITÓRIAS", Valor = tostring(vitorias) .. " (" .. taxa .. "%)", Cor = Color3.fromRGB(255, 215, 0) },
        { Titulo = "PONTOS", Valor = tostring(pontos), Cor = Color3.fromRGB(255, 180, 50) },
        { Titulo = "APOIADO", Valor = tostring(robux) .. " R$", Cor = Color3.fromRGB(0, 230, 120) }
    }

    local larguraCard = 0.22
    for i, col in ipairs(colunas) do
        local xPos = 0.32 + (i - 1) * larguraCard
        local frameStat = Instance.new("Frame", containerMeuPerfil)
        frameStat.Size = UDim2.new(larguraCard - 0.02, 0, 0.75, 0)
        frameStat.Position = UDim2.new(xPos, 0, 0.5, 0)
        frameStat.AnchorPoint = Vector2.new(0, 0.5)
        frameStat.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        Instance.new("UICorner", frameStat).CornerRadius = UDim.new(0, 6)

        local tLabel = Instance.new("TextLabel", frameStat)
        tLabel.Size = UDim2.new(1, 0, 0, 14)
        tLabel.Position = UDim2.new(0, 0, 0, 4)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = col.Titulo
        tLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextSize = 10

        local vLabel = Instance.new("TextLabel", frameStat)
        vLabel.Size = UDim2.new(1, 0, 0, 20)
        vLabel.Position = UDim2.new(0, 0, 0, 18)
        vLabel.BackgroundTransparency = 1
        vLabel.Text = col.Valor
        vLabel.TextColor3 = col.Cor
        vLabel.Font = Enum.Font.GothamBlack
        vLabel.TextSize = 14
    end
end

-- Atualiza visual das abas
local function atualizarBotoesAbas()
    if not btnAbaVitorias or not btnAbaPontos or not btnAbaRobux then return end
    
    btnAbaVitorias.BackgroundColor3 = (abaAtual == "Vitorias") and COR_ABA_ATIVA or COR_ABA_INATIVA
    btnAbaPontos.BackgroundColor3   = (abaAtual == "Pontos") and COR_ABA_ATIVA or COR_ABA_INATIVA
    btnAbaRobux.BackgroundColor3    = (abaAtual == "Robux") and COR_ABA_ATIVA or COR_ABA_INATIVA
end

-- Carrega dados do servidor
function LeaderboardUI.CarregarDados(categoria)
    abaAtual = categoria or abaAtual
    atualizarBotoesAbas()

    versaoRequisicao += 1
    local meuIdRequisicao = versaoRequisicao

    limparLista()
    if containerLista then
        containerLista.CanvasPosition = Vector2.new(0, 0)
    end

    if textoStatusCarregando then
        textoStatusCarregando.Visible = true
        textoStatusCarregando.Text = "Carregando ranking global..."
    end

    task.spawn(function()
        local ok, resultado = pcall(function()
            return rfGetLeaderboard:InvokeServer(abaAtual)
        end)

        -- Se o usuário mudou de aba antes da resposta chegar, descarta
        if meuIdRequisicao ~= versaoRequisicao then
            return
        end

        if textoStatusCarregando then
            textoStatusCarregando.Visible = false
        end

        if ok and resultado then
            cacheLocalDados[abaAtual] = resultado.TopList or {}
            renderizarLista(resultado.TopList or {}, abaAtual)
            renderizarMeuPerfil(resultado.MeuDado or {})
        else
            warn("Falha ao buscar dados de Leaderboard:", resultado)
            if textoStatusCarregando then
                textoStatusCarregando.Visible = true
                textoStatusCarregando.Text = "Não foi possível carregar os dados. Tente novamente."
            end
        end
    end)
end

function LeaderboardUI.Abrir(categoria)
    if modalLeaderboard then
        modalLeaderboard.Visible = true
        LeaderboardUI.CarregarDados(categoria or abaAtual)
    end
end

function LeaderboardUI.Fechar()
    if modalLeaderboard then
        modalLeaderboard.Visible = false
    end
end

function LeaderboardUI.Alternar()
    if modalLeaderboard then
        if modalLeaderboard.Visible then
            LeaderboardUI.Fechar()
        else
            LeaderboardUI.Abrir()
        end
    end
end

function LeaderboardUI.DefinirVisibilidade(visivel)
    if btnLeaderboard then
        btnLeaderboard.Visible = visivel
    end
    if not visivel and modalLeaderboard then
        modalLeaderboard.Visible = false
    end
end

-- ====================================================================
-- MONTAGEM DA INTERFACE
-- ====================================================================

function LeaderboardUI.Inicializar(parentGui)
    -- 1. BOTÃO REDONDO PRETO PADRÃO NO TOPO DA UI
    btnLeaderboard = Instance.new("TextButton", parentGui)
    btnLeaderboard.Name = "BtnLeaderboard"
    btnLeaderboard.Size = UDim2.new(0, 46, 0, 46)
    btnLeaderboard.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    btnLeaderboard.BackgroundTransparency = 0.25
    btnLeaderboard.Text = "🏆"
    btnLeaderboard.TextColor3 = Color3.new(1, 1, 1)
    btnLeaderboard.Font = Enum.Font.GothamBlack
    btnLeaderboard.TextSize = 22
    btnLeaderboard.ZIndex = 40

    local function recalcularPosicaoBotao()
        if not btnLeaderboard then return end
        local inset = GuiService:GetGuiInset()
        local alturaTopbar = math.max(inset.Y, 54)
        btnLeaderboard.Position = UDim2.new(0, 16, 0, alturaTopbar + 12)
    end

    recalcularPosicaoBotao()
    GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(recalcularPosicaoBotao)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recalcularPosicaoBotao)
    end
    
    Instance.new("UICorner", btnLeaderboard).CornerRadius = UDim.new(1, 0) -- Perfeitamente redondo
    
    local strokeBtn = Instance.new("UIStroke", btnLeaderboard)
    strokeBtn.Color = Color3.fromRGB(255, 255, 255)
    strokeBtn.Transparency = 0.8
    strokeBtn.Thickness = 1.5

    -- Animação de hover
    btnLeaderboard.MouseEnter:Connect(function()
        TweenService:Create(btnLeaderboard, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.05,
            BackgroundColor3 = Color3.fromRGB(38, 38, 46)
        }):Play()
    end)
    btnLeaderboard.MouseLeave:Connect(function()
        TweenService:Create(btnLeaderboard, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.25,
            BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        }):Play()
    end)

    btnLeaderboard.Activated:Connect(function()
        LeaderboardUI.Alternar()
    end)

    -- 2. PAINEL MODAL DO LEADERBOARD
    modalLeaderboard = Instance.new("Frame", parentGui)
    modalLeaderboard.Name = "ModalLeaderboard"
    modalLeaderboard.Size = UDim2.new(0, 560, 0, 480)
    modalLeaderboard.Position = UDim2.new(0.5, 0, 0.5, 0)
    modalLeaderboard.AnchorPoint = Vector2.new(0.5, 0.5)
    modalLeaderboard.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    modalLeaderboard.BorderSizePixel = 0
    modalLeaderboard.Visible = false
    modalLeaderboard.ZIndex = 80

    Instance.new("UICorner", modalLeaderboard).CornerRadius = UDim.new(0, 16)
    local strokeModal = Instance.new("UIStroke", modalLeaderboard)
    strokeModal.Color = Color3.fromRGB(55, 55, 70)
    strokeModal.Thickness = 1.5

    -- Header do Modal
    local header = Instance.new("Frame", modalLeaderboard)
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.ZIndex = 81

    local titulo = Instance.new("TextLabel", header)
    titulo.Size = UDim2.new(0.7, 0, 1, 0)
    titulo.Position = UDim2.new(0, 24, 0, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "🏆 RANKING GLOBAL"
    titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
    titulo.Font = Enum.Font.GothamBlack
    titulo.TextSize = 22
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.ZIndex = 82

    -- Botão Fechar (X)
    local btnFechar = Instance.new("TextButton", header)
    btnFechar.Size = UDim2.new(0, 36, 0, 36)
    btnFechar.Position = UDim2.new(1, -16, 0.5, 0)
    btnFechar.AnchorPoint = Vector2.new(1, 0.5)
    btnFechar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btnFechar.Text = "✕"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.TextSize = 18
    btnFechar.ZIndex = 82
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    btnFechar.Activated:Connect(function() LeaderboardUI.Fechar() end)

    -- Container de Abas
    local containerAbas = Instance.new("Frame", modalLeaderboard)
    containerAbas.Size = UDim2.new(1, -40, 0, 40)
    containerAbas.Position = UDim2.new(0, 20, 0, 65)
    containerAbas.BackgroundTransparency = 1
    containerAbas.ZIndex = 81

    local function criarBotaoAba(texto, xPos, cat)
        local btn = Instance.new("TextButton", containerAbas)
        btn.Size = UDim2.new(0.31, 0, 1, 0)
        btn.Position = UDim2.new(xPos, 0, 0, 0)
        btn.BackgroundColor3 = COR_ABA_INATIVA
        btn.Text = texto
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.ZIndex = 82
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.Activated:Connect(function()
            LeaderboardUI.CarregarDados(cat)
        end)
        return btn
    end

    btnAbaVitorias = criarBotaoAba("🏆 Vitórias", 0.00, "Vitorias")
    btnAbaPontos   = criarBotaoAba("⭐ Pontos", 0.345, "Pontos")
    btnAbaRobux    = criarBotaoAba("💎 Apoiadores", 0.69, "Robux")

    -- Texto Status / Loading
    textoStatusCarregando = Instance.new("TextLabel", modalLeaderboard)
    textoStatusCarregando.Size = UDim2.new(1, 0, 0, 30)
    textoStatusCarregando.Position = UDim2.new(0, 0, 0, 115)
    textoStatusCarregando.BackgroundTransparency = 1
    textoStatusCarregando.Text = "Carregando ranking global..."
    textoStatusCarregando.TextColor3 = Color3.fromRGB(180, 180, 190)
    textoStatusCarregando.Font = Enum.Font.GothamMedium
    textoStatusCarregando.TextSize = 14
    textoStatusCarregando.Visible = false
    textoStatusCarregando.ZIndex = 83

    -- Lista Deslizante (ScrollingFrame)
    containerLista = Instance.new("ScrollingFrame", modalLeaderboard)
    containerLista.Size = UDim2.new(1, -40, 1, -200)
    containerLista.Position = UDim2.new(0, 20, 0, 115)
    containerLista.BackgroundTransparency = 1
    containerLista.ScrollBarThickness = 5
    containerLista.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    containerLista.AutomaticCanvasSize = Enum.AutomaticSize.Y
    containerLista.ZIndex = 81

    local layoutLista = Instance.new("UIListLayout", containerLista)
    layoutLista.Padding = UDim.new(0, 6)
    layoutLista.SortOrder = Enum.SortOrder.LayoutOrder

    -- Container do Rodapé: "Seu Desempenho"
    containerMeuPerfil = Instance.new("Frame", modalLeaderboard)
    containerMeuPerfil.Size = UDim2.new(1, -40, 0, 65)
    containerMeuPerfil.Position = UDim2.new(0, 20, 1, -75)
    containerMeuPerfil.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    containerMeuPerfil.BorderSizePixel = 0
    containerMeuPerfil.ZIndex = 82
    Instance.new("UICorner", containerMeuPerfil).CornerRadius = UDim.new(0, 10)

    local strokePerfil = Instance.new("UIStroke", containerMeuPerfil)
    strokePerfil.Color = Color3.fromRGB(70, 70, 85)
    strokePerfil.Thickness = 1
end

return LeaderboardUI

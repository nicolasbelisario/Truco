local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataManager = require(script.Parent.DataManager)

local LeaderboardManager = {}

-- OrderedDataStores para cada métrica competitiva
local ODS_Vitorias = DataStoreService:GetOrderedDataStore("Leaderboard_Vitorias_v1")
local ODS_Pontos   = DataStoreService:GetOrderedDataStore("Leaderboard_Pontos_v1")
local ODS_Robux    = DataStoreService:GetOrderedDataStore("Leaderboard_Robux_v1")

local cacheRanking = {
    Vitorias = {},
    Pontos = {},
    Robux = {}
}

local cacheNomes = {}
local pendentesSalvar = {}

local Eventos = ReplicatedStorage:WaitForChild("Events")
local rfGetLeaderboard = Eventos:WaitForChild("GetLeaderboardData")

-- Helper para buscar nome de usuário com cache
local function obterNomeJogador(userId)
    if cacheNomes[userId] then return cacheNomes[userId] end
    local jogadorOnline = Players:GetPlayerByUserId(userId)
    if jogadorOnline then
        cacheNomes[userId] = jogadorOnline.DisplayName or jogadorOnline.Name
        return cacheNomes[userId]
    end
    
    local ok, nome = pcall(function()
        return Players:GetNameFromUserIdAsync(userId)
    end)
    if ok and nome then
        cacheNomes[userId] = nome
        return nome
    end
    return "Jogador_" .. tostring(userId)
end

local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")

-- Atualiza o OrderedDataStore com os dados recentes do jogador
function LeaderboardManager.AtualizarODSJogador(jogador, dados)
    if not jogador or not dados then return end
    local userId = tostring(jogador.UserId)
    
    pendentesSalvar[userId] = {
        UserId = userId,
        Vitorias = dados.Vitorias or 0,
        Pontos = dados.Pontos or 0,
        RobuxGasto = dados.RobuxGasto or 0
    }

    -- Processa rapidamente para refletir na leaderboard sem demora
    task.spawn(function()
        task.wait(0.5)
        LeaderboardManager.SalvarEntradaODS(userId, pendentesSalvar[userId])
    end)
end

-- Salva uma entrada individual no OrderedDataStore
function LeaderboardManager.SalvarEntradaODS(chave, info)
    if not info then return end
    local alterou = false

    local okVit, errVit = pcall(function()
        if info.Vitorias and info.Vitorias > 0 then
            ODS_Vitorias:SetAsync(chave, math.floor(info.Vitorias))
            alterou = true
        end
    end)
    if not okVit then warn("[LeaderboardManager] Erro ODS Vitórias:", errVit) end

    local okPts, errPts = pcall(function()
        if info.Pontos and info.Pontos > 0 then
            ODS_Pontos:SetAsync(chave, math.floor(info.Pontos))
            alterou = true
        end
    end)
    if not okPts then warn("[LeaderboardManager] Erro ODS Pontos:", errPts) end

    local okRbx, errRbx = pcall(function()
        if info.RobuxGasto and info.RobuxGasto > 0 then
            ODS_Robux:SetAsync(chave, math.floor(info.RobuxGasto))
            alterou = true
        end
    end)
    if not okRbx then warn("[LeaderboardManager] Erro ODS Robux:", errRbx) end

    if alterou then
        task.delay(1, function()
            LeaderboardManager.AtualizarTodosRankings()
        end)
    end
end

-- Processa fila pendente de atualização no OrderedDataStore
local function processarFilaODS()
    for userIdStr, info in pairs(pendentesSalvar) do
        pendentesSalvar[userIdStr] = nil
        LeaderboardManager.SalvarEntradaODS(userIdStr, info)
        task.wait(0.2)
    end
end

-- Consulta os melhores do OrderedDataStore e atualiza o cache
local function carregarTopRanking(ods, categoria)
    local lista = {}
    local ok, pages = pcall(function()
        return ods:GetSortedAsync(false, 50, 1) -- Maiores primeiro, top 50, mínimo 1
    end)
    
    if ok and pages then
        local currentPage = pages:GetCurrentPage()
        for rank, entry in ipairs(currentPage) do
            local userId = tonumber(entry.key)
            if userId then
                local nome = obterNomeJogador(userId)
                table.insert(lista, {
                    Rank = rank,
                    UserId = userId,
                    Nome = nome,
                    Valor = entry.value
                })
            end
        end
    else
        warn("[LeaderboardManager] Falha ao consultar ranking " .. categoria .. ":", tostring(pages))
    end
    
    cacheRanking[categoria] = lista
end



function LeaderboardManager.AtualizarTodosRankings()
    carregarTopRanking(ODS_Vitorias, "Vitorias")
    task.wait(0.5)
    carregarTopRanking(ODS_Pontos, "Pontos")
    task.wait(0.5)
    carregarTopRanking(ODS_Robux, "Robux")
    
    LeaderboardManager.AtualizarQuadroFisico()
    task.spawn(function()
        LeaderboardManager.AtualizarPodio3D()
    end)
end

-- ====================================================================
-- QUADRO FÍSICO NO MAPA (LOBBY SURFACEGUI)
-- ====================================================================

local surfaceGuiQuadro = nil
local frameListaQuadro = nil
local textoTituloQuadro = nil

function LeaderboardManager._ConfigurarQuadroNoMapa()
    -- Procura no Workspace por uma Part ou Model chamada "LeaderboardBoard"
    local boardObj = workspace:FindFirstChild("LeaderboardBoard", true)
    local boardPart = nil
    
    if boardObj then
        if boardObj:IsA("BasePart") then
            boardPart = boardObj
        elseif boardObj:IsA("Model") then
            boardPart = boardObj:FindFirstChild("DisplayPart") or boardObj.PrimaryPart or boardObj:FindFirstChildWhichIsA("BasePart")
        end
    end

    if not boardPart then
        -- Cria uma estrutura física elegante caso ainda não tenha sido colocada no mapa pelo desenvolvedor no Studio
        local pastaMesas = workspace:FindFirstChild("MesasFolder")
        local basePos = Vector3.new(0, 10, 30)
        if pastaMesas and #pastaMesas:GetChildren() > 0 then
            local primeiraMesa = pastaMesas:GetChildren()[1]
            if primeiraMesa:IsA("Model") and primeiraMesa.PrimaryPart then
                basePos = primeiraMesa.PrimaryPart.Position + Vector3.new(0, 8, 35)
            end
        end
        
        local modelo = Instance.new("Model")
        modelo.Name = "LeaderboardBoard"
        modelo.Parent = workspace
        
        boardPart = Instance.new("Part")
        boardPart.Name = "DisplayPart"
        boardPart.Size = Vector3.new(16, 12, 1)
        boardPart.Position = basePos
        boardPart.Anchored = true
        boardPart.Color = Color3.fromRGB(245, 245, 248)
        boardPart.Material = Enum.Material.SmoothPlastic
        boardPart.Parent = modelo
        modelo.PrimaryPart = boardPart
    else
        boardPart.Color = Color3.fromRGB(245, 245, 248)
        boardPart.Material = Enum.Material.SmoothPlastic
    end

    -- Se já tinha SurfaceGui anterior, limpa
    for _, child in ipairs(boardPart:GetChildren()) do
        if child:IsA("SurfaceGui") and child.Name == "LeaderboardSurfaceGui" then
            child:Destroy()
        end
    end

    surfaceGuiQuadro = Instance.new("SurfaceGui")
    surfaceGuiQuadro.Name = "LeaderboardSurfaceGui"
    surfaceGuiQuadro.Face = Enum.NormalId.Front
    surfaceGuiQuadro.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGuiQuadro.PixelsPerStud = 50
    surfaceGuiQuadro.LightInfluence = 0.15
    surfaceGuiQuadro.Brightness = 0.95
    surfaceGuiQuadro.Parent = boardPart

    local container = Instance.new("Frame", surfaceGuiQuadro)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0

    local grad = Instance.new("UIGradient", container)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 247, 252))
    })
    grad.Rotation = 90

    -- Top Header
    local header = Instance.new("Frame", container)
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundColor3 = Color3.fromRGB(240, 243, 250)
    header.BorderSizePixel = 0

    local linhaDivisoria = Instance.new("Frame", header)
    linhaDivisoria.Size = UDim2.new(1, 0, 0, 2)
    linhaDivisoria.Position = UDim2.new(0, 0, 1, -2)
    linhaDivisoria.BackgroundColor3 = Color3.fromRGB(220, 225, 235)
    linhaDivisoria.BorderSizePixel = 0

    textoTituloQuadro = Instance.new("TextLabel", header)
    textoTituloQuadro.Size = UDim2.new(1, 0, 1, 0)
    textoTituloQuadro.BackgroundTransparency = 1
    textoTituloQuadro.Text = "🏆 TOP 10 VITÓRIAS — TRUCO PAULISTA"
    textoTituloQuadro.TextColor3 = Color3.fromRGB(25, 25, 35)
    textoTituloQuadro.Font = Enum.Font.GothamBlack
    textoTituloQuadro.TextSize = 30

    -- Lista de jogadores do quadro
    frameListaQuadro = Instance.new("ScrollingFrame", container)
    frameListaQuadro.Size = UDim2.new(1, -40, 1, -100)
    frameListaQuadro.Position = UDim2.new(0, 20, 0, 90)
    frameListaQuadro.BackgroundTransparency = 1
    frameListaQuadro.ScrollBarThickness = 6
    frameListaQuadro.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local layout = Instance.new("UIListLayout", frameListaQuadro)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
end

function LeaderboardManager.AtualizarQuadroFisico()
    if not frameListaQuadro then return end
    
    for _, filho in ipairs(frameListaQuadro:GetChildren()) do
        if not filho:IsA("UIListLayout") then filho:Destroy() end
    end
    
    local topVitorias = cacheRanking.Vitorias or {}
    
    if #topVitorias == 0 then
        local lblVazio = Instance.new("TextLabel", frameListaQuadro)
        lblVazio.Size = UDim2.new(1, 0, 0, 60)
        lblVazio.BackgroundTransparency = 1
        lblVazio.Text = "Aguardando primeiras vitórias registradas..."
        lblVazio.TextColor3 = Color3.fromRGB(130, 135, 145)
        lblVazio.Font = Enum.Font.GothamMedium
        lblVazio.TextSize = 20
        return
    end

    for rank = 1, math.min(10, #topVitorias) do
        local item = topVitorias[rank]
        local row = Instance.new("Frame", frameListaQuadro)
        row.Size = UDim2.new(1, 0, 0, 48)
        row.LayoutOrder = rank
        row.BorderSizePixel = 0
        
        -- Destaques limpos no fundo branco
        if rank == 1 then
            row.BackgroundColor3 = Color3.fromRGB(255, 248, 220) -- Dourado creme
        elseif rank == 2 then
            row.BackgroundColor3 = Color3.fromRGB(242, 244, 250) -- Prateado suave
        elseif rank == 3 then
            row.BackgroundColor3 = Color3.fromRGB(250, 242, 235) -- Bronze suave
        else
            row.BackgroundColor3 = (rank % 2 == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(246, 248, 252)
        end
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local borda = Instance.new("UIStroke", row)
        borda.Thickness = 1.2
        if rank == 1 then
            borda.Color = Color3.fromRGB(240, 190, 50)
            borda.Transparency = 0.2
        elseif rank == 2 then
            borda.Color = Color3.fromRGB(195, 200, 215)
            borda.Transparency = 0.3
        elseif rank == 3 then
            borda.Color = Color3.fromRGB(215, 165, 130)
            borda.Transparency = 0.3
        else
            borda.Color = Color3.fromRGB(225, 228, 238)
            borda.Transparency = 0.5
        end

        local posText = (rank == 1 and "🥇 1º") or (rank == 2 and "🥈 2º") or (rank == 3 and "🥉 3º") or ("#" .. tostring(rank))
        local lblRank = Instance.new("TextLabel", row)
        lblRank.Size = UDim2.new(0, 80, 1, 0)
        lblRank.Position = UDim2.new(0, 15, 0, 0)
        lblRank.BackgroundTransparency = 1
        lblRank.Text = posText
        if rank == 1 then
            lblRank.TextColor3 = Color3.fromRGB(180, 125, 0)
        elseif rank == 2 then
            lblRank.TextColor3 = Color3.fromRGB(90, 95, 110)
        elseif rank == 3 then
            lblRank.TextColor3 = Color3.fromRGB(160, 95, 45)
        else
            lblRank.TextColor3 = Color3.fromRGB(110, 115, 125)
        end
        lblRank.Font = Enum.Font.GothamBold
        lblRank.TextSize = 22
        lblRank.TextXAlignment = Enum.TextXAlignment.Left

        local lblNome = Instance.new("TextLabel", row)
        lblNome.Size = UDim2.new(0.6, 0, 1, 0)
        lblNome.Position = UDim2.new(0, 100, 0, 0)
        lblNome.BackgroundTransparency = 1
        lblNome.Text = item.Nome
        lblNome.TextColor3 = Color3.fromRGB(25, 25, 35) -- Escuro legível
        lblNome.Font = Enum.Font.GothamBold
        lblNome.TextSize = 20
        lblNome.TextXAlignment = Enum.TextXAlignment.Left

        local lblValor = Instance.new("TextLabel", row)
        lblValor.Size = UDim2.new(0.3, -20, 1, 0)
        lblValor.Position = UDim2.new(0.7, 0, 0, 0)
        lblValor.BackgroundTransparency = 1
        lblValor.Text = tostring(item.Valor) .. " vitórias"
        lblValor.TextColor3 = Color3.fromRGB(190, 120, 15) -- Dourado/âmbar escuro
        lblValor.Font = Enum.Font.GothamBlack
        lblValor.TextSize = 20
        lblValor.TextXAlignment = Enum.TextXAlignment.Right
    end
end

-- ====================================================================
-- PÓDIO 3D DO TOP 3 GLOBAL (AVATARES REAIS DE Leaderboard_Vitorias_v1)
-- ====================================================================

local ANIMACOES_PODIO_R15 = {
    [1] = "rbxassetid://507770677", -- Cheer (1º lugar)
    [2] = "rbxassetid://507766388", -- Idle (2º lugar)
    [3] = "rbxassetid://507766388", -- Idle (3º lugar)
}

local estadoPodioAtual = {} -- [rank] = { UserId = number?, Nome = string?, Valor = number? }
local versaoPodio = 0

local function atualizarPlacaPedestal(pedestal, nomeTexto, vitoriasTexto)
    if not pedestal then return end
    local placa = pedestal:FindFirstChild("Placa")
    local gui = placa and placa:FindFirstChild("PlacaPodioGui")
    local container = gui and gui:FindFirstChild("Container")
    if not container then return end

    local lblNome = container:FindFirstChild("LblNome")
    if lblNome and lblNome:IsA("TextLabel") then
        lblNome.Text = nomeTexto
    end
    local lblVit = container:FindFirstChild("LblVitorias")
    if lblVit and lblVit:IsA("TextLabel") then
        lblVit.Text = vitoriasTexto
    end
end

local function obterDescricaoAvatarSegura(userId)
    if type(userId) == "number" and userId > 0 then
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if ok and desc then
            return desc
        end
    end
    return Instance.new("HumanoidDescription")
end

local function posicionarAvatarNoPedestal(modeloAvatar, pontoCF)
    local hrp = modeloAvatar:FindFirstChild("HumanoidRootPart")
    local humanoide = modeloAvatar:FindFirstChildOfClass("Humanoid")

    -- Calcula deslocamento exato do centro do HumanoidRootPart até a sola dos pés
    local alturaPe = 3.0
    if hrp and humanoide and humanoide.HipHeight > 0.1 then
        alturaPe = humanoide.HipHeight + (hrp.Size.Y * 0.5)
    else
        local bboxCF, bboxSize = modeloAvatar:GetBoundingBox()
        local refY = hrp and hrp.Position.Y or bboxCF.Position.Y
        alturaPe = math.max(refY - (bboxCF.Position.Y - bboxSize.Y * 0.5), 2.5)
    end

    local destinoCF = pontoCF * CFrame.new(0, alturaPe, 0)
    if hrp then
        modeloAvatar.PrimaryPart = hrp
        modeloAvatar:PivotTo(destinoCF)
    else
        modeloAvatar:PivotTo(destinoCF)
    end
end

local function aplicarAnimacaoPodio(modeloAvatar, rank)
    local humanoide = modeloAvatar:FindFirstChildOfClass("Humanoid")
    if not humanoide then return end

    local animator = humanoide:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoide
    end

    local animId = ANIMACOES_PODIO_R15[rank] or ANIMACOES_PODIO_R15[2]
    local anim = Instance.new("Animation")
    anim.Name = "PodioAnim"
    anim.AnimationId = animId
    anim.Parent = modeloAvatar

    pcall(function()
        local track = animator:LoadAnimation(anim)
        track.Looped = true
        track:Play()
    end)
end

function LeaderboardManager.AtualizarPodio3D()
    local podio = workspace:FindFirstChild("PodioTop3", true)
    if not podio then return end

    versaoPodio += 1
    local minhaVersao = versaoPodio

    local pastaAvatares = podio:FindFirstChild("AvataresTop3")
    if not pastaAvatares then
        pastaAvatares = Instance.new("Folder")
        pastaAvatares.Name = "AvataresTop3"
        pastaAvatares.Parent = podio
    end

    local topVitorias = cacheRanking.Vitorias or {}

    for rank = 1, 3 do
        if minhaVersao ~= versaoPodio then return end

        local pedestal = podio:FindFirstChild("Pedestal" .. tostring(rank))
        local pontoAvatar = pedestal and pedestal:FindFirstChild("PontoAvatar")
        local item = topVitorias[rank]
        local nomeModelo = "AvatarRank" .. tostring(rank)

        if not item then
            atualizarPlacaPedestal(pedestal, "Vaga Aberta", "— vitórias")
            local antigo = pastaAvatares:FindFirstChild(nomeModelo)
            if antigo then antigo:Destroy() end
            estadoPodioAtual[rank] = nil
        else
            local sufixoVit = (item.Valor == 1) and " vitória" or " vitórias"
            atualizarPlacaPedestal(pedestal, item.Nome, tostring(item.Valor) .. sufixoVit)

            local anterior = estadoPodioAtual[rank]
            local jaExiste = pastaAvatares:FindFirstChild(nomeModelo) ~= nil

            -- Só recria o modelo 3D se o UserId mudou ou se o avatar ainda não foi instanciado
            if (not jaExiste) or (not anterior) or (anterior.UserId ~= item.UserId) then
                local desc = obterDescricaoAvatarSegura(item.UserId)
                local okModelo, modeloAvatar = pcall(function()
                    return Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R15)
                end)

                if minhaVersao ~= versaoPodio then
                    if okModelo and modeloAvatar then modeloAvatar:Destroy() end
                    return
                end

                if okModelo and modeloAvatar and pontoAvatar then
                    local antigo = pastaAvatares:FindFirstChild(nomeModelo)
                    if antigo then antigo:Destroy() end

                    modeloAvatar.Name = nomeModelo

                    -- Remove quaisquer scripts internos e desativa colisão para impedir empurrões
                    for _, descPart in ipairs(modeloAvatar:GetDescendants()) do
                        if descPart:IsA("BaseScript") then
                            descPart:Destroy()
                        elseif descPart:IsA("BasePart") then
                            descPart.CanCollide = false
                            descPart.Anchored = (descPart.Name == "HumanoidRootPart")
                        end
                    end

                    local humanoide = modeloAvatar:FindFirstChildOfClass("Humanoid")
                    if humanoide then
                        humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        humanoide.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                    end

                    modeloAvatar.Parent = pastaAvatares
                    posicionarAvatarNoPedestal(modeloAvatar, pontoAvatar.CFrame)
                    aplicarAnimacaoPodio(modeloAvatar, rank)

                    estadoPodioAtual[rank] = {
                        UserId = item.UserId,
                        Nome = item.Nome,
                        Valor = item.Valor,
                    }
                elseif not okModelo then
                    warn("[LeaderboardManager] Falha ao criar avatar 3D do pódio rank " .. rank .. ":", tostring(modeloAvatar))
                end
            else
                estadoPodioAtual[rank].Nome = item.Nome
                estadoPodioAtual[rank].Valor = item.Valor
            end
        end
    end
end

-- ====================================================================
-- ATENDIMENTO DE REDE (CLIENT REQUESTS)
-- ====================================================================

rfGetLeaderboard.OnServerInvoke = function(jogador, categoria)
    local cat = categoria or "Vitorias"
    if not cacheRanking[cat] then cat = "Vitorias" end
    
    local dadosJogador = DataManager.ObterDados(jogador) or {}
    
    return {
        Categoria = cat,
        TopList = cacheRanking[cat] or {},
        MeuDado = {
            Pontos = dadosJogador.Pontos or 0,
            Vitorias = dadosJogador.Vitorias or 0,
            Derrotas = dadosJogador.Derrotas or 0,
            PartidasJogadas = dadosJogador.PartidasJogadas or 0,
            RobuxGasto = dadosJogador.RobuxGasto or 0
        }
    }
end

-- ====================================================================
-- INICIALIZAÇÃO E LOOPS
-- ====================================================================

function LeaderboardManager.Inicializar()
    -- Vincula callback de alteração de dados no DataManager
    DataManager.OnStatChanged = function(jogador, dados)
        LeaderboardManager.AtualizarODSJogador(jogador, dados)
    end

    -- Registra jogadores que já estejam online
    for _, jog in ipairs(Players:GetPlayers()) do
        local dados = DataManager.ObterDados(jog)
        if dados then
            LeaderboardManager.AtualizarODSJogador(jog, dados)
        end
    end

    LeaderboardManager._ConfigurarQuadroNoMapa()

    -- Primeira carga
    task.spawn(function()
        task.wait(1)
        LeaderboardManager.AtualizarTodosRankings()
    end)

    -- Loop de persistência periódica de ODS
    task.spawn(function()
        while true do
            task.wait(15)
            processarFilaODS()
        end
    end)

    -- Loop de atualização do ranking a cada 60 segundos
    task.spawn(function()
        while true do
            task.wait(60)
            LeaderboardManager.AtualizarTodosRankings()
        end
    end)
end

LeaderboardManager.Inicializar()

return LeaderboardManager

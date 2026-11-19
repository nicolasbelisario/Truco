local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Eventos = ReplicatedStorage:WaitForChild("Events")

local LobbyUI = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local VERDE      = Color3.fromRGB(39, 174, 96)
local VERDE_HOV  = Color3.fromRGB(46, 204, 113)
local VERMELHO   = Color3.fromRGB(200, 50, 50)
local AZUL       = Color3.fromRGB(52, 152, 219)
local ROXO       = Color3.fromRGB(155, 89, 182)
local TEAL       = Color3.fromRGB(26, 188, 156)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(180, 180, 190)

local matchmakingEvent = nil
local getRoomsDataFunc = nil

local barraLobby = nil
local btnJogarAgora = nil
local btnAbrirSalas = nil
local modalSalas = nil
local listaSalasFrame = nil
local lblStatusSalas = nil
local inputCodigoSala = nil
local inputNomeSala = nil
local bannerToast = nil
local lblToast = nil
local strokeToast = nil
local pillCodigoSala = nil
local lblCodigoSala = nil

local botoesFiltro = {}
local filtroAtual = "Todas"
local salasCache = {}
local estaSentado = false
local buscandoQuickPlay = false
local toastToken = 0

local function corPorModo(sala)
    if sala.Privada then return ACENTO end
    if sala.Modo == "SOLO 1v3" then return AZUL end
    if sala.Modo == "DUPLA 2v2" then return ROXO end
    if sala.Modo == "TRIO 3v1" then return TEAL end
    return VERDE
end

local function mostrarToast(mensagem, tipo)
    if not bannerToast or not lblToast or not strokeToast then return end
    toastToken += 1
    local meuToken = toastToken

    local cor = ACENTO
    if tipo == "sucesso" then
        cor = VERDE
    elseif tipo == "erro" then
        cor = VERMELHO
    end

    lblToast.Text = tostring(mensagem or "")
    strokeToast.Color = cor
    bannerToast.Visible = true
    bannerToast.BackgroundTransparency = 0.08
    lblToast.TextTransparency = 0

    task.delay(3.5, function()
        if toastToken ~= meuToken or not bannerToast then return end
        local t1 = TweenService:Create(bannerToast, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
        local t2 = TweenService:Create(lblToast, TweenInfo.new(0.35), { TextTransparency = 1 })
        t1:Play()
        t2:Play()
        t1.Completed:Connect(function()
            if toastToken == meuToken and bannerToast then
                bannerToast.Visible = false
            end
        end)
    end)
end

function LobbyUI.ExibirCodigoPrivado(codigo)
    if not pillCodigoSala or not lblCodigoSala then return end
    if codigo and tostring(codigo) ~= "" then
        lblCodigoSala.Text = "🔒 MESA PRIVADA • CÓDIGO: " .. tostring(codigo)
        pillCodigoSala.Visible = true
    else
        pillCodigoSala.Visible = false
    end
end

function LobbyUI.OcultarCodigoPrivado()
    if pillCodigoSala then
        pillCodigoSala.Visible = false
    end
end

local function atualizarVisualFiltros()
    for chave, btn in pairs(botoesFiltro) do
        local ativo = (chave == filtroAtual)
        btn.BackgroundColor3 = ativo and ACENTO or BG_BOTAO
        btn.TextColor3 = ativo and BG_ESCURO or TEXTO_PRIM
    end
end

local function limparListaSalas()
    if not listaSalasFrame then return end
    for _, filho in ipairs(listaSalasFrame:GetChildren()) do
        if not filho:IsA("UIListLayout") then
            filho:Destroy()
        end
    end
end

local function salaPassaFiltro(sala)
    if filtroAtual == "PvP" then
        return not sala.UsaBots
    elseif filtroAtual == "PvE" then
        return sala.UsaBots == true
    end
    return true
end

local function renderizarSalas(lista)
    salasCache = lista or salasCache or {}
    if not listaSalasFrame then return end
    limparListaSalas()

    local exibidas = 0
    for idx, sala in ipairs(salasCache) do
        if salaPassaFiltro(sala) then
            exibidas += 1
            local corModo = corPorModo(sala)

            local row = Instance.new("Frame")
            row.Name = "Sala_" .. tostring(sala.Id)
            row.Size = UDim2.new(1, -4, 0, 58)
            row.BackgroundColor3 = BG_PAINEL
            row.BorderSizePixel = 0
            row.LayoutOrder = idx
            row.ZIndex = 82
            row.Parent = listaSalasFrame
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

            local stroke = Instance.new("UIStroke", row)
            stroke.Thickness = 1
            stroke.Color = sala.TemVaga and corModo or Color3.fromRGB(60, 60, 72)
            stroke.Transparency = sala.TemVaga and 0.45 or 0.7

            -- Badge lateral de modo
            local badge = Instance.new("TextLabel")
            badge.Name = "BadgeModo"
            badge.Size = UDim2.new(0, 104, 0, 26)
            badge.Position = UDim2.new(0, 10, 0.5, 0)
            badge.AnchorPoint = Vector2.new(0, 0.5)
            badge.BackgroundColor3 = corModo
            badge.BackgroundTransparency = 0.15
            badge.Text = sala.ModoBadge or sala.Modo or "PVP 4P"
            badge.TextColor3 = TEXTO_PRIM
            badge.Font = Enum.Font.GothamBlack
            badge.TextSize = 12
            badge.ZIndex = 83
            badge.Parent = row
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

            -- Nome da sala / mesa
            local lblNome = Instance.new("TextLabel")
            lblNome.Name = "LblNome"
            lblNome.Size = UDim2.new(1, -238, 0, 22)
            lblNome.Position = UDim2.new(0, 124, 0, 8)
            lblNome.BackgroundTransparency = 1
            lblNome.Text = sala.NomeExibicao or sala.Nome
            lblNome.TextColor3 = TEXTO_PRIM
            lblNome.Font = Enum.Font.GothamBold
            lblNome.TextSize = 14
            lblNome.TextXAlignment = Enum.TextXAlignment.Left
            lblNome.TextTruncate = Enum.TextTruncate.AtEnd
            lblNome.ZIndex = 83
            lblNome.Parent = row

            -- Status / Vagas / Placar ao vivo
            local subTexto = ""
            local corSub = TEXTO_SEC
            if sala.Estado == "WAITING" then
                local livres = math.max(0, (sala.MaxJogadores or 4) - (sala.Ocupados or 0))
                local sufixo = (livres == 1) and "1 vaga" or (tostring(livres) .. " vagas")
                subTexto = string.format("🪑 %d/%d  •  %s", sala.Ocupados or 0, sala.MaxJogadores or 4, sufixo)
                if sala.Privada then
                    subTexto = subTexto .. "  •  🔒 Privada"
                    corSub = Color3.fromRGB(255, 210, 115)
                elseif not sala.UsaBots and (sala.Humanos or 0) > 0 then
                    corSub = Color3.fromRGB(130, 235, 165)
                end
            elseif sala.Estado == "COUNTDOWN" then
                subTexto = "⏱️ Iniciando partida... (4/4)"
                corSub = ACENTO
            else
                subTexto = string.format("🃏 Em jogo  •  Placar %d x %d", sala.PlacarA or 0, sala.PlacarB or 0)
                if (sala.BotsTemporarios or 0) > 0 then
                    subTexto = subTexto .. "  •  🤖 Bot Sub"
                end
                corSub = Color3.fromRGB(240, 200, 120)
            end

            local lblSub = Instance.new("TextLabel")
            lblSub.Name = "LblSub"
            lblSub.Size = UDim2.new(1, -238, 0, 18)
            lblSub.Position = UDim2.new(0, 124, 0, 32)
            lblSub.BackgroundTransparency = 1
            lblSub.Text = subTexto
            lblSub.TextColor3 = corSub
            lblSub.Font = Enum.Font.GothamMedium
            lblSub.TextSize = 12
            lblSub.TextXAlignment = Enum.TextXAlignment.Left
            lblSub.TextTruncate = Enum.TextTruncate.AtEnd
            lblSub.ZIndex = 83
            lblSub.Parent = row

            -- Botão de ação
            local btnEntrar = Instance.new("TextButton")
            btnEntrar.Name = "BtnEntrar"
            btnEntrar.Size = UDim2.new(0, 96, 0, 34)
            btnEntrar.Position = UDim2.new(1, -10, 0.5, 0)
            btnEntrar.AnchorPoint = Vector2.new(1, 0.5)
            btnEntrar.Font = Enum.Font.GothamBlack
            btnEntrar.TextSize = 12
            btnEntrar.TextColor3 = TEXTO_PRIM
            btnEntrar.ZIndex = 84
            btnEntrar.Parent = row
            Instance.new("UICorner", btnEntrar).CornerRadius = UDim.new(0, 8)

            if sala.TemVaga then
                if sala.Privada then
                    btnEntrar.Text = "🔒 CÓDIGO"
                    btnEntrar.BackgroundColor3 = ACENTO
                    btnEntrar.TextColor3 = BG_ESCURO
                    btnEntrar.Activated:Connect(function()
                        local codigo = inputCodigoSala and inputCodigoSala.Text or ""
                        codigo = codigo:gsub("%s+", "")
                        if codigo == "" then
                            mostrarToast("Digite o código de 4 dígitos no campo acima para entrar.", "info")
                            if inputCodigoSala then inputCodigoSala:CaptureFocus() end
                            return
                        end
                        if matchmakingEvent then
                            matchmakingEvent:FireServer("EntrarMesa", sala.Nome, codigo)
                        end
                    end)
                else
                    btnEntrar.Text = "ENTRAR"
                    btnEntrar.BackgroundColor3 = VERDE
                    btnEntrar.Activated:Connect(function()
                        if matchmakingEvent then
                            matchmakingEvent:FireServer("EntrarMesa", sala.Nome)
                        end
                    end)
                end
            else
                btnEntrar.Text = (sala.Estado == "WAITING") and "LOTADA" or "EM JOGO"
                btnEntrar.BackgroundColor3 = Color3.fromRGB(58, 58, 70)
                btnEntrar.TextColor3 = TEXTO_SEC
                btnEntrar.Active = false
                btnEntrar.AutoButtonColor = false
            end
        end
    end

    if lblStatusSalas then
        lblStatusSalas.Visible = (exibidas == 0)
        if exibidas == 0 then
            lblStatusSalas.Text = "Nenhuma mesa encontrada neste filtro."
        end
    end
end

function LobbyUI.AtualizarSalas()
    if not getRoomsDataFunc then return end
    if lblStatusSalas then
        lblStatusSalas.Visible = true
        lblStatusSalas.Text = "Atualizando mesas..."
    end

    task.spawn(function()
        local ok, lista = pcall(function()
            return getRoomsDataFunc:InvokeServer()
        end)
        if ok and type(lista) == "table" then
            renderizarSalas(lista)
        else
            if lblStatusSalas then
                lblStatusSalas.Visible = true
                lblStatusSalas.Text = "Não foi possível carregar as mesas."
            end
        end
    end)
end

function LobbyUI.AbrirSalas()
    if estaSentado or not modalSalas then return end
    modalSalas.Visible = true
    LobbyUI.AtualizarSalas()
end

function LobbyUI.FecharSalas()
    if modalSalas then
        modalSalas.Visible = false
    end
end

function LobbyUI.AlternarSalas()
    if not modalSalas then return end
    if modalSalas.Visible then
        LobbyUI.FecharSalas()
    else
        LobbyUI.AbrirSalas()
    end
end

function LobbyUI.DefinirSentado(sentado)
    estaSentado = sentado == true
    if barraLobby then
        barraLobby.Visible = not estaSentado
    end
    if estaSentado then
        LobbyUI.FecharSalas()
    else
        LobbyUI.OcultarCodigoPrivado()
    end
end

function LobbyUI.Inicializar(painelTela)
    -- ==========================================
    -- 1. BARRA DE AÇÕES DO LOBBY ("JOGAR AGORA" + "SALAS")
    -- ==========================================
    barraLobby = Instance.new("Frame")
    barraLobby.Name = "BarraLobbyQuickPlay"
    barraLobby.Size = UDim2.new(0, 344, 0, 56)
    barraLobby.Position = UDim2.new(0.5, 0, 1, -24)
    barraLobby.AnchorPoint = Vector2.new(0.5, 1)
    barraLobby.BackgroundTransparency = 1
    barraLobby.ZIndex = 45
    barraLobby.Parent = painelTela

    local layoutBarra = Instance.new("UIListLayout", barraLobby)
    layoutBarra.FillDirection = Enum.FillDirection.Horizontal
    layoutBarra.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutBarra.VerticalAlignment = Enum.VerticalAlignment.Center
    layoutBarra.Padding = UDim.new(0, 12)

    -- Botão Principal: JOGAR AGORA (Quick Play)
    btnJogarAgora = Instance.new("TextButton")
    btnJogarAgora.Name = "BtnJogarAgora"
    btnJogarAgora.Size = UDim2.new(0, 208, 0, 52)
    btnJogarAgora.BackgroundColor3 = VERDE
    btnJogarAgora.Text = "▶ JOGAR AGORA"
    btnJogarAgora.TextColor3 = TEXTO_PRIM
    btnJogarAgora.Font = Enum.Font.GothamBlack
    btnJogarAgora.TextSize = 18
    btnJogarAgora.AutoButtonColor = false
    btnJogarAgora.LayoutOrder = 1
    btnJogarAgora.ZIndex = 46
    btnJogarAgora.Parent = barraLobby
    Instance.new("UICorner", btnJogarAgora).CornerRadius = UDim.new(0, 14)

    local strokeQuick = Instance.new("UIStroke", btnJogarAgora)
    strokeQuick.Thickness = 2
    strokeQuick.Color = Color3.fromRGB(145, 255, 185)
    strokeQuick.Transparency = 0.25

    btnJogarAgora.MouseEnter:Connect(function()
        if buscandoQuickPlay then return end
        TweenService:Create(btnJogarAgora, TweenInfo.new(0.15), { BackgroundColor3 = VERDE_HOV }):Play()
    end)
    btnJogarAgora.MouseLeave:Connect(function()
        if buscandoQuickPlay then return end
        TweenService:Create(btnJogarAgora, TweenInfo.new(0.15), { BackgroundColor3 = VERDE }):Play()
    end)

    btnJogarAgora.Activated:Connect(function()
        if buscandoQuickPlay or not matchmakingEvent then return end
        buscandoQuickPlay = true
        btnJogarAgora.Text = "⏳ BUSCANDO..."
        btnJogarAgora.BackgroundColor3 = Color3.fromRGB(32, 130, 74)
        matchmakingEvent:FireServer("QuickPlay")
        task.delay(2.5, function()
            if buscandoQuickPlay then
                buscandoQuickPlay = false
                if btnJogarAgora then
                    btnJogarAgora.Text = "▶ JOGAR AGORA"
                    btnJogarAgora.BackgroundColor3 = VERDE
                end
            end
        end)
    end)

    -- Botão Secundário: MESAS (Matchmaking / Mesas Públicas e Privadas)
    btnAbrirSalas = Instance.new("TextButton")
    btnAbrirSalas.Name = "BtnMesas"
    btnAbrirSalas.Size = UDim2.new(0, 118, 0, 52)
    btnAbrirSalas.BackgroundColor3 = BG_PAINEL
    btnAbrirSalas.Text = "🃏 MESAS"
    btnAbrirSalas.TextColor3 = TEXTO_PRIM
    btnAbrirSalas.Font = Enum.Font.GothamBlack
    btnAbrirSalas.TextSize = 15
    btnAbrirSalas.AutoButtonColor = false
    btnAbrirSalas.LayoutOrder = 2
    btnAbrirSalas.ZIndex = 46
    btnAbrirSalas.Parent = barraLobby
    Instance.new("UICorner", btnAbrirSalas).CornerRadius = UDim.new(0, 14)

    local strokeSalas = Instance.new("UIStroke", btnAbrirSalas)
    strokeSalas.Thickness = 1.6
    strokeSalas.Color = ACENTO
    strokeSalas.Transparency = 0.25

    btnAbrirSalas.MouseEnter:Connect(function()
        TweenService:Create(btnAbrirSalas, TweenInfo.new(0.15), { BackgroundColor3 = BG_BOTAO }):Play()
    end)
    btnAbrirSalas.MouseLeave:Connect(function()
        TweenService:Create(btnAbrirSalas, TweenInfo.new(0.15), { BackgroundColor3 = BG_PAINEL }):Play()
    end)

    btnAbrirSalas.Activated:Connect(function()
        LobbyUI.AlternarSalas()
    end)

    -- ==========================================
    -- 2. BANNER TOAST & PILL DE CÓDIGO PRIVADO
    -- ==========================================
    bannerToast = Instance.new("Frame")
    bannerToast.Name = "BannerToastMatchmaking"
    bannerToast.Size = UDim2.new(0, 380, 0, 42)
    bannerToast.Position = UDim2.new(0.5, 0, 0, 56)
    bannerToast.AnchorPoint = Vector2.new(0.5, 0)
    bannerToast.BackgroundColor3 = BG_ESCURO
    bannerToast.BackgroundTransparency = 0.08
    bannerToast.Visible = false
    bannerToast.ZIndex = 120
    bannerToast.Parent = painelTela
    Instance.new("UICorner", bannerToast).CornerRadius = UDim.new(0, 12)

    strokeToast = Instance.new("UIStroke", bannerToast)
    strokeToast.Thickness = 1.8
    strokeToast.Color = ACENTO

    lblToast = Instance.new("TextLabel")
    lblToast.Size = UDim2.new(1, -20, 1, 0)
    lblToast.Position = UDim2.new(0, 10, 0, 0)
    lblToast.BackgroundTransparency = 1
    lblToast.TextColor3 = TEXTO_PRIM
    lblToast.Font = Enum.Font.GothamBold
    lblToast.TextSize = 14
    lblToast.TextTruncate = Enum.TextTruncate.AtEnd
    lblToast.ZIndex = 121
    lblToast.Parent = bannerToast

    pillCodigoSala = Instance.new("Frame")
    pillCodigoSala.Name = "PillCodigoSalaPrivada"
    pillCodigoSala.Size = UDim2.new(0, 265, 0, 34)
    pillCodigoSala.Position = UDim2.new(0.5, 0, 0, 52)
    pillCodigoSala.AnchorPoint = Vector2.new(0.5, 0)
    pillCodigoSala.BackgroundColor3 = BG_ESCURO
    pillCodigoSala.BackgroundTransparency = 0.12
    pillCodigoSala.Visible = false
    pillCodigoSala.ZIndex = 95
    pillCodigoSala.Parent = painelTela
    Instance.new("UICorner", pillCodigoSala).CornerRadius = UDim.new(1, 0)

    local strokePill = Instance.new("UIStroke", pillCodigoSala)
    strokePill.Thickness = 1.6
    strokePill.Color = ACENTO

    lblCodigoSala = Instance.new("TextLabel")
    lblCodigoSala.Size = UDim2.new(1, -16, 1, 0)
    lblCodigoSala.Position = UDim2.new(0, 8, 0, 0)
    lblCodigoSala.BackgroundTransparency = 1
    lblCodigoSala.TextColor3 = Color3.fromRGB(255, 225, 110)
    lblCodigoSala.Font = Enum.Font.GothamBlack
    lblCodigoSala.TextSize = 14
    lblCodigoSala.ZIndex = 96
    lblCodigoSala.Parent = pillCodigoSala

    -- ==========================================
    -- 3. MODAL DE SALAS & MATCHMAKING
    -- ==========================================
    modalSalas = Instance.new("Frame")
    modalSalas.Name = "ModalSalas"
    modalSalas.Size = UDim2.new(0.92, 0, 0.86, 0)
    modalSalas.Position = UDim2.new(0.5, 0, 0.5, 0)
    modalSalas.AnchorPoint = Vector2.new(0.5, 0.5)
    modalSalas.BackgroundColor3 = BG_ESCURO
    modalSalas.BorderSizePixel = 0
    modalSalas.Visible = false
    modalSalas.ZIndex = 80
    modalSalas.Parent = painelTela
    Instance.new("UICorner", modalSalas).CornerRadius = UDim.new(0, 16)

    local sizeCons = Instance.new("UISizeConstraint", modalSalas)
    sizeCons.MaxSize = Vector2.new(580, 520)

    local strokeModal = Instance.new("UIStroke", modalSalas)
    strokeModal.Color = Color3.fromRGB(55, 55, 70)
    strokeModal.Thickness = 1.5

    -- Header
    local header = Instance.new("Frame", modalSalas)
    header.Size = UDim2.new(1, 0, 0, 56)
    header.BackgroundTransparency = 1
    header.ZIndex = 81

    local titulo = Instance.new("TextLabel", header)
    titulo.Size = UDim2.new(0.7, 0, 1, 0)
    titulo.Position = UDim2.new(0, 20, 0, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text = "🃏 MESAS & PARTIDAS"
    titulo.TextColor3 = ACENTO
    titulo.Font = Enum.Font.GothamBlack
    titulo.TextSize = 20
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.ZIndex = 82

    local btnAtualizar = Instance.new("TextButton", header)
    btnAtualizar.Size = UDim2.new(0, 34, 0, 34)
    btnAtualizar.Position = UDim2.new(1, -58, 0.5, 0)
    btnAtualizar.AnchorPoint = Vector2.new(1, 0.5)
    btnAtualizar.BackgroundColor3 = BG_BOTAO
    btnAtualizar.Text = "🔄"
    btnAtualizar.TextColor3 = TEXTO_PRIM
    btnAtualizar.Font = Enum.Font.GothamBold
    btnAtualizar.TextSize = 16
    btnAtualizar.ZIndex = 82
    Instance.new("UICorner", btnAtualizar).CornerRadius = UDim.new(1, 0)
    btnAtualizar.Activated:Connect(function() LobbyUI.AtualizarSalas() end)

    local btnFechar = Instance.new("TextButton", header)
    btnFechar.Size = UDim2.new(0, 34, 0, 34)
    btnFechar.Position = UDim2.new(1, -16, 0.5, 0)
    btnFechar.AnchorPoint = Vector2.new(1, 0.5)
    btnFechar.BackgroundColor3 = BG_BOTAO
    btnFechar.Text = "X"
    btnFechar.TextColor3 = TEXTO_PRIM
    btnFechar.Font = Enum.Font.GothamBlack
    btnFechar.TextSize = 16
    btnFechar.ZIndex = 82
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    btnFechar.Activated:Connect(function() LobbyUI.FecharSalas() end)

    -- Abas de Filtro
    local containerFiltros = Instance.new("Frame", modalSalas)
    containerFiltros.Size = UDim2.new(1, -36, 0, 34)
    containerFiltros.Position = UDim2.new(0, 18, 0, 56)
    containerFiltros.BackgroundTransparency = 1
    containerFiltros.ZIndex = 81

    local function criarBotaoFiltro(texto, chave, xPos)
        local btn = Instance.new("TextButton", containerFiltros)
        btn.Size = UDim2.new(0.32, 0, 1, 0)
        btn.Position = UDim2.new(xPos, 0, 0, 0)
        btn.BackgroundColor3 = BG_BOTAO
        btn.Text = texto
        btn.TextColor3 = TEXTO_PRIM
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.ZIndex = 82
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.Activated:Connect(function()
            filtroAtual = chave
            atualizarVisualFiltros()
            renderizarSalas(salasCache)
        end)
        botoesFiltro[chave] = btn
    end

    criarBotaoFiltro("Todas", "Todas", 0)
    criarBotaoFiltro("⚔️ PvP Públicas", "PvP", 0.34)
    criarBotaoFiltro("🤖 PvE (Bots)", "PvE", 0.68)
    atualizarVisualFiltros()

    -- Barra Rápida: Entrar por Código de Sala Privada
    local barraCodigo = Instance.new("Frame", modalSalas)
    barraCodigo.Size = UDim2.new(1, -36, 0, 36)
    barraCodigo.Position = UDim2.new(0, 18, 0, 98)
    barraCodigo.BackgroundColor3 = BG_PAINEL
    barraCodigo.ZIndex = 81
    Instance.new("UICorner", barraCodigo).CornerRadius = UDim.new(0, 8)

    inputCodigoSala = Instance.new("TextBox", barraCodigo)
    inputCodigoSala.Size = UDim2.new(1, -124, 1, -6)
    inputCodigoSala.Position = UDim2.new(0, 10, 0, 3)
    inputCodigoSala.BackgroundTransparency = 1
    inputCodigoSala.PlaceholderText = "🔒 Código da mesa privada (4 dígitos)..."
    inputCodigoSala.PlaceholderColor3 = TEXTO_SEC
    inputCodigoSala.Text = ""
    inputCodigoSala.TextColor3 = TEXTO_PRIM
    inputCodigoSala.Font = Enum.Font.GothamMedium
    inputCodigoSala.TextSize = 13
    inputCodigoSala.TextXAlignment = Enum.TextXAlignment.Left
    inputCodigoSala.ClearTextOnFocus = false
    inputCodigoSala.ZIndex = 82

    local btnEntrarCodigo = Instance.new("TextButton", barraCodigo)
    btnEntrarCodigo.Size = UDim2.new(0, 104, 1, -6)
    btnEntrarCodigo.Position = UDim2.new(1, -4, 0, 3)
    btnEntrarCodigo.AnchorPoint = Vector2.new(1, 0)
    btnEntrarCodigo.BackgroundColor3 = ACENTO
    btnEntrarCodigo.Text = "ENTRAR"
    btnEntrarCodigo.TextColor3 = BG_ESCURO
    btnEntrarCodigo.Font = Enum.Font.GothamBlack
    btnEntrarCodigo.TextSize = 12
    btnEntrarCodigo.ZIndex = 82
    Instance.new("UICorner", btnEntrarCodigo).CornerRadius = UDim.new(0, 6)
    btnEntrarCodigo.Activated:Connect(function()
        if not matchmakingEvent then return end
        local codigo = inputCodigoSala.Text:gsub("%s+", "")
        if codigo == "" then
            mostrarToast("Informe o código de 4 dígitos da mesa privada.", "erro")
            return
        end
        matchmakingEvent:FireServer("EntrarPorCodigo", codigo)
    end)

    -- Status vazio/carregando
    lblStatusSalas = Instance.new("TextLabel", modalSalas)
    lblStatusSalas.Size = UDim2.new(1, -36, 0, 28)
    lblStatusSalas.Position = UDim2.new(0, 18, 0, 146)
    lblStatusSalas.BackgroundTransparency = 1
    lblStatusSalas.Text = ""
    lblStatusSalas.TextColor3 = TEXTO_SEC
    lblStatusSalas.Font = Enum.Font.GothamMedium
    lblStatusSalas.TextSize = 14
    lblStatusSalas.Visible = false
    lblStatusSalas.ZIndex = 83

    -- Lista de Salas (ScrollingFrame)
    listaSalasFrame = Instance.new("ScrollingFrame", modalSalas)
    listaSalasFrame.Name = "ListaSalas"
    listaSalasFrame.Size = UDim2.new(1, -36, 1, -248)
    listaSalasFrame.Position = UDim2.new(0, 18, 0, 142)
    listaSalasFrame.BackgroundTransparency = 1
    listaSalasFrame.BorderSizePixel = 0
    listaSalasFrame.ScrollBarThickness = 5
    listaSalasFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    listaSalasFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listaSalasFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listaSalasFrame.ZIndex = 81

    local layoutLista = Instance.new("UIListLayout", listaSalasFrame)
    layoutLista.Padding = UDim.new(0, 8)
    layoutLista.SortOrder = Enum.SortOrder.LayoutOrder

    -- Rodapé: Criar Sala PvP Pública ou Privada
    local rodapeCriar = Instance.new("Frame", modalSalas)
    rodapeCriar.Name = "RodapeCriarSala"
    rodapeCriar.Size = UDim2.new(1, -36, 0, 88)
    rodapeCriar.Position = UDim2.new(0, 18, 1, -98)
    rodapeCriar.BackgroundColor3 = BG_PAINEL
    rodapeCriar.ZIndex = 82
    Instance.new("UICorner", rodapeCriar).CornerRadius = UDim.new(0, 10)

    local strokeRodape = Instance.new("UIStroke", rodapeCriar)
    strokeRodape.Color = Color3.fromRGB(65, 65, 80)
    strokeRodape.Thickness = 1

    inputNomeSala = Instance.new("TextBox", rodapeCriar)
    inputNomeSala.Size = UDim2.new(1, -16, 0, 32)
    inputNomeSala.Position = UDim2.new(0, 8, 0, 8)
    inputNomeSala.BackgroundColor3 = BG_ESCURO
    inputNomeSala.PlaceholderText = "Nome da nova mesa PvP (opcional)..."
    inputNomeSala.PlaceholderColor3 = TEXTO_SEC
    inputNomeSala.Text = ""
    inputNomeSala.TextColor3 = TEXTO_PRIM
    inputNomeSala.Font = Enum.Font.GothamMedium
    inputNomeSala.TextSize = 13
    inputNomeSala.ClearTextOnFocus = false
    inputNomeSala.ZIndex = 83
    Instance.new("UICorner", inputNomeSala).CornerRadius = UDim.new(0, 6)

    local btnCriarPublica = Instance.new("TextButton", rodapeCriar)
    btnCriarPublica.Size = UDim2.new(0.48, -6, 0, 34)
    btnCriarPublica.Position = UDim2.new(0, 8, 0, 46)
    btnCriarPublica.BackgroundColor3 = VERDE
    btnCriarPublica.Text = "+ MESA PÚBLICA"
    btnCriarPublica.TextColor3 = TEXTO_PRIM
    btnCriarPublica.Font = Enum.Font.GothamBlack
    btnCriarPublica.TextSize = 13
    btnCriarPublica.ZIndex = 83
    Instance.new("UICorner", btnCriarPublica).CornerRadius = UDim.new(0, 8)
    btnCriarPublica.Activated:Connect(function()
        if not matchmakingEvent then return end
        matchmakingEvent:FireServer("CriarSala", {
            NomeSala = inputNomeSala.Text,
            Privada = false,
        })
    end)

    local btnCriarPrivada = Instance.new("TextButton", rodapeCriar)
    btnCriarPrivada.Size = UDim2.new(0.48, -6, 0, 34)
    btnCriarPrivada.Position = UDim2.new(1, -8, 0, 46)
    btnCriarPrivada.AnchorPoint = Vector2.new(1, 0)
    btnCriarPrivada.BackgroundColor3 = ACENTO
    btnCriarPrivada.Text = "🔒 MESA PRIVADA"
    btnCriarPrivada.TextColor3 = BG_ESCURO
    btnCriarPrivada.Font = Enum.Font.GothamBlack
    btnCriarPrivada.TextSize = 13
    btnCriarPrivada.ZIndex = 83
    Instance.new("UICorner", btnCriarPrivada).CornerRadius = UDim.new(0, 8)
    btnCriarPrivada.Activated:Connect(function()
        if not matchmakingEvent then return end
        matchmakingEvent:FireServer("CriarSala", {
            NomeSala = inputNomeSala.Text,
            Privada = true,
        })
    end)

    -- Responsividade mobile para a barra de Quick Play
    local function ajustarResponsivo()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if vp.X < 520 or vp.Y < 500 then
            barraLobby.Size = UDim2.new(0, 290, 0, 48)
            barraLobby.Position = UDim2.new(0.5, 0, 1, -16)
            btnJogarAgora.Size = UDim2.new(0, 174, 0, 44)
            btnJogarAgora.TextSize = 15
            btnAbrirSalas.Size = UDim2.new(0, 102, 0, 44)
            btnAbrirSalas.TextSize = 14
            bannerToast.Size = UDim2.new(0.9, 0, 0, 38)
        else
            barraLobby.Size = UDim2.new(0, 344, 0, 56)
            barraLobby.Position = UDim2.new(0.5, 0, 1, -24)
            btnJogarAgora.Size = UDim2.new(0, 208, 0, 52)
            btnJogarAgora.TextSize = 18
            btnAbrirSalas.Size = UDim2.new(0, 118, 0, 52)
            btnAbrirSalas.TextSize = 15
            bannerToast.Size = UDim2.new(0, 380, 0, 42)
        end
    end
    ajustarResponsivo()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarResponsivo)
    end

    -- ==========================================
    -- 4. CONEXÃO COM REMOTOS DE MATCHMAKING
    -- ==========================================
    task.spawn(function()
        matchmakingEvent = Eventos:WaitForChild("MatchmakingEvent", 15)
        getRoomsDataFunc = Eventos:WaitForChild("GetRoomsData", 15)

        if matchmakingEvent then
            matchmakingEvent.OnClientEvent:Connect(function(tipo, dados)
                if tipo == "RoomListUpdate" and type(dados) == "table" then
                    salasCache = dados
                    if modalSalas and modalSalas.Visible then
                        renderizarSalas(dados)
                    end
                elseif tipo == "QuickPlayResult" and type(dados) == "table" then
                    buscandoQuickPlay = false
                    if btnJogarAgora then
                        btnJogarAgora.Text = "▶ JOGAR AGORA"
                        btnJogarAgora.BackgroundColor3 = VERDE
                    end

                    if dados.Sucesso then
                        LobbyUI.FecharSalas()
                        mostrarToast(dados.Mensagem or "Entrando na mesa...", "sucesso")
                        if dados.Privada and dados.Codigo then
                            LobbyUI.ExibirCodigoPrivado(dados.Codigo)
                        else
                            LobbyUI.OcultarCodigoPrivado()
                        end
                    else
                        mostrarToast(dados.Mensagem or "Não foi possível entrar na mesa.", "erro")
                    end
                end
            end)
        end
    end)
end

return LobbyUI

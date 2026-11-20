--[[
    TutorialMatch.luau
    Partida tutorial interativa e scriptada contra bots (Issue #8).
    Utiliza os mesmos componentes de UI do jogo (ScoreUI, HandUI, TableUI, TrucoUI, BtnTruco),
    com card central grande da personagem guia (Workspace.Tutorial.copinhodecocacola) e
    spotlight de tela inteira (vinheta escura recortada apenas onde o jogador deve clicar).
    Totalmente isolada do servidor: nunca dispara eventos de partida real nem altera ranking/economia.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GuideAvatar = require(script.Parent:WaitForChild("GuideAvatar"))

local TutorialMatch = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 26)
local BG_BOTAO   = Color3.fromRGB(42, 42, 56)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local OURO_VIVO  = Color3.fromRGB(255, 222, 72)
local VERDE      = Color3.fromRGB(39, 174, 96)
local AZUL       = Color3.fromRGB(48, 138, 218)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(195, 198, 212)

local TOTAL_PASSOS = 6
local TRANSPARENCIA_VINHETA = 0.48

local jogadorLocal = Players.LocalPlayer
local painelTela = nil
local hooks = nil

local ativo = false
local sessaoId = 0
local etapaAtual = nil -- string identificadora do estado interativo

-- Elementos visuais do Tutorial Interativo
local camadaTutorial = nil
local cardGuia = nil
local retratoGuia = nil
local lblPassoGuia = nil
local lblFalaGuia = nil
local barraProgresso = nil
local btnContinuarGuia = nil
local pillAcaoGuia = nil
local btnPularTopo = nil
local modalConclusao = nil
local retratoConclusao = nil

-- Spotlight (vinheta escura de 4 retângulos ao redor do alvo clicável)
local vinhetaPaineis = nil -- { Top, Bottom, Left, Right }
local vinhetaAtiva = false
local vinhetaTweens = {}

local highlightSlots = {} -- { { box, stroke, badge, badgeLbl, alvo, tweenPulso } }
local posicaoCardModo = "centro" -- "centro" | "topoCentro" | "abaixoTruco"
local connRenderHighlight = nil
local connViewport = nil
local onContinuarCallback = nil
local tweenCameraTutorial = nil
local tweenPosCard = nil

local function cancelarTweenCamera()
    if tweenCameraTutorial then
        tweenCameraTutorial:Cancel()
        tweenCameraTutorial = nil
    end
end

local function enquadrarCameraMesaTutorial()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local pastaMesas = workspace:FindFirstChild("MesasFolder")
    if not pastaMesas then return end

    local mesaAlvo = pastaMesas:FindFirstChild("MesaPvE_Solo_1")
        or pastaMesas:FindFirstChild("MesaPvE_Solo_2")
        or pastaMesas:FindFirstChild("Mesa1")
        or pastaMesas:FindFirstChildWhichIsA("Model")
    if not mesaAlvo then return end

    local modeloMesa = mesaAlvo:FindFirstChild("Mesa")
    local tampo = modeloMesa and modeloMesa:FindFirstChild("Topo")
    if not tampo then return end

    local topoY = tampo.Position.Y + (tampo.Size.Y / 2)
    local centro = Vector3.new(tampo.Position.X, topoY, tampo.Position.Z)
    local camPos = centro + Vector3.new(6.8, 5.2, 3.8)
    local cfAlvo = CFrame.lookAt(camPos, centro + Vector3.new(0, -0.35, 0))

    cancelarTweenCamera()
    cam.CameraType = Enum.CameraType.Scriptable
    tweenCameraTutorial = TweenService:Create(
        cam,
        TweenInfo.new(0.85, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { CFrame = cfAlvo }
    )
    tweenCameraTutorial:Play()
end

local function restaurarCamera()
    cancelarTweenCamera()
    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
    end
end

local function definirVisibilidadeBaloesMesas(visivel)
    local pastaMesas = workspace:FindFirstChild("MesasFolder")
    if not pastaMesas then return end
    for _, desc in ipairs(pastaMesas:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Name == "BillboardStatusMesa" then
            desc.Enabled = visivel
        end
    end
end

-- ==========================================
-- SISTEMA DE SPOTLIGHT (VINHETA DE TELA INTEIRA) + HIGHLIGHT PULSANTE
-- ==========================================

local function criarVinhetaSpotlight()
    local function criarPainel(nome)
        local p = Instance.new("Frame")
        p.Name = nome
        p.BackgroundColor3 = Color3.new(0, 0, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.Visible = false
        p.Active = true -- bloqueia cliques fora da área recortada durante a ação
        p.ZIndex = 172
        p.Parent = camadaTutorial
        return p
    end

    vinhetaPaineis = {
        Top    = criarPainel("SpotlightTop"),
        Bottom = criarPainel("SpotlightBottom"),
        Left   = criarPainel("SpotlightLeft"),
        Right  = criarPainel("SpotlightRight"),
    }
end

local function cancelarTweensVinheta()
    for _, t in ipairs(vinhetaTweens) do
        t:Cancel()
    end
    table.clear(vinhetaTweens)
end

local function definirVinhetaAtiva(ligar)
    if not vinhetaPaineis then return end
    local novoEstado = (ligar == true)
    if vinhetaAtiva == novoEstado then return end
    vinhetaAtiva = novoEstado

    cancelarTweensVinheta()
    for _, painel in pairs(vinhetaPaineis) do
        if vinhetaAtiva then
            painel.Visible = true
            painel.BackgroundTransparency = 1
            local tw = TweenService:Create(
                painel,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = TRANSPARENCIA_VINHETA }
            )
            tw:Play()
            table.insert(vinhetaTweens, tw)
        else
            painel.Visible = false
            painel.BackgroundTransparency = 1
        end
    end
end

local function atualizarRecorteVinheta(x1, y1, x2, y2, telaW, telaH)
    if not vinhetaPaineis then return end
    if not vinhetaAtiva then
        for _, painel in pairs(vinhetaPaineis) do
            painel.Visible = false
        end
        return
    end

    local cx1 = math.clamp(math.floor(x1), 0, telaW)
    local cy1 = math.clamp(math.floor(y1), 0, telaH)
    local cx2 = math.clamp(math.ceil(x2), cx1, telaW)
    local cy2 = math.clamp(math.ceil(y2), cy1, telaH)
    local hMeio = math.max(0, cy2 - cy1)

    -- Topo: largura inteira, do y=0 até y=cy1
    vinhetaPaineis.Top.Position = UDim2.new(0, 0, 0, 0)
    vinhetaPaineis.Top.Size     = UDim2.new(0, telaW, 0, cy1)
    vinhetaPaineis.Top.Visible  = (cy1 > 0)

    -- Base: largura inteira, do y=cy2 até telaH
    local hBase = math.max(0, telaH - cy2)
    vinhetaPaineis.Bottom.Position = UDim2.new(0, 0, 0, cy2)
    vinhetaPaineis.Bottom.Size     = UDim2.new(0, telaW, 0, hBase)
    vinhetaPaineis.Bottom.Visible  = (hBase > 0)

    -- Esquerda: altura do recorte, do x=0 até x=cx1
    vinhetaPaineis.Left.Position = UDim2.new(0, 0, 0, cy1)
    vinhetaPaineis.Left.Size     = UDim2.new(0, cx1, 0, hMeio)
    vinhetaPaineis.Left.Visible  = (cx1 > 0 and hMeio > 0)

    -- Direita: altura do recorte, do x=cx2 até telaW
    local wDir = math.max(0, telaW - cx2)
    vinhetaPaineis.Right.Position = UDim2.new(0, cx2, 0, cy1)
    vinhetaPaineis.Right.Size     = UDim2.new(0, wDir, 0, hMeio)
    vinhetaPaineis.Right.Visible  = (wDir > 0 and hMeio > 0)
end

local function criarSlotHighlight(idx)
    local box = Instance.new("Frame")
    box.Name = "TutorialHighlight_" .. idx
    box.BackgroundColor3 = OURO_VIVO
    box.BackgroundTransparency = 0.92
    box.BorderSizePixel = 0
    box.Visible = false
    box.Active = false
    box.ZIndex = 175
    box.Parent = camadaTutorial
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", box)
    stroke.Color = OURO_VIVO
    stroke.Thickness = 3.8
    stroke.Transparency = 0.04

    local badge = Instance.new("Frame")
    badge.Name = "BadgeHighlight"
    badge.AutomaticSize = Enum.AutomaticSize.X
    badge.Size = UDim2.new(0, 0, 0, 30)
    badge.AnchorPoint = Vector2.new(0.5, 1)
    badge.Position = UDim2.new(0.5, 0, 0, -10)
    badge.BackgroundColor3 = Color3.fromRGB(20, 18, 10)
    badge.BackgroundTransparency = 0.03
    badge.BorderSizePixel = 0
    badge.ZIndex = 178
    badge.Parent = box
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    local strokeBadge = Instance.new("UIStroke", badge)
    strokeBadge.Color = OURO_VIVO
    strokeBadge.Thickness = 1.8

    local padBadge = Instance.new("UIPadding", badge)
    padBadge.PaddingLeft = UDim.new(0, 12)
    padBadge.PaddingRight = UDim.new(0, 12)
    padBadge.PaddingTop = UDim.new(0, 3)
    padBadge.PaddingBottom = UDim.new(0, 3)

    local badgeLbl = Instance.new("TextLabel")
    badgeLbl.Name = "TextoBadge"
    badgeLbl.AutomaticSize = Enum.AutomaticSize.X
    badgeLbl.Size = UDim2.new(0, 0, 1, 0)
    badgeLbl.BackgroundTransparency = 1
    badgeLbl.Text = ""
    badgeLbl.TextColor3 = OURO_VIVO
    badgeLbl.Font = Enum.Font.GothamBlack
    badgeLbl.TextSize = 14
    badgeLbl.ZIndex = 179
    badgeLbl.Parent = badge

    local tweenPulso = TweenService:Create(
        stroke,
        TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Thickness = 5.6, Transparency = 0.32 }
    )
    tweenPulso:Play()

    return {
        box = box,
        stroke = stroke,
        badge = badge,
        badgeLbl = badgeLbl,
        alvo = nil,
        tweenPulso = tweenPulso,
    }
end

local function atualizarPosicoesHighlights()
    if not ativo or not painelTela then return end
    local origemTela = painelTela.AbsolutePosition
    local tamanhoTela = painelTela.AbsoluteSize
    local recortePrincipal = nil

    for idx, slot in ipairs(highlightSlots) do
        local alvo = slot.alvo
        if alvo and alvo.Parent and alvo:IsA("GuiObject") and alvo.Visible then
            local absPos = alvo.AbsolutePosition
            local absSize = alvo.AbsoluteSize
            if absSize.X > 4 and absSize.Y > 4 then
                local pad = vinhetaAtiva and 8 or 6
                local relX = (absPos.X - origemTela.X) - pad
                local relY = (absPos.Y - origemTela.Y) - pad
                local larg = absSize.X + (pad * 2)
                local alt = absSize.Y + (pad * 2)

                slot.box.Position = UDim2.new(0, relX, 0, relY)
                slot.box.Size = UDim2.new(0, larg, 0, alt)
                slot.box.Visible = true

                if idx == 1 then
                    recortePrincipal = { relX, relY, relX + larg, relY + alt }
                end

                -- Mantém o badge sempre dentro da tela e longe do botão "Pular Tutorial"
                local anchorX = 0.5
                local posXScale = 0.5
                if (relX + larg) > (tamanhoTela.X - 125) then
                    anchorX = 1
                    posXScale = 1
                elseif relX < 105 then
                    anchorX = 0
                    posXScale = 0
                end

                if relY < 86 then
                    slot.badge.AnchorPoint = Vector2.new(anchorX, 0)
                    slot.badge.Position = UDim2.new(posXScale, 0, 1, 10)
                else
                    slot.badge.AnchorPoint = Vector2.new(anchorX, 1)
                    slot.badge.Position = UDim2.new(posXScale, 0, 0, -10)
                end
            else
                slot.box.Visible = false
            end
        else
            slot.box.Visible = false
        end
    end

    if vinhetaAtiva then
        if recortePrincipal then
            atualizarRecorteVinheta(
                recortePrincipal[1],
                recortePrincipal[2],
                recortePrincipal[3],
                recortePrincipal[4],
                tamanhoTela.X,
                tamanhoTela.Y
            )
        else
            atualizarRecorteVinheta(0, 0, 0, 0, tamanhoTela.X, tamanhoTela.Y)
        end
    end
end

local function definirHighlights(lista, comVinheta)
    for i, slot in ipairs(highlightSlots) do
        local item = lista and lista[i] or nil
        if item and item.alvo then
            slot.alvo = item.alvo
            local txt = item.texto or ""
            slot.badgeLbl.Text = txt
            slot.badge.Visible = (txt ~= "")
        else
            slot.alvo = nil
            slot.box.Visible = false
        end
    end

    definirVinhetaAtiva(comVinheta == true and lista ~= nil and #lista > 0)
    atualizarPosicoesHighlights()
end

local function limparHighlights()
    definirHighlights(nil, false)
end

-- ==========================================
-- CARD CENTRAL DA GUIA (copinhodecocacola)
-- ==========================================

local function calcularAlvoCardGuia()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local ehCompacto = (vp.X < 640 or vp.Y < 470)
    local ehMedio = (not ehCompacto) and (vp.X < 1000 or vp.Y < 600)

    local larg, alt, retrW, retrH, fontPasso, fontFala, fontBtn, fontPill, altBtn
    if ehCompacto then
        larg = math.clamp(math.floor(vp.X * 0.92), 300, 440)
        alt = 144
        retrW, retrH = 86, 110
        fontPasso, fontFala, fontBtn, fontPill, altBtn = 12, 14, 14, 12, 32
    elseif ehMedio then
        larg = math.clamp(math.floor(vp.X * 0.56), 440, 520)
        alt = 160
        retrW, retrH = 104, 130
        fontPasso, fontFala, fontBtn, fontPill, altBtn = 13, 16, 15, 13, 36
    else
        larg = math.clamp(math.floor(vp.X * 0.44), 500, 580)
        alt = 178
        retrW, retrH = 118, 144
        fontPasso, fontFala, fontBtn, fontPill, altBtn = 14, 18, 16, 14, 38
    end

    local posAlvo, anchorAlvo
    if posicaoCardModo == "topoCentro" then
        -- Centro-superior: deixa a carta jogada na mesa e o menu Aberta/Coberta 100% livres
        anchorAlvo = Vector2.new(0.5, 0)
        posAlvo = UDim2.new(0.5, 0, 0, ehCompacto and 46 or 54)
    elseif posicaoCardModo == "abaixoTruco" then
        -- Logo abaixo do modal de desafio de Truco, bem no centro visual da tela
        local yBase = math.floor(vp.Y * 0.43)
        if hooks and hooks.obterPainelTrucoUI then
            local painelTruco = hooks.obterPainelTrucoUI()
            if painelTruco and painelTruco.Visible and painelTruco.AbsoluteSize.Y > 20 and painelTela then
                local bottomTruco = (painelTruco.AbsolutePosition.Y - painelTela.AbsolutePosition.Y) + painelTruco.AbsoluteSize.Y
                yBase = math.min(bottomTruco + 18, math.floor(vp.Y * 0.52))
            end
        end
        anchorAlvo = Vector2.new(0.5, 0)
        posAlvo = UDim2.new(0.5, 0, 0, yBase)
    else
        -- Centro da tela (acima do leque de cartas)
        anchorAlvo = Vector2.new(0.5, 0.5)
        posAlvo = UDim2.new(0.5, 0, 0.42, 0)
    end

    return {
        size = UDim2.new(0, larg, 0, alt),
        pos = posAlvo,
        anchor = anchorAlvo,
        retrW = retrW,
        retrH = retrH,
        fontPasso = fontPasso,
        fontFala = fontFala,
        fontBtn = fontBtn,
        fontPill = fontPill,
        altBtn = altBtn,
    }
end

local function atualizarLayoutResponsivo(animarPosicao)
    if not cardGuia then return end
    local cfg = calcularAlvoCardGuia()
    local conteudoFala = cardGuia:FindFirstChild("ConteudoFala")

    cardGuia.Size = cfg.size
    cardGuia.AnchorPoint = cfg.anchor

    if tweenPosCard then
        tweenPosCard:Cancel()
        tweenPosCard = nil
    end
    if animarPosicao and cardGuia.Visible then
        tweenPosCard = TweenService:Create(
            cardGuia,
            TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = cfg.pos }
        )
        tweenPosCard:Play()
    else
        cardGuia.Position = cfg.pos
    end

    if retratoGuia and retratoGuia.Container then
        retratoGuia.Container.Size = UDim2.new(0, cfg.retrW, 0, cfg.retrH)
    end
    if conteudoFala then
        local xTexto = cfg.retrW + 24
        conteudoFala.Size = UDim2.new(1, -(xTexto + 14), 1, -22)
        conteudoFala.Position = UDim2.new(0, xTexto, 0, 16)
    end

    if lblPassoGuia then lblPassoGuia.TextSize = cfg.fontPasso end
    if lblFalaGuia then
        lblFalaGuia.TextSize = cfg.fontFala
        lblFalaGuia.Size = UDim2.new(1, 0, 1, -(cfg.altBtn + 28))
    end
    if btnContinuarGuia then
        btnContinuarGuia.Size = UDim2.new(1, 0, 0, cfg.altBtn)
        btnContinuarGuia.TextSize = cfg.fontBtn
    end
    if pillAcaoGuia then
        pillAcaoGuia.Size = UDim2.new(1, 0, 0, math.max(28, cfg.altBtn - 6))
        pillAcaoGuia.TextSize = cfg.fontPill
    end
end

local function definirPosicaoCard(modo, animar)
    posicaoCardModo = modo or "centro"
    atualizarLayoutResponsivo(animar ~= false)
end

local function atualizarFalaGuia(passoNum, tituloPasso, fala, textoBotaoContinuar, callbackContinuar, textoAcaoInterativa, modoPosicao)
    if not cardGuia then return end

    if modoPosicao then
        definirPosicaoCard(modoPosicao, cardGuia.Visible)
    end

    cardGuia.Visible = true
    lblPassoGuia.Text = string.format("PASSO %d/%d  •  %s", passoNum, TOTAL_PASSOS, string.upper(tituloPasso))
    lblFalaGuia.Text = fala

    local frac = math.clamp(passoNum / TOTAL_PASSOS, 0.08, 1)
    TweenService:Create(barraProgresso, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(frac, 0, 1, 0),
    }):Play()

    onContinuarCallback = callbackContinuar

    if callbackContinuar then
        btnContinuarGuia.Visible = true
        btnContinuarGuia.Text = textoBotaoContinuar or "CONTINUAR >"
        pillAcaoGuia.Visible = false
    else
        btnContinuarGuia.Visible = false
        pillAcaoGuia.Visible = (textoAcaoInterativa ~= nil and textoAcaoInterativa ~= "")
        if pillAcaoGuia.Visible then
            pillAcaoGuia.Text = textoAcaoInterativa
        end
    end

    if retratoGuia then
        retratoGuia:PulsarFala()
    end
end

local function criarUI()
    if camadaTutorial then return end

    camadaTutorial = Instance.new("Frame")
    camadaTutorial.Name = "CamadaTutorialInterativo"
    camadaTutorial.Size = UDim2.new(1, 0, 1, 0)
    camadaTutorial.BackgroundTransparency = 1
    camadaTutorial.Visible = false
    camadaTutorial.ZIndex = 170
    camadaTutorial.Parent = painelTela

    -- Máscara de vinheta escura (4 painéis recortando apenas onde o jogador precisa clicar)
    criarVinhetaSpotlight()

    -- 2 slots de highlight simultâneos (ex.: Vira + Carta Manilha)
    table.insert(highlightSlots, criarSlotHighlight(1))
    table.insert(highlightSlots, criarSlotHighlight(2))

    -- Botão discreto de pular no topo direito (sempre acessível acima da vinheta)
    btnPularTopo = Instance.new("TextButton")
    btnPularTopo.Name = "BtnPularTutorialTopo"
    btnPularTopo.Size = UDim2.new(0, 152, 0, 36)
    btnPularTopo.Position = UDim2.new(1, -16, 0, 12)
    btnPularTopo.AnchorPoint = Vector2.new(1, 0)
    btnPularTopo.BackgroundColor3 = BG_ESCURO
    btnPularTopo.BackgroundTransparency = 0.08
    btnPularTopo.Text = "⏭ Pular Tutorial"
    btnPularTopo.TextColor3 = TEXTO_SEC
    btnPularTopo.Font = Enum.Font.GothamBold
    btnPularTopo.TextSize = 14
    btnPularTopo.AutoButtonColor = true
    btnPularTopo.ZIndex = 190
    btnPularTopo.Parent = camadaTutorial
    Instance.new("UICorner", btnPularTopo).CornerRadius = UDim.new(1, 0)

    local strokePular = Instance.new("UIStroke", btnPularTopo)
    strokePular.Color = Color3.fromRGB(105, 105, 128)
    strokePular.Thickness = 1.4

    btnPularTopo.Activated:Connect(function()
        if hooks and hooks.marcarTutorialVisto then
            hooks.marcarTutorialVisto()
        end
        TutorialMatch.Encerrar()
    end)

    -- Card Central Grande da Guia (copinhodecocacola)
    cardGuia = Instance.new("Frame")
    cardGuia.Name = "CardGuiaTutorial"
    cardGuia.Size = UDim2.new(0, 540, 0, 178)
    cardGuia.Position = UDim2.new(0.5, 0, 0.42, 0)
    cardGuia.AnchorPoint = Vector2.new(0.5, 0.5)
    cardGuia.BackgroundColor3 = BG_ESCURO
    cardGuia.BackgroundTransparency = 0.04
    cardGuia.BorderSizePixel = 0
    cardGuia.Active = true
    cardGuia.ZIndex = 180
    cardGuia.Parent = camadaTutorial
    Instance.new("UICorner", cardGuia).CornerRadius = UDim.new(0, 18)

    local strokeCard = Instance.new("UIStroke", cardGuia)
    strokeCard.Color = ACENTO
    strokeCard.Thickness = 2.4
    strokeCard.Transparency = 0.08

    -- Trilho de progresso no topo do card
    local trilhoProg = Instance.new("Frame")
    trilhoProg.Name = "TrilhoProgresso"
    trilhoProg.Size = UDim2.new(1, -28, 0, 5)
    trilhoProg.Position = UDim2.new(0, 14, 0, 7)
    trilhoProg.BackgroundColor3 = Color3.fromRGB(48, 48, 64)
    trilhoProg.BorderSizePixel = 0
    trilhoProg.ZIndex = 181
    trilhoProg.Parent = cardGuia
    Instance.new("UICorner", trilhoProg).CornerRadius = UDim.new(1, 0)

    barraProgresso = Instance.new("Frame")
    barraProgresso.Name = "BarraProgresso"
    barraProgresso.Size = UDim2.new(0.16, 0, 1, 0)
    barraProgresso.BackgroundColor3 = ACENTO
    barraProgresso.BorderSizePixel = 0
    barraProgresso.ZIndex = 182
    barraProgresso.Parent = trilhoProg
    Instance.new("UICorner", barraProgresso).CornerRadius = UDim.new(1, 0)

    -- Retrato 3D da personagem da barraca do tutorial (copinhodecocacola)
    retratoGuia = GuideAvatar.CriarRetrato(cardGuia, {
        Name = "RetratoCopinhoGuia",
        Size = UDim2.new(0, 118, 0, 144),
        Position = UDim2.new(0, 12, 0.5, 4),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 182,
        MostrarTag = true,
        DistanciaCamera = 3.9,
        FieldOfView = 36,
    })

    -- Área de texto e botão à direita do retrato
    local conteudoTexto = Instance.new("Frame")
    conteudoTexto.Name = "ConteudoFala"
    conteudoTexto.Size = UDim2.new(1, -156, 1, -22)
    conteudoTexto.Position = UDim2.new(0, 142, 0, 16)
    conteudoTexto.BackgroundTransparency = 1
    conteudoTexto.ZIndex = 182
    conteudoTexto.Parent = cardGuia

    lblPassoGuia = Instance.new("TextLabel")
    lblPassoGuia.Name = "LblPasso"
    lblPassoGuia.Size = UDim2.new(1, 0, 0, 22)
    lblPassoGuia.Position = UDim2.new(0, 0, 0, 0)
    lblPassoGuia.BackgroundTransparency = 1
    lblPassoGuia.Text = "PASSO 1/6 • O OBJETIVO"
    lblPassoGuia.TextColor3 = ACENTO
    lblPassoGuia.Font = Enum.Font.GothamBlack
    lblPassoGuia.TextSize = 14
    lblPassoGuia.TextXAlignment = Enum.TextXAlignment.Left
    lblPassoGuia.TextTruncate = Enum.TextTruncate.AtEnd
    lblPassoGuia.ZIndex = 183
    lblPassoGuia.Parent = conteudoTexto

    lblFalaGuia = Instance.new("TextLabel")
    lblFalaGuia.Name = "LblFala"
    lblFalaGuia.Size = UDim2.new(1, 0, 1, -66)
    lblFalaGuia.Position = UDim2.new(0, 0, 0, 23)
    lblFalaGuia.BackgroundTransparency = 1
    lblFalaGuia.Text = ""
    lblFalaGuia.TextColor3 = TEXTO_PRIM
    lblFalaGuia.Font = Enum.Font.GothamMedium
    lblFalaGuia.TextSize = 18
    lblFalaGuia.TextWrapped = true
    lblFalaGuia.TextXAlignment = Enum.TextXAlignment.Left
    lblFalaGuia.TextYAlignment = Enum.TextYAlignment.Top
    lblFalaGuia.ZIndex = 183
    lblFalaGuia.Parent = conteudoTexto

    btnContinuarGuia = Instance.new("TextButton")
    btnContinuarGuia.Name = "BtnContinuarGuia"
    btnContinuarGuia.Size = UDim2.new(1, 0, 0, 38)
    btnContinuarGuia.Position = UDim2.new(0, 0, 1, -2)
    btnContinuarGuia.AnchorPoint = Vector2.new(0, 1)
    btnContinuarGuia.BackgroundColor3 = VERDE
    btnContinuarGuia.Text = "CONTINUAR >"
    btnContinuarGuia.TextColor3 = TEXTO_PRIM
    btnContinuarGuia.Font = Enum.Font.GothamBlack
    btnContinuarGuia.TextSize = 16
    btnContinuarGuia.AutoButtonColor = true
    btnContinuarGuia.Visible = false
    btnContinuarGuia.ZIndex = 185
    btnContinuarGuia.Parent = conteudoTexto
    Instance.new("UICorner", btnContinuarGuia).CornerRadius = UDim.new(0, 10)

    btnContinuarGuia.Activated:Connect(function()
        local cb = onContinuarCallback
        onContinuarCallback = nil
        if cb then cb() end
    end)

    pillAcaoGuia = Instance.new("TextLabel")
    pillAcaoGuia.Name = "PillAcao"
    pillAcaoGuia.Size = UDim2.new(1, 0, 0, 32)
    pillAcaoGuia.Position = UDim2.new(0, 0, 1, -2)
    pillAcaoGuia.AnchorPoint = Vector2.new(0, 1)
    pillAcaoGuia.BackgroundColor3 = Color3.fromRGB(48, 38, 14)
    pillAcaoGuia.BackgroundTransparency = 0.08
    pillAcaoGuia.Text = "👆 Faça a ação destacada"
    pillAcaoGuia.TextColor3 = OURO_VIVO
    pillAcaoGuia.Font = Enum.Font.GothamBold
    pillAcaoGuia.TextSize = 14
    pillAcaoGuia.Visible = false
    pillAcaoGuia.ZIndex = 184
    pillAcaoGuia.Parent = conteudoTexto
    Instance.new("UICorner", pillAcaoGuia).CornerRadius = UDim.new(0, 9)
    local strokePill = Instance.new("UIStroke", pillAcaoGuia)
    strokePill.Color = ACENTO
    strokePill.Thickness = 1.2

    -- Modal Final de Conclusão do Tutorial
    modalConclusao = Instance.new("Frame")
    modalConclusao.Name = "ModalConclusaoTutorial"
    modalConclusao.Size = UDim2.new(0.92, 0, 0, 340)
    modalConclusao.Position = UDim2.new(0.5, 0, 0.5, 0)
    modalConclusao.AnchorPoint = Vector2.new(0.5, 0.5)
    modalConclusao.BackgroundColor3 = BG_ESCURO
    modalConclusao.Visible = false
    modalConclusao.ZIndex = 195
    modalConclusao.Parent = camadaTutorial
    Instance.new("UICorner", modalConclusao).CornerRadius = UDim.new(0, 18)

    local sizeCons = Instance.new("UISizeConstraint", modalConclusao)
    sizeCons.MaxSize = Vector2.new(520, 360)

    local strokeFim = Instance.new("UIStroke", modalConclusao)
    strokeFim.Color = ACENTO
    strokeFim.Thickness = 2.2

    retratoConclusao = GuideAvatar.CriarRetrato(modalConclusao, {
        Name = "RetratoConclusao",
        Size = UDim2.new(0, 122, 0, 146),
        Position = UDim2.new(0, 18, 0, 22),
        AnchorPoint = Vector2.new(0, 0),
        ZIndex = 196,
        MostrarTag = true,
        DistanciaCamera = 3.85,
        FieldOfView = 36,
    })

    local tituloFim = Instance.new("TextLabel", modalConclusao)
    tituloFim.Size = UDim2.new(1, -166, 0, 36)
    tituloFim.Position = UDim2.new(0, 152, 0, 22)
    tituloFim.BackgroundTransparency = 1
    tituloFim.Text = "🎉 TUTORIAL CONCLUÍDO!"
    tituloFim.TextColor3 = OURO_VIVO
    tituloFim.Font = Enum.Font.GothamBlack
    tituloFim.TextSize = 22
    tituloFim.TextXAlignment = Enum.TextXAlignment.Left
    tituloFim.TextScaled = true
    tituloFim.ZIndex = 197
    Instance.new("UITextSizeConstraint", tituloFim).MaxTextSize = 23

    local textoFim = Instance.new("TextLabel", modalConclusao)
    textoFim.Size = UDim2.new(1, -166, 0, 112)
    textoFim.Position = UDim2.new(0, 152, 0, 62)
    textoFim.BackgroundTransparency = 1
    textoFim.Text = "Mandou bem demais! Agora você já sabe identificar Manilhas, jogar cartas, gritar TRUCO e puxar SEIS!\n\nQue tal testar tudo em uma partida real contra bots na Mesa Solo?"
    textoFim.TextColor3 = TEXTO_PRIM
    textoFim.Font = Enum.Font.GothamMedium
    textoFim.TextSize = 16
    textoFim.TextWrapped = true
    textoFim.TextXAlignment = Enum.TextXAlignment.Left
    textoFim.TextYAlignment = Enum.TextYAlignment.Top
    textoFim.ZIndex = 197

    local btnIrSolo = Instance.new("TextButton", modalConclusao)
    btnIrSolo.Name = "BtnIrMesaSoloFim"
    btnIrSolo.Size = UDim2.new(1, -36, 0, 46)
    btnIrSolo.Position = UDim2.new(0.5, 0, 1, -116)
    btnIrSolo.AnchorPoint = Vector2.new(0.5, 0)
    btnIrSolo.BackgroundColor3 = VERDE
    btnIrSolo.Text = "🤖 JOGAR NA MESA SOLO (1v3)"
    btnIrSolo.TextColor3 = TEXTO_PRIM
    btnIrSolo.Font = Enum.Font.GothamBlack
    btnIrSolo.TextSize = 16
    btnIrSolo.AutoButtonColor = true
    btnIrSolo.ZIndex = 197
    Instance.new("UICorner", btnIrSolo).CornerRadius = UDim.new(0, 10)
    btnIrSolo.Activated:Connect(function()
        TutorialMatch.Encerrar()
        if hooks and hooks.irParaMesaSolo then
            hooks.irParaMesaSolo()
        end
    end)

    local btnRegras = Instance.new("TextButton", modalConclusao)
    btnRegras.Name = "BtnVerRegrasFim"
    btnRegras.Size = UDim2.new(0.47, -14, 0, 40)
    btnRegras.Position = UDim2.new(0, 18, 1, -58)
    btnRegras.BackgroundColor3 = AZUL
    btnRegras.Text = "📖 GUIA DE REGRAS"
    btnRegras.TextColor3 = TEXTO_PRIM
    btnRegras.Font = Enum.Font.GothamBold
    btnRegras.TextSize = 14
    btnRegras.AutoButtonColor = true
    btnRegras.ZIndex = 197
    Instance.new("UICorner", btnRegras).CornerRadius = UDim.new(0, 10)
    btnRegras.Activated:Connect(function()
        TutorialMatch.Encerrar()
        if hooks and hooks.abrirSlidesRegras then
            hooks.abrirSlidesRegras()
        end
    end)

    local btnLobby = Instance.new("TextButton", modalConclusao)
    btnLobby.Name = "BtnVoltarLobbyFim"
    btnLobby.Size = UDim2.new(0.47, -14, 0, 40)
    btnLobby.Position = UDim2.new(1, -18, 1, -58)
    btnLobby.AnchorPoint = Vector2.new(1, 0)
    btnLobby.BackgroundColor3 = BG_BOTAO
    btnLobby.Text = "VOLTAR AO LOBBY"
    btnLobby.TextColor3 = TEXTO_PRIM
    btnLobby.Font = Enum.Font.GothamBold
    btnLobby.TextSize = 14
    btnLobby.AutoButtonColor = true
    btnLobby.ZIndex = 197
    Instance.new("UICorner", btnLobby).CornerRadius = UDim.new(0, 10)
    btnLobby.Activated:Connect(function()
        TutorialMatch.Encerrar()
    end)

    atualizarLayoutResponsivo(false)
    if workspace.CurrentCamera and not connViewport then
        connViewport = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            atualizarLayoutResponsivo(false)
        end)
    end
end

-- ==========================================
-- ROTEIRO DA PARTIDA TUTORIAL SCRIPTADA
-- ==========================================

local function esperar(segundos, minhaSessao)
    task.wait(segundos)
    return ativo and sessaoId == minhaSessao
end

local function finalizarComCelebracao(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "CONCLUIDO"
    limparHighlights()
    hooks.definirBtnTruco(false)
    hooks.ocultarDesafioTruco()
    hooks.limparMao()
    hooks.limparMesa()
    hooks.definirFiltroCliqueCarta(nil)

    if hooks.marcarTutorialVisto then
        hooks.marcarTutorialVisto()
    end

    cardGuia.Visible = false
    btnPularTopo.Visible = false
    modalConclusao.Visible = true
    if retratoConclusao then
        retratoConclusao:PulsarFala()
    end
    hooks.tocarSom("Victory")
end

local function iniciarMao2Scriptada(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "MAO2_INTRO"
    limparHighlights()
    hooks.limparMao()
    hooks.limparMesa()
    hooks.definirBtnTruco(false)
    hooks.tocarSom("Shuffle")

    -- Mão 2: Vira = A de Espadas -> Manilha = 2!
    hooks.definirVira("A", "Espadas")
    hooks.atualizarValorRodada(1)
    hooks.atualizarEstatisticas("Bot Parceiro", 0, 0, {})
    hooks.atualizarStatus("Mão 2 — Nova Vira!", Color3.fromRGB(255, 255, 255))

    hooks.adicionarCartaMao({ idUnico = "2_Copas", Value = "2", Suit = "Copas", ManilhaStrength = 3 })
    hooks.adicionarCartaMao({ idUnico = "3_Paus",  Value = "3", Suit = "Paus",  ManilhaStrength = 0 })
    hooks.adicionarCartaMao({ idUnico = "K_Ouros", Value = "K", Suit = "Ouros", ManilhaStrength = 0 })

    hooks.definirEstadoMao(false, 1, false)
    hooks.definirFiltroCliqueCarta(function() return false end)

    local cartaCopas = hooks.obterElementoCarta("2_Copas")
    definirHighlights({
        { alvo = hooks.obterPainelVira(), texto = "👀 NOVA MANILHA: 2" },
        { alvo = cartaCopas,              texto = "✨ COPAS ♥️!" },
    }, false)

    atualizarFalaGuia(
        6,
        "PUXANDO UM SEIS!",
        "Nova Mão! A Vira virou Ás, então a Manilha agora é 2 — e seu 2 de Copas já brilhou! Espera... o Rival vai falar!",
        nil,
        nil,
        "⏳ Aguarde o Rival...",
        "centro"
    )

    if not esperar(2.1, minhaSessao) then return end

    -- Bot Rival 1 grita TRUCO! (3 pontos) -> Jogador vai puxar SEIS!
    etapaAtual = "AGUARDANDO_PUXAR_SEIS"
    hooks.tocarSom("Truco")
    hooks.atualizarStatus("TRUCO! Vale 3", Color3.fromRGB(255, 210, 70))

    hooks.mostrarDesafioTruco(3, "Bot Rival 1", function(resposta)
        if not ativo or sessaoId ~= minhaSessao or etapaAtual ~= "AGUARDANDO_PUXAR_SEIS" then return end
        if resposta ~= "Aumentar" then return end

        etapaAtual = "SEIS_ENVIADO"
        limparHighlights()
        hooks.ocultarDesafioTruco()
        hooks.tocarSom("Truco")
        hooks.atualizarValorRodada(3)
        hooks.atualizarStatus("SEIS!! Vale 6", Color3.fromRGB(255, 215, 60))

        atualizarFalaGuia(
            6,
            "SEEEIS!!",
            "ISSO AÍ!! Você puxou SEIS (6 pontos)! Agora o rival precisa aceitar, aumentar pra 9 ou correr...",
            nil,
            nil,
            "⏳ Rivais decidindo...",
            "centro"
        )

        task.spawn(function()
            if not esperar(1.6, minhaSessao) then return end
            hooks.tocarSom("TrucoFlee")
            hooks.mostrarAvisoFuga("Bot Rival 1 e Bot Rival 2 correram!")
            hooks.atualizarPlacar(6, 0)
            hooks.atualizarStatus("Rivais correram! +3 pontos", Color3.fromRGB(115, 240, 155))

            atualizarFalaGuia(
                6,
                "ELES CORRERAM!",
                "Eles fugiram com medo do seu SEIS! Quando o rival corre, sua dupla ganha os pontos anteriores (+3 pts → Placar 6 x 0)!",
                "FINALIZAR >",
                function()
                    finalizarComCelebracao(minhaSessao)
                end,
                nil,
                "centro"
            )
        end)
    end, "Aumentar")

    task.defer(function()
        if not ativo or sessaoId ~= minhaSessao then return end
        local btnSeis = hooks.obterBotaoTrucoUI("AumentarBtn")
        -- Spotlight de tela inteira recortando apenas o botão 6!
        definirHighlights({
            { alvo = btnSeis, texto = "⚡ CLIQUE EM 6!" },
        }, true)
        definirPosicaoCard("abaixoTruco", true)
    end)

    atualizarFalaGuia(
        6,
        "PUXANDO UM SEIS!",
        "O Rival gritou TRUCO! Como você tem Manilha de Copas e um 3, dá pra retrucar! Clique em 6! para puxar SEIS!",
        nil,
        nil,
        "⚡ Clique no botão 6! destacado acima",
        "abaixoTruco"
    )
end

local function iniciarEtapa5JogarZap(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "AGUARDANDO_CLIQUE_ZAP"

    hooks.definirBtnTruco(false)
    hooks.definirEstadoMao(true, 2, false)
    hooks.definirFiltroCliqueCarta(function(card)
        return card and card.idUnico == "6_Paus"
    end)
    hooks.atualizarStatus("SUA VEZ! Jogue o ZAP!", Color3.fromRGB(255, 235, 65))

    local btnZap = hooks.obterElementoCarta("6_Paus")
    -- Spotlight de tela inteira recortando apenas o ZAP ♣️
    definirHighlights({
        { alvo = btnZap, texto = "👇 CLIQUE NO ZAP ♣️" },
    }, true)

    atualizarFalaGuia(
        5,
        "JOGANDO A MANILHA",
        "Eles aceitaram por 3 pontos! Na 2ª queda você pode jogar Aberta ou Coberta. Clique no seu ZAP (6 de Paus)!",
        nil,
        nil,
        "👆 Clique no 6 de Paus (ZAP ♣️)",
        "topoCentro"
    )
end

local function iniciarEtapa4GritarTruco(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "AGUARDANDO_BOTAO_TRUCO"

    hooks.definirEstadoMao(true, 2, false)
    hooks.definirFiltroCliqueCarta(function() return false end)
    hooks.definirBtnTruco(true, "TRUCO!")
    hooks.atualizarStatus("SUA VEZ! Grite TRUCO!", Color3.fromRGB(255, 225, 60))

    -- Spotlight de tela inteira recortando apenas o botão TRUCO!
    definirHighlights({
        { alvo = hooks.obterBtnTruco(), texto = "🔥 CLIQUE EM TRUCO!" },
    }, true)

    atualizarFalaGuia(
        4,
        "GRITANDO TRUCO!",
        "Você levou a 1ª queda e ainda tem o ZAP na mão! Clique em TRUCO! para aumentar esta Mão de 1 para 3 pontos!",
        nil,
        nil,
        "🔥 Clique no botão vermelho TRUCO!",
        "centro"
    )
end

local function iniciarEtapa3PrimeiraJogada(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "PREPARANDO_QUEDA1"
    limparHighlights()

    atualizarFalaGuia(
        3,
        "1ª QUEDA — SUA VEZ",
        "Bot Rival 1 começou jogando um 2 de Paus na mesa...",
        nil,
        nil,
        "⏳ Aguarde a jogada...",
        "topoCentro"
    )

    task.spawn(function()
        if not esperar(0.65, minhaSessao) then return end
        hooks.adicionarCartaMesa("Bot Rival 1", "2", "Paus", false)
        hooks.tocarSom("CardPlay")

        if not esperar(0.5, minhaSessao) then return end

        etapaAtual = "AGUARDANDO_JOGAR_3"
        hooks.definirEstadoMao(true, 1, false)
        hooks.definirFiltroCliqueCarta(function(card)
            return card and card.idUnico == "3_Copas"
        end)
        hooks.atualizarStatus("SUA VEZ!", Color3.fromRGB(255, 255, 0))

        local btnTres = hooks.obterElementoCarta("3_Copas")
        -- Spotlight de tela inteira recortando apenas o 3 de Copas
        definirHighlights({
            { alvo = btnTres, texto = "👇 CLIQUE NO 3 DE COPAS" },
        }, true)

        atualizarFalaGuia(
            3,
            "1ª QUEDA — SUA VEZ",
            "Na ordem normal (4..7, Q, J, K, A, 2, 3), o 3 vence do 2! Clique no seu 3 de Copas para vencer e economizar o ZAP.",
            nil,
            nil,
            "👆 Clique no 3 de Copas destacado embaixo",
            "topoCentro"
        )
    end)
end

local function iniciarEtapa2Manilhas(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "PASSO2_MANILHAS"

    local btnZap = hooks.obterElementoCarta("6_Paus")
    definirHighlights({
        { alvo = hooks.obterPainelVira(), texto = "👀 VIRA = 5 → MANILHA = 6" },
        { alvo = btnZap,                  texto = "✨ SEU ZAP ♣️!" },
    }, false)

    atualizarFalaGuia(
        2,
        "A VIRA E AS MANILHAS",
        "A Vira é 5, então todo 6 vira MANILHA (a carta logo acima)! Seu 6 de Paus já brilha dourado — é o ZAP, a carta mais forte do jogo!",
        "ENTENDI! >",
        function()
            iniciarEtapa3PrimeiraJogada(minhaSessao)
        end,
        nil,
        "centro"
    )
end

local function iniciarEtapa1Objetivo(minhaSessao)
    if not ativo or sessaoId ~= minhaSessao then return end
    etapaAtual = "PASSO1_OBJETIVO"

    hooks.tocarSom("Shuffle")
    hooks.atualizarPlacar(0, 0)
    hooks.atualizarValorRodada(1)
    hooks.atualizarEstatisticas("Bot Parceiro", 0, 0, {})
    hooks.atualizarStatus("Partida Tutorial", Color3.fromRGB(255, 255, 255))

    -- Mão 1: Vira = 5 de Ouros -> Manilha = 6
    hooks.definirVira("5", "Ouros")
    hooks.limparMao()
    hooks.limparMesa()
    hooks.definirBtnTruco(false)

    hooks.adicionarCartaMao({ idUnico = "6_Paus",    Value = "6", Suit = "Paus",    ManilhaStrength = 4 })
    hooks.adicionarCartaMao({ idUnico = "3_Copas",   Value = "3", Suit = "Copas",   ManilhaStrength = 0 })
    hooks.adicionarCartaMao({ idUnico = "4_Espadas", Value = "4", Suit = "Espadas", ManilhaStrength = 0 })

    hooks.definirEstadoMao(false, 1, false)
    hooks.definirFiltroCliqueCarta(function() return false end)

    definirHighlights({
        { alvo = hooks.obterContainerInfo(), texto = "👀 DUPLA, QUEDAS E PLACAR" },
    }, false)

    atualizarFalaGuia(
        1,
        "O OBJETIVO",
        "Oi! Vou te ensinar Truco Paulista rapidinho! Você joga em dupla com o Bot Parceiro: vença 2 de 3 quedas pra levar a Mão e some 12 pontos!",
        "CONTINUAR >",
        function()
            iniciarEtapa2Manilhas(minhaSessao)
        end,
        nil,
        "centro"
    )
end

-- ==========================================
-- HANDLERS DE AÇÕES DO JOGADOR NA PARTIDA TUTORIAL
-- ==========================================

local function aoJogadorJogarCarta(cardId, escondida)
    if not ativo then return end
    local minhaSessao = sessaoId

    if etapaAtual == "AGUARDANDO_JOGAR_3" and cardId == "3_Copas" then
        etapaAtual = "RESOLVENDO_QUEDA1"
        limparHighlights()
        hooks.definirEstadoMao(false, 1, false)
        hooks.definirFiltroCliqueCarta(function() return false end)

        hooks.adicionarCartaMesa(jogadorLocal.Name, "3", "Copas", false)
        hooks.tocarSom("CardPlay")
        hooks.atualizarStatus("Vez dos Bots...", Color3.fromRGB(255, 255, 255))

        atualizarFalaGuia(
            3,
            "BOA JOGADA!",
            "Boa! Seu 3 de Copas assumiu a liderança. Vamos ver o que o resto da mesa joga...",
            nil,
            nil,
            "⏳ Aguardando bots...",
            "topoCentro"
        )

        task.spawn(function()
            if not esperar(0.65, minhaSessao) then return end
            hooks.adicionarCartaMesa("Bot Rival 2", "Q", "Copas", false)
            hooks.tocarSom("CardPlay")

            if not esperar(0.65, minhaSessao) then return end
            hooks.adicionarCartaMesa("Bot Parceiro", "7", "Paus", false)
            hooks.tocarSom("CardPlay")

            if not esperar(0.85, minhaSessao) then return end
            hooks.tocarSom("RoundWin")
            hooks.atualizarEstatisticas("Bot Parceiro", 1, 0, { "NOS" })
            hooks.limparMesa()
            hooks.atualizarStatus("Sua dupla venceu a 1ª queda!", Color3.fromRGB(115, 240, 155))

            if not esperar(0.8, minhaSessao) then return end
            iniciarEtapa4GritarTruco(minhaSessao)
        end)

    elseif etapaAtual == "AGUARDANDO_CLIQUE_ZAP" and cardId == "6_Paus" then
        etapaAtual = "RESOLVENDO_QUEDA2"
        limparHighlights()
        hooks.definirEstadoMao(false, 2, false)
        hooks.definirFiltroCliqueCarta(function() return false end)

        hooks.adicionarCartaMesa(jogadorLocal.Name, "6", "Paus", escondida == true)
        hooks.tocarSom("ZapImpact")
        hooks.atualizarStatus("ZAP NA MESA!!", Color3.fromRGB(255, 225, 70))

        atualizarFalaGuia(
            5,
            "ZAP NA MESA!!",
            "BOAA!! O 6 de Paus (ZAP) bate qualquer carta — até as outras Manilhas (Paus > Copas > Espadas > Ouros)!",
            nil,
            nil,
            "⏳ Fechando a Mão...",
            "topoCentro"
        )

        task.spawn(function()
            if not esperar(0.65, minhaSessao) then return end
            hooks.adicionarCartaMesa("Bot Rival 2", "6", "Ouros", false)
            hooks.tocarSom("ZapImpact")

            if not esperar(0.65, minhaSessao) then return end
            hooks.adicionarCartaMesa("Bot Parceiro", "Q", "Ouros", false)
            hooks.tocarSom("CardPlay")

            if not esperar(0.65, minhaSessao) then return end
            hooks.adicionarCartaMesa("Bot Rival 1", "K", "Espadas", false)
            hooks.tocarSom("CardPlay")

            if not esperar(0.95, minhaSessao) then return end
            hooks.tocarSom("RoundWin")
            hooks.atualizarEstatisticas("Bot Parceiro", 2, 0, { "NOS", "NOS" })
            hooks.limparMesa()
            hooks.limparMao()
            hooks.atualizarPlacar(3, 0)
            hooks.mostrarVencedorRodada("Você e Bot Parceiro ganharam a Mão! (+3)")

            if not esperar(2.2, minhaSessao) then return end
            iniciarMao2Scriptada(minhaSessao)
        end)
    end
end

local function aoJogadorPedirTruco()
    if not ativo or etapaAtual ~= "AGUARDANDO_BOTAO_TRUCO" then return end
    local minhaSessao = sessaoId
    etapaAtual = "RESOLVENDO_TRUCO_1"
    limparHighlights()

    hooks.definirBtnTruco(false)
    hooks.tocarSom("Truco")
    hooks.atualizarStatus("TRUCO! Vale 3", Color3.fromRGB(255, 215, 65))

    atualizarFalaGuia(
        4,
        "TRUCO PEDIDO!",
        "TRUUUCO!! Você desafiou os bots por 3 pontos. Eles podem Aceitar (Descer), Fugir ou Aumentar pra 6...",
        nil,
        nil,
        "⏳ Rivais respondendo...",
        "centro"
    )

    task.spawn(function()
        if not esperar(1.4, minhaSessao) then return end
        hooks.tocarSom("TrucoAccept")
        hooks.atualizarValorRodada(3)
        hooks.atualizarStatus("TRUCO ACEITO! Vale 3", Color3.fromRGB(115, 240, 155))

        if not esperar(0.85, minhaSessao) then return end
        iniciarEtapa5JogarZap(minhaSessao)
    end)
end

local function aoOpcoesJogadaAbertas(painelOpcoes)
    if not ativo or etapaAtual ~= "AGUARDANDO_CLIQUE_ZAP" or not painelOpcoes then return end

    local btnAberta = painelOpcoes:FindFirstChild("BtnJogarAberta")
    local btnCoberta = painelOpcoes:FindFirstChild("BtnJogarCoberta")

    for _, filho in ipairs(painelOpcoes:GetChildren()) do
        if filho:IsA("TextButton") then
            if not btnAberta and string.find(string.upper(filho.Text), "ABERTA") then
                btnAberta = filho
            elseif not btnCoberta and string.find(string.upper(filho.Text), "COBERT") then
                btnCoberta = filho
            end
        end
    end

    if btnCoberta then
        btnCoberta:SetAttribute("BloqueadoTutorial", true)
        pcall(function() btnCoberta.Interactable = false end)
        btnCoberta.Active = false
        btnCoberta.BackgroundTransparency = 0.6
        btnCoberta.TextTransparency = 0.45
    end

    if btnAberta then
        -- Spotlight de tela inteira recortando apenas o botão JOGAR ABERTA
        definirHighlights({
            { alvo = btnAberta, texto = "👇 JOGAR ABERTA" },
        }, true)
        atualizarFalaGuia(
            5,
            "ESCOLHA JOGAR ABERTA",
            "Perfeito! Agora clique em JOGAR ABERTA para descer seu ZAP virado pra cima e fechar a Mão!",
            nil,
            nil,
            "👇 Clique em JOGAR ABERTA",
            "topoCentro"
        )
    end
end

-- ==========================================
-- API PÚBLICA
-- ==========================================

function TutorialMatch.Inicializar(paiTela, callbacksHooks)
    painelTela = paiTela
    hooks = callbacksHooks
    criarUI()
end

function TutorialMatch.EstaAtivo()
    return ativo
end

function TutorialMatch.Iniciar()
    if ativo or not hooks or not painelTela then return end
    criarUI()

    ativo = true
    sessaoId += 1
    local minhaSessao = sessaoId
    etapaAtual = "INICIANDO"
    posicaoCardModo = "centro"

    ProximityPromptService.Enabled = false
    definirVisibilidadeBaloesMesas(false)
    camadaTutorial.Visible = true
    cardGuia.Visible = true
    btnPularTopo.Visible = true
    modalConclusao.Visible = false
    limparHighlights()
    atualizarLayoutResponsivo(false)

    hooks.ativarModoTutorial({
        onJogarCarta = aoJogadorJogarCarta,
        onPedirTruco = aoJogadorPedirTruco,
        onOpcoesJogadaAbertas = aoOpcoesJogadaAbertas,
    })

    enquadrarCameraMesaTutorial()

    if connRenderHighlight then
        connRenderHighlight:Disconnect()
    end
    connRenderHighlight = RunService.RenderStepped:Connect(atualizarPosicoesHighlights)

    task.defer(function()
        if ativo and sessaoId == minhaSessao then
            iniciarEtapa1Objetivo(minhaSessao)
        end
    end)
end

function TutorialMatch.Encerrar()
    if not ativo then return end
    ativo = false
    sessaoId += 1
    etapaAtual = nil
    onContinuarCallback = nil

    if connRenderHighlight then
        connRenderHighlight:Disconnect()
        connRenderHighlight = nil
    end

    limparHighlights()
    if camadaTutorial then camadaTutorial.Visible = false end
    if modalConclusao then modalConclusao.Visible = false end
    if cardGuia then cardGuia.Visible = false end

    restaurarCamera()
    definirVisibilidadeBaloesMesas(true)
    ProximityPromptService.Enabled = true

    if hooks and hooks.desativarModoTutorial then
        hooks.desativarModoTutorial()
    end
end

return TutorialMatch

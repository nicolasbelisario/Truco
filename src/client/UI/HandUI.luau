local TweenService = game:GetService("TweenService")
local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local HandUI = {}

local painelMao
local eMinhaVez = false
local numeroQuedaAtual = 1
local trucoPendente = false
local dadosJogador = { SkinEquipada = "Padrao" }
local valorViraAtual = nil
local filtroClique = nil -- function(card) -> boolean (usado no tutorial interativo)

local cartasAtivas = {} -- lista ordenada de { wrapper, btn, card, baseZ, seloFrame, seloLbl, strokeManilha, tweenPulso }
local connViewport = nil

-- Callbacks injetados (D)
local onJogarCarta    -- function(cardId, escondida)
local onPedirOpcoes   -- function(btnImg, card, container, callbackJogar)
local onOcultarOpcoes -- function()

local TWEEN_LEQUE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_PULSO_MANILHA = TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local COR_OURO_MANILHA = Color3.fromRGB(255, 212, 55)

local function atualizarZIndexEntrada(item, zBase)
    if item.wrapper then item.wrapper.ZIndex = zBase end
    if item.btn then item.btn.ZIndex = zBase end
    if item.seloFrame then item.seloFrame.ZIndex = zBase + 2 end
    if item.seloLbl then item.seloLbl.ZIndex = zBase + 3 end
end

local function limparDestaqueManilha(item)
    if item.tweenPulso then
        item.tweenPulso:Cancel()
        item.tweenPulso = nil
    end
    if item.strokeManilha then
        item.strokeManilha:Destroy()
        item.strokeManilha = nil
    end
    if item.seloFrame then
        item.seloFrame:Destroy()
        item.seloFrame = nil
        item.seloLbl = nil
    end
end

local function aplicarDestaqueManilha(item)
    limparDestaqueManilha(item)
    if not item.btn or not item.btn.Parent or not item.card then return end

    local infoManilha = nil
    if valorViraAtual then
        infoManilha = CardSettings.ObterInfoManilha(item.card.Value, item.card.Suit, valorViraAtual)
    elseif item.card.ManilhaStrength and item.card.ManilhaStrength > 0 then
        infoManilha = CardSettings.ManilhaInfoPorNaipe[item.card.Suit]
    end

    if not infoManilha then return end

    -- Borda brilhante dourada animada
    local stroke = Instance.new("UIStroke")
    stroke.Name = "BordaManilha"
    stroke.Color = COR_OURO_MANILHA
    stroke.Thickness = 2.8
    stroke.Transparency = 0.05
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = item.btn

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 155)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 178, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 244, 155)),
    })
    grad.Rotation = 35
    grad.Parent = stroke

    local tweenPulso = TweenService:Create(stroke, TWEEN_PULSO_MANILHA, {
        Thickness = 4.0,
        Transparency = 0.25,
    })
    tweenPulso:Play()

    -- Selo discreto no topo-centro da carta (ex.: ZAP ♣️, COPAS ♥️, ESPADAS ♠️, OUROS ♦️)
    local selo = Instance.new("Frame")
    selo.Name = "SeloManilha"
    selo.AnchorPoint = Vector2.new(0.5, 0.5)
    selo.Position = UDim2.new(0.5, 0, 0, -2)
    selo.Size = UDim2.new(0.94, 0, 0.16, 0)
    selo.BackgroundColor3 = Color3.fromRGB(22, 18, 10)
    selo.BackgroundTransparency = 0.06
    selo.BorderSizePixel = 0
    selo.ZIndex = (item.btn.ZIndex or 1) + 2
    selo.Parent = item.btn
    Instance.new("UICorner", selo).CornerRadius = UDim.new(1, 0)

    local seloSizeCons = Instance.new("UISizeConstraint", selo)
    seloSizeCons.MinSize = Vector2.new(54, 16)
    seloSizeCons.MaxSize = Vector2.new(124, 22)

    local strokeSelo = Instance.new("UIStroke", selo)
    strokeSelo.Color = COR_OURO_MANILHA
    strokeSelo.Thickness = 1.4
    strokeSelo.Transparency = 0.1

    local padSelo = Instance.new("UIPadding", selo)
    padSelo.PaddingLeft = UDim.new(0, 4)
    padSelo.PaddingRight = UDim.new(0, 4)
    padSelo.PaddingTop = UDim.new(0, 1)
    padSelo.PaddingBottom = UDim.new(0, 1)

    local lblSelo = Instance.new("TextLabel")
    lblSelo.Name = "TextoSelo"
    lblSelo.Size = UDim2.new(1, 0, 1, 0)
    lblSelo.BackgroundTransparency = 1
    lblSelo.Text = infoManilha.Selo
    lblSelo.TextColor3 = infoManilha.CorTexto
    lblSelo.Font = Enum.Font.GothamBlack
    lblSelo.TextScaled = true
    lblSelo.ZIndex = (item.btn.ZIndex or 1) + 3
    lblSelo.Parent = selo

    local limTexto = Instance.new("UITextSizeConstraint", lblSelo)
    limTexto.MaxTextSize = 11
    limTexto.MinTextSize = 7

    item.strokeManilha = stroke
    item.tweenPulso = tweenPulso
    item.seloFrame = selo
    item.seloLbl = lblSelo
end

local function calcularDimensoesCarta()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local alturaAlvo = math.clamp(vp.Y * 0.23, 96, 166)
    local larguraMax = math.clamp((vp.X * 0.54) / 2.65, 62, 118)
    local largura = math.min(math.round(alturaAlvo * 0.699), math.round(larguraMax))
    local altura = math.round(largura / 0.699)
    return largura, altura, vp
end

local function calcularParametrosLeque(total, largura)
    local stepX = largura * 0.88
    if total == 3 then
        return { -stepX, 0, stepX }, { 8, 0, 8 }, { -6, 0, 6 }
    elseif total == 2 then
        return { -stepX * 0.52, stepX * 0.52 }, { 2, 2 }, { -3.5, 3.5 }
    elseif total == 1 then
        return { 0 }, { 0 }, { 0 }
    end

    -- Fallback genérico caso haja quantidade diferente de cartas
    local xs, ys, rots = {}, {}, {}
    local centro = (total + 1) / 2
    for i = 1, total do
        local offset = i - centro
        xs[i] = offset * stepX
        ys[i] = math.abs(offset) * 5
        rots[i] = offset * 5
    end
    return xs, ys, rots
end

local function limparEntradasInvalidas()
    for i = #cartasAtivas, 1, -1 do
        local item = cartasAtivas[i]
        if not item.wrapper or not item.wrapper.Parent then
            table.remove(cartasAtivas, i)
        end
    end
end

local function reorganizarLeque(instantaneo)
    if not painelMao then return end
    limparEntradasInvalidas()

    local largura, altura = calcularDimensoesCarta()
    painelMao.Size = UDim2.new(0.75, 0, 0, altura + 24)

    local total = #cartasAtivas
    if total == 0 then return end

    local xs, ys, rots = calcularParametrosLeque(total, largura)
    for i, item in ipairs(cartasAtivas) do
        item.baseZ = i
        atualizarZIndexEntrada(item, i)

        local tamanhoAlvo = UDim2.new(0, largura, 0, altura)
        local posAlvo = UDim2.new(0.5, xs[i], 1, ys[i])
        local rotAlvo = rots[i]

        if instantaneo then
            item.wrapper.Size = tamanhoAlvo
            item.wrapper.Position = posAlvo
            item.wrapper.Rotation = rotAlvo
        else
            TweenService:Create(item.wrapper, TWEEN_LEQUE, {
                Size = tamanhoAlvo,
                Position = posAlvo,
                Rotation = rotAlvo,
            }):Play()
        end
    end
end

function HandUI.Inicializar(pai, callbacks)
    onJogarCarta    = callbacks.onJogarCarta
    onPedirOpcoes   = callbacks.onPedirOpcoes
    onOcultarOpcoes = callbacks.onOcultarOpcoes

    painelMao = Instance.new("Frame")
    painelMao.Name = "HandFrame"
    painelMao.Size = UDim2.new(0.75, 0, 0, 180)
    painelMao.Position = UDim2.new(0.5, 0, 0.985, 0)
    painelMao.AnchorPoint = Vector2.new(0.5, 1)
    painelMao.BackgroundTransparency = 1
    painelMao.ClipsDescendants = false
    painelMao.Parent = pai

    if not connViewport and workspace.CurrentCamera then
        connViewport = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            reorganizarLeque(true)
        end)
    end
end

function HandUI.DefinirEstado(minhaVez, numQueda, truco, dados)
    if minhaVez ~= nil then eMinhaVez = minhaVez end
    if numQueda ~= nil then numeroQuedaAtual = numQueda end
    if truco ~= nil then trucoPendente = truco end
    if dados then
        dadosJogador = dados
        local skin = dadosJogador.SkinEquipada or "Padrao"
        for _, item in ipairs(cartasAtivas) do
            if item.btn and item.btn.Parent and item.card then
                CardSettings.AplicarSkinCarta(item.btn, item.card.Value, item.card.Suit, false, skin)
            end
        end
    end
end

function HandUI.AdicionarCarta(card)
    if not painelMao then return end

    local largura, altura = calcularDimensoesCarta()
    local wrapper = Instance.new("Frame")
    wrapper.Name = "CardWrapper"
    wrapper.ClipsDescendants = false
    wrapper.AnchorPoint = Vector2.new(0.5, 1)
    wrapper.Size = UDim2.new(0, largura, 0, altura)
    wrapper.Position = UDim2.new(0.5, 0, 1, 20)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = painelMao

    local btn = Instance.new("ImageButton")
    btn.Name = card.idUnico
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Position = UDim2.new(0, 0, 0, 0)
    btn.BackgroundTransparency = 1
    CardSettings.AplicarSkinCarta(btn, card.Value, card.Suit, false, dadosJogador.SkinEquipada or "Padrao")
    btn.Parent = wrapper
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local entrada = {
        wrapper = wrapper,
        btn = btn,
        card = card,
        baseZ = #cartasAtivas + 1,
        seloFrame = nil,
        seloLbl = nil,
        strokeManilha = nil,
        tweenPulso = nil,
    }
    table.insert(cartasAtivas, entrada)
    aplicarDestaqueManilha(entrada)

    wrapper.AncestryChanged:Connect(function(_, novoPai)
        if not novoPai then
            limparDestaqueManilha(entrada)
            for idx, item in ipairs(cartasAtivas) do
                if item == entrada then
                    table.remove(cartasAtivas, idx)
                    break
                end
            end
            task.defer(function()
                reorganizarLeque(false)
            end)
        end
    end)

    btn.MouseEnter:Connect(function()
        atualizarZIndexEntrada(entrada, 20)
        btn:TweenPosition(UDim2.new(0, 0, -0.18, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
    end)
    btn.MouseLeave:Connect(function()
        atualizarZIndexEntrada(entrada, entrada.baseZ)
        btn:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
    end)

    btn.Activated:Connect(function()
        if not eMinhaVez then return end
        if trucoPendente then return end
        if filtroClique and not filtroClique(card) then return end

        if numeroQuedaAtual >= 2 then
            atualizarZIndexEntrada(entrada, 25)
            if onPedirOpcoes then onPedirOpcoes(btn, card, wrapper, onJogarCarta) end
        else
            eMinhaVez = false
            if onJogarCarta then onJogarCarta(card.idUnico, false) end
            wrapper:Destroy()
            if onOcultarOpcoes then onOcultarOpcoes() end
        end
    end)

    reorganizarLeque(false)
end

function HandUI.DefinirVira(vira)
    if type(vira) == "table" then
        valorViraAtual = vira.Value or vira.valor
    else
        valorViraAtual = vira
    end
    for _, item in ipairs(cartasAtivas) do
        aplicarDestaqueManilha(item)
        atualizarZIndexEntrada(item, item.baseZ)
    end
end

function HandUI.DefinirFiltroClique(fn)
    filtroClique = fn
end

function HandUI.ObterElementoCarta(cardId)
    for _, item in ipairs(cartasAtivas) do
        if item.card and item.card.idUnico == cardId and item.btn and item.btn.Parent then
            return item.btn, item.wrapper
        end
    end
    return nil, nil
end

function HandUI.Limpar()
    for _, item in ipairs(cartasAtivas) do
        limparDestaqueManilha(item)
    end
    table.clear(cartasAtivas)
    if not painelMao then return end
    painelMao:ClearAllChildren()
end

return HandUI

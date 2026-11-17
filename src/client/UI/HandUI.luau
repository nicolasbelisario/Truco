local TweenService = game:GetService("TweenService")
local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local HandUI = {}

local painelMao
local eMinhaVez = false
local numeroQuedaAtual = 1
local trucoPendente = false
local dadosJogador = { SkinEquipada = "Padrao" }

local cartasAtivas = {} -- lista ordenada de { wrapper, btn, card, baseZ }
local connViewport = nil

-- Callbacks injetados (D)
local onJogarCarta    -- function(cardId, escondida)
local onPedirOpcoes   -- function(btnImg, card, container, callbackJogar)
local onOcultarOpcoes -- function()

local TWEEN_LEQUE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
        item.wrapper.ZIndex = i
        item.btn.ZIndex = i

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
    eMinhaVez = minhaVez
    numeroQuedaAtual = numQueda or 1
    trucoPendente = truco or false
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
    }
    table.insert(cartasAtivas, entrada)

    wrapper.AncestryChanged:Connect(function(_, novoPai)
        if not novoPai then
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
        wrapper.ZIndex = 20
        btn.ZIndex = 20
        btn:TweenPosition(UDim2.new(0, 0, -0.18, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
    end)
    btn.MouseLeave:Connect(function()
        wrapper.ZIndex = entrada.baseZ
        btn.ZIndex = entrada.baseZ
        btn:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.16, true)
    end)

    btn.Activated:Connect(function()
        if not eMinhaVez then return end
        if trucoPendente then return end

        if numeroQuedaAtual >= 2 then
            wrapper.ZIndex = 25
            btn.ZIndex = 25
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

function HandUI.Limpar()
    table.clear(cartasAtivas)
    if not painelMao then return end
    painelMao:ClearAllChildren()
end

return HandUI

local Eventos = game.ReplicatedStorage:WaitForChild("Events")
local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local HandUI = {}

local painelMao
local eMinhaVez = false
local numeroQuedaAtual = 1
local trucoPendente = false
local dadosJogador = { SkinEquipada = "Padrao" }

-- Callbacks injetados (D)
local onJogarCarta   -- function(valor, naipe, escondida)
local onPedirOpcoes  -- function(btnImg, valor, naipe, container, callbackJogar)
local onOcultarOpcoes -- function()

function HandUI.Inicializar(pai, callbacks)
    onJogarCarta   = callbacks.onJogarCarta
    onPedirOpcoes  = callbacks.onPedirOpcoes
    onOcultarOpcoes = callbacks.onOcultarOpcoes

    painelMao = Instance.new("Frame")
    painelMao.Name = "HandFrame"
    painelMao.Size = UDim2.new(0.6, 0, 0.25, 0)
    painelMao.Position = UDim2.new(0.5, 0, 0.98, 0)
    painelMao.AnchorPoint = Vector2.new(0.5, 1)
    painelMao.BackgroundTransparency = 1
    painelMao.ClipsDescendants = false
    painelMao.Parent = pai

    local layout = Instance.new("UIListLayout", painelMao)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 15)
end

function HandUI.DefinirEstado(minhaVez, numQueda, truco, dados)
    eMinhaVez = minhaVez
    numeroQuedaAtual = numQueda or 1
    trucoPendente = truco or false
    if dados then dadosJogador = dados end
end

function HandUI.AdicionarCarta(card)
    local wrapper = Instance.new("Frame")
    wrapper.Name = "CardWrapper"
    wrapper.ClipsDescendants = false
    wrapper.Size = UDim2.new(0, 110, 0, 160)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = painelMao

    local btn = Instance.new("ImageButton")
    btn.Name = card.idUnico
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    CardSettings.AplicarSkinCarta(btn, card.Value, card.Suit, false, dadosJogador.SkinEquipada or "Padrao")
    btn.Parent = wrapper
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        wrapper.ZIndex = 10
        btn:TweenPosition(UDim2.new(0, 0, -0.2, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)
    btn.MouseLeave:Connect(function()
        wrapper.ZIndex = 1
        btn:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    end)

    btn.Activated:Connect(function()
        if not eMinhaVez then return end
        if trucoPendente then return end 

        if numeroQuedaAtual >= 2 then
            wrapper.ZIndex = 20
            -- Passa o método onJogarCarta junto para que o menu flutuante possa engatilhar a ação
            if onPedirOpcoes then onPedirOpcoes(btn, card, wrapper, onJogarCarta) end
        else
            eMinhaVez = false
            if onJogarCarta then onJogarCarta(card.idUnico, false) end
            wrapper:Destroy()
            if onOcultarOpcoes then onOcultarOpcoes() end
        end
    end)
end

function HandUI.Limpar()
    if not painelMao then return end
    painelMao:ClearAllChildren()
    local layout = Instance.new("UIListLayout", painelMao)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 15)
end

return HandUI
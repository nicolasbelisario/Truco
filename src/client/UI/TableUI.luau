local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local TableUI = {}

local centroMesa
local modoLateral = false
local gradeVisivel = false

local function atualizarLayoutContainer()
    if not centroMesa then return end

    for _, filho in ipairs(centroMesa:GetChildren()) do
        if filho:IsA("UILayout") then
            filho:Destroy()
        end
    end

    if modoLateral then
        centroMesa.Size = UDim2.new(0, 110, 1, -250)
        centroMesa.Position = UDim2.new(1, -16, 0, 234)
        centroMesa.AnchorPoint = Vector2.new(1, 0)

        local listaCartas = Instance.new("UIListLayout", centroMesa)
        listaCartas.FillDirection = Enum.FillDirection.Vertical
        listaCartas.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listaCartas.VerticalAlignment = Enum.VerticalAlignment.Top
        listaCartas.SortOrder = Enum.SortOrder.LayoutOrder
        listaCartas.Padding = UDim.new(0, 6)
    else
        centroMesa.Size = UDim2.new(0.5, 0, 0.4, 0)
        centroMesa.Position = UDim2.new(0.5, 0, 0.5, 0)
        centroMesa.AnchorPoint = Vector2.new(0.5, 0.5)

        local gradeCartas = Instance.new("UIGridLayout", centroMesa)
        gradeCartas.CellSize = UDim2.new(0, 110, 0, 150)
        gradeCartas.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gradeCartas.VerticalAlignment = Enum.VerticalAlignment.Center
    end
end

local function aplicarLayoutSlot(slotCarta)
    local etiquetaNome = slotCarta:FindFirstChild("NomeJogador")
    local cartaImg = slotCarta:FindFirstChild("CartaImagem")
    local limiteTexto = etiquetaNome and etiquetaNome:FindFirstChildOfClass("UITextSizeConstraint")

    if modoLateral then
        slotCarta.Size = UDim2.new(1, 0, 0, 112)
        if etiquetaNome then
            etiquetaNome.Size = UDim2.new(1, 0, 0, 16)
            etiquetaNome.Position = UDim2.new(0.5, 0, 0, 0)
            etiquetaNome.AnchorPoint = Vector2.new(0.5, 0)
        end
        if limiteTexto then limiteTexto.MaxTextSize = 14 end
        if cartaImg then
            cartaImg.Size = UDim2.new(0, 68, 0, 94)
            cartaImg.Position = UDim2.new(0.5, 0, 0, 18)
            cartaImg.AnchorPoint = Vector2.new(0.5, 0)
        end
    else
        slotCarta.Size = UDim2.new(0, 110, 0, 150)
        if etiquetaNome then
            etiquetaNome.Size = UDim2.new(1.2, 0, 0.2, 0)
            etiquetaNome.Position = UDim2.new(0.5, 0, 0, -5)
            etiquetaNome.AnchorPoint = Vector2.new(0.5, 1)
        end
        if limiteTexto then limiteTexto.MaxTextSize = 18 end
        if cartaImg then
            cartaImg.Size = UDim2.new(1, 0, 1, 0)
            cartaImg.Position = UDim2.new(0.5, 0, 0.5, 0)
            cartaImg.AnchorPoint = Vector2.new(0.5, 0.5)
        end
    end
end

--[[
    Inicializa o container opcional da grade 2D de cartas da mesa.
    Inicia oculto por padrão para priorizar a imersão 3D em TableVisuals.
]]
function TableUI.Inicializar(pai)
    centroMesa = Instance.new("Frame")
    centroMesa.Name = "TableCenter"
    centroMesa.BackgroundTransparency = 1
    centroMesa.Visible = gradeVisivel
    centroMesa.Parent = pai

    modoLateral = false
    atualizarLayoutContainer()
end

function TableUI.DefinirVisivel(ativo)
    gradeVisivel = (ativo == true)
    if centroMesa then
        centroMesa.Visible = gradeVisivel
    end
end

function TableUI.EstaVisivel()
    return gradeVisivel
end

function TableUI.AlternarVisivel()
    TableUI.DefinirVisivel(not gradeVisivel)
    return gradeVisivel
end

function TableUI.DefinirModoLateral(ativo)
    local novoEstado = (ativo == true)
    if modoLateral == novoEstado then return end

    modoLateral = novoEstado
    atualizarLayoutContainer()

    if not centroMesa then return end
    for _, filho in ipairs(centroMesa:GetChildren()) do
        if filho:IsA("Frame") then
            aplicarLayoutSlot(filho)
        end
    end
end

function TableUI.AdicionarCarta(nomeJogador, valor, naipe, escondida, nomeSkin)
    if not centroMesa then return end

    local slotCarta = Instance.new("Frame")
    slotCarta.BackgroundTransparency = 1
    slotCarta.Parent = centroMesa

    local etiquetaNome = Instance.new("TextLabel")
    etiquetaNome.Name = "NomeJogador"
    etiquetaNome.Text = nomeJogador
    etiquetaNome.BackgroundTransparency = 1
    etiquetaNome.TextColor3 = Color3.new(1, 1, 1)
    etiquetaNome.Font = Enum.Font.GothamBlack
    etiquetaNome.TextScaled = true
    etiquetaNome.Parent = slotCarta

    local limiteTexto = Instance.new("UITextSizeConstraint", etiquetaNome)
    limiteTexto.MaxTextSize = 18
    local contorno = Instance.new("UIStroke", etiquetaNome)
    contorno.Thickness = 2

    local cartaImg = Instance.new("ImageLabel")
    cartaImg.Name = "CartaImagem"
    cartaImg.BackgroundTransparency = 1
    cartaImg.Parent = slotCarta

    CardSettings.AplicarSkinCarta(cartaImg, valor, naipe, escondida, nomeSkin)

    local curva = Instance.new("UICorner")
    curva.CornerRadius = UDim.new(0, 8)
    curva.Parent = cartaImg

    aplicarLayoutSlot(slotCarta)
end

function TableUI.Limpar()
    if not centroMesa then return end
    for _, filho in ipairs(centroMesa:GetChildren()) do
        if filho:IsA("GuiObject") then filho:Destroy() end
    end
end

return TableUI

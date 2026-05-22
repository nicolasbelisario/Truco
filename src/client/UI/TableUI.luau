local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local TableUI = {}

local centroMesa

function TableUI.Inicializar(pai)
    centroMesa = Instance.new("Frame")
    centroMesa.Name = "TableCenter"
    centroMesa.Size = UDim2.new(0.5, 0, 0.4, 0)
    centroMesa.Position = UDim2.new(0.5, 0, 0.5, 0)
    centroMesa.AnchorPoint = Vector2.new(0.5, 0.5)
    centroMesa.BackgroundTransparency = 1
    centroMesa.Parent = pai

    local gradeCartas = Instance.new("UIGridLayout", centroMesa)
    gradeCartas.CellSize = UDim2.new(0, 110, 0, 150)
    gradeCartas.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gradeCartas.VerticalAlignment = Enum.VerticalAlignment.Center
end

function TableUI.AdicionarCarta(nomeJogador, valor, naipe, escondida, nomeSkin)
    if not centroMesa then return end

    local cartaImg = Instance.new("ImageLabel")
    cartaImg.Size = UDim2.new(0, 110, 0, 160)
    cartaImg.BackgroundTransparency = 1
    
    CardSettings.AplicarSkinCarta(cartaImg, valor, naipe, escondida, nomeSkin)
    
    local curva = Instance.new("UICorner")
    curva.CornerRadius = UDim.new(0, 8)
    curva.Parent = cartaImg
    
    local etiquetaNome = Instance.new("TextLabel")
    etiquetaNome.Text = nomeJogador
    etiquetaNome.Size = UDim2.new(1.2, 0, 0.2, 0)
    etiquetaNome.Position = UDim2.new(0.5, 0, 0, -5)
    etiquetaNome.AnchorPoint = Vector2.new(0.5, 1)
    etiquetaNome.BackgroundTransparency = 1
    etiquetaNome.TextColor3 = Color3.new(1, 1, 1)
    etiquetaNome.Font = Enum.Font.GothamBlack
    etiquetaNome.TextScaled = true
    etiquetaNome.Parent = cartaImg
    
    local limiteTexto = Instance.new("UITextSizeConstraint", etiquetaNome)
    limiteTexto.MaxTextSize = 18
    local contorno = Instance.new("UIStroke", etiquetaNome)
    contorno.Thickness = 2
    
    cartaImg.Parent = centroMesa
end

function TableUI.Limpar()
    if not centroMesa then return end
    for _, filho in ipairs(centroMesa:GetChildren()) do
        if filho:IsA("GuiObject") then filho:Destroy() end
    end
end

return TableUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local jogadorLocal = Players.LocalPlayer
local Eventos = ReplicatedStorage:WaitForChild("Events")
local CardSettings = require(ReplicatedStorage.Shared.CardSettings)

local ShopUI = {}

local btnLoja, menuLoja, paginaPontos, paginaRobux, textoMeusPontos
local btnAbaPontos, btnAbaRobux
local dadosJogador = { Pontos = 0, SkinsCompradas = {"Padrao"}, SkinEquipada = "Padrao" }

local CATALOGO_SKINS = {
    { Id = "Padrao", Nome = "Baralho Clássico", Preco = 0, Desc = "O bom e velho Truco raiz." },
    { Id = "Rosa", Nome = "Baralho Rosa", Preco = 200, Desc = "Para quem gosta de um jogo fofinho." },
    { Id = "Nacional", Nome = "Baralho Nacional", Preco = 300, Desc = "Baralho 100% patriota." },
    { Id = "Estrela", Nome = "Baralho Estelar", Preco = 300, Desc = "Baralho 100% da Estrela Vermelha." },
}

local function renderizarSkins()
    if not paginaPontos then return end
    
    for _, filho in ipairs(paginaPontos:GetChildren()) do
        if filho:IsA("Frame") then filho:Destroy() end
    end

    for _, skin in ipairs(CATALOGO_SKINS) do
        local frameItem = Instance.new("Frame")
        frameItem.Size = UDim2.new(1, -10, 0, 100)
        frameItem.BackgroundTransparency = 1
        frameItem.Parent = paginaPontos

        local icone = Instance.new("ImageLabel", frameItem)
        icone.Size = UDim2.new(0, 60, 0, 85)
        icone.Position = UDim2.new(0, 20, 0.5, 0)
        icone.AnchorPoint = Vector2.new(0, 0.5)
        icone.BackgroundTransparency = 1
        Instance.new("UICorner", icone).CornerRadius = UDim.new(0, 6)

        CardSettings.AplicarSkinCarta(icone, "A", "Espadas", false, skin.Id)

        local titulo = Instance.new("TextLabel", frameItem)
        titulo.Size = UDim2.new(0.6, 0, 0.3, 0)
        titulo.Position = UDim2.new(0, 100, 0, 10)
        titulo.BackgroundTransparency = 1
        titulo.Text = skin.Nome
        titulo.TextColor3 = Color3.new(1, 1, 1)
        titulo.Font = Enum.Font.GothamBlack
        titulo.TextSize = 22
        titulo.TextXAlignment = Enum.TextXAlignment.Left

        local descricao = Instance.new("TextLabel", frameItem)
        descricao.Size = UDim2.new(0.6, 0, 0.3, 0)
        descricao.Position = UDim2.new(0, 100, 0, 35)
        descricao.BackgroundTransparency = 1
        descricao.Text = skin.Desc
        descricao.TextColor3 = Color3.new(1, 1, 1)
        descricao.Font = Enum.Font.GothamMedium
        descricao.TextSize = 16
        descricao.TextXAlignment = Enum.TextXAlignment.Left

        local btnAcao = Instance.new("TextButton", frameItem)
        btnAcao.Size = UDim2.new(0, 140, 0, 35)
        btnAcao.Position = UDim2.new(0, 100, 0, 65)
        btnAcao.Font = Enum.Font.GothamBold
        Instance.new("UICorner", btnAcao).CornerRadius = UDim.new(0.5, 0)

        local jaPossui = table.find(dadosJogador.SkinsCompradas, skin.Id)
        local estaEquipado = (dadosJogador.SkinEquipada == skin.Id)

        if estaEquipado then
            btnAcao.Text = "EQUIPADO"
            btnAcao.BackgroundColor3 = Color3.fromRGB(200, 105, 50)
            btnAcao.TextColor3 = Color3.new(1, 1, 1)
        elseif jaPossui then
            btnAcao.Text = "EQUIPAR"
            btnAcao.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            btnAcao.TextColor3 = Color3.new(1, 1, 1)
            btnAcao.Activated:Connect(function()
                Eventos.ShopActionEvent:FireServer("Equipar", skin.Id)
            end)
        else
            btnAcao.Text = skin.Preco .. " PTS - COMPRAR"
            btnAcao.BackgroundColor3 = (dadosJogador.Pontos >= skin.Preco) and Color3.fromRGB(0, 196, 39) or Color3.fromRGB(100, 100, 100)
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
    icone.BackgroundColor3 = Color3.fromRGB(180, 100, 50)
    icone.ZIndex = 51 
    icone.Parent = frameItem
    Instance.new("UICorner", icone).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        local sucesso, informacao = pcall(function()
            local tipoBusca = ehGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
            return MarketplaceService:GetProductInfo(idProduto, tipoBusca)
        end)

        if sucesso and informacao and informacao.IconImageAssetId and informacao.IconImageAssetId > 0 then
            icone.Image = "rbxassetid://" .. informacao.IconImageAssetId
            icone.BackgroundTransparency = 1
        end
    end)

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
    btnComprar.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    
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

function ShopUI.Inicializar(pai)
    btnLoja = Instance.new("TextButton", pai)
    btnLoja.Name = "BtnLoja"
    btnLoja.Size = UDim2.new(0, 180, 0, 80)
    btnLoja.Position = UDim2.new(0.85, 0, 0.85, 0) 
    btnLoja.BackgroundColor3 = Color3.fromRGB(0, 196, 39)
    btnLoja.Text = "LOJA"
    btnLoja.TextColor3 = Color3.new(1,1,1)
    btnLoja.Font = Enum.Font.GothamBlack
    btnLoja.TextSize = 35
    Instance.new("UICorner", btnLoja).CornerRadius = UDim.new(0, 12)

    menuLoja = Instance.new("Frame", pai)
    menuLoja.Name = "MenuLoja"
    menuLoja.Size = UDim2.new(0, 600, 0, 400)
    menuLoja.Position = UDim2.new(0.5, 0, 0.5, 0)
    menuLoja.AnchorPoint = Vector2.new(0.5, 0.5)
    menuLoja.BackgroundColor3 = Color3.fromRGB(175, 175, 175)
    menuLoja.Visible = false
    menuLoja.ZIndex = 50
    Instance.new("UICorner", menuLoja).CornerRadius = UDim.new(0, 20)

    local btnFechar = Instance.new("TextButton", menuLoja)
    btnFechar.Size = UDim2.new(0, 40, 0, 40)
    btnFechar.Position = UDim2.new(1, -15, 0, 15)
    btnFechar.AnchorPoint = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnFechar.Text = "X"
    btnFechar.TextColor3 = Color3.new(1, 1, 1)
    btnFechar.Font = Enum.Font.GothamBlack
    btnFechar.ZIndex = 52
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)
    
    btnFechar.Activated:Connect(function() menuLoja.Visible = false end)
    btnLoja.Activated:Connect(function() menuLoja.Visible = not menuLoja.Visible end)

    local containerAbas = Instance.new("Frame", menuLoja)
    containerAbas.Size = UDim2.new(1, 0, 0, 80)
    containerAbas.BackgroundTransparency = 1

    local corLaranjaAtivo = Color3.fromRGB(200, 105, 50)
    local corLaranjaInativo = Color3.fromRGB(255, 145, 75)
    local corVerdeAtivo = Color3.fromRGB(0, 150, 60)
    local corVerdeInativo = Color3.fromRGB(0, 200, 80)

    btnAbaPontos = Instance.new("TextButton", containerAbas)
    btnAbaPontos.Size = UDim2.new(0, 200, 0, 60)
    btnAbaPontos.Position = UDim2.new(0.30, 0, 0.5, 0)
    btnAbaPontos.AnchorPoint = Vector2.new(0.5, 0.5)
    btnAbaPontos.BackgroundColor3 = corLaranjaAtivo
    btnAbaPontos.Text = "PONTOS"
    btnAbaPontos.TextColor3 = Color3.new(1, 1, 1)
    btnAbaPontos.Font = Enum.Font.GothamBlack
    btnAbaPontos.TextSize = 30
    btnAbaPontos.ZIndex = 51
    Instance.new("UICorner", btnAbaPontos).CornerRadius = UDim.new(0.5, 0)

    btnAbaRobux = Instance.new("TextButton", containerAbas)
    btnAbaRobux.Size = UDim2.new(0, 200, 0, 60)
    btnAbaRobux.Position = UDim2.new(0.70, 0, 0.5, 0)
    btnAbaRobux.AnchorPoint = Vector2.new(0.5, 0.5)
    btnAbaRobux.BackgroundColor3 = corVerdeInativo
    btnAbaRobux.Text = "ROBUX"
    btnAbaRobux.TextColor3 = Color3.new(1, 1, 1)
    btnAbaRobux.Font = Enum.Font.GothamBlack
    btnAbaRobux.TextSize = 30
    btnAbaRobux.ZIndex = 51
    Instance.new("UICorner", btnAbaRobux).CornerRadius = UDim.new(0.5, 0)

    textoMeusPontos = Instance.new("TextLabel", menuLoja)
    textoMeusPontos.Size = UDim2.new(1, 0, 0, 30)
    textoMeusPontos.Position = UDim2.new(0, 0, 0, -35)
    textoMeusPontos.BackgroundTransparency = 1
    textoMeusPontos.Text = "MEUS PONTOS: 0"
    textoMeusPontos.TextColor3 = Color3.fromRGB(255, 215, 0)
    textoMeusPontos.Font = Enum.Font.GothamBlack
    textoMeusPontos.TextSize = 24

    paginaPontos = Instance.new("ScrollingFrame", menuLoja)
    paginaPontos.Size = UDim2.new(1, -40, 1, -110)
    paginaPontos.Position = UDim2.new(0, 20, 0, 90)
    paginaPontos.BackgroundTransparency = 1
    paginaPontos.ScrollBarThickness = 6
    paginaPontos.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    Instance.new("UIListLayout", paginaPontos).Padding = UDim.new(0, 15)

    paginaRobux = Instance.new("ScrollingFrame", menuLoja)
    paginaRobux.Size = UDim2.new(1, -40, 1, -110)
    paginaRobux.Position = UDim2.new(0, 20, 0, 90)
    paginaRobux.BackgroundTransparency = 1
    paginaRobux.ScrollBarThickness = 6
    paginaRobux.Visible = false
    paginaRobux.AutomaticCanvasSize = Enum.AutomaticSize.Y 
    Instance.new("UIListLayout", paginaRobux).Padding = UDim.new(0, 15)

    -- Itens baseados na sua versão antiga
    criarItemLoja("100 Pontos", "Impulsione suas compras!", "10", 3554291316, false)
    criarItemLoja("500 Pontos", "Fique rico rapidamente!", "40", 3554291580, false)
    criarItemLoja("Doação 1", "Vai me ajudar a desenvolver o jogo :D", "15", 3549774213, false)
    criarItemLoja("Doação 2", "Vai me ajudar a desenvolver o jogo :D", "30", 3549774425, false)

    btnAbaPontos.Activated:Connect(function()
        paginaPontos.Visible = true; paginaRobux.Visible = false
        btnAbaPontos.BackgroundColor3 = corLaranjaAtivo; btnAbaRobux.BackgroundColor3 = corVerdeInativo
    end)

    btnAbaRobux.Activated:Connect(function()
        paginaPontos.Visible = false; paginaRobux.Visible = true
        btnAbaPontos.BackgroundColor3 = corLaranjaInativo; btnAbaRobux.BackgroundColor3 = corVerdeAtivo
    end)
end

function ShopUI.AtualizarDados(novosDados)
    dadosJogador = novosDados
    if textoMeusPontos then
        textoMeusPontos.Text = "MEUS PONTOS: " .. tostring(dadosJogador.Pontos)
    end
    renderizarSkins()
end

function ShopUI.DefinirVisibilidade(visivel)
    if btnLoja then btnLoja.Visible = visivel end
    if not visivel and menuLoja then menuLoja.Visible = false end
end

return ShopUI
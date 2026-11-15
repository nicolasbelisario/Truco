local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local jogadorLocal       = Players.LocalPlayer
local Eventos            = ReplicatedStorage:WaitForChild("Events")
local CardSettings       = require(ReplicatedStorage.Shared.CardSettings)
local EconomyConfig      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("EconomyConfig"))

local ShopUI = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local VERDE      = Color3.fromRGB(39, 174, 96)
local VERMELHO   = Color3.fromRGB(200, 50, 50)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(180, 180, 190)

local COR_ABA_ATIVA   = ACENTO
local COR_ABA_INATIVA = BG_PAINEL

local btnLoja, menuLoja, paginaPontos, paginaRobux, textoMeusPontos
local btnAbaPontos, btnAbaRobux
local dadosJogador = { Pontos = 0, SkinsCompradas = {EconomyConfig.SkinPadraoId}, SkinEquipada = EconomyConfig.SkinPadraoId }

local CATALOGO_SKINS = EconomyConfig.Skins


local function renderizarSkins()
    if not paginaPontos then return end

    for _, filho in ipairs(paginaPontos:GetChildren()) do
        if filho:IsA("Frame") then filho:Destroy() end
    end

    for _, skin in ipairs(CATALOGO_SKINS) do
        local frameItem = Instance.new("Frame")
        frameItem.Size               = UDim2.new(1, -10, 0, 100)
        frameItem.BackgroundTransparency = 1
        frameItem.Parent             = paginaPontos

        local icone = Instance.new("ImageLabel", frameItem)
        icone.Size                = UDim2.new(0, 60, 0, 85)
        icone.Position            = UDim2.new(0, 20, 0.5, 0)
        icone.AnchorPoint         = Vector2.new(0, 0.5)
        icone.BackgroundTransparency = 1
        Instance.new("UICorner", icone).CornerRadius = UDim.new(0, 6)

        CardSettings.AplicarSkinCarta(icone, "A", "Espadas", false, skin.Id)

        local titulo = Instance.new("TextLabel", frameItem)
        titulo.Size               = UDim2.new(0.6, 0, 0.3, 0)
        titulo.Position           = UDim2.new(0, 100, 0, 10)
        titulo.BackgroundTransparency = 1
        titulo.Text               = skin.Nome
        titulo.TextColor3         = TEXTO_PRIM
        titulo.Font               = Enum.Font.GothamBlack
        titulo.TextScaled         = false
        titulo.TextSize           = 22
        titulo.TextXAlignment     = Enum.TextXAlignment.Left

        local descricao = Instance.new("TextLabel", frameItem)
        descricao.Size            = UDim2.new(0.6, 0, 0.3, 0)
        descricao.Position        = UDim2.new(0, 100, 0, 35)
        descricao.BackgroundTransparency = 1
        descricao.Text            = skin.Desc
        descricao.TextColor3      = TEXTO_SEC
        descricao.Font            = Enum.Font.GothamMedium
        descricao.TextScaled      = false
        descricao.TextSize        = 16
        descricao.TextXAlignment  = Enum.TextXAlignment.Left

        local btnAcao = Instance.new("TextButton", frameItem)
        btnAcao.Size            = UDim2.new(0, 140, 0, 35)
        btnAcao.Position        = UDim2.new(0, 100, 0, 65)
        btnAcao.Font            = Enum.Font.GothamBold
        btnAcao.TextScaled      = false
        btnAcao.TextSize        = 14
        btnAcao.AutoButtonColor = true
        Instance.new("UICorner", btnAcao).CornerRadius = UDim.new(0.5, 0)

        local jaPossui    = table.find(dadosJogador.SkinsCompradas, skin.Id)
        local estaEquipado = (dadosJogador.SkinEquipada == skin.Id)

        if estaEquipado then
            btnAcao.Text             = "EQUIPADO"
            btnAcao.BackgroundColor3 = Color3.fromRGB(200, 105, 50)
            btnAcao.TextColor3       = TEXTO_PRIM
        elseif jaPossui then
            btnAcao.Text             = "EQUIPAR"
            btnAcao.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            btnAcao.TextColor3       = TEXTO_PRIM
            btnAcao.Activated:Connect(function()
                Eventos.ShopActionEvent:FireServer("Equipar", skin.Id)
            end)
        else
            btnAcao.Text             = skin.Preco .. " PTS - COMPRAR"
            btnAcao.BackgroundColor3 = (dadosJogador.Pontos >= skin.Preco) and VERDE or Color3.fromRGB(100, 100, 100)
            btnAcao.TextColor3       = TEXTO_PRIM
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
    frameItem.Size               = UDim2.new(1, -10, 0, 100)
    frameItem.BackgroundTransparency = 1
    frameItem.ZIndex             = 51
    frameItem.Parent             = paginaRobux

    local icone = Instance.new("ImageLabel")
    icone.Size            = UDim2.new(0, 80, 0, 80)
    icone.Position        = UDim2.new(0, 10, 0.5, 0)
    icone.AnchorPoint     = Vector2.new(0, 0.5)
    icone.BackgroundColor3 = Color3.fromRGB(180, 100, 50)
    icone.ZIndex          = 51
    icone.Parent          = frameItem
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
    titulo.Size           = UDim2.new(0.6, 0, 0.3, 0)
    titulo.Position       = UDim2.new(0, 110, 0, 10)
    titulo.BackgroundTransparency = 1
    titulo.Text           = nome
    titulo.TextColor3     = TEXTO_PRIM
    titulo.Font           = Enum.Font.GothamBlack
    titulo.TextScaled     = false
    titulo.TextSize       = 22
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.ZIndex         = 51
    titulo.Parent         = frameItem

    local descricao = Instance.new("TextLabel")
    descricao.Size           = UDim2.new(0.6, 0, 0.3, 0)
    descricao.Position       = UDim2.new(0, 110, 0, 35)
    descricao.BackgroundTransparency = 1
    descricao.Text           = desc
    descricao.TextColor3     = TEXTO_SEC
    descricao.Font           = Enum.Font.GothamMedium
    descricao.TextScaled     = false
    descricao.TextSize       = 18
    descricao.TextXAlignment = Enum.TextXAlignment.Left
    descricao.ZIndex         = 51
    descricao.Parent         = frameItem

    local btnComprar = Instance.new("TextButton")
    btnComprar.Size            = UDim2.new(0, 120, 0, 35)
    btnComprar.Position        = UDim2.new(0, 110, 0, 65)
    btnComprar.BackgroundColor3 = VERDE
    btnComprar.Text            = "R$ " .. preco .. " COMPRAR"
    btnComprar.TextColor3      = TEXTO_PRIM
    btnComprar.Font            = Enum.Font.GothamBold
    btnComprar.TextScaled      = false
    btnComprar.TextSize        = 14
    btnComprar.AutoButtonColor = true
    btnComprar.ZIndex          = 52
    btnComprar.Parent          = frameItem
    Instance.new("UICorner", btnComprar).CornerRadius = UDim.new(0.5, 0)

    btnComprar.Activated:Connect(function()
        if ehGamepass then
            MarketplaceService:PromptGamePassPurchase(jogadorLocal, idProduto)
        else
            MarketplaceService:PromptProductPurchase(jogadorLocal, idProduto)
        end
    end)
end

function ShopUI.Inicializar(pai, containerMenu)
    local GuiService = game:GetService("GuiService")
    local TweenService = game:GetService("TweenService")

    if containerMenu then
        btnLoja = Instance.new("TextButton", containerMenu)
        btnLoja.Name            = "BtnLoja"
        btnLoja.Size            = UDim2.new(0, 46, 0, 46)
        btnLoja.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        btnLoja.BackgroundTransparency = 0.25
        btnLoja.Text            = "🛒"
        btnLoja.TextSize        = 22
        btnLoja.TextColor3      = TEXTO_PRIM
        btnLoja.Font            = Enum.Font.GothamBlack
        btnLoja.AutoButtonColor = true
        btnLoja.LayoutOrder     = 2
        btnLoja.ZIndex          = 41
        Instance.new("UICorner", btnLoja).CornerRadius = UDim.new(1, 0)

        local bordaBtn = Instance.new("UIStroke", btnLoja)
        bordaBtn.Thickness    = 1.5
        bordaBtn.Color        = Color3.new(1, 1, 1)
        bordaBtn.Transparency = 0.8

        btnLoja.MouseEnter:Connect(function()
            TweenService:Create(btnLoja, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.05,
                BackgroundColor3 = Color3.fromRGB(38, 38, 46)
            }):Play()
        end)
        btnLoja.MouseLeave:Connect(function()
            TweenService:Create(btnLoja, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.25,
                BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            }):Play()
        end)

        btnLoja.Activated:Connect(function()
            ShopUI.Alternar()
        end)
    else
        btnLoja = Instance.new("TextButton", pai)
        btnLoja.Name            = "BtnLoja"
        btnLoja.Size            = UDim2.new(0, 46, 0, 46)
        btnLoja.AnchorPoint     = Vector2.new(0, 0)
        btnLoja.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        btnLoja.BackgroundTransparency = 0.25
        btnLoja.Text            = "🛒"
        btnLoja.TextSize        = 22
        btnLoja.TextColor3      = TEXTO_PRIM
        btnLoja.Font            = Enum.Font.GothamBlack
        btnLoja.AutoButtonColor = true
        btnLoja.ZIndex          = 40
        Instance.new("UICorner", btnLoja).CornerRadius = UDim.new(1, 0)

        local bordaBtn = Instance.new("UIStroke", btnLoja)
        bordaBtn.Thickness    = 1.5
        bordaBtn.Color        = Color3.new(1, 1, 1)
        bordaBtn.Transparency = 0.8

        local function recalcularPosicaoBotaoLoja()
            if not btnLoja then return end
            local inset = GuiService:GetGuiInset()
            local alturaTopbar = math.max(inset.Y, 54)
            btnLoja.Position = UDim2.new(0, 16, 0, alturaTopbar + 12 + 46 + 8)
        end
        recalcularPosicaoBotaoLoja()
        GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(recalcularPosicaoBotaoLoja)
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(recalcularPosicaoBotaoLoja)
        end

        btnLoja.MouseEnter:Connect(function()
            TweenService:Create(btnLoja, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.05,
                BackgroundColor3 = Color3.fromRGB(38, 38, 46)
            }):Play()
        end)
        btnLoja.MouseLeave:Connect(function()
            TweenService:Create(btnLoja, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.25,
                BackgroundColor3 = Color3.fromRGB(24, 24, 28)
            }):Play()
        end)

        btnLoja.Activated:Connect(function()
            ShopUI.Alternar()
        end)
    end

    -- Modal da loja
    menuLoja = Instance.new("Frame", pai)
    menuLoja.Name            = "MenuLoja"
    menuLoja.Size            = UDim2.new(0.9, 0, 0.85, 0)
    menuLoja.Position        = UDim2.new(0.5, 0, 0.5, 0)
    menuLoja.AnchorPoint     = Vector2.new(0.5, 0.5)
    menuLoja.BackgroundColor3 = BG_ESCURO
    menuLoja.Visible         = false
    menuLoja.ZIndex          = 50
    Instance.new("UICorner", menuLoja).CornerRadius = UDim.new(0, 16)

    local bordaModal = Instance.new("UIStroke", menuLoja)
    bordaModal.Thickness = 1.5
    bordaModal.Color     = Color3.fromRGB(55, 55, 70)

    -- Tamanho máximo para telas grandes
    local sizeCons = Instance.new("UISizeConstraint", menuLoja)
    sizeCons.MaxSize = Vector2.new(580, 520)

    -- Botão fechar
    local btnFechar = Instance.new("TextButton", menuLoja)
    btnFechar.Name            = "BtnFechar"
    btnFechar.Size            = UDim2.new(0, 36, 0, 36)
    btnFechar.Position        = UDim2.new(1, -10, 0, 10)
    btnFechar.AnchorPoint     = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = BG_BOTAO
    btnFechar.Text            = "X"
    btnFechar.TextColor3      = TEXTO_PRIM
    btnFechar.Font            = Enum.Font.GothamBlack
    btnFechar.TextScaled      = false
    btnFechar.TextSize        = 18
    btnFechar.AutoButtonColor = true
    btnFechar.ZIndex          = 52
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)

    btnFechar.Activated:Connect(function() menuLoja.Visible = false end)

    -- Mini container de pontos (topo do modal)
    local containerPontos = Instance.new("Frame", menuLoja)
    containerPontos.Size            = UDim2.new(0.65, 0, 0, 36)
    containerPontos.Position        = UDim2.new(0.5, 0, 0, 10)
    containerPontos.AnchorPoint     = Vector2.new(0.5, 0)
    containerPontos.BackgroundColor3 = BG_PAINEL
    containerPontos.ZIndex          = 51
    Instance.new("UICorner", containerPontos).CornerRadius = UDim.new(0, 10)
    local bordaPontos = Instance.new("UIStroke", containerPontos)
    bordaPontos.Thickness = 1
    bordaPontos.Color     = Color3.fromRGB(55, 55, 70)

    textoMeusPontos = Instance.new("TextLabel", containerPontos)
    textoMeusPontos.Size               = UDim2.new(1, -10, 1, 0)
    textoMeusPontos.Position           = UDim2.new(0.5, 0, 0.5, 0)
    textoMeusPontos.AnchorPoint        = Vector2.new(0.5, 0.5)
    textoMeusPontos.BackgroundTransparency = 1
    textoMeusPontos.Text               = "MEUS PONTOS: 0"
    textoMeusPontos.TextColor3         = ACENTO
    textoMeusPontos.Font               = Enum.Font.GothamBold
    textoMeusPontos.TextScaled         = false
    textoMeusPontos.TextSize           = 16
    textoMeusPontos.ZIndex             = 52

    -- Container das abas
    local containerAbas = Instance.new("Frame", menuLoja)
    containerAbas.Size               = UDim2.new(1, 0, 0, 52)
    containerAbas.Position           = UDim2.new(0, 0, 0, 52)
    containerAbas.BackgroundTransparency = 1
    containerAbas.ZIndex             = 51

    local layoutAbas = Instance.new("UIListLayout", containerAbas)
    layoutAbas.FillDirection       = Enum.FillDirection.Horizontal
    layoutAbas.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layoutAbas.Padding             = UDim.new(0, 10)

    btnAbaPontos = Instance.new("TextButton", containerAbas)
    btnAbaPontos.Size            = UDim2.new(0.42, 0, 0, 40)
    btnAbaPontos.BackgroundColor3 = COR_ABA_ATIVA
    btnAbaPontos.Text            = "PONTOS"
    btnAbaPontos.TextColor3      = TEXTO_PRIM
    btnAbaPontos.Font            = Enum.Font.GothamBold
    btnAbaPontos.TextScaled      = false
    btnAbaPontos.TextSize        = 14
    btnAbaPontos.AutoButtonColor = true
    btnAbaPontos.ZIndex          = 51
    Instance.new("UICorner", btnAbaPontos).CornerRadius = UDim.new(0.5, 0)

    btnAbaRobux = Instance.new("TextButton", containerAbas)
    btnAbaRobux.Size            = UDim2.new(0.42, 0, 0, 40)
    btnAbaRobux.BackgroundColor3 = COR_ABA_INATIVA
    btnAbaRobux.Text            = "ROBUX"
    btnAbaRobux.TextColor3      = TEXTO_PRIM
    btnAbaRobux.Font            = Enum.Font.GothamBold
    btnAbaRobux.TextScaled      = false
    btnAbaRobux.TextSize        = 14
    btnAbaRobux.AutoButtonColor = true
    btnAbaRobux.ZIndex          = 51
    Instance.new("UICorner", btnAbaRobux).CornerRadius = UDim.new(0.5, 0)

    -- Páginas de conteúdo
    paginaPontos = Instance.new("ScrollingFrame", menuLoja)
    paginaPontos.Size                = UDim2.new(1, -40, 1, -120)
    paginaPontos.Position            = UDim2.new(0, 20, 0, 110)
    paginaPontos.BackgroundTransparency = 1
    paginaPontos.ScrollBarThickness  = 6
    paginaPontos.AutomaticCanvasSize = Enum.AutomaticSize.Y
    paginaPontos.ZIndex              = 51
    Instance.new("UIListLayout", paginaPontos).Padding = UDim.new(0, 15)

    paginaRobux = Instance.new("ScrollingFrame", menuLoja)
    paginaRobux.Size                = UDim2.new(1, -40, 1, -120)
    paginaRobux.Position            = UDim2.new(0, 20, 0, 110)
    paginaRobux.BackgroundTransparency = 1
    paginaRobux.ScrollBarThickness  = 6
    paginaRobux.Visible             = false
    paginaRobux.AutomaticCanvasSize = Enum.AutomaticSize.Y
    paginaRobux.ZIndex              = 51
    Instance.new("UIListLayout", paginaRobux).Padding = UDim.new(0, 15)

    -- Itens carregados dinamicamente da configuração unificada
    for _, item in ipairs(EconomyConfig.ProdutosRobux) do
        criarItemLoja(item.Nome, item.Desc, item.PrecoRobux, item.IdProduto, item.EhGamepass)
    end

    btnAbaPontos.Activated:Connect(function()
        paginaPontos.Visible          = true;  paginaRobux.Visible = false
        btnAbaPontos.BackgroundColor3 = COR_ABA_ATIVA;  btnAbaRobux.BackgroundColor3 = COR_ABA_INATIVA
    end)

    btnAbaRobux.Activated:Connect(function()
        paginaPontos.Visible          = false; paginaRobux.Visible = true
        btnAbaPontos.BackgroundColor3 = COR_ABA_INATIVA; btnAbaRobux.BackgroundColor3 = COR_ABA_ATIVA
    end)

    renderizarSkins()
end

-- Permite que o UIManager posicione o botão da loja (ex: dentro da barra de ações)
function ShopUI.DefinirPosicaoBotao(pos)
    if btnLoja then btnLoja.Position = pos end
end

function ShopUI.Alternar()
    if menuLoja then
        menuLoja.Visible = not menuLoja.Visible
        if menuLoja.Visible then
            renderizarSkins()
        end
    end
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

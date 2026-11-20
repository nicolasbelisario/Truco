local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)
local CardSettings = require(game.ReplicatedStorage.Shared.CardSettings)

local ScoreUI = {}

local COR_NOS      = Color3.fromRGB(39, 174, 96)
local COR_ELES     = Color3.fromRGB(210, 55, 55)
local COR_CANGA    = Color3.fromRGB(240, 195, 35)
local COR_PENDENTE = Color3.fromRGB(68, 72, 85)
local COR_OURO     = Color3.fromRGB(255, 215, 60)

local COR_BORDA_ATIVA    = Color3.fromRGB(235, 240, 250)
local COR_BORDA_PENDENTE = Color3.fromRGB(95, 100, 115)

-- Referências internas (injetadas pelo UIManager)
local textoCronometro, textoPlacarJogo, textoValorRodada, textoEstatisticas
local painelEstatisticas, painelVira, containerInfoScore
local marcadoresQuedas = {}
local viraAtual = nil
local imgViraAtual = nil

local function corParaResultado(resultado)
    if resultado == "NOS" then
        return COR_NOS, COR_BORDA_ATIVA
    elseif resultado == "ELES" then
        return COR_ELES, COR_BORDA_ATIVA
    elseif resultado == "CANGA" then
        return COR_CANGA, COR_BORDA_ATIVA
    end
    return COR_PENDENTE, COR_BORDA_PENDENTE
end

local function atualizarCirculosQuedas(nossasQuedas, quedasInimigo, historicoQuedas)
    if #marcadoresQuedas == 0 then return end

    local lista = {}
    if type(historicoQuedas) == "table" then
        for i = 1, 3 do
            lista[i] = historicoQuedas[i]
        end
    else
        local idx = 1
        for _ = 1, (nossasQuedas or 0) do
            if idx <= 3 then
                lista[idx] = "NOS"
                idx += 1
            end
        end
        for _ = 1, (quedasInimigo or 0) do
            if idx <= 3 then
                lista[idx] = "ELES"
                idx += 1
            end
        end
    end

    for i, circulo in ipairs(marcadoresQuedas) do
        local corFundo, corBorda = corParaResultado(lista[i])
        circulo.BackgroundColor3 = corFundo
        local borda = circulo:FindFirstChildOfClass("UIStroke")
        if borda then
            borda.Color = corBorda
            borda.Transparency = lista[i] and 0.15 or 0.55
        end
    end
end

-- (O) Aberto para extensão: novos métodos de exibição sem modificar os existentes
function ScoreUI.Inicializar(refs)
    textoCronometro    = refs.textoCronometro
    textoPlacarJogo    = refs.textoPlacarJogo
    textoValorRodada   = refs.textoValorRodada
    textoEstatisticas  = refs.textoEstatisticas
    painelEstatisticas = refs.painelEstatisticas
    painelVira         = refs.painelVira
    containerInfoScore = refs.containerInfoScore
    marcadoresQuedas   = refs.marcadoresQuedas or {}
    atualizarCirculosQuedas(0, 0, nil)
end

function ScoreUI.DefinirVira(val, naipe, nomeSkin, estaSentado)
    if not painelVira then return end
    for _, filho in ipairs(painelVira:GetChildren()) do
        if not filho:IsA("UICorner") and not filho:IsA("UIStroke") then
            filho:Destroy()
        end
    end

    local skin = nomeSkin or "Padrao"
    local valorManilha = CardSettings.ObterValorManilha(val)
    local simboloNaipe = CardSettings.SuitSymbols[naipe] or naipe

    viraAtual = { valor = val, naipe = naipe, manilha = valorManilha }
    if estaSentado ~= nil then
        painelVira.Visible = estaSentado
    end

    local tituloLbl = Instance.new("TextLabel")
    tituloLbl.Name = "TituloVira"
    tituloLbl.Text = "VIRA"
    tituloLbl.Size = UDim2.new(1, 0, 0.13, 0)
    tituloLbl.Position = UDim2.new(0, 0, 0.02, 0)
    tituloLbl.BackgroundTransparency = 1
    tituloLbl.TextColor3 = COR_OURO
    tituloLbl.Font = Enum.Font.GothamBlack
    tituloLbl.TextScaled = true
    tituloLbl.Parent = painelVira
    local limTitulo = Instance.new("UITextSizeConstraint", tituloLbl)
    limTitulo.MaxTextSize = 15

    local imgVira = Instance.new("ImageLabel")
    imgVira.Name = "ImgVira"
    imgVira.Size = UDim2.new(0.70, 0, 0.49, 0)
    imgVira.Position = UDim2.new(0.5, 0, 0.41, 0)
    imgVira.AnchorPoint = Vector2.new(0.5, 0.5)
    imgVira.BackgroundTransparency = 1
    imgVira.Parent = painelVira
    local ratio = Instance.new("UIAspectRatioConstraint", imgVira)
    ratio.AspectRatio = 93 / 133
    Instance.new("UICorner", imgVira).CornerRadius = UDim.new(0, 6)
    imgViraAtual = imgVira

    CardSettings.AplicarSkinCarta(imgVira, val, naipe, false, skin)

    local textoCarta = Instance.new("TextLabel")
    textoCarta.Name = "TextoCartaVira"
    textoCarta.Text = tostring(val) .. " " .. tostring(simboloNaipe)
    textoCarta.Size = UDim2.new(1, -8, 0.11, 0)
    textoCarta.Position = UDim2.new(0.5, 0, 0.72, 0)
    textoCarta.AnchorPoint = Vector2.new(0.5, 0.5)
    textoCarta.BackgroundTransparency = 1
    textoCarta.TextColor3 = Color3.fromRGB(220, 224, 235)
    textoCarta.Font = Enum.Font.GothamBold
    textoCarta.TextScaled = true
    textoCarta.Parent = painelVira
    local constraintCarta = Instance.new("UITextSizeConstraint", textoCarta)
    constraintCarta.MaxTextSize = 13

    -- Indicador claro da Manilha da Mão logo abaixo da Vira (Issue #8)
    local badgeManilha = Instance.new("Frame")
    badgeManilha.Name = "BadgeManilha"
    badgeManilha.Size = UDim2.new(1, -10, 0.19, 0)
    badgeManilha.Position = UDim2.new(0.5, 0, 0.885, 0)
    badgeManilha.AnchorPoint = Vector2.new(0.5, 0.5)
    badgeManilha.BackgroundColor3 = Color3.fromRGB(48, 36, 10)
    badgeManilha.BackgroundTransparency = 0.08
    badgeManilha.BorderSizePixel = 0
    badgeManilha.Parent = painelVira
    Instance.new("UICorner", badgeManilha).CornerRadius = UDim.new(0, 7)

    local strokeManilha = Instance.new("UIStroke", badgeManilha)
    strokeManilha.Color = COR_OURO
    strokeManilha.Thickness = 1.4
    strokeManilha.Transparency = 0.15

    local padBadge = Instance.new("UIPadding", badgeManilha)
    padBadge.PaddingLeft = UDim.new(0, 4)
    padBadge.PaddingRight = UDim.new(0, 4)
    padBadge.PaddingTop = UDim.new(0, 2)
    padBadge.PaddingBottom = UDim.new(0, 2)

    local lblManilha = Instance.new("TextLabel")
    lblManilha.Name = "TextoManilha"
    lblManilha.Size = UDim2.new(1, 0, 1, 0)
    lblManilha.BackgroundTransparency = 1
    lblManilha.Text = "Manilha: " .. tostring(valorManilha or "?")
    lblManilha.TextColor3 = Color3.fromRGB(255, 228, 100)
    lblManilha.Font = Enum.Font.GothamBlack
    lblManilha.TextScaled = true
    lblManilha.Parent = badgeManilha
    local limManilha = Instance.new("UITextSizeConstraint", lblManilha)
    limManilha.MaxTextSize = 13
    limManilha.MinTextSize = 8
end

function ScoreUI.AtualizarSkinVira(nomeSkin)
    if imgViraAtual and imgViraAtual.Parent and viraAtual then
        CardSettings.AplicarSkinCarta(imgViraAtual, viraAtual.valor, viraAtual.naipe, false, nomeSkin or "Padrao")
    end
end

function ScoreUI.LimparVira()
    viraAtual = nil
    imgViraAtual = nil
    if painelVira then
        painelVira.Visible = false
        for _, filho in ipairs(painelVira:GetChildren()) do
            if not filho:IsA("UICorner") and not filho:IsA("UIStroke") then
                filho:Destroy()
            end
        end
    end
end

function ScoreUI.ObterPainelVira()
    return painelVira
end

function ScoreUI.ObterContainerInfo()
    return containerInfoScore
end

function ScoreUI.ObterPainelEstatisticas()
    return painelEstatisticas
end

function ScoreUI.AtualizarStatus(msg, val)
    if not textoCronometro then return end
    local nome = GameConfig.StateDisplayNames[msg] or msg
    local num = tonumber(val)
    textoCronometro.Text = (num and num > 0) and (nome .. " " .. num) or nome
    textoCronometro.Visible = true
end

function ScoreUI.AtualizarPlacar(meu, inimigo)
    if textoPlacarJogo then
        textoPlacarJogo.Text = "JOGO: " .. meu .. " x " .. inimigo
    end
end

function ScoreUI.AtualizarValorRodada(val, estaSentado)
    if textoValorRodada then
        textoValorRodada.Text = "VALE: " .. tostring(val)
        textoValorRodada.Visible = estaSentado
    end
end

function ScoreUI.AtualizarEstatisticas(parceiro, nossasQuedas, quedasInimigo, estaSentado, historicoQuedas)
    if not painelEstatisticas then return end
    painelEstatisticas.Visible = estaSentado
    if textoEstatisticas then
        textoEstatisticas.Text = "Dupla: " .. (parceiro or "Ninguém")
    end
    atualizarCirculosQuedas(nossasQuedas, quedasInimigo, historicoQuedas)
end

function ScoreUI.DefinirVisibilidade(visivel)
    if painelEstatisticas then painelEstatisticas.Visible = visivel end
    if textoPlacarJogo then textoPlacarJogo.Visible = visivel end
    if painelVira then painelVira.Visible = visivel end
    if textoValorRodada then textoValorRodada.Visible = visivel end
end

function ScoreUI.MostrarPlacar(estaSentado)
    if textoPlacarJogo then textoPlacarJogo.Visible = estaSentado end
end

function ScoreUI.OcultarPlacar()
    if textoPlacarJogo then textoPlacarJogo.Visible = false end
end

return ScoreUI

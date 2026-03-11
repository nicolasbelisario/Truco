local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players") 
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local VisuaisMesa = {}

-- CONFIGURAÇÕES VISUAIS
local TAMANHO_CARTA = Vector3.new(1.05, 0.02, 0.7) 
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Variáveis da Mesa Atual
local pastaMesaAtual = nil
local containerCartas = nil
local pastaCadeiras = nil
local modeloMesa = nil
local tampoMesa = nil

-- Posições Relativas (Offsets para as 4 cadeiras jogarem pro centro)
local POSICOES_MESA = {
    [1] = CFrame.new(0, 0.05, 1.2),
    [2] = CFrame.new(1.2, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0),
    [3] = CFrame.new(0, 0.05, -1.2) * CFrame.Angles(0, math.rad(180), 0),
    [4] = CFrame.new(-1.2, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0),
}

-- [MÉTODO] Salva as referências do cenário da mesa que o jogador sentou
function VisuaisMesa.DefinirMesaAtual(modelo)
    if not modelo then
        pastaMesaAtual = nil
        return
    end
    pastaMesaAtual = modelo
    containerCartas = pastaMesaAtual:FindFirstChild("CartasNaMesa")
    pastaCadeiras = pastaMesaAtual:FindFirstChild("Cadeiras")
    modeloMesa = pastaMesaAtual:FindFirstChild("Mesa") 
    
    if modeloMesa then
        tampoMesa = modeloMesa:FindFirstChild("Topo")
    end

    if not containerCartas then warn("VisuaisMesa: Faltou pasta 'CartasNaMesa'") end
    if not tampoMesa then warn("VisuaisMesa: Faltou 'Topo' da mesa") end
end

-- [MÉTODO ÚNICO E SIMPLIFICADO] Descobre o número da cadeira (1 a 4) e o Personagem 3D, seja Bot ou Player
local function ObterDadosAssentoEAvatar(alvo)
    if not pastaCadeiras then return 1, nil end
    
    for _, caixaAssento in ipairs(pastaCadeiras:GetChildren()) do
        local numAssento = tonumber(caixaAssento.Name:match("%d+"))
        local assentoRoblox = caixaAssento:FindFirstChildWhichIsA("Seat") or caixaAssento
        
        -- Se for Jogador Real
        if typeof(alvo) == "Instance" and alvo:IsA("Player") then
            if assentoRoblox:IsA("Seat") and assentoRoblox.Occupant and assentoRoblox.Occupant.Parent == alvo.Character then
                return numAssento, alvo.Character
            end
        -- Se for Bot (string)
        elseif type(alvo) == "string" then
            local botModel = caixaAssento:FindFirstChild(alvo)
            if botModel then
                return numAssento, botModel
            end
        end
    end
    return 1, nil -- Fallback de segurança
end

-- [MÉTODO] Cria a carta fisicamente na mesa e a joga no centro
function VisuaisMesa.GerarCarta(jogadorOuNome, valor, naipe, estaEscondida, nomeSkin)
    if not pastaMesaAtual or not containerCartas or not tampoMesa then return end

    local numCadeira, personagemAlvo = ObterDadosAssentoEAvatar(jogadorOuNome)
    local nomeJogador = typeof(jogadorOuNome) == "Instance" and jogadorOuNome.Name or jogadorOuNome
    
    nomeSkin = nomeSkin or "Padrao" -- Garantia de segurança

    -- 2. Criação da Carta (Part 3D)
    local pecaCarta = Instance.new("Part")
    pecaCarta.Name = "Card_" .. nomeJogador
    pecaCarta.Size = TAMANHO_CARTA
    pecaCarta.Material = Enum.Material.Plastic
    pecaCarta.Anchored = true
    pecaCarta.CanCollide = false
    
    -- Face Cima
    local guiCima = Instance.new("SurfaceGui")
    guiCima.Face = Enum.NormalId.Top
    guiCima.CanvasSize = Vector2.new(700, 1050)
    guiCima.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    guiCima.Parent = pecaCarta
    
    local imgCima = Instance.new("ImageLabel")
    imgCima.Size = UDim2.new(1, 0, 1, 0)
    imgCima.BackgroundTransparency = 1
    imgCima.ScaleType = Enum.ScaleType.Fit
    imgCima.Parent = guiCima
    
    -- Aplica na parte de Cima (Aberta ou Escondida baseada na jogada)
    CardSettings.AplicarSkinCarta(imgCima, valor, naipe, estaEscondida, nomeSkin)
    
    local guiBaixo = guiCima:Clone()
    guiBaixo.Face = Enum.NormalId.Bottom
    guiBaixo.Parent = pecaCarta
    
    CardSettings.AplicarSkinCarta(guiBaixo.ImageLabel, valor, naipe, true, nomeSkin)
    
    -- 3. Ponto de Partida (Do peito ou de cima da mesa)
    local posInicial = tampoMesa.Position + Vector3.new(0, 4, 0)
    if personagemAlvo and personagemAlvo:FindFirstChild("HumanoidRootPart") then
        local hrp = personagemAlvo.HumanoidRootPart
        posInicial = hrp.Position + (hrp.CFrame.LookVector * 1.5)
    end
    
    pecaCarta.Position = posInicial
    pecaCarta.CFrame = CFrame.new(posInicial) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), 0)
    pecaCarta.Parent = containerCartas
    
    -- 4. Animação suave para ir ao meio da mesa
    local posFinalY = tampoMesa.Position.Y + (tampoMesa.Size.Y / 2) + (TAMANHO_CARTA.Y / 2)
    local cframeAlvoBase = POSICOES_MESA[numCadeira] or CFrame.new(0,0,0)
    local rotBaguncada = CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
    
    local posFinalVector = Vector3.new(tampoMesa.Position.X, posFinalY, tampoMesa.Position.Z)
    local cframeFinal = CFrame.new(posFinalVector) * cframeAlvoBase * rotBaguncada
    
    TweenService:Create(pecaCarta, TWEEN_INFO, {CFrame = cframeFinal}):Play()
end

-- [MÉTODO] Faz as cartas sumirem voando para cima
function VisuaisMesa.LimparMesa()
    if not containerCartas then return end
    for _, carta in ipairs(containerCartas:GetChildren()) do
        if carta:IsA("BasePart") then
            TweenService:Create(carta, TweenInfo.new(0.5), {
                Transparency = 1, 
                Position = carta.Position + Vector3.new(0, 1, 0)
            }):Play()
            Debris:AddItem(carta, 0.5)
        end
    end
end

return VisuaisMesa
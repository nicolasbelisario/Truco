local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players") -- Necessário
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local TableVisuals = {}

-- CONFIGURAÇÕES VISUAIS
local CARD_SIZE = Vector3.new(1.05, 0.02, 0.7) 
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Variáveis da Mesa Atual
local currentTableFolder = nil
local cartasContainer = nil
local cadeirasFolder = nil
local mesaModel = nil
local tampoMesa = nil

-- Posições Relativas (Offsets)
local POSICOES_MESA = {
    [1] = CFrame.new(0, 0.05, 1.2),
    [2] = CFrame.new(1.2, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0),
    [3] = CFrame.new(0, 0.05, -1.2) * CFrame.Angles(0, math.rad(180), 0),
    [4] = CFrame.new(-1.2, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0),
}

function TableVisuals.SetCurrentTable(tableModel)
    if not tableModel then
        currentTableFolder = nil
        return
    end
    currentTableFolder = tableModel
    
    -- Tenta achar os containers
    cartasContainer = currentTableFolder:FindFirstChild("CartasNaMesa")
    cadeirasFolder = currentTableFolder:FindFirstChild("Cadeiras")
    mesaModel = currentTableFolder:FindFirstChild("Mesa") 
    
    if mesaModel then
        tampoMesa = mesaModel:FindFirstChild("Topo")
    end

    -- DEBUG: Avisa se faltar algo essencial
    if not cartasContainer then warn("TableVisuals: Pasta 'CartasNaMesa' não encontrada em " .. tableModel.Name) end
    if not tampoMesa then warn("TableVisuals: Part 'Topo' não encontrada em " .. tableModel.Name) end
end

-- Função auxiliar para localizar o Bot Visual na mesa
local function FindBotCharacterInTable(botName)
    if not cadeirasFolder then return nil end
    
    -- Procura dentro de cada cadeira
    for _, seatContainer in ipairs(cadeirasFolder:GetChildren()) do
        -- O bot visual costuma ser filho da Cadeira (ex: Cadeira2 -> Bot Rival 1)
        local botModel = seatContainer:FindFirstChild(botName)
        if botModel then return botModel end
    end
    return nil
end

-- Função inteligente que descobre a cadeira baseada no Jogador OU Nome do Bot
local function GetSeatNumberFromTarget(target)
    if not cadeirasFolder then return 1 end
    
    for _, seatContainer in ipairs(cadeirasFolder:GetChildren()) do
        local seatName = seatContainer.Name -- "Cadeira1"
        local seatNum = tonumber(seatName:match("%d+"))
        
        -- Verifica se tem Seat object
        local seatObject = seatContainer:FindFirstChildWhichIsA("Seat") or seatContainer
        
        if typeof(target) == "Instance" and target:IsA("Player") then
            -- Lógica para Jogador Real
            if seatObject:IsA("Seat") and seatObject.Occupant and seatObject.Occupant.Parent == target.Character then
                return seatNum
            end
        elseif type(target) == "string" then
            -- Lógica para BOT (String)
            -- Verifica se o nome do Bot está dentro dessa pasta de cadeira
            if seatContainer:FindFirstChild(target) then
                return seatNum
            end
        end
    end
    return nil -- Não achou
end

-- SpawnCard agora aceita (Player Instance) OU (String Name)
function TableVisuals.SpawnCard(playerOrName, rank, suit, isHidden)
	-- DEBUG: Verifica se tudo foi inicializado antes de tentar spawnar
    if not currentTableFolder then 
        warn("TableVisuals: Tentativa de SpawnCard sem mesa definida (currentTableFolder is nil)")
        return 
    end
    if not cartasContainer or not tampoMesa then 
        warn("TableVisuals: Impossível spawnar carta. CartasNaMesa ou TampoMesa não encontrados.")
        return 
    end

    if not currentTableFolder or not cartasContainer or not tampoMesa then return end

    local character = nil
    local playerName = ""
    local seatNum = 1

    -- 1. Identificar quem é e onde está
    if typeof(playerOrName) == "Instance" and playerOrName:IsA("Player") then
        playerName = playerOrName.Name
        character = playerOrName.Character
        seatNum = GetSeatNumberFromTarget(playerOrName) or 1
    elseif type(playerOrName) == "string" then
        playerName = playerOrName
        character = FindBotCharacterInTable(playerName)
        seatNum = GetSeatNumberFromTarget(playerName) or 2 -- Fallback
    end

    -- 2. Criação da Carta
    local cardPart = Instance.new("Part")
    cardPart.Name = "Card_" .. playerName
    cardPart.Size = CARD_SIZE
    cardPart.Material = Enum.Material.Plastic
    cardPart.Color = Color3.new(1, 1, 1)
    cardPart.Anchored = true
    cardPart.CanCollide = false
    cardPart.CastShadow = true
    
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.CanvasSize = Vector2.new(700, 1050)
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    surfaceGui.Parent = cardPart
    
    local imgLabel = Instance.new("ImageLabel")
    imgLabel.Size = UDim2.new(1, 0, 1, 0)
    imgLabel.BackgroundTransparency = 1
    imgLabel.ScaleType = Enum.ScaleType.Fit
    imgLabel.Parent = surfaceGui
    
    if isHidden then
        imgLabel.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"
    else
        local key = rank .. "_" .. suit
        imgLabel.Image = CardSettings.Images[key] or ""
    end
    
    local backSurface = surfaceGui:Clone()
    backSurface.Face = Enum.NormalId.Bottom
    backSurface.Parent = cardPart
    backSurface.ImageLabel.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"

    -- 3. Posição Inicial (Sai do peito/mão do personagem)
    local startPos = tampoMesa.Position + Vector3.new(0, 4, 0)
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        -- Faz a carta sair um pouco a frente do boneco
        startPos = hrp.Position + (hrp.CFrame.LookVector * 1.5)
    end
    
    cardPart.Position = startPos
    -- Rotação aleatória inicial para dar efeito
    cardPart.CFrame = CFrame.new(startPos) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), 0)
    cardPart.Parent = cartasContainer
    
    -- 4. Animação para o Destino
    local centroMesa = tampoMesa.Position
    local alturaFinal = centroMesa.Y + (tampoMesa.Size.Y / 2) + (CARD_SIZE.Y / 2)
    
    local targetBaseCFrame = POSICOES_MESA[seatNum] or CFrame.new(0,0,0)
    -- Adiciona uma rotaçãozinha bagunçada para parecer natural
    local randomMessyRotation = CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
    
    local finalPos = Vector3.new(centroMesa.X, alturaFinal, centroMesa.Z)
    local finalCFrame = CFrame.new(finalPos) * targetBaseCFrame * randomMessyRotation
    
    local tween = TweenService:Create(cardPart, TWEEN_INFO, {CFrame = finalCFrame})
    tween:Play()
    
    -- Opcional: Efeito sonoro 3D na carta
    -- local sound = Instance.new("Sound", cardPart) ...
end

function TableVisuals.ClearTable()
    if not cartasContainer then return end
    for _, child in ipairs(cartasContainer:GetChildren()) do
        if child:IsA("BasePart") then
            local tween = TweenService:Create(child, TweenInfo.new(0.5), {
                Transparency = 1, 
                Position = child.Position + Vector3.new(0, 1, 0)
            })
            tween:Play()
            Debris:AddItem(child, 0.5)
        end
    end
end

return TableVisuals
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local TableVisuals = {}

-- CONFIGURAÇÕES VISUAIS
local CARD_SIZE = Vector3.new(0.7, 0.02, 1.05) -- Tamanho da carta 3D
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- REFERÊNCIAS DA HIERARQUIA (Baseado nas suas imagens)
local mesaFolder = workspace:WaitForChild("MesaTruco")
local cartasContainer = mesaFolder:WaitForChild("CartasNaMesa")
local cadeirasFolder = mesaFolder:WaitForChild("Cadeiras")

-- Pega a parte física do tampo da mesa
local mesaModel = mesaFolder:WaitForChild("Mesa")
local tampoMesa = mesaModel:WaitForChild("Topo") 

-- Posições relativas ao centro da mesa para cada jogador
-- Como a mesa é redonda, ajustei para formar uma cruz (+) em volta do centro
local POSICOES_MESA = {
	[1] = CFrame.new(0, 0.05, 1.2),   -- Jogador 1 (Frente/Baixo)
	[2] = CFrame.new(1.2, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0),    -- Jogador 2 (Direita)
	[3] = CFrame.new(0, 0.05, -1.2) * CFrame.Angles(0, math.rad(180), 0),  -- Jogador 3 (Topo)
	[4] = CFrame.new(-1.2, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0),  -- Jogador 4 (Esquerda)
}

-- Tenta descobrir o número da cadeira do jogador
local function GetPlayerSeatNumber(player)
	for _, seat in ipairs(cadeirasFolder:GetChildren()) do
		if seat:IsA("Seat") and seat.Occupant and seat.Occupant.Parent == player.Character then
			-- Extrai o número do nome (ex: "Cadeira1" -> 1)
			return tonumber(seat.Name:match("%d+"))
		end
	end
	return nil
end

-- Se não achar a cadeira, chuta a posição baseada na proximidade (fallback)
local function GetBestSeatPosition(player)
	local char = player.Character
	if not char or not char.PrimaryPart then return 1 end
	
	local seatNum = GetPlayerSeatNumber(player)
	if seatNum then return seatNum end

	local shortestDist = math.huge
	local bestSeat = 1
	
	for _, seat in ipairs(cadeirasFolder:GetChildren()) do
		if seat:IsA("Part") or seat:IsA("Seat") then
			local dist = (seat.Position - char.PrimaryPart.Position).Magnitude
			if dist < shortestDist then
				shortestDist = dist
				bestSeat = tonumber(seat.Name:match("%d+")) or 1
			end
		end
	end
	return bestSeat
end

function TableVisuals.SpawnCard(player, rank, suit, isHidden)
	-- 1. Cria a Parte Física
	local cardPart = Instance.new("Part")
	cardPart.Name = "Card_" .. player.Name
	cardPart.Size = CARD_SIZE
	cardPart.Material = Enum.Material.Plastic
	cardPart.Color = Color3.new(1, 1, 1)
	cardPart.Anchored = true
	cardPart.CanCollide = false
	cardPart.CastShadow = true
	
	-- 2. Textura (SurfaceGui)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 200 
	surfaceGui.Parent = cardPart
	
	local imgLabel = Instance.new("ImageLabel")
	imgLabel.Size = UDim2.new(1, 0, 1, 0)
	imgLabel.BackgroundTransparency = 1
	-- CORREÇÃO DA ROTAÇÃO DA IMAGEM: 
	-- Se a imagem estiver vindo de lado, podemos rotacionar o ImageLabel aqui.
	-- Tente 90 ou -90 se ainda estiver errado.
	imgLabel.Rotation = 90 
	imgLabel.Parent = surfaceGui
	
	if isHidden then
		imgLabel.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"
	else
		local key = rank .. "_" .. suit
		imgLabel.Image = CardSettings.Images[key] or ""
	end
	
	-- 3. Posição Inicial
	local startPos = tampoMesa.Position + Vector3.new(0, 5, 0)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		startPos = player.Character.HumanoidRootPart.Position + (player.Character.HumanoidRootPart.CFrame.LookVector * 2)
	end
	
	cardPart.Position = startPos
	-- CORREÇÃO DA ROTAÇÃO 3D:
	-- A carta deve começar deitada (Face Top virada pra cima) e girada aleatoriamente no Y.
	cardPart.CFrame = CFrame.new(startPos) * CFrame.Angles(0, math.rad(math.random(0,360)), 0)
	cardPart.Parent = cartasContainer
	
	-- 4. Destino
	local seatNum = GetBestSeatPosition(player)
	local centroMesa = tampoMesa.Position
	local alturaFinal = centroMesa.Y + (tampoMesa.Size.Y / 2) + (CARD_SIZE.Y / 2)
	
	local targetOffset = POSICOES_MESA[seatNum] or CFrame.new(0,0,0)
	local randomRotation = CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
	
	local finalPos = Vector3.new(centroMesa.X, alturaFinal, centroMesa.Z)
	local finalCFrame = CFrame.new(finalPos) * targetOffset * randomRotation
	
	-- 5. Animação
	local tween = TweenService:Create(cardPart, TWEEN_INFO, {CFrame = finalCFrame})
	tween:Play()
end

function TableVisuals.ClearTable()
	for _, child in ipairs(cartasContainer:GetChildren()) do
		if child:IsA("BasePart") then
			-- Efeito de sumir: Sobe e fica transparente
			local tween = TweenService:Create(child, TweenInfo.new(0.5), {
				Transparency = 1, 
				Position = child.Position + Vector3.new(0, 2, 0)
			})
			tween:Play()
			Debris:AddItem(child, 0.5)
		end
	end
end

return TableVisuals
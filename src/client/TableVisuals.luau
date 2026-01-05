local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local TableVisuals = {}

-- CONFIGURAÇÕES VISUAIS
-- DEFINITIVO: Formato RETRATO (Mais comprido no Z).
-- X = Largura (Curto), Y = Espessura, Z = Altura (Comprido)
local CARD_SIZE = Vector3.new(1.05, 0.02, 0.7) 
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- REFERÊNCIAS
local mesaFolder = workspace:WaitForChild("MesaTruco")
local cartasContainer = mesaFolder:WaitForChild("CartasNaMesa")
local cadeirasFolder = mesaFolder:WaitForChild("Cadeiras")
local mesaModel = mesaFolder:WaitForChild("Mesa")
local tampoMesa = mesaModel:WaitForChild("Topo") 

-- Posições Finais na Mesa
-- Como a Part agora é "Retrato" (comprida no Z), precisamos girar a Part em 90 graus no Y
-- para ela ficar deitada de lado para os jogadores 2 e 4.
local POSICOES_MESA = {
	[1] = CFrame.new(0, 0.05, 1.2),   -- Jogador 1 (Frente) -> Carta Reta
	[2] = CFrame.new(1.2, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0), -- Jogador 2 (Direita) -> Gira 90 graus
	[3] = CFrame.new(0, 0.05, -1.2) * CFrame.Angles(0, math.rad(180), 0), -- Jogador 3 (Frente oposta) -> Gira 180
	[4] = CFrame.new(-1.2, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0), -- Jogador 4 (Esquerda) -> Gira -90
}

local function GetPlayerSeatNumber(player)
	for _, seat in ipairs(cadeirasFolder:GetChildren()) do
		if seat:IsA("Seat") and seat.Occupant and seat.Occupant.Parent == player.Character then
			return tonumber(seat.Name:match("%d+"))
		end
	end
	return nil
end

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
	-- 1. Parte Física
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
	-- CanvasSize garante que o Roblox não tente esticar a imagem erraticamente
	surfaceGui.CanvasSize = Vector2.new(700, 1050) -- Proporção aproximada 2:3
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.Parent = cardPart
	
	local imgLabel = Instance.new("ImageLabel")
	imgLabel.Size = UDim2.new(1, 0, 1, 0)
	imgLabel.BackgroundTransparency = 1
	imgLabel.ScaleType = Enum.ScaleType.Fit -- Garante que a imagem caiba inteira
	
	-- CORREÇÃO PRINCIPAL: Rotação ZERO. A imagem entra reta na peça.
	imgLabel.Rotation = 0 
	imgLabel.Parent = surfaceGui
	
	if isHidden then
		imgLabel.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"
	else
		local key = rank .. "_" .. suit
		imgLabel.Image = CardSettings.Images[key] or ""
	end
	
	-- (Opcional) Verso da carta
	local backSurface = surfaceGui:Clone()
	backSurface.Face = Enum.NormalId.Bottom
	backSurface.Parent = cardPart
	backSurface.ImageLabel.Image = CardSettings.Images["CardBack"] or "rbxassetid://0"

	-- 3. Posição Inicial
	local startPos = tampoMesa.Position + Vector3.new(0, 5, 0)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		startPos = player.Character.HumanoidRootPart.Position + (player.Character.HumanoidRootPart.CFrame.LookVector * 2)
	end
	
	cardPart.Position = startPos
	
	-- Começa "reta" (sem girar no eixo Z ou X para não ficar de lado), apenas rotação aleatória no Y (giro de mesa)
	cardPart.CFrame = CFrame.new(startPos) * CFrame.Angles(0, math.rad(math.random(0,360)), 0)
	cardPart.Parent = cartasContainer
	
	-- 4. Destino
	local seatNum = GetBestSeatPosition(player)
	local centroMesa = tampoMesa.Position
	local alturaFinal = centroMesa.Y + (tampoMesa.Size.Y / 2) + (CARD_SIZE.Y / 2)
	
	-- Offset base para onde a carta vai (relativo ao centro)
	local targetBaseCFrame = POSICOES_MESA[seatNum] or CFrame.new(0,0,0)
	
	-- "Bagunça" natural: gira um pouquinho a carta para ela não ficar 100% alinhada roboticamente
	local randomMessyRotation = CFrame.Angles(0, math.rad(math.random(-20, 20)), 0)
	
	-- Monta o CFrame final
	local finalPos = Vector3.new(centroMesa.X, alturaFinal, centroMesa.Z)
	
	-- A ordem de multiplicação importa: Posição * Rotação do Lugar * Rotação da "Bagunça"
	local finalCFrame = CFrame.new(finalPos) * targetBaseCFrame * randomMessyRotation
	
	local tween = TweenService:Create(cardPart, TWEEN_INFO, {CFrame = finalCFrame})
	tween:Play()
end

function TableVisuals.ClearTable()
	for _, child in ipairs(cartasContainer:GetChildren()) do
		if child:IsA("BasePart") then
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local SeatManager = {}
local playersSeated = {}
local onSeatedChangeCallback = nil -- Variável para armazenar o aviso ao GameManager

-- Função interna para travar ou destravar o pulo do jogador
local function setJumpState(character, canJump)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if canJump then
            humanoid.JumpPower = 50 -- Valor padrão do Roblox
        else
            humanoid.JumpPower = 0
        end
    end
end

-- Inicializa o sistema de assentos e aceita uma função de aviso opcional
function SeatManager.Init(callback)
    onSeatedChangeCallback = callback -- Define a função que será chamada em mudanças
    
    local mesaTruco = workspace:WaitForChild("MesaTruco")
    local pastaCadeiras = mesaTruco:WaitForChild("Cadeiras")
    
    print("SeatManager: Iniciando busca por cadeiras em " .. pastaCadeiras:GetFullName())

    for _, modeloCadeira in ipairs(pastaCadeiras:GetChildren()) do
        local seat = modeloCadeira:FindFirstChildWhichIsA("Seat")
        
        if seat then
            seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                local humanoid = seat.Occupant
                if humanoid then
                    local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
                    if player then
                        playersSeated[modeloCadeira.Name] = player
                        print(player.Name .. " sentou na " .. modeloCadeira.Name)
                        
                        -- Notifica o servidor para atualizar a UI dos jogadores
                        if onSeatedChangeCallback then onSeatedChangeCallback() end
                        
                        SeatManager.CheckPlayers()
                    end
                else
                    -- Identifica quem saiu da cadeira para restaurar o pulo e limpar a lista
                    for name, player in pairs(playersSeated) do
                        if name == modeloCadeira.Name then
                            if player.Character then
                                setJumpState(player.Character, true)
                            end
                            print(player.Name .. " saiu da " .. modeloCadeira.Name)
                            playersSeated[name] = nil
                            
                            -- Notifica o servidor que um jogador saiu
                            if onSeatedChangeCallback then onSeatedChangeCallback() end
                            break
                        end
                    end
                end
            end)
        end
    end
end

function SeatManager.GetSeatedPlayers()
    local count = 0
    for _ in pairs(playersSeated) do count += 1 end
    return count, playersSeated
end

function SeatManager.CheckPlayers()
    local count, _ = SeatManager.GetSeatedPlayers()
    print("Jogadores na mesa: " .. count .. "/4")
    
    if count == GameConfig.MAX_PLAYERS then
        print("MESA CHEIA! Prontos para o Truco.")
    end
end

-- Trava o pulo do jogador durante a partida
function SeatManager.SetJumpLock(player, locked)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = locked and 0 or 50
        end
    end
end

return SeatManager

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- local SeatManager = {}
-- local playersSeated = {}
-- local onSeatedChange = nil

-- -- Função interna para travar ou destravar o pulo do jogador
-- local function setJumpState(character, canJump)
-- 	local humanoid = character:FindFirstChildOfClass("Humanoid")
-- 	if humanoid then
-- 		if canJump then
-- 			humanoid.JumpPower = 50 -- Valor padrão do Roblox
-- 		else
-- 			humanoid.JumpPower = 0
-- 		end
-- 	end
-- end

-- function SeatManager.Init()
--     onSeatedChange = callback
-- 	local mesaTruco = workspace:WaitForChild("MesaTruco")
-- 	local pastaCadeiras = mesaTruco:WaitForChild("Cadeiras")
	
-- 	print("SeatManager: Iniciando busca por cadeiras em " .. pastaCadeiras:GetFullName())

-- 	for _, modeloCadeira in ipairs(pastaCadeiras:GetChildren()) do
-- 		local seat = modeloCadeira:FindFirstChildWhichIsA("Seat")
		
-- 		if seat then
-- 			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
-- 				local humanoid = seat.Occupant
-- 				if humanoid then
-- 					local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
-- 					if player then
-- 						playersSeated[modeloCadeira.Name] = player
-- 						print(player.Name .. " sentou na " .. modeloCadeira.Name)
						
-- 						SeatManager.CheckPlayers()
-- 					end
-- 				else
-- 					-- Como não temos mais o humanoid (ele levantou ou saiu), 
-- 					-- precisamos identificar quem saiu da tabela para restaurar o pulo se necessário
-- 					-- Nota: Se o jogador saiu do jogo, o personagem some, então não precisamos resetar o pulo dele.
-- 					for name, player in pairs(playersSeated) do
-- 						if name == modeloCadeira.Name then
-- 							if player.Character then
-- 								setJumpState(player.Character, true)
-- 							end
-- 							print(player.Name .. " saiu da " .. modeloCadeira.Name)
-- 							playersSeated[name] = nil
-- 							break
-- 						end
-- 					end
-- 				end
-- 			end)
-- 		end
-- 	end
-- end

-- function SeatManager.GetSeatedPlayers()
-- 	local count = 0
-- 	for _ in pairs(playersSeated) do count += 1 end
-- 	return count, playersSeated
-- end

-- function SeatManager.CheckPlayers()
-- 	local count, _ = SeatManager.GetSeatedPlayers()
-- 	print("Jogadores na mesa: " .. count .. "/4")
	
-- 	if count == GameConfig.MAX_PLAYERS then
-- 		print("MESA CHEIA! Prontos para o Truco.")
-- 		-- No futuro, aqui chamaremos o início da partida
-- 	end
-- end

-- function SeatManager.SetJumpLock(player, locked)
-- 	local character = player.Character
-- 	if character then
-- 		local humanoid = character:FindFirstChildOfClass("Humanoid")
-- 		if humanoid then
-- 			humanoid.JumpPower = locked and 0 or 50
-- 		end
-- 	end
-- end

-- return SeatManager
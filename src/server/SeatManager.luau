local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local SeatManager = {}
local playersSeated = {} -- Armazena [NomeCadeira] = Player
local onSeatedChangeCallback = nil 

-- Gerencia a física do pulo (evita que jogadores pulem da cadeira durante o jogo)
local function setJumpState(character, canJump)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = canJump and 50 or 0
    end
end

-- Inicializa o monitoramento das cadeiras
function SeatManager.Init(callback)
    onSeatedChangeCallback = callback
    
    local mesaTruco = workspace:WaitForChild("MesaTruco")
    local pastaCadeiras = mesaTruco:WaitForChild("Cadeiras")
    
    print("SeatManager: Monitorando " .. pastaCadeiras:GetFullName())

    for _, modeloCadeira in ipairs(pastaCadeiras:GetChildren()) do
        local seat = modeloCadeira:FindFirstChildWhichIsA("Seat")
        
        if seat then
            seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                local humanoid = seat.Occupant
                
                if humanoid then
                    -- Jogador sentou
                    local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
                    if player then
                        playersSeated[modeloCadeira.Name] = player
                        print(player.Name .. " sentou na " .. modeloCadeira.Name)
                        
                        if onSeatedChangeCallback then onSeatedChangeCallback() end
                        SeatManager.CheckPlayers()
                    end
                else
                    -- Jogador levantou
                    for name, player in pairs(playersSeated) do
                        if name == modeloCadeira.Name then
                            if player.Character then
                                setJumpState(player.Character, true) -- Restaura o pulo
                            end
                            print(player.Name .. " saiu da " .. modeloCadeira.Name)
                            playersSeated[name] = nil
                            
                            -- Remove UI de jogo
                            Events.GameStatusEvent:FireClient(player, "HIDE_SCOREBOARD")
                            
                            if onSeatedChangeCallback then onSeatedChangeCallback() end
                            break
                        end
                    end
                end
            end)
        end
    end
end

-- Retorna a contagem e a tabela de jogadores sentados
function SeatManager.GetSeatedPlayers()
    local count = 0
    for _ in pairs(playersSeated) do count += 1 end
    return count, playersSeated
end

function SeatManager.CheckPlayers()
    local count, _ = SeatManager.GetSeatedPlayers()
    if count == GameConfig.MAX_PLAYERS then
        print("MESA CHEIA! Aguardando início.")
    end
end

-- Trava/Destrava movimentação
function SeatManager.SetJumpLock(player, locked)
    if player and player.Character then
        setJumpState(player.Character, not locked)
    end
end

return SeatManager
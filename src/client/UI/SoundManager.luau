local SoundService = game:GetService("SoundService")

local SoundManager = {}

local SONS = {
    ["Shuffle"]  = "rbxassetid://128706455708345",
    ["Truco"]    = "rbxassetid://7152989885",
    ["CardPlay"] = "rbxassetid://3456145589",
    ["Victory"]  = "rbxassetid://12222253",
}

local mutado = false
local volume = 1

function SoundManager.Tocar(nomeSom)
    local id = SONS[nomeSom]
    if not id then return end

    local som = Instance.new("Sound")
    som.SoundId = id
    som.Volume = mutado and 0 or volume
    som.Parent = SoundService
    som.Ended:Connect(function() som:Destroy() end)
    som:Play()
end

-- Alterna o estado de mudo e retorna o novo estado (true = mutado)
function SoundManager.AlternarMute()
    mutado = not mutado
    return mutado
end

-- Retorna se o áudio está mutado
function SoundManager.EstaMutado()
    return mutado
end

return SoundManager

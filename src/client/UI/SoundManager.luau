local SoundService = game:GetService("SoundService")

local SoundManager = {}

local SONS = {
    ["Shuffle"]  = "rbxassetid://128706455708345",
    ["Truco"]    = "rbxassetid://7152989885",
    ["CardPlay"] = "rbxassetid://3456145589",
    ["Victory"]  = "rbxassetid://12222253",
}

function SoundManager.Tocar(nomeSom)
    local id = SONS[nomeSom]
    if not id then return end

    local som = Instance.new("Sound")
    som.SoundId = id
    som.Volume = 1
    som.Parent = SoundService
    som.Ended:Connect(function() som:Destroy() end)
    som:Play()
end

return SoundManager
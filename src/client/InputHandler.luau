local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Q then
        Events.SignalEvent:FireServer("LevantarMao")
    elseif input.KeyCode == Enum.KeyCode.E then
        Events.SignalEvent:FireServer("OlharLado")
    end
end)
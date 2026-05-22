local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CameraManager = {}
local Camera = workspace.CurrentCamera

function CameraManager.AplicarTensao(nomeAlvo)
    local alvo = Players:FindFirstChild(nomeAlvo)
    if not alvo or not alvo.Character then return end

    local head = alvo.Character:FindFirstChild("Head")
    if not head then return end

    Camera.CameraType = Enum.CameraType.Scriptable
    local pos = head.Position + (head.CFrame.LookVector * 5) + Vector3.new(0, 1, 0)

    TweenService:Create(Camera, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(pos, head.Position)
    }):Play()
end

function CameraManager.Resetar()
    Camera.CameraType = Enum.CameraType.Custom
end

return CameraManager
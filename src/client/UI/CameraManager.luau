local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CameraManager = {}
local Camera = workspace.CurrentCamera
local pastaMesaAtual = nil

local function obterPersonagemAlvo(nomeAlvo)
    if not nomeAlvo then return nil end

    local jogador = Players:FindFirstChild(nomeAlvo)
    if jogador and jogador.Character then
        return jogador.Character
    end

    if pastaMesaAtual then
        local pastaCadeiras = pastaMesaAtual:FindFirstChild("Cadeiras")
        if pastaCadeiras then
            for _, caixaAssento in ipairs(pastaCadeiras:GetChildren()) do
                local botModel = caixaAssento:FindFirstChild(nomeAlvo)
                if botModel then
                    return botModel
                end
            end
        end
    end

    return nil
end

function CameraManager.DefinirMesaAtual(modeloMesa)
    pastaMesaAtual = modeloMesa
end

function CameraManager.AplicarTensao(nomeAlvo)
    local personagem = obterPersonagemAlvo(nomeAlvo)
    if not personagem then return end

    local head = personagem:FindFirstChild("Head")
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
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CameraManager = {}
local Camera = workspace.CurrentCamera

local pastaMesaAtual = nil
local nomeAssentoAtual = nil
local modoMesaAtivo = false
local modoCameraLivre = false
local emTensao = false
local tweenAtual = nil
local connViewport = nil
local listenersModo = {}

local function obterCamera()
    Camera = workspace.CurrentCamera or Camera
    return Camera
end

local function notificarListeners()
    for _, cb in ipairs(listenersModo) do
        task.spawn(cb, modoCameraLivre, modoMesaAtivo)
    end
end

local function cancelarTween()
    if tweenAtual then
        tweenAtual:Cancel()
        tweenAtual = nil
    end
end

-- Oculta o avatar local apenas para o próprio jogador durante a visão em primeira-pessoa elevada,
-- evitando que a cabeça bloqueie o tampo da mesa e restaurando ao sair ou usar câmera livre.
local function definirVisibilidadeAvatarLocal(ocultar)
    local plr = Players.LocalPlayer
    local char = plr and plr.Character
    if not char then return end

    local valor = ocultar and 1 or 0
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") or desc:IsA("Decal") then
            desc.LocalTransparencyModifier = valor
        end
    end
end

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

local function obterDirecaoAssento(tampoMesa)
    if pastaMesaAtual and nomeAssentoAtual then
        local pastaCadeiras = pastaMesaAtual:FindFirstChild("Cadeiras")
        local caixa = pastaCadeiras and pastaCadeiras:FindFirstChild(nomeAssentoAtual)
        local assento = caixa and (caixa:FindFirstChildWhichIsA("Seat") or caixa:FindFirstChildWhichIsA("BasePart"))
        if assento then
            local delta = Vector3.new(
                assento.Position.X - tampoMesa.Position.X,
                0,
                assento.Position.Z - tampoMesa.Position.Z
            )
            if delta.Magnitude > 0.05 then
                return delta.Unit
            end
            local lookFlat = Vector3.new(-assento.CFrame.LookVector.X, 0, -assento.CFrame.LookVector.Z)
            if lookFlat.Magnitude > 0.05 then
                return lookFlat.Unit
            end
        end
    end
    return Vector3.new(1, 0, 0)
end

local function calcularCFrameMesa()
    if not pastaMesaAtual then return nil end
    local modeloMesa = pastaMesaAtual:FindFirstChild("Mesa")
    local tampoMesa = modeloMesa and modeloMesa:FindFirstChild("Topo")
    if not tampoMesa then return nil end

    local cam = obterCamera()
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local aspect = (vp.X > 10 and vp.Y > 10) and (vp.X / vp.Y) or 1.77
    -- Afasta suavemente em telas estreitas/verticais (mobile portrait) para manter os 3 oponentes visíveis
    local escalaAspecto = math.clamp(1.42 / math.max(aspect, 0.52), 1.0, 1.68)

    local dirParaCadeira = obterDirecaoAssento(tampoMesa)
    local topoSuperficieY = tampoMesa.Position.Y + (tampoMesa.Size.Y / 2)
    local centroTopo = Vector3.new(tampoMesa.Position.X, topoSuperficieY, tampoMesa.Position.Z)

    local distHorizontal = 5.45 * escalaAspecto
    local altura = 3.95 * (1 + (escalaAspecto - 1) * 0.45)

    local camPos = centroTopo + (dirParaCadeira * distHorizontal) + Vector3.new(0, altura, 0)
    local lookTarget = centroTopo - (dirParaCadeira * 0.65) + Vector3.new(0, -0.25, 0)

    return CFrame.lookAt(camPos, lookTarget)
end

local function aplicarCFrameMesa(duracao)
    local cam = obterCamera()
    if not cam then return end
    local cframeAlvo = calcularCFrameMesa()
    if not cframeAlvo then return end

    cancelarTween()
    cam.CameraType = Enum.CameraType.Scriptable
    definirVisibilidadeAvatarLocal(true)

    if duracao and duracao > 0 then
        tweenAtual = TweenService:Create(
            cam,
            TweenInfo.new(duracao, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { CFrame = cframeAlvo }
        )
        tweenAtual:Play()
    else
        cam.CFrame = cframeAlvo
    end
end

local function garantirListenerViewport()
    if connViewport then return end
    local cam = obterCamera()
    if not cam then return end

    connViewport = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if modoMesaAtivo and not modoCameraLivre and not emTensao then
            aplicarCFrameMesa(0)
        end
    end)
end

--[[
    Registra a mesa atual para enquadramento e efeitos de tensão.
]]
function CameraManager.DefinirMesaAtual(modeloMesa, nomeAssento)
    pastaMesaAtual = modeloMesa
    if nomeAssento ~= nil then
        nomeAssentoAtual = nomeAssento
    end
    if not modeloMesa then
        CameraManager.DesativarModoMesa()
    end
end

function CameraManager.DefinirMeuAssento(nomeAssento)
    nomeAssentoAtual = nomeAssento
    if modoMesaAtivo and not modoCameraLivre and not emTensao then
        aplicarCFrameMesa(0.6)
    end
end

--[[
    Ativa a câmera tabletop elevada olhando para Mesa.Topo e os 3 oponentes.
]]
function CameraManager.AtivarModoMesa(modeloMesa, nomeAssento)
    if modeloMesa then pastaMesaAtual = modeloMesa end
    if nomeAssento then nomeAssentoAtual = nomeAssento end
    if not pastaMesaAtual or not nomeAssentoAtual then return end

    modoMesaAtivo = true
    modoCameraLivre = false
    emTensao = false
    garantirListenerViewport()
    aplicarCFrameMesa(0.75)
    notificarListeners()
end

function CameraManager.FocarMesaSeAtivo()
    if modoMesaAtivo and not modoCameraLivre and not emTensao then
        aplicarCFrameMesa(0.55)
    end
end

function CameraManager.DesativarModoMesa()
    modoMesaAtivo = false
    modoCameraLivre = false
    emTensao = false
    nomeAssentoAtual = nil
    cancelarTween()
    definirVisibilidadeAvatarLocal(false)

    local cam = obterCamera()
    if cam then
        cam.CameraType = Enum.CameraType.Custom
    end
    notificarListeners()
end

--[[
    Alterna entre câmera focada na mesa e câmera livre (Custom) enquanto sentado.
]]
function CameraManager.AlternarCameraLivre()
    if not modoMesaAtivo then return false end
    modoCameraLivre = not modoCameraLivre

    if modoCameraLivre then
        cancelarTween()
        definirVisibilidadeAvatarLocal(false)
        local cam = obterCamera()
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
    else
        if not emTensao then
            aplicarCFrameMesa(0.6)
        end
    end

    notificarListeners()
    return modoCameraLivre
end

function CameraManager.EstaCameraLivre()
    return modoCameraLivre
end

function CameraManager.AoMudarModoCamera(callback)
    table.insert(listenersModo, callback)
end

function CameraManager.AplicarTensao(nomeAlvo)
    local personagem = obterPersonagemAlvo(nomeAlvo)
    if not personagem then return end

    local head = personagem:FindFirstChild("Head")
    if not head then return end

    local cam = obterCamera()
    if not cam then return end

    emTensao = true
    definirVisibilidadeAvatarLocal(false)
    cancelarTween()
    cam.CameraType = Enum.CameraType.Scriptable
    local pos = head.Position + (head.CFrame.LookVector * 5) + Vector3.new(0, 1, 0)

    tweenAtual = TweenService:Create(cam, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(pos, head.Position)
    })
    tweenAtual:Play()
end

function CameraManager.Resetar()
    emTensao = false
    if modoMesaAtivo and not modoCameraLivre then
        aplicarCFrameMesa(0.65)
    else
        cancelarTween()
        definirVisibilidadeAvatarLocal(false)
        local cam = obterCamera()
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end

return CameraManager

--[[
    GuideAvatar.luau
    Renderiza a personagem guia da barraca do tutorial (Workspace.Tutorial.copinhodecocacola)
    em um ViewportFrame 3D estilizado (com fallback de thumbnail caso o modelo ainda não tenha feito streaming).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GuideAvatar = {}

local ACENTO = Color3.fromRGB(240, 160, 40)
local BG_RETRATO = Color3.fromRGB(26, 28, 40)

local thumbnailFallbackCache = nil
local buscandoThumbnail = false

local function obterThumbnailFallbackAsync()
    if thumbnailFallbackCache then
        return thumbnailFallbackCache
    end
    if buscandoThumbnail then
        local inicio = tick()
        while buscandoThumbnail and (tick() - inicio) < 4 do
            task.wait(0.1)
        end
        return thumbnailFallbackCache
    end

    buscandoThumbnail = true
    local ok, thumb = pcall(function()
        local userId = Players:GetUserIdFromNameAsync("copinhodecocacola")
        local url, ready = Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.AvatarBust,
            Enum.ThumbnailSize.Size180x180
        )
        if ready and url and url ~= "" then
            return url
        end
        return nil
    end)
    buscandoThumbnail = false

    if ok and thumb then
        thumbnailFallbackCache = thumb
    end
    return thumbnailFallbackCache
end

local function localizarModeloGuiaPronto()
    local pastaTutorial = workspace:FindFirstChild("Tutorial") or workspace:WaitForChild("Tutorial", 12)
    if not pastaTutorial then return nil end

    local modelo = pastaTutorial:FindFirstChild("copinhodecocacola")
        or pastaTutorial:WaitForChild("copinhodecocacola", 12)
    if not modelo then return nil end

    -- Aguarda as partes essenciais replicarem (StreamingEnabled / carregamento inicial)
    local head = modelo:FindFirstChild("Head") or modelo:WaitForChild("Head", 12)
    if not head then return nil end
    local _ = modelo:FindFirstChild("UpperTorso") or modelo:WaitForChild("UpperTorso", 6)

    -- Pequena folga para acessórios (chapéu, cabelo, Zzz) e roupas terminarem de replicar
    task.wait(0.3)
    if not modelo.Parent then return nil end
    return modelo
end

local function clonarModeloComSeguranca(modeloOriginal)
    local restaurar = {}
    if not modeloOriginal.Archivable then
        restaurar[modeloOriginal] = false
        modeloOriginal.Archivable = true
    end
    for _, desc in ipairs(modeloOriginal:GetDescendants()) do
        if not desc.Archivable then
            restaurar[desc] = false
            desc.Archivable = true
        end
    end

    local ok, clone = pcall(function()
        return modeloOriginal:Clone()
    end)

    for inst, valorOriginal in pairs(restaurar) do
        if inst and inst.Parent then
            inst.Archivable = valorOriginal
        end
    end

    if ok then
        return clone
    end
    return nil
end

local function limparCloneParaViewport(modeloClone)
    for _, desc in ipairs(modeloClone:GetDescendants()) do
        if desc:IsA("ProximityPrompt")
            or desc:IsA("BaseScript")
            or desc:IsA("Sound")
            or desc:IsA("BillboardGui")
            or desc:IsA("SurfaceGui") then
            desc:Destroy()
        elseif desc:IsA("BasePart") then
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.CastShadow = false
        end
    end

    local hum = modeloClone:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end

    local hrp = modeloClone:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        hrp.Anchored = true
    end
end

--[[
    Cria um retrato 3D da guia copinhodecocacola dentro de `pai`.
    @param pai Instance: GuiObject pai.
    @param opcoes table?: { Name, Size, Position, AnchorPoint, ZIndex, CornerRadius, MostrarTag }
    @return table: controlador { Container, Viewport, PulsarFala(), Destruir() }
]]
function GuideAvatar.CriarRetrato(pai, opcoes)
    local cfg = opcoes or {}
    local zBase = cfg.ZIndex or 90

    local container = Instance.new("Frame")
    container.Name = cfg.Name or "RetratoGuiaTutorial"
    container.Size = cfg.Size or UDim2.new(0, 96, 0, 108)
    container.Position = cfg.Position or UDim2.new(0, 0, 0, 0)
    container.AnchorPoint = cfg.AnchorPoint or Vector2.new(0, 0)
    container.BackgroundColor3 = BG_RETRATO
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.ZIndex = zBase
    container.Parent = pai
    Instance.new("UICorner", container).CornerRadius = cfg.CornerRadius or UDim.new(0, 14)

    local gradFundo = Instance.new("UIGradient", container)
    gradFundo.Rotation = 90
    gradFundo.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 46, 78)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(28, 28, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 28)),
    })

    local stroke = Instance.new("UIStroke", container)
    stroke.Thickness = 2
    stroke.Color = ACENTO
    stroke.Transparency = 0.12

    -- Imagem de fallback (exibida apenas enquanto/se o modelo 3D não estiver pronto)
    local fallbackImg = Instance.new("ImageLabel")
    fallbackImg.Name = "FallbackThumb"
    fallbackImg.Size = UDim2.new(1, 0, 1, 0)
    fallbackImg.BackgroundTransparency = 1
    fallbackImg.ScaleType = Enum.ScaleType.Crop
    fallbackImg.ImageTransparency = 0
    fallbackImg.Visible = false
    fallbackImg.ZIndex = zBase + 1
    fallbackImg.Parent = container

    -- ViewportFrame 3D com WorldModel (obrigatório para Shirt/Pants/Accessories R15)
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "ViewportGuia"
    viewport.Size = UDim2.new(1, 0, 1, 0)
    viewport.Position = UDim2.new(0, 0, 0, 0)
    viewport.BackgroundTransparency = 1
    viewport.Ambient = Color3.fromRGB(225, 225, 236)
    viewport.LightColor = Color3.fromRGB(255, 250, 238)
    viewport.LightDirection = Vector3.new(-0.8, -1, -1.2)
    viewport.ZIndex = zBase + 2
    viewport.Parent = container

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    local camera = Instance.new("Camera")
    camera.FieldOfView = cfg.FieldOfView or 36
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    if cfg.MostrarTag then
        local tag = Instance.new("TextLabel")
        tag.Name = "TagGuia"
        tag.Size = UDim2.new(1, -8, 0, 18)
        tag.Position = UDim2.new(0.5, 0, 1, -4)
        tag.AnchorPoint = Vector2.new(0.5, 1)
        tag.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        tag.BackgroundTransparency = 0.18
        tag.Text = "GUIA"
        tag.TextColor3 = ACENTO
        tag.Font = Enum.Font.GothamBlack
        tag.TextSize = 10
        tag.ZIndex = zBase + 4
        tag.Parent = container
        Instance.new("UICorner", tag).CornerRadius = UDim.new(1, 0)
    end

    local destruido = false
    local modelo3DCarregado = false
    local tentandoCarregar = false
    local connRender = nil
    local connVisivel = nil
    local baseHeadPos = nil
    local baseLookVec = nil
    local baseRightVec = nil
    local pulsoFalaAte = 0

    local function desconectar()
        destruido = true
        if connRender then
            connRender:Disconnect()
            connRender = nil
        end
        if connVisivel then
            connVisivel:Disconnect()
            connVisivel = nil
        end
    end

    container.AncestryChanged:Connect(function(_, novoPai)
        if not novoPai then
            desconectar()
        end
    end)

    local function tentarCarregarModelo3D()
        if destruido or modelo3DCarregado or tentandoCarregar then return end
        tentandoCarregar = true

        task.spawn(function()
            local modeloOriginal = localizarModeloGuiaPronto()
            if destruido or not modeloOriginal or not worldModel.Parent then
                tentandoCarregar = false
                return
            end

            local clone = clonarModeloComSeguranca(modeloOriginal)
            if destruido or not clone then
                tentandoCarregar = false
                return
            end

            limparCloneParaViewport(clone)
            worldModel:ClearAllChildren()
            clone.Parent = worldModel

            local head = clone:FindFirstChild("Head") or clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
            if not head then
                clone:Destroy()
                tentandoCarregar = false
                return
            end

            modelo3DCarregado = true
            tentandoCarregar = false
            baseHeadPos = head.Position
            baseLookVec = head.CFrame.LookVector
            baseRightVec = head.CFrame.RightVector
            fallbackImg.Visible = false

            local dist = cfg.DistanciaCamera or 3.85
            local offsetY = cfg.OffsetAltura or 0.18
            local lookOffsetY = cfg.LookOffsetY or 0.04

            local function atualizarCamera(t)
                local falando = (tick() < pulsoFalaAte)
                local amp = falando and 0.08 or 0.03
                local freq = falando and 9.5 or 1.8
                local bobY = math.sin(t * freq) * amp
                local swayX = math.cos(t * 1.1) * 0.08

                local camPos = baseHeadPos
                    + (baseLookVec * dist)
                    + (baseRightVec * (0.18 + swayX))
                    + Vector3.new(0, offsetY + bobY, 0)
                local targetPos = baseHeadPos + Vector3.new(0, lookOffsetY + (bobY * 0.35), 0)
                camera.CFrame = CFrame.lookAt(camPos, targetPos)
            end

            atualizarCamera(0)

            local tempo = 0
            if connRender then connRender:Disconnect() end
            connRender = RunService.RenderStepped:Connect(function(dt)
                if destruido or not viewport.Parent then
                    desconectar()
                    return
                end
                if not viewport.Visible or not container.Visible then return end
                tempo += dt
                atualizarCamera(tempo)
            end)
        end)
    end

    -- Carrega fallback rápido apenas enquanto o modelo 3D da barraca ainda não replicou
    task.spawn(function()
        local thumb = obterThumbnailFallbackAsync()
        if not destruido and thumb and not modelo3DCarregado and fallbackImg.Parent then
            fallbackImg.Image = thumb
            fallbackImg.Visible = true
        end
    end)

    -- Carrega o modelo 3D real da barraca (e re-tenta se ficar visível antes de ter replicado)
    tentarCarregarModelo3D()
    connVisivel = container:GetPropertyChangedSignal("Visible"):Connect(function()
        if container.Visible and not modelo3DCarregado then
            tentarCarregarModelo3D()
        end
    end)

    local controlador = {
        Container = container,
        Viewport = viewport,
    }

    function controlador:PulsarFala()
        if destruido or not container.Parent then return end
        if not modelo3DCarregado then
            tentarCarregarModelo3D()
        end
        pulsoFalaAte = tick() + 0.65
        local scale = container:FindFirstChildOfClass("UIScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Parent = container
        end
        scale.Scale = 1.06
        TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1.0,
        }):Play()
    end

    function controlador:Destruir()
        desconectar()
        if container and container.Parent then
            container:Destroy()
        end
    end

    return controlador
end

return GuideAvatar

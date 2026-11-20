local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local VisuaisMesa = {}

-- CONFIGURAÇÕES VISUAIS
-- Na face Top do SurfaceGui no Roblox, o eixo X do Canvas mapeia para o eixo Z da Part
-- e o eixo Y do Canvas mapeia para o eixo X da Part.
local TAMANHO_CARTA_MESA = Vector3.new(1.04, 0.02, 0.72)
local TAMANHO_MONTE = Vector3.new(1.06, 0.24, 0.74)
local TAMANHO_CARTA_MAO = Vector3.new(0.42, 0.60, 0.014)
local RAIO_CARTA_JOGADA = 1.85
local RAIO_PLACA_ASSENTO = 3.28
local TWEEN_JOGADA = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_VIRA = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local COR_EQUIPE_A = Color3.fromRGB(46, 204, 113)
local COR_EQUIPE_B = Color3.fromRGB(231, 76, 60)
local COR_TURNO_ATIVO = Color3.fromRGB(255, 210, 55)
local COR_COASTER_BASE = Color3.fromRGB(36, 40, 52)

-- Variáveis da Mesa Atual
local pastaMesaAtual = nil
local containerCartas = nil
local pastaCadeiras = nil
local modeloMesa = nil
local tampoMesa = nil
local assentoLocalNome = nil

local pastaVisual3D = nil
local pastaJogadas = nil
local pastaCentro = nil
local pastaAssentos = nil
local pastaMaos = nil

local monteDeckPart = nil
local viraCardPart = nil
local viraAtualInfo = nil -- { valor, naipe, skin }
local jogadorTurnoAtual = nil
local ocultarMaoLocal = true

local contagemCartasAssento = {} -- [1..4] = number
local skinsAssento = {}          -- [1..4] = string
local maosAvatares3D = {}        -- [1..4] = { model, handPart, connections }
local placasAssentos = {}        -- [1..4] = { coaster, anchorPart, frame, dot, nameLbl, stroke, nomeExibicao }
local conexoesMesa = {}

local FALLBACK_DIRS = {
    [1] = Vector3.new(1, 0, 0),
    [2] = Vector3.new(0, 0, 1),
    [3] = Vector3.new(-1, 0, 0),
    [4] = Vector3.new(0, 0, -1),
}

local function desconectarLista(lista)
    for _, conn in ipairs(lista) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(lista)
end

local function garantirSubPastas()
    if not containerCartas then return false end

    if not pastaVisual3D or not pastaVisual3D.Parent then
        pastaVisual3D = containerCartas:FindFirstChild("VisualMesa3D")
        if not pastaVisual3D then
            pastaVisual3D = Instance.new("Folder")
            pastaVisual3D.Name = "VisualMesa3D"
            pastaVisual3D.Parent = containerCartas
        end
    end

    local function obterOuCriar(nome)
        local f = pastaVisual3D:FindFirstChild(nome)
        if not f then
            f = Instance.new("Folder")
            f.Name = nome
            f.Parent = pastaVisual3D
        end
        return f
    end

    pastaJogadas = obterOuCriar("Jogadas")
    pastaCentro = obterOuCriar("Centro")
    pastaAssentos = obterOuCriar("Assentos")
    pastaMaos = obterOuCriar("Maos")
    return true
end

local function obterCaixaEAssento(numAssento)
    if not pastaCadeiras then return nil, nil end
    local caixa = pastaCadeiras:FindFirstChild("Cadeira" .. tostring(numAssento))
    if not caixa then return nil, nil end
    local seat = caixa:FindFirstChildWhichIsA("Seat") or caixa:FindFirstChildWhichIsA("BasePart")
    return caixa, seat
end

local function obterDirecaoAssento(numAssento)
    if tampoMesa then
        local _, seat = obterCaixaEAssento(numAssento)
        if seat then
            local delta = Vector3.new(
                seat.Position.X - tampoMesa.Position.X,
                0,
                seat.Position.Z - tampoMesa.Position.Z
            )
            if delta.Magnitude > 0.05 then
                return delta.Unit
            end
        end
    end
    return FALLBACK_DIRS[numAssento] or Vector3.new(1, 0, 0)
end

local function obterDirecaoLocalParaCentro()
    local numLocal = assentoLocalNome and tonumber(assentoLocalNome:match("%d+"))
    if numLocal then
        return -obterDirecaoAssento(numLocal)
    end
    return Vector3.new(-1, 0, 0)
end

-- Calcula a altura exata da superfície de Mesa.Topo no ponto (x, z),
-- considerando o SpecialMesh(Sphere) presente nas mesas.
local function obterAlturaSuperficie(posMundoXZ)
    if not tampoMesa then return 0 end

    local rel = tampoMesa.CFrame:PointToObjectSpace(posMundoXZ)
    local mesh = tampoMesa:FindFirstChildWhichIsA("SpecialMesh")
    local localTopY = tampoMesa.Size.Y / 2

    if mesh and mesh.MeshType == Enum.MeshType.Sphere then
        local rx = math.max(tampoMesa.Size.X / 2, 0.01)
        local rz = math.max(tampoMesa.Size.Z / 2, 0.01)
        local normSq = (rel.X / rx) ^ 2 + (rel.Z / rz) ^ 2
        localTopY = (tampoMesa.Size.Y / 2) * math.sqrt(math.max(0, 1 - math.min(normSq, 1)))
    end

    return (tampoMesa.CFrame * CFrame.new(rel.X, localTopY, rel.Z)).Position.Y
end

local function obterDadosAssentoEAvatar(alvo)
    if not pastaCadeiras then return 1, nil, nil end

    for _, caixaAssento in ipairs(pastaCadeiras:GetChildren()) do
        local numAssento = tonumber(caixaAssento.Name:match("%d+"))
        local assentoRoblox = caixaAssento:FindFirstChildWhichIsA("Seat")

        if typeof(alvo) == "Instance" and alvo:IsA("Player") then
            if assentoRoblox and assentoRoblox.Occupant and assentoRoblox.Occupant.Parent == alvo.Character then
                return numAssento or 1, alvo.Character, assentoRoblox
            end
        elseif type(alvo) == "string" then
            local botModel = caixaAssento:FindFirstChild(alvo)
            if botModel and botModel:IsA("Model") then
                return numAssento or 1, botModel, assentoRoblox
            end
            if assentoRoblox and assentoRoblox.Occupant then
                local char = assentoRoblox.Occupant.Parent
                local plr = Players:GetPlayerFromCharacter(char)
                if plr and (plr.Name == alvo or plr.DisplayName == alvo) then
                    return numAssento or 1, char, assentoRoblox
                end
            end
        end
    end

    return 1, nil, nil
end

local function obterOcupanteCadeira(numAssento)
    local caixa, seat = obterCaixaEAssento(numAssento)
    if not caixa then return nil, nil, false, "Padrao" end

    if seat and seat.Occupant then
        local char = seat.Occupant.Parent
        local plr = Players:GetPlayerFromCharacter(char)
        if plr then
            local skin = plr:GetAttribute("SkinEquipada") or skinsAssento[numAssento] or "Padrao"
            return plr.Name, char, false, skin
        end
    end

    for _, filho in ipairs(caixa:GetChildren()) do
        if filho:IsA("Model") and filho:FindFirstChild("Humanoid") then
            return filho.Name, filho, true, "Padrao"
        end
    end

    return nil, nil, false, "Padrao"
end

local function obterParteMaoAvatar(personagem)
    if not personagem then return nil end
    -- Prioriza UpperTorso/Torso para posicionar o leque visível acima da borda da mesa
    -- (no SitAnim padrão do Roblox, LeftHand/RightHand ficam pendurados abaixo do tampo)
    return personagem:FindFirstChild("UpperTorso")
        or personagem:FindFirstChild("Torso")
        or personagem:FindFirstChild("LeftHand")
        or personagem:FindFirstChild("Left Arm")
        or personagem:FindFirstChild("HumanoidRootPart")
end

local function aplicarFaceCarta(part, face, valor, naipe, escondida, nomeSkin, zIndexBase)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "CardFace_" .. face.Name
    gui.Face = face
    gui.CanvasSize = Vector2.new(372, 532)
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.LightInfluence = 0.25
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = part

    local img = Instance.new("ImageLabel")
    img.Name = "CardImage"
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.ScaleType = Enum.ScaleType.Stretch
    img.ZIndex = zIndexBase or 1
    img.Parent = gui

    CardSettings.AplicarSkinCarta(img, valor, naipe, escondida, nomeSkin or "Padrao")
    return gui, img
end

local function cframeCartaPlanaNoPonto(posXZ, alturaPeca, dirOlharFrente)
    local ySup = obterAlturaSuperficie(posXZ)
    local pos = Vector3.new(posXZ.X, ySup + (alturaPeca / 2) + 0.008, posXZ.Z)
    local forward = Vector3.new(dirOlharFrente.X, 0, dirOlharFrente.Z)
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -1)
    else
        forward = forward.Unit
    end
    -- Gira -90 graus em Y para alinhar o topo da arte (-X da Part) à direção de frente desejada
    return CFrame.lookAt(pos, pos + forward, Vector3.yAxis) * CFrame.Angles(0, math.rad(-90), 0)
end

-- ==========================================
-- MONTE DO BARALHO & VIRA 3D
-- ==========================================

local function destruirCentroMesa()
    if monteDeckPart then
        monteDeckPart:Destroy()
        monteDeckPart = nil
    end
    if viraCardPart then
        viraCardPart:Destroy()
        viraCardPart = nil
    end
    if pastaCentro then
        pastaCentro:ClearAllChildren()
    end
end

local function criarOuAtualizarMonte(nomeSkin)
    if not tampoMesa or not garantirSubPastas() then return end

    local dirFrente = obterDirecaoLocalParaCentro()
    local dirDireita = dirFrente:Cross(Vector3.yAxis).Unit
    local posMonteXZ = tampoMesa.Position - (dirDireita * 0.56)
    local cfMonte = cframeCartaPlanaNoPonto(posMonteXZ, TAMANHO_MONTE.Y, dirFrente)

    if not monteDeckPart or not monteDeckPart.Parent then
        monteDeckPart = Instance.new("Part")
        monteDeckPart.Name = "MonteBaralho3D"
        monteDeckPart.Size = TAMANHO_MONTE
        monteDeckPart.Material = Enum.Material.SmoothPlastic
        monteDeckPart.Color = Color3.fromRGB(236, 231, 218)
        monteDeckPart.Anchored = true
        monteDeckPart.CanCollide = false
        monteDeckPart.CanTouch = false
        monteDeckPart.CanQuery = false
        monteDeckPart.CFrame = cfMonte
        monteDeckPart.Parent = pastaCentro

        aplicarFaceCarta(monteDeckPart, Enum.NormalId.Top, nil, nil, true, nomeSkin or "Padrao")
    else
        monteDeckPart.CFrame = cfMonte
        local gui = monteDeckPart:FindFirstChild("CardFace_Top")
        local img = gui and gui:FindFirstChild("CardImage")
        if img then
            CardSettings.AplicarSkinCarta(img, nil, nil, true, nomeSkin or "Padrao")
        end
    end
end

function VisuaisMesa.DefinirMonteEVira(valor, naipe, nomeSkin)
    if not tampoMesa or not garantirSubPastas() then return end

    local skin = nomeSkin or "Padrao"
    viraAtualInfo = { valor = valor, naipe = naipe, skin = skin }

    criarOuAtualizarMonte(skin)

    if viraCardPart then
        viraCardPart:Destroy()
        viraCardPart = nil
    end

    local dirFrente = obterDirecaoLocalParaCentro()
    local dirDireita = dirFrente:Cross(Vector3.yAxis).Unit
    local posViraXZ = tampoMesa.Position + (dirDireita * 0.56)
    local cfFinal = cframeCartaPlanaNoPonto(posViraXZ, TAMANHO_CARTA_MESA.Y, dirFrente) * CFrame.Angles(0, math.rad(-8), 0)

    local cartaVira = Instance.new("Part")
    cartaVira.Name = "ViraCard3D"
    cartaVira.Size = TAMANHO_CARTA_MESA
    cartaVira.Material = Enum.Material.SmoothPlastic
    cartaVira.Color = Color3.fromRGB(245, 245, 245)
    cartaVira.Anchored = true
    cartaVira.CanCollide = false
    cartaVira.CanTouch = false
    cartaVira.CanQuery = false

    aplicarFaceCarta(cartaVira, Enum.NormalId.Top, valor, naipe, false, skin)
    aplicarFaceCarta(cartaVira, Enum.NormalId.Bottom, valor, naipe, true, skin)

    local destaque = Instance.new("Highlight")
    destaque.Name = "ViraHighlight"
    destaque.Adornee = cartaVira
    destaque.FillColor = Color3.fromRGB(255, 215, 70)
    destaque.FillTransparency = 0.92
    destaque.OutlineColor = Color3.fromRGB(255, 210, 60)
    destaque.OutlineTransparency = 0.25
    destaque.Parent = cartaVira

    local valorManilha = CardSettings.ObterValorManilha(valor)

    local tagVira = Instance.new("BillboardGui")
    tagVira.Name = "ViraLabel"
    tagVira.Size = UDim2.new(1.75, 0, 0.36, 0)
    tagVira.StudsOffset = Vector3.new(0, 0.56, 0)
    tagVira.AlwaysOnTop = false
    tagVira.MaxDistance = 40
    tagVira.Parent = cartaVira

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(1, 0, 1, 0)
    badge.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    badge.BackgroundTransparency = 0.12
    badge.Text = valorManilha and ("VIRA • Manilha: " .. tostring(valorManilha)) or "VIRA"
    badge.TextColor3 = Color3.fromRGB(255, 220, 75)
    badge.Font = Enum.Font.GothamBlack
    badge.TextScaled = true
    badge.Parent = tagVira
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0.45, 0)
    local padBadge = Instance.new("UIPadding", badge)
    padBadge.PaddingTop = UDim.new(0.12, 0)
    padBadge.PaddingBottom = UDim.new(0.12, 0)
    padBadge.PaddingLeft = UDim.new(0.12, 0)
    padBadge.PaddingRight = UDim.new(0.12, 0)
    local stroke = Instance.new("UIStroke", badge)
    stroke.Thickness = 1.4
    stroke.Color = Color3.fromRGB(255, 210, 60)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local posOrigem = monteDeckPart and monteDeckPart.CFrame or cfFinal
    cartaVira.CFrame = posOrigem * CFrame.new(0, 0.22, 0) * CFrame.Angles(math.rad(140), 0, 0)
    cartaVira.Parent = pastaCentro
    viraCardPart = cartaVira

    TweenService:Create(cartaVira, TWEEN_VIRA, { CFrame = cfFinal }):Play()
end

function VisuaisMesa.AtualizarSkinVira(nomeSkin)
    local skin = nomeSkin or "Padrao"
    if monteDeckPart and monteDeckPart.Parent then
        local gui = monteDeckPart:FindFirstChild("CardFace_Top")
        local img = gui and gui:FindFirstChild("CardImage")
        if img then
            CardSettings.AplicarSkinCarta(img, nil, nil, true, skin)
        end
    end
    if viraAtualInfo and viraCardPart and viraCardPart.Parent then
        viraAtualInfo.skin = skin
        local guiTop = viraCardPart:FindFirstChild("CardFace_Top")
        local imgTop = guiTop and guiTop:FindFirstChild("CardImage")
        if imgTop then
            CardSettings.AplicarSkinCarta(imgTop, viraAtualInfo.valor, viraAtualInfo.naipe, false, skin)
        end
        local guiBot = viraCardPart:FindFirstChild("CardFace_Bottom")
        local imgBot = guiBot and guiBot:FindFirstChild("CardImage")
        if imgBot then
            CardSettings.AplicarSkinCarta(imgBot, viraAtualInfo.valor, viraAtualInfo.naipe, true, skin)
        end
    end
end

-- ==========================================
-- PLACAS DE NOME & ZONAS DE JOGADA EM 3D
-- ==========================================

local function obterEquipeLocalNum()
    local numLocal = assentoLocalNome and tonumber(assentoLocalNome:match("%d+"))
    return numLocal and ((numLocal % 2 == 1) and "A" or "B") or "A"
end

local function atualizarVisualPlacas()
    local minhaEquipe = obterEquipeLocalNum()

    for num = 1, 4 do
        local info = placasAssentos[num]
        if info then
            local nomeExib, _, _, _ = obterOcupanteCadeira(num)
            local equipeAssento = (num % 2 == 1) and "A" or "B"
            local corEquipe = (equipeAssento == minhaEquipe) and COR_EQUIPE_A or COR_EQUIPE_B
            local ehTurno = (nomeExib ~= nil and jogadorTurnoAtual ~= nil and nomeExib == jogadorTurnoAtual)

            if info.coaster and info.coaster.Parent then
                if ehTurno then
                    info.coaster.Color = COR_TURNO_ATIVO
                    info.coaster.Transparency = 0.35
                elseif nomeExib then
                    info.coaster.Color = corEquipe
                    info.coaster.Transparency = 0.78
                else
                    info.coaster.Color = COR_COASTER_BASE
                    info.coaster.Transparency = 0.85
                end
            end

            if info.billboard and info.billboard.Parent then
                local ehLocal = (nomeExib ~= nil and nomeExib == Players.LocalPlayer.Name)
                -- Oculta a placa 3D do próprio jogador na visão em primeira-pessoa elevada
                local mostrarPlaca = (nomeExib ~= nil) and (not ehLocal or not ocultarMaoLocal)
                info.billboard.Enabled = mostrarPlaca
                if mostrarPlaca then
                    info.nameLbl.Text = ehLocal and (nomeExib .. " (Você)") or nomeExib
                    info.nameLbl.TextColor3 = ehTurno and COR_TURNO_ATIVO or Color3.new(1, 1, 1)
                    info.dot.BackgroundColor3 = corEquipe
                    info.stroke.Color = ehTurno and COR_TURNO_ATIVO or corEquipe
                    info.stroke.Thickness = ehTurno and 2.5 or 1.4
                    info.stroke.Transparency = ehTurno and 0 or 0.35
                end
            end
        end
    end
end

local function criarPlacasAssentos()
    if not tampoMesa or not garantirSubPastas() then return end

    pastaAssentos:ClearAllChildren()
    table.clear(placasAssentos)

    for num = 1, 4 do
        local dir = obterDirecaoAssento(num)

        -- Marcador discreto no tampo onde a carta do assento cai
        local posZoneXZ = tampoMesa.Position + (dir * RAIO_CARTA_JOGADA)
        local yZone = obterAlturaSuperficie(posZoneXZ)
        local coaster = Instance.new("Part")
        coaster.Name = "Zone_Cadeira" .. num
        coaster.Shape = Enum.PartType.Cylinder
        coaster.Size = Vector3.new(0.015, 1.32, 1.32)
        coaster.Material = Enum.Material.SmoothPlastic
        coaster.Color = COR_COASTER_BASE
        coaster.Transparency = 0.82
        coaster.Anchored = true
        coaster.CanCollide = false
        coaster.CanTouch = false
        coaster.CanQuery = false
        coaster.CFrame = CFrame.new(posZoneXZ.X, yZone + 0.008, posZoneXZ.Z) * CFrame.Angles(0, 0, math.rad(90))
        coaster.Parent = pastaAssentos

        -- Âncora da placa de nome na borda do tampo da mesa
        local posPlacaXZ = tampoMesa.Position + (dir * RAIO_PLACA_ASSENTO)
        local yPlaca = obterAlturaSuperficie(posPlacaXZ)
        local anchor = Instance.new("Part")
        anchor.Name = "PlacaAnchor_Cadeira" .. num
        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.Position = Vector3.new(posPlacaXZ.X, yPlaca + 0.22, posPlacaXZ.Z)
        anchor.Parent = pastaAssentos

        local bb = Instance.new("BillboardGui")
        bb.Name = "NomeMesa3D"
        bb.Size = UDim2.new(1.9, 0, 0.42, 0)
        bb.AlwaysOnTop = false
        bb.MaxDistance = 45
        bb.Enabled = false
        bb.Parent = anchor

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        frame.BackgroundTransparency = 0.18
        frame.Parent = bb
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0.45, 0)

        local stroke = Instance.new("UIStroke", frame)
        stroke.Thickness = 1.4
        stroke.Color = COR_EQUIPE_A

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0.14, 0, 0.45, 0)
        dot.Position = UDim2.new(0.06, 0, 0.5, 0)
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.BackgroundColor3 = COR_EQUIPE_A
        dot.BorderSizePixel = 0
        dot.Parent = frame
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local aspectDot = Instance.new("UIAspectRatioConstraint", dot)
        aspectDot.AspectRatio = 1

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.76, 0, 0.85, 0)
        nameLbl.Position = UDim2.new(0.21, 0, 0.5, 0)
        nameLbl.AnchorPoint = Vector2.new(0, 0.5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextScaled = true
        nameLbl.TextColor3 = Color3.new(1, 1, 1)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = frame

        placasAssentos[num] = {
            coaster = coaster,
            anchor = anchor,
            billboard = bb,
            frame = frame,
            dot = dot,
            nameLbl = nameLbl,
            stroke = stroke,
        }
    end

    atualizarVisualPlacas()
end

function VisuaisMesa.AtualizarTurno(nomeJogador)
    jogadorTurnoAtual = nomeJogador
    atualizarVisualPlacas()
end

-- ==========================================
-- CARTAS FÍSICAS NA MÃO DOS AVATARES 3D
-- ==========================================

local function limparMaoAvatar(numAssento)
    local reg = maosAvatares3D[numAssento]
    if reg then
        if reg.connections then
            desconectarLista(reg.connections)
        end
        if reg.model and reg.model.Parent then
            reg.model:Destroy()
        end
        maosAvatares3D[numAssento] = nil
    end
end

local function limparTodasMaosAvatares()
    for num = 1, 4 do
        limparMaoAvatar(num)
    end
    table.clear(contagemCartasAssento)
end

local function calcularOffsetsMao3D(total)
    -- Ângulos em Z positivos inclinam o topo (+Y) para -X e negativos para +X,
    -- abrindo o leque corretamente no topo (\ | /) com as bases juntas na mão.
    if total == 3 then
        return { -0.14, 0, 0.14 }, { 16, 0, -16 }
    elseif total == 2 then
        return { -0.075, 0.075 }, { 10, -10 }
    end
    return { 0 }, { 0 }
end

local function renderizarMaoAvatar(numAssento)
    limparMaoAvatar(numAssento)

    local qtd = contagemCartasAssento[numAssento] or 0
    if qtd <= 0 or not pastaMesaAtual or not garantirSubPastas() then return end

    local numLocal = assentoLocalNome and tonumber(assentoLocalNome:match("%d+"))
    if ocultarMaoLocal and numLocal and numAssento == numLocal then
        return
    end

    local _, personagem, ehBot, skinPadrao = obterOcupanteCadeira(numAssento)
    if not personagem then return end

    local anchorPart = obterParteMaoAvatar(personagem)
    if not anchorPart then return end

    local skin = skinsAssento[numAssento] or skinPadrao or "Padrao"
    if ehBot then
        skin = "Padrao"
    end

    local modeloMao = Instance.new("Model")
    modeloMao.Name = "Mao3D_Cadeira" .. tostring(numAssento)
    modeloMao.Parent = pastaMaos

    local xs, angles = calcularOffsetsMao3D(qtd)
    local alturaAcimaTampo = 0.22
    local topoY = tampoMesa and (tampoMesa.Position.Y + tampoMesa.Size.Y / 2) or (anchorPart.Position.Y + 0.9)
    local dyRel = math.clamp((topoY + alturaAcimaTampo) - anchorPart.Position.Y, 0.45, 1.55)

    local baseGrip
    if anchorPart.Name == "UpperTorso" or anchorPart.Name == "Torso" or anchorPart.Name == "HumanoidRootPart" then
        -- Posiciona o leque à esquerda/ombro do avatar acima da borda da mesa, levemente inclinado para o avatar ler
        baseGrip = CFrame.new(-0.72, dyRel, -1.04) * CFrame.Angles(math.rad(14), math.rad(14), 0)
    else
        local isRight = (anchorPart.Name == "RightHand" or anchorPart.Name == "Right Arm")
        baseGrip = isRight
            and (CFrame.new(-0.08, 0.65, -0.45) * CFrame.Angles(math.rad(16), math.rad(-10), 0))
            or (CFrame.new(0.08, 0.65, -0.45) * CFrame.Angles(math.rad(16), math.rad(10), 0))
    end

    local primeiraCarta = nil
    for i = 1, qtd do
        local carta = Instance.new("Part")
        carta.Name = "HandCard_" .. i
        carta.Size = TAMANHO_CARTA_MAO
        carta.Material = Enum.Material.SmoothPlastic
        carta.Color = Color3.fromRGB(240, 240, 240)
        carta.Anchored = false
        carta.CanCollide = false
        carta.CanTouch = false
        carta.CanQuery = false
        carta.Massless = true
        carta.CastShadow = false

        -- IMPORTANTE: Ambas as faces mostram APENAS o fundo da skin selecionada.
        -- Nenhuma informação da frente da carta é exibida na mão 3D.
        aplicarFaceCarta(carta, Enum.NormalId.Front, nil, nil, true, skin)
        aplicarFaceCarta(carta, Enum.NormalId.Back, nil, nil, true, skin)

        local c0 = baseGrip
            * CFrame.new(xs[i] or 0, 0, (i - 1) * 0.018)
            * CFrame.Angles(0, 0, math.rad(angles[i] or 0))

        carta.CFrame = anchorPart.CFrame * c0
        carta.Parent = modeloMao

        local weld = Instance.new("Weld")
        weld.Name = "HandCardWeld_" .. i
        weld.Part0 = anchorPart
        weld.Part1 = carta
        weld.C0 = c0
        weld.C1 = CFrame.new()
        weld.Parent = carta

        if not primeiraCarta then
            primeiraCarta = carta
        end
    end

    local conns = {}
    -- Caso ApplyDescription substitua partes do Bot, re-anexa as cartas restantes
    table.insert(conns, anchorPart.AncestryChanged:Connect(function(_, novoPai)
        if not novoPai and pastaMesaAtual and (contagemCartasAssento[numAssento] or 0) > 0 then
            task.delay(0.15, function()
                if pastaMesaAtual and (contagemCartasAssento[numAssento] or 0) > 0 then
                    renderizarMaoAvatar(numAssento)
                end
            end)
        end
    end))

    maosAvatares3D[numAssento] = {
        model = modeloMao,
        handPart = primeiraCarta or anchorPart,
        connections = conns,
    }
end

function VisuaisMesa.DefinirOcultarMaoLocal(ocultar)
    ocultarMaoLocal = (ocultar == true)
    local numLocal = assentoLocalNome and tonumber(assentoLocalNome:match("%d+"))
    if numLocal and (contagemCartasAssento[numLocal] or 0) > 0 then
        renderizarMaoAvatar(numLocal)
    end
    atualizarVisualPlacas()
end

function VisuaisMesa.InicializarMaosAvatares()
    if not pastaMesaAtual then return end

    for num = 1, 4 do
        local _, _, ehBot, skin = obterOcupanteCadeira(num)
        contagemCartasAssento[num] = 3
        skinsAssento[num] = ehBot and "Padrao" or (skin or "Padrao")
        renderizarMaoAvatar(num)
    end
    atualizarVisualPlacas()
end

-- ==========================================
-- API PRINCIPAL DA MESA 3D
-- ==========================================

function VisuaisMesa.DefinirMesaAtual(modelo, nomeAssento)
    if not modelo then
        VisuaisMesa.LimparTudo()
        pastaMesaAtual = nil
        containerCartas = nil
        pastaCadeiras = nil
        modeloMesa = nil
        tampoMesa = nil
        assentoLocalNome = nil
        return
    end

    if pastaMesaAtual ~= modelo then
        VisuaisMesa.LimparTudo()
    end

    pastaMesaAtual = modelo
    if nomeAssento then
        assentoLocalNome = nomeAssento
    end

    containerCartas = pastaMesaAtual:FindFirstChild("CartasNaMesa")
    pastaCadeiras = pastaMesaAtual:FindFirstChild("Cadeiras")
    modeloMesa = pastaMesaAtual:FindFirstChild("Mesa")
    tampoMesa = modeloMesa and modeloMesa:FindFirstChild("Topo")

    if not containerCartas then warn("VisuaisMesa: Faltou pasta 'CartasNaMesa'") end
    if not tampoMesa then warn("VisuaisMesa: Faltou 'Topo' da mesa") end

    if garantirSubPastas() then
        criarPlacasAssentos()
        criarOuAtualizarMonte("Padrao")
    end

    desconectarLista(conexoesMesa)
    if pastaCadeiras then
        for num = 1, 4 do
            local caixa, seat = obterCaixaEAssento(num)
            if seat and seat:IsA("Seat") then
                table.insert(conexoesMesa, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    atualizarVisualPlacas()
                end))
            end
            if caixa then
                table.insert(conexoesMesa, caixa.ChildAdded:Connect(function(novoFilho)
                    task.defer(function()
                        atualizarVisualPlacas()
                        if novoFilho:IsA("Model") and (contagemCartasAssento[num] or 0) > 0 then
                            task.wait(0.1)
                            renderizarMaoAvatar(num)
                        end
                    end)
                end))
                table.insert(conexoesMesa, caixa.ChildRemoved:Connect(function()
                    task.defer(atualizarVisualPlacas)
                end))
            end
        end
    end
end

-- Gera a carta física jogada na mesa, consome 1 carta da mão 3D do avatar e destaca o jogador
function VisuaisMesa.GerarCarta(jogadorOuNome, valor, naipe, estaEscondida, nomeSkin)
    if not pastaMesaAtual or not containerCartas or not tampoMesa then return end
    if not garantirSubPastas() then return end

    local numCadeira, personagemAlvo = obterDadosAssentoEAvatar(jogadorOuNome)
    local nomeJogador = typeof(jogadorOuNome) == "Instance" and jogadorOuNome.Name or tostring(jogadorOuNome)
    nomeSkin = nomeSkin or "Padrao"

    skinsAssento[numCadeira] = nomeSkin

    -- Captura a posição da mão antes de remover 1 carta do leque 3D do avatar
    local dirAssento = obterDirecaoAssento(numCadeira)
    local posInicial = tampoMesa.Position + (dirAssento * 3.6) + Vector3.new(0, 0.9, 0)
    local handAtual = maosAvatares3D[numCadeira] and maosAvatares3D[numCadeira].handPart
    if handAtual and handAtual.Parent then
        posInicial = handAtual.Position
    elseif personagemAlvo and personagemAlvo:FindFirstChild("HumanoidRootPart") then
        local hrp = personagemAlvo.HumanoidRootPart
        posInicial = hrp.Position + (hrp.CFrame.LookVector * 1.4) + Vector3.new(0, 0.8, 0)
    end

    if (contagemCartasAssento[numCadeira] or 0) > 0 then
        contagemCartasAssento[numCadeira] -= 1
        renderizarMaoAvatar(numCadeira)
    end

    local pecaCarta = Instance.new("Part")
    pecaCarta.Name = "Card_" .. nomeJogador
    pecaCarta.Size = TAMANHO_CARTA_MESA
    pecaCarta.Material = Enum.Material.SmoothPlastic
    pecaCarta.Color = Color3.fromRGB(245, 245, 245)
    pecaCarta.Anchored = true
    pecaCarta.CanCollide = false
    pecaCarta.CanTouch = false
    pecaCarta.CanQuery = false

    aplicarFaceCarta(pecaCarta, Enum.NormalId.Top, valor, naipe, estaEscondida, nomeSkin)
    aplicarFaceCarta(pecaCarta, Enum.NormalId.Bottom, valor, naipe, true, nomeSkin)

    -- Exibe etiqueta discreta na carta apenas quando jogada coberta (ou sem placa de assento visível)
    if estaEscondida then
        local tag = Instance.new("BillboardGui")
        tag.Name = "CardOwnerTag"
        tag.Size = UDim2.new(1.3, 0, 0.3, 0)
        tag.StudsOffset = Vector3.new(0, 0.28, 0)
        tag.AlwaysOnTop = false
        tag.MaxDistance = 40
        tag.Parent = pecaCarta

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        lbl.BackgroundTransparency = 0.2
        lbl.Text = "Coberta"
        lbl.TextColor3 = Color3.fromRGB(205, 210, 225)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Parent = tag
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0.45, 0)
        local stroke = Instance.new("UIStroke", lbl)
        stroke.Thickness = 1
        stroke.Color = Color3.fromRGB(80, 85, 100)
    end

    pecaCarta.CFrame = CFrame.new(posInicial)
        * CFrame.Angles(math.rad(math.random(-140, 140)), math.rad(math.random(-180, 180)), 0)
    pecaCarta.Parent = pastaJogadas

    -- Destino sobre Mesa.Topo em frente ao assento do jogador
    local dirLateral = dirAssento:Cross(Vector3.yAxis).Unit
    local jitterLateral = (math.random(-8, 8) / 100)
    local jitterRadial = (math.random(-6, 6) / 100)

    local posDestinoXZ = tampoMesa.Position
        + (dirAssento * (RAIO_CARTA_JOGADA + jitterRadial))
        + (dirLateral * jitterLateral)

    local qtdAtual = #pastaJogadas:GetChildren()
    local cframeBase = cframeCartaPlanaNoPonto(posDestinoXZ, TAMANHO_CARTA_MESA.Y, -dirAssento)
    local rotBaguncada = CFrame.Angles(0, math.rad(math.random(-10, 10)), 0)
    local cframeFinal = cframeBase * CFrame.new(0, qtdAtual * 0.004, 0) * rotBaguncada

    TweenService:Create(pecaCarta, TWEEN_JOGADA, { CFrame = cframeFinal }):Play()
end

-- Limpa apenas as cartas jogadas na queda atual (mantém Monte, Vira, Placas e Mãos 3D)
function VisuaisMesa.LimparMesa()
    if not pastaJogadas then return end
    for _, carta in ipairs(pastaJogadas:GetChildren()) do
        if carta:IsA("BasePart") then
            carta.Name = "ClearingCard"
            TweenService:Create(carta, TweenInfo.new(0.45), {
                Transparency = 1,
                Position = carta.Position + Vector3.new(0, 1, 0),
            }):Play()
            Debris:AddItem(carta, 0.45)
        end
    end
end

-- Limpa os elementos da mão/partida mantendo o Monte e as Placas de assento se ainda estiver sentado
function VisuaisMesa.LimparPartida()
    VisuaisMesa.LimparMesa()
    limparTodasMaosAvatares()
    jogadorTurnoAtual = nil
    viraAtualInfo = nil
    if viraCardPart then
        viraCardPart:Destroy()
        viraCardPart = nil
    end
    atualizarVisualPlacas()
end

-- Remove todos os elementos 3D gerados pelo cliente ao sair da mesa
function VisuaisMesa.LimparTudo()
    desconectarLista(conexoesMesa)
    limparTodasMaosAvatares()
    destruirCentroMesa()
    jogadorTurnoAtual = nil
    viraAtualInfo = nil
    table.clear(skinsAssento)
    table.clear(placasAssentos)

    if pastaVisual3D and pastaVisual3D.Parent then
        pastaVisual3D:Destroy()
    end
    pastaVisual3D = nil
    pastaJogadas = nil
    pastaCentro = nil
    pastaAssentos = nil
    pastaMaos = nil
end

return VisuaisMesa

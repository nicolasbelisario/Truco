local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")

local AudioUI = {}

-- ==========================================
-- DESIGN SYSTEM
-- ==========================================
local BG_ESCURO  = Color3.fromRGB(18, 18, 24)
local BG_PAINEL  = Color3.fromRGB(28, 28, 36)
local BG_BOTAO   = Color3.fromRGB(40, 40, 52)
local ACENTO     = Color3.fromRGB(240, 160, 40)
local VERDE      = Color3.fromRGB(39, 174, 96)
local VERMELHO   = Color3.fromRGB(200, 50, 50)
local TEXTO_PRIM = Color3.new(1, 1, 1)
local TEXTO_SEC  = Color3.fromRGB(180, 180, 190)

local SoundManager
local btnMuteGlobal: TextButton? = nil
local painelAudio: Frame?        = nil
local btnMutePainel: TextButton? = nil

local atualizarSliderBGM: ((number) -> ())? = nil
local atualizarSliderSFX: ((number) -> ())? = nil

local function aplicarHoverBotaoMenu(botao: TextButton, ehMuteAtivoFn: (() -> boolean)?)
    botao.MouseEnter:Connect(function()
        if ehMuteAtivoFn and ehMuteAtivoFn() then return end
        TweenService:Create(botao, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.05,
            BackgroundColor3 = Color3.fromRGB(38, 38, 46),
        }):Play()
    end)

    botao.MouseLeave:Connect(function()
        if ehMuteAtivoFn and ehMuteAtivoFn() then return end
        TweenService:Create(botao, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.25,
            BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        }):Play()
    end)
end

local function criarBotaoMenuCircular(containerMenu: Instance, nome: string, icone: string, layoutOrder: number): TextButton
    local btn = Instance.new("TextButton")
    btn.Name                   = nome
    btn.Size                   = UDim2.new(0, 46, 0, 46)
    btn.BackgroundColor3       = Color3.fromRGB(24, 24, 28)
    btn.BackgroundTransparency = 0.25
    btn.Text                   = icone
    btn.TextSize               = 22
    btn.TextColor3             = TEXTO_PRIM
    btn.Font                   = Enum.Font.GothamBlack
    btn.AutoButtonColor        = true
    btn.LayoutOrder            = layoutOrder
    btn.ZIndex                 = 41
    btn.Parent                 = containerMenu
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local borda = Instance.new("UIStroke", btn)
    borda.Thickness    = 1.5
    borda.Color        = Color3.new(1, 1, 1)
    borda.Transparency = 0.8

    return btn
end

local function criarSliderVolume(
    pai: Instance,
    tituloTexto: string,
    corPreenchimento: Color3,
    valorInicial: number,
    layoutOrder: number,
    aoAlterar: (number) -> ()
): (number) -> ()
    local bloco = Instance.new("Frame")
    bloco.Name                   = "SliderBloco_" .. layoutOrder
    bloco.Size                   = UDim2.new(1, 0, 0, 44)
    bloco.BackgroundTransparency = 1
    bloco.LayoutOrder            = layoutOrder
    bloco.ZIndex                 = 71
    bloco.Parent                 = pai

    local cabecalho = Instance.new("Frame")
    cabecalho.Size                   = UDim2.new(1, 0, 0, 18)
    cabecalho.BackgroundTransparency = 1
    cabecalho.ZIndex                 = 71
    cabecalho.Parent                 = bloco

    local lblTitulo = Instance.new("TextLabel")
    lblTitulo.Size                   = UDim2.new(0.7, 0, 1, 0)
    lblTitulo.BackgroundTransparency = 1
    lblTitulo.Text                   = tituloTexto
    lblTitulo.TextColor3             = TEXTO_PRIM
    lblTitulo.Font                   = Enum.Font.GothamBold
    lblTitulo.TextSize               = 13
    lblTitulo.TextXAlignment         = Enum.TextXAlignment.Left
    lblTitulo.ZIndex                 = 71
    lblTitulo.Parent                 = cabecalho

    local lblPorcentagem = Instance.new("TextLabel")
    lblPorcentagem.Size                   = UDim2.new(0.3, 0, 1, 0)
    lblPorcentagem.Position               = UDim2.new(0.7, 0, 0, 0)
    lblPorcentagem.BackgroundTransparency = 1
    lblPorcentagem.TextColor3             = TEXTO_SEC
    lblPorcentagem.Font                   = Enum.Font.GothamBold
    lblPorcentagem.TextSize               = 13
    lblPorcentagem.TextXAlignment         = Enum.TextXAlignment.Right
    lblPorcentagem.ZIndex                 = 71
    lblPorcentagem.Parent                 = cabecalho

    local areaInteracao = Instance.new("TextButton")
    areaInteracao.Name                   = "HitboxSlider"
    areaInteracao.Size                   = UDim2.new(1, 0, 0, 24)
    areaInteracao.Position               = UDim2.new(0, 0, 0, 20)
    areaInteracao.BackgroundTransparency = 1
    areaInteracao.Text                   = ""
    areaInteracao.AutoButtonColor        = false
    areaInteracao.ZIndex                 = 74
    areaInteracao.Parent                 = bloco

    local trilho = Instance.new("Frame")
    trilho.Name             = "Trilho"
    trilho.Size             = UDim2.new(1, 0, 0, 8)
    trilho.Position         = UDim2.new(0, 0, 0.5, 0)
    trilho.AnchorPoint      = Vector2.new(0, 0.5)
    trilho.BackgroundColor3 = BG_BOTAO
    trilho.BorderSizePixel  = 0
    trilho.ZIndex           = 71
    trilho.Parent           = areaInteracao
    Instance.new("UICorner", trilho).CornerRadius = UDim.new(1, 0)

    local preenchimento = Instance.new("Frame")
    preenchimento.Name             = "Preenchimento"
    preenchimento.BackgroundColor3 = corPreenchimento
    preenchimento.BorderSizePixel  = 0
    preenchimento.ZIndex           = 72
    preenchimento.Parent           = trilho
    Instance.new("UICorner", preenchimento).CornerRadius = UDim.new(1, 0)

    local marcador = Instance.new("Frame")
    marcador.Name             = "Marcador"
    marcador.Size             = UDim2.new(0, 16, 0, 16)
    marcador.AnchorPoint      = Vector2.new(0.5, 0.5)
    marcador.BackgroundColor3 = TEXTO_PRIM
    marcador.BorderSizePixel  = 0
    marcador.ZIndex           = 73
    marcador.Parent           = trilho
    Instance.new("UICorner", marcador).CornerRadius = UDim.new(1, 0)

    local bordaMarcador = Instance.new("UIStroke", marcador)
    bordaMarcador.Thickness = 2
    bordaMarcador.Color     = corPreenchimento

    local function atualizarVisual(alpha: number)
        local v = math.clamp(alpha, 0, 1)
        preenchimento.Size = UDim2.new(v, 0, 1, 0)
        marcador.Position  = UDim2.new(v, 0, 0.5, 0)
        lblPorcentagem.Text = tostring(math.round(v * 100)) .. "%"
    end

    local function atualizarPorPosicaoX(posX: number)
        local largura = math.max(trilho.AbsoluteSize.X, 1)
        local alpha = math.clamp((posX - trilho.AbsolutePosition.X) / largura, 0, 1)
        atualizarVisual(alpha)
        aoAlterar(alpha)
    end

    local arrastando = false

    areaInteracao.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = true
            atualizarPorPosicaoX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not arrastando then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            atualizarPorPosicaoX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not arrastando then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            arrastando = false
        end
    end)

    atualizarVisual(valorInicial)
    return atualizarVisual
end

local function sincronizarVisual()
    if not SoundManager then return end
    local mutado = SoundManager.EstaMutado()

    if btnMuteGlobal then
        btnMuteGlobal.Text = mutado and "🔇" or "🔊"
        btnMuteGlobal.BackgroundColor3 = mutado
            and Color3.fromRGB(70, 25, 25)
            or Color3.fromRGB(24, 24, 28)
        btnMuteGlobal.BackgroundTransparency = mutado and 0.1 or 0.25
    end

    if btnMutePainel then
        btnMutePainel.Text = mutado and "🔇 SOM MUTADO (ATIVAR)" or "🔊 MUTAR TODO O ÁUDIO"
        btnMutePainel.BackgroundColor3 = mutado and VERDE or VERMELHO
    end

    if atualizarSliderBGM then
        atualizarSliderBGM(SoundManager.ObterVolumeBGM())
    end
    if atualizarSliderSFX then
        atualizarSliderSFX(SoundManager.ObterVolumeSFX())
    end
end

function AudioUI.Inicializar(pai: Instance, containerMenu: Instance, soundManagerRef: any)
    SoundManager = soundManagerRef

    btnMuteGlobal = criarBotaoMenuCircular(containerMenu, "BtnMuteGlobal", "🔊", 4)
    aplicarHoverBotaoMenu(btnMuteGlobal, function()
        return SoundManager and SoundManager.EstaMutado()
    end)

    -- Mini Painel de Áudio
    painelAudio = Instance.new("Frame")
    painelAudio.Name             = "PainelAudio"
    painelAudio.Size             = UDim2.new(0, 255, 0, 206)
    painelAudio.BackgroundColor3 = BG_ESCURO
    painelAudio.Visible          = false
    painelAudio.ZIndex           = 70
    painelAudio.Parent           = pai
    Instance.new("UICorner", painelAudio).CornerRadius = UDim.new(0, 14)

    local borda = Instance.new("UIStroke", painelAudio)
    borda.Thickness = 1.5
    borda.Color     = Color3.fromRGB(55, 55, 70)

    local function atualizarPosicaoPainel()
        if not painelAudio then return end
        local inset = GuiService:GetGuiInset()
        local alturaTopbar = math.max(inset.Y, 54)
        painelAudio.Position = UDim2.new(0, 74, 0, alturaTopbar + 12)
    end
    atualizarPosicaoPainel()
    GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(atualizarPosicaoPainel)

    local pad = Instance.new("UIPadding", painelAudio)
    pad.PaddingTop    = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft   = UDim.new(0, 14)
    pad.PaddingRight  = UDim.new(0, 14)

    local layout = Instance.new("UIListLayout", painelAudio)
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Padding             = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Cabeçalho
    local header = Instance.new("Frame")
    header.Name                   = "Header"
    header.Size                   = UDim2.new(1, 0, 0, 26)
    header.BackgroundTransparency = 1
    header.LayoutOrder            = 1
    header.ZIndex                 = 71
    header.Parent                 = painelAudio

    local titulo = Instance.new("TextLabel")
    titulo.Size                   = UDim2.new(1, -30, 1, 0)
    titulo.BackgroundTransparency = 1
    titulo.Text                   = "🎚️ CONTROLE DE ÁUDIO"
    titulo.TextColor3             = ACENTO
    titulo.Font                   = Enum.Font.GothamBlack
    titulo.TextSize               = 15
    titulo.TextXAlignment         = Enum.TextXAlignment.Left
    titulo.ZIndex                 = 71
    titulo.Parent                 = header

    local btnFechar = Instance.new("TextButton")
    btnFechar.Name             = "BtnFechar"
    btnFechar.Size             = UDim2.new(0, 26, 0, 26)
    btnFechar.Position         = UDim2.new(1, 0, 0, 0)
    btnFechar.AnchorPoint      = Vector2.new(1, 0)
    btnFechar.BackgroundColor3 = BG_BOTAO
    btnFechar.Text             = "X"
    btnFechar.TextColor3       = TEXTO_PRIM
    btnFechar.Font             = Enum.Font.GothamBlack
    btnFechar.TextSize         = 14
    btnFechar.ZIndex           = 72
    btnFechar.Parent           = header
    Instance.new("UICorner", btnFechar).CornerRadius = UDim.new(1, 0)

    btnFechar.Activated:Connect(function()
        if painelAudio then painelAudio.Visible = false end
    end)

    -- Sliders independentes de BGM e SFX
    atualizarSliderBGM = criarSliderVolume(
        painelAudio,
        "🎵 Música (BGM)",
        ACENTO,
        SoundManager.ObterVolumeBGM(),
        2,
        function(v)
            SoundManager.DefinirVolumeBGM(v)
        end
    )

    atualizarSliderSFX = criarSliderVolume(
        painelAudio,
        "⚡ Efeitos (SFX)",
        Color3.fromRGB(70, 175, 255),
        SoundManager.ObterVolumeSFX(),
        3,
        function(v)
            SoundManager.DefinirVolumeSFX(v)
        end
    )

    -- Botão de Mute Global dentro do painel
    btnMutePainel = Instance.new("TextButton")
    btnMutePainel.Name             = "BtnMutePainel"
    btnMutePainel.Size             = UDim2.new(1, 0, 0, 34)
    btnMutePainel.BackgroundColor3 = VERMELHO
    btnMutePainel.TextColor3       = TEXTO_PRIM
    btnMutePainel.Font             = Enum.Font.GothamBold
    btnMutePainel.TextSize         = 13
    btnMutePainel.AutoButtonColor  = true
    btnMutePainel.LayoutOrder      = 4
    btnMutePainel.ZIndex           = 72
    btnMutePainel.Parent           = painelAudio
    Instance.new("UICorner", btnMutePainel).CornerRadius = UDim.new(0, 8)

    btnMutePainel.Activated:Connect(function()
        SoundManager.AlternarMute()
        sincronizarVisual()
    end)

    btnMuteGlobal.Activated:Connect(function()
        if not painelAudio then return end
        painelAudio.Visible = not painelAudio.Visible
        if painelAudio.Visible then
            sincronizarVisual()
        end
    end)

    SoundManager.AoMudarEstadoAudio(sincronizarVisual)
    sincronizarVisual()
end

function AudioUI.Fechar()
    if painelAudio then
        painelAudio.Visible = false
    end
end

return AudioUI

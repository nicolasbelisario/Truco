local SoundService    = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService    = game:GetService("TweenService")
local Players         = game:GetService("Players")

local SoundManager = {}

-- Registro de SFX (RN-16)
local SONS = {
    ["Shuffle"]     = "rbxassetid://128706455708345",
    ["Truco"]       = "rbxassetid://7152989885",
    ["TrucoAccept"] = "rbxassetid://84617122458494",
    ["TrucoFlee"]   = "rbxassetid://85843458426701",
    ["CardPlay"]    = "rbxassetid://3456145589",
    ["ZapImpact"]   = "rbxassetid://9113535048",
    ["RoundWin"]    = "rbxassetid://103516326607012",
    ["RoundLose"]   = "rbxassetid://1327132588",
    ["Victory"]     = "rbxassetid://12222253",
    ["Defeat"]      = "rbxassetid://190705984",
    ["Tension"]     = "rbxassetid://9043365842",
}

-- Playlist de música de fundo (BGM) centralizada (D-04)
local PLAYLIST_BGM = {
    "rbxassetid://1845341094",
    "rbxassetid://1848354536",
    "rbxassetid://1837429944",
    "rbxassetid://9043887091",
    "rbxassetid://1838457617",
}

local ATTR_VOLUME_BGM = "AudioVolumeBGM"
local ATTR_VOLUME_SFX = "AudioVolumeSFX"
local ATTR_MUTADO     = "AudioMutado"

local DEFAULT_VOLUME_BGM = 0.3
local DEFAULT_VOLUME_SFX = 1.0
local DEFAULT_MUTADO     = false

local FATOR_VOLUME_TENSAO_BGM = 1.15
local VELOCIDADE_NORMAL_BGM   = 1.0
local VELOCIDADE_TENSAO_BGM   = 1.15
local FATOR_VOLUME_SFX_TENSAO = 0.45

local inicializado     = false
local prefsCarregadas  = false
local mutado           = DEFAULT_MUTADO
local volumeBGM        = DEFAULT_VOLUME_BGM
local volumeSFX        = DEFAULT_VOLUME_SFX
local modoTensao       = false

local objetoMusica: Sound? = nil
local somTensao: Sound?    = nil
local indiceMusicaAtual    = 0
local tweenVelocidadeBGM: Tween? = nil

-- Rastreia SFX ativos para aplicar mute/volume imediatamente ([Sound] = multiplicador)
local sonsAtivos: { [Sound]: number } = {}
local listenersEstado: { () -> () }   = {}

local function obterJogadorLocal(): Player?
    return Players.LocalPlayer
end

local function notificarListeners()
    for _, cb in ipairs(listenersEstado) do
        task.spawn(cb)
    end
end

local function carregarPreferencias()
    if prefsCarregadas then return end
    prefsCarregadas = true

    local jogador = obterJogadorLocal()
    if not jogador then return end

    local attrBGM = jogador:GetAttribute(ATTR_VOLUME_BGM)
    local attrSFX = jogador:GetAttribute(ATTR_VOLUME_SFX)
    local attrMut = jogador:GetAttribute(ATTR_MUTADO)

    if type(attrBGM) == "number" then
        volumeBGM = math.clamp(attrBGM, 0, 1)
    else
        jogador:SetAttribute(ATTR_VOLUME_BGM, volumeBGM)
    end

    if type(attrSFX) == "number" then
        volumeSFX = math.clamp(attrSFX, 0, 1)
    else
        jogador:SetAttribute(ATTR_VOLUME_SFX, volumeSFX)
    end

    if type(attrMut) == "boolean" then
        mutado = attrMut
    else
        jogador:SetAttribute(ATTR_MUTADO, mutado)
    end
end

local function salvarPreferencias()
    local jogador = obterJogadorLocal()
    if not jogador then return end

    jogador:SetAttribute(ATTR_VOLUME_BGM, volumeBGM)
    jogador:SetAttribute(ATTR_VOLUME_SFX, volumeSFX)
    jogador:SetAttribute(ATTR_MUTADO, mutado)
end

local function calcularVolumeBGMReal(): number
    if mutado then return 0 end
    local fator = modoTensao and FATOR_VOLUME_TENSAO_BGM or 1
    return math.clamp(volumeBGM * fator, 0, 1)
end

local function calcularVolumeSFXReal(multiplicador: number?): number
    if mutado then return 0 end
    return math.clamp(volumeSFX * (multiplicador or 1), 0, 1)
end

local function aplicarVolumesAtuais()
    if objetoMusica then
        objetoMusica.Volume = calcularVolumeBGMReal()
    end

    if somTensao then
        somTensao.Volume = calcularVolumeSFXReal(FATOR_VOLUME_SFX_TENSAO)
    end

    for som, mult in pairs(sonsAtivos) do
        if som and som.Parent then
            som.Volume = calcularVolumeSFXReal(mult)
        else
            sonsAtivos[som] = nil
        end
    end
end

local function precarregarAudios()
    task.spawn(function()
        local instancias: { Instance } = {}

        for nome, id in pairs(SONS) do
            local s = Instance.new("Sound")
            s.Name    = "Preload_SFX_" .. nome
            s.SoundId = id
            table.insert(instancias, s)
        end

        for i, id in ipairs(PLAYLIST_BGM) do
            local s = Instance.new("Sound")
            s.Name    = "Preload_BGM_" .. tostring(i)
            s.SoundId = id
            table.insert(instancias, s)
        end

        pcall(function()
            ContentProvider:PreloadAsync(instancias)
        end)

        for _, s in ipairs(instancias) do
            s:Destroy()
        end
    end)
end

local function escolherProximoIndiceBGM(): number
    if #PLAYLIST_BGM <= 1 then return 1 end
    local novoIndice = math.random(1, #PLAYLIST_BGM)
    if novoIndice == indiceMusicaAtual then
        novoIndice = (novoIndice % #PLAYLIST_BGM) + 1
    end
    return novoIndice
end

local function tocarProximaMusica()
    if not objetoMusica or #PLAYLIST_BGM == 0 then return end

    indiceMusicaAtual = escolherProximoIndiceBGM()
    local idEscolhido = PLAYLIST_BGM[indiceMusicaAtual]

    objetoMusica.SoundId = idEscolhido
    objetoMusica.Volume  = calcularVolumeBGMReal()
    objetoMusica.PlaybackSpeed = modoTensao and VELOCIDADE_TENSAO_BGM or VELOCIDADE_NORMAL_BGM

    if not objetoMusica.IsLoaded then
        objetoMusica.Loaded:Wait()
    end

    if objetoMusica and objetoMusica.SoundId == idEscolhido then
        objetoMusica.Volume = calcularVolumeBGMReal()
        objetoMusica:Play()
    end
end

local function garantirBGMInstanciada()
    if objetoMusica and objetoMusica.Parent then return end

    -- Reaproveita se já existir uma instância prévia no SoundService
    local existente = SoundService:FindFirstChild("BackgroundMusic")
    if existente and existente:IsA("Sound") then
        objetoMusica = existente
    else
        local musica = Instance.new("Sound")
        musica.Name   = "BackgroundMusic"
        musica.Looped = false
        musica.Parent = SoundService
        objetoMusica  = musica
    end

    if objetoMusica then
        objetoMusica.Volume        = calcularVolumeBGMReal()
        objetoMusica.PlaybackSpeed = modoTensao and VELOCIDADE_TENSAO_BGM or VELOCIDADE_NORMAL_BGM
        objetoMusica.Ended:Connect(function()
            task.spawn(tocarProximaMusica)
        end)
    end
end

function SoundManager.Inicializar()
    if inicializado then return end
    inicializado = true

    carregarPreferencias()
    precarregarAudios()
    garantirBGMInstanciada()
    task.spawn(tocarProximaMusica)
end

function SoundManager.Tocar(nomeSom: string, multiplicadorVolume: number?)
    carregarPreferencias()

    local id = SONS[nomeSom]
    if not id then return end

    local mult = multiplicadorVolume or 1
    local som = Instance.new("Sound")
    som.Name    = "SFX_" .. nomeSom
    som.SoundId = id
    som.Volume  = calcularVolumeSFXReal(mult)
    som.Parent  = SoundService

    sonsAtivos[som] = mult
    som.Ended:Connect(function()
        sonsAtivos[som] = nil
        som:Destroy()
    end)
    som:Play()
end

-- Alterna o estado de mudo global (BGM + SFX) e retorna o novo estado (true = mutado)
function SoundManager.AlternarMute(): boolean
    carregarPreferencias()
    mutado = not mutado
    aplicarVolumesAtuais()
    salvarPreferencias()
    notificarListeners()
    return mutado
end

function SoundManager.DefinirMute(novoEstado: boolean): boolean
    carregarPreferencias()
    mutado = (novoEstado == true)
    aplicarVolumesAtuais()
    salvarPreferencias()
    notificarListeners()
    return mutado
end

-- Retorna se o áudio global está mutado
function SoundManager.EstaMutado(): boolean
    carregarPreferencias()
    return mutado
end

function SoundManager.DefinirVolumeBGM(novoVolume: number)
    carregarPreferencias()
    volumeBGM = math.clamp(tonumber(novoVolume) or DEFAULT_VOLUME_BGM, 0, 1)
    aplicarVolumesAtuais()
    salvarPreferencias()
    notificarListeners()
end

function SoundManager.ObterVolumeBGM(): number
    carregarPreferencias()
    return volumeBGM
end

function SoundManager.DefinirVolumeSFX(novoVolume: number)
    carregarPreferencias()
    volumeSFX = math.clamp(tonumber(novoVolume) or DEFAULT_VOLUME_SFX, 0, 1)
    aplicarVolumesAtuais()
    salvarPreferencias()
    notificarListeners()
end

function SoundManager.ObterVolumeSFX(): number
    carregarPreferencias()
    return volumeSFX
end

-- Ajusta trilha dinâmica e som de tensão para Mão de Onze / Mão de Ferro
function SoundManager.DefinirModoTensao(ativo: boolean)
    carregarPreferencias()
    local novoEstado = (ativo == true)
    if modoTensao == novoEstado then return end
    modoTensao = novoEstado

    if tweenVelocidadeBGM then
        tweenVelocidadeBGM:Cancel()
        tweenVelocidadeBGM = nil
    end

    if objetoMusica then
        local velocidadeAlvo = modoTensao and VELOCIDADE_TENSAO_BGM or VELOCIDADE_NORMAL_BGM
        tweenVelocidadeBGM = TweenService:Create(
            objetoMusica,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { PlaybackSpeed = velocidadeAlvo }
        )
        tweenVelocidadeBGM:Play()
    end

    aplicarVolumesAtuais()

    if modoTensao then
        local idTensao = SONS["Tension"]
        if idTensao then
            if not somTensao then
                local s = Instance.new("Sound")
                s.Name    = "SFX_TensionLoop"
                s.SoundId = idTensao
                s.Looped  = true
                s.Parent  = SoundService
                somTensao = s
            end
            if somTensao then
                somTensao.Volume = calcularVolumeSFXReal(FATOR_VOLUME_SFX_TENSAO)
                if not somTensao.IsPlaying then
                    somTensao:Play()
                end
            end
        end
    else
        if somTensao and somTensao.IsPlaying then
            somTensao:Stop()
        end
    end
end

function SoundManager.EstaEmModoTensao(): boolean
    return modoTensao
end

function SoundManager.AoMudarEstadoAudio(callback: () -> ())
    table.insert(listenersEstado, callback)
end

function SoundManager.ObterSonsRegistrados(): { [string]: string }
    local copia = {}
    for k, v in pairs(SONS) do
        copia[k] = v
    end
    return copia
end

return SoundManager

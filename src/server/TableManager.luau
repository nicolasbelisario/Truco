local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Eventos = ReplicatedStorage:WaitForChild("Events")
local Partida = require(script.Parent.Classes:WaitForChild("Match"))

local GerenciadorMesas = {}
local listaMesas = {}         -- Associa o Modelo 3D à Classe Partida
local mesasPorNome = {}       -- Associa o Nome do Modelo à Classe Partida
local listaMesasOrdenada = {} -- Lista ordenada para Matchmaking e Painel de Salas
local jogadorParaMesa = {}    -- Associa o Jogador à Partida que ele está jogando
local ultimoUsoMatchmaking = {}

local matchmakingEvent = nil
local getRoomsDataFunc = nil
local broadcastPendente = false

-- CONFIGURAÇÃO DOS BOTS POR TIPO (Attribute "TipoMesa") OU PREFIXO DO NOME DA MESA (PvE)
local CONFIG_BOTS = {
    ["MesaPvE_Solo"]  = {2, 3, 4}, -- 1 Humano vs 3 Bots
    ["MesaPvE_Dupla"] = {2, 4},    -- 2 Humanos vs 2 Bots
    ["MesaPvE_Trio"]  = {4},       -- 3 Humanos vs 1 Bot
}

local ORDEM_TIPOS = {
    ["PvP"]           = 1,
    ["MesaPvE_Solo"]  = 2,
    ["MesaPvE_Dupla"] = 3,
    ["MesaPvE_Trio"]  = 4,
}

local function garantirRemoto(nome, classe)
    local existente = Eventos:FindFirstChild(nome)
    if existente then return existente end
    local novo = Instance.new(classe)
    novo.Name = nome
    novo.Parent = Eventos
    return novo
end

-- Resolve a configuração de cadeiras de bots e o tipo de mesa (retrocompatível)
local function resolverConfigMesa(modeloMesa)
    local tipoMesa = modeloMesa:GetAttribute("TipoMesa")
    if type(tipoMesa) == "string" then
        if CONFIG_BOTS[tipoMesa] then
            return CONFIG_BOTS[tipoMesa], tipoMesa
        elseif tipoMesa == "PvP" then
            return {}, "PvP"
        end
    end

    local nomeMesa = modeloMesa.Name
    if CONFIG_BOTS[nomeMesa] then
        return CONFIG_BOTS[nomeMesa], nomeMesa
    end

    for prefixo, cadeiras in pairs(CONFIG_BOTS) do
        if nomeMesa:sub(1, #prefixo) == prefixo then
            local proximoChar = nomeMesa:sub(#prefixo + 1, #prefixo + 1)
            if proximoChar == "" or proximoChar == "_" or proximoChar:match("%d") then
                return cadeiras, prefixo
            end
        end
    end

    return {}, "PvP"
end

local function gerarCodigoSalaUnico()
    local usados = {}
    for _, partida in ipairs(listaMesasOrdenada) do
        if partida.SalaPrivada and partida.CodigoSala then
            usados[partida.CodigoSala] = true
        end
    end

    for _ = 1, 50 do
        local codigo = tostring(math.random(1000, 9999))
        if not usados[codigo] then
            return codigo
        end
    end

    return tostring(math.random(1000, 9999))
end

local function sanitizarNomeSala(nomeBruto, nomeJogador)
    if type(nomeBruto) ~= "string" then
        return "Mesa de " .. nomeJogador
    end
    local limpo = nomeBruto:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[%c]", "")
    if limpo == "" then
        return "Mesa de " .. nomeJogador
    end
    if #limpo > 24 then
        limpo = limpo:sub(1, 24)
    end
    return limpo
end

--[[
    Retorna a lista serializada de todas as mesas/salas para o Painel de Matchmaking.
]]
function GerenciadorMesas.ObterListaSalas()
    local salas = {}
    for _, partida in ipairs(listaMesasOrdenada) do
        table.insert(salas, partida:ObterResumoSala())
    end
    return salas
end

local function agendarBroadcastListaSalas()
    if broadcastPendente or not matchmakingEvent then return end
    broadcastPendente = true
    task.delay(0.15, function()
        broadcastPendente = false
        if matchmakingEvent then
            matchmakingEvent:FireAllClients("RoomListUpdate", GerenciadorMesas.ObterListaSalas())
        end
    end)
end

--[[
    Calcula a pontuação de prioridade de uma mesa para Quick Play ("Jogar Agora").
    Prioridade: PvP 3/4 > PvP 2/4 > PvP 1/4 > PvE com humanos esperando > PvE Solo (início imediato) > PvE > PvP vazia.
]]
local function calcularPontuacaoQuickPlay(partida, filtroModo)
    if partida.Estado ~= "WAITING" then return -1 end
    if partida.SalaPrivada then return -1 end
    if not partida:ObterPrimeiraCadeiraLivre() then return -1 end

    if filtroModo == "PvP" and partida.UsaBots then return -1 end
    if filtroModo == "PvE" and not partida.UsaBots then return -1 end
    if (filtroModo == "PvE_Solo" or filtroModo == "MesaPvE_Solo") and partida.TipoMesa ~= "MesaPvE_Solo" then
        return -1
    end

    local humanos = partida:ContarHumanos()
    local ocupados = partida:ContarJogadores()

    if not partida.UsaBots then
        local bonusCustom = partida.SalaCustom and 15 or 0
        if humanos == 3 then
            return 1000 + bonusCustom
        elseif humanos == 2 then
            return 800 + bonusCustom
        elseif humanos == 1 then
            return 600 + bonusCustom
        else
            return 100 + bonusCustom
        end
    else
        if humanos > 0 then
            return 500 + (ocupados * 20)
        end
        local qtdBots = #partida.AssentosBots
        if qtdBots == 3 then
            return 450 -- SOLO 1v3: 1 humano basta para iniciar imediatamente
        elseif qtdBots == 2 then
            return 300 -- DUPLA 2v2
        else
            return 200 -- TRIO 3v1
        end
    end
end

--[[
    Encontra a melhor mesa disponível e senta o jogador automaticamente ("Jogar Agora").
]]
function GerenciadorMesas.ExecutarQuickPlay(jogador, filtroModo)
    local mesaAtual = jogadorParaMesa[jogador]
    if mesaAtual and (mesaAtual:EstaEmPartidaAtiva() or mesaAtual.Estado == "COUNTDOWN") then
        return { Sucesso = false, Mensagem = "Você já está em uma partida em andamento!" }
    end

    local melhorPartida = nil
    local melhorPontuacao = -1
    local usouFallbackSolo = false

    for _, partida in ipairs(listaMesasOrdenada) do
        if partida ~= mesaAtual then
            local pontuacao = calcularPontuacaoQuickPlay(partida, filtroModo)
            if pontuacao > melhorPontuacao then
                melhorPontuacao = pontuacao
                melhorPartida = partida
            end
        end
    end

    -- Se pediu MesaPvE_Solo e todas as Solo estiverem ocupadas, tenta outra PvE disponível como fallback
    if not melhorPartida and (filtroModo == "PvE_Solo" or filtroModo == "MesaPvE_Solo") then
        for _, partida in ipairs(listaMesasOrdenada) do
            if partida ~= mesaAtual then
                local pontuacao = calcularPontuacaoQuickPlay(partida, "PvE")
                if pontuacao > melhorPontuacao then
                    melhorPontuacao = pontuacao
                    melhorPartida = partida
                    usouFallbackSolo = true
                end
            end
        end
    end

    if not melhorPartida then
        return {
            Sucesso = false,
            Mensagem = "Todas as mesas estão ocupadas no momento. Tente novamente em instantes!",
        }
    end

    local ok, msg = melhorPartida:SentarJogadorNoAssento(jogador, nil, nil)
    if ok and usouFallbackSolo then
        msg = "Mesas Solo ocupadas — você entrou em " .. melhorPartida:ObterNomeExibicao() .. "!"
    end
    return {
        Sucesso = ok,
        Mensagem = msg,
        MesaNome = melhorPartida.Modelo.Name,
        NomeExibicao = melhorPartida:ObterNomeExibicao(),
        Privada = melhorPartida.SalaPrivada,
        Codigo = melhorPartida.SalaPrivada and melhorPartida.CodigoSala or nil,
    }
end

--[[
    Cria uma sala PvP pública ou privada alocando uma mesa PvP vazia e sentando o anfitrião.
]]
function GerenciadorMesas.CriarSala(jogador, opcoes)
    local mesaAtual = jogadorParaMesa[jogador]
    if mesaAtual and (mesaAtual:EstaEmPartidaAtiva() or mesaAtual.Estado == "COUNTDOWN") then
        return { Sucesso = false, Mensagem = "Finalize sua partida atual antes de criar uma mesa." }
    end

    local mesaLivre = nil
    for _, partida in ipairs(listaMesasOrdenada) do
        if not partida.UsaBots
            and partida.Estado == "WAITING"
            and partida:ContarJogadores() == 0
            and not partida.SalaCustom then
            mesaLivre = partida
            break
        end
    end

    if not mesaLivre then
        return {
            Sucesso = false,
            Mensagem = "Não há mesas PvP vazias disponíveis para criar uma nova partida agora.",
        }
    end

    local dados = (type(opcoes) == "table") and opcoes or {}
    local privada = dados.Privada == true
    local nomeSala = sanitizarNomeSala(dados.NomeSala, jogador.Name)
    local codigo = privada and gerarCodigoSalaUnico() or nil

    mesaLivre:ConfigurarSala(jogador, nomeSala, privada, codigo)
    local ok, msg = mesaLivre:SentarJogadorNoAssento(jogador, nil, codigo)

    if not ok then
        mesaLivre:LimparConfiguracaoSala()
        return { Sucesso = false, Mensagem = msg }
    end

    local mensagemFinal = privada
        and ("Mesa privada criada! Código: " .. codigo)
        or ("Mesa pública '" .. nomeSala .. "' criada! Aguardando jogadores...")

    return {
        Sucesso = true,
        Mensagem = mensagemFinal,
        MesaNome = mesaLivre.Modelo.Name,
        NomeExibicao = nomeSala,
        Privada = privada,
        Codigo = codigo,
    }
end

--[[
    Posiciona o jogador em uma sala específica pelo nome do modelo da mesa.
]]
function GerenciadorMesas.EntrarEmSala(jogador, nomeMesa, codigo)
    if type(nomeMesa) ~= "string" then
        return { Sucesso = false, Mensagem = "Mesa inválida." }
    end
    local partida = mesasPorNome[nomeMesa]
    if not partida then
        return { Sucesso = false, Mensagem = "Mesa não encontrada." }
    end

    local ok, msg = partida:SentarJogadorNoAssento(jogador, nil, codigo)
    return {
        Sucesso = ok,
        Mensagem = msg,
        MesaNome = partida.Modelo.Name,
        NomeExibicao = partida:ObterNomeExibicao(),
        Privada = partida.SalaPrivada,
        Codigo = (ok and partida.SalaPrivada) and partida.CodigoSala or nil,
    }
end

--[[
    Localiza uma sala privada ativa pelo código de 4 dígitos e posiciona o jogador nela.
]]
function GerenciadorMesas.EntrarPorCodigo(jogador, codigoBruto)
    local codigo = type(codigoBruto) == "string" and codigoBruto:gsub("%s+", "") or tostring(codigoBruto or "")
    if codigo == "" then
        return { Sucesso = false, Mensagem = "Digite o código da mesa privada." }
    end

    for _, partida in ipairs(listaMesasOrdenada) do
        if partida.SalaPrivada and partida.CodigoSala == codigo then
            local ok, msg = partida:SentarJogadorNoAssento(jogador, nil, codigo)
            return {
                Sucesso = ok,
                Mensagem = msg,
                MesaNome = partida.Modelo.Name,
                NomeExibicao = partida:ObterNomeExibicao(),
                Privada = true,
                Codigo = ok and codigo or nil,
            }
        end
    end

    return { Sucesso = false, Mensagem = "Nenhuma mesa privada encontrada com o código " .. codigo .. "." }
end

-- [MÉTODO] Lê todas as mesas do mapa e cria as instâncias lógicas
function GerenciadorMesas.Inicializar(pasta)
    matchmakingEvent = garantirRemoto("MatchmakingEvent", "RemoteEvent")
    getRoomsDataFunc = garantirRemoto("GetRoomsData", "RemoteFunction")

    for _, modeloMesa in ipairs(pasta:GetChildren()) do
        local cadeirasBot, tipoMesa = resolverConfigMesa(modeloMesa)
        local partida = Partida.nova(modeloMesa, cadeirasBot, tipoMesa)

        listaMesas[modeloMesa] = partida
        mesasPorNome[modeloMesa.Name] = partida
        table.insert(listaMesasOrdenada, partida)

        -- Callbacks para registrar qual jogador está em qual mesa
        partida.OnPlayerJoin = function(jogador)
            jogadorParaMesa[jogador] = partida
        end

        partida.OnPlayerLeave = function(jogador)
            if jogadorParaMesa[jogador] == partida then
                jogadorParaMesa[jogador] = nil
            end
        end

        partida.CanPlayerJoin = function(jogador, partidaAlvo)
            local atual = jogadorParaMesa[jogador]
            if atual and atual ~= partidaAlvo and (atual:EstaEmPartidaAtiva() or atual.Estado == "COUNTDOWN") then
                return false, "Você já está em uma partida em andamento!"
            end
            return true
        end

        partida.OnStateChanged = function()
            agendarBroadcastListaSalas()
        end
    end

    table.sort(listaMesasOrdenada, function(a, b)
        local ordemA = ORDEM_TIPOS[a.TipoMesa] or 99
        local ordemB = ORDEM_TIPOS[b.TipoMesa] or 99
        if ordemA ~= ordemB then
            return ordemA < ordemB
        end
        return a.Modelo.Name < b.Modelo.Name
    end)

    -- Garante substituição por Bot (Drop-in) ou limpeza de assento ao desconectar do servidor
    Players.PlayerRemoving:Connect(function(jogador)
        ultimoUsoMatchmaking[jogador] = nil
        local partida = jogadorParaMesa[jogador]
        if partida then
            partida:ProcessarSaidaJogador(jogador)
            if jogadorParaMesa[jogador] == partida then
                jogadorParaMesa[jogador] = nil
            end
        end
    end)

    GerenciadorMesas.ConfigurarRede()
end

-- [MÉTODO] Recebe as ações dos clientes e redireciona para a mesa correta
function GerenciadorMesas.ConfigurarRede()
    Eventos.PlayCardEvent.OnServerEvent:Connect(function(jogador, cardId, escondida)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:JogadorJogarCarta(jogador, cardId, escondida) end
    end)

    Eventos.TrucoEvent.OnServerEvent:Connect(function(jogador, acao, subAcao)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:ProcessarAcaoTruco(jogador, acao, subAcao) end
    end)

    Eventos.GameStatusEvent.OnServerEvent:Connect(function(jogador, acao, valor)
        local partida = jogadorParaMesa[jogador]
        if partida then
            if acao == "CutAction" then
                partida:JogadorCortarBaralho(jogador, valor)
            elseif acao == "HandOfElevenDecision" then
                partida:JogadorDecidirMaoDeOnze(jogador, valor)
            end
        end
    end)

    Eventos.SignalEvent.OnServerEvent:Connect(function(jogador, tipoSinal)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:TransmitirSinal(jogador, tipoSinal) end
    end)

    -- Matchmaking, Quick Play e Salas Públicas/Privadas (UC-15)
    if getRoomsDataFunc then
        getRoomsDataFunc.OnServerInvoke = function()
            return GerenciadorMesas.ObterListaSalas()
        end
    end

    if matchmakingEvent then
        matchmakingEvent.OnServerEvent:Connect(function(jogador, acao, arg1, arg2)
            local agora = tick()
            if ultimoUsoMatchmaking[jogador] and (agora - ultimoUsoMatchmaking[jogador]) < 0.4 then
                return
            end
            ultimoUsoMatchmaking[jogador] = agora

            local resultado = nil
            if acao == "QuickPlay" then
                resultado = GerenciadorMesas.ExecutarQuickPlay(jogador, arg1)
            elseif acao == "EntrarMesa" then
                resultado = GerenciadorMesas.EntrarEmSala(jogador, arg1, arg2)
            elseif acao == "EntrarPorCodigo" then
                resultado = GerenciadorMesas.EntrarPorCodigo(jogador, arg1)
            elseif acao == "CriarSala" then
                resultado = GerenciadorMesas.CriarSala(jogador, arg1)
            end

            if resultado then
                matchmakingEvent:FireClient(jogador, "QuickPlayResult", resultado)
            end
        end)
    end
end

return GerenciadorMesas

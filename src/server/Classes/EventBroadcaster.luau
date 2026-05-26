local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local EventBroadcaster = {}

-- (I) Interface mínima — Match só precisa dessas funções

--[[
    Envia uma mensagem de status e dados auxiliares para todos os jogadores na mesa,
    exceto para os Bots.
    @param assentos table: Lista de assentos e seus ocupantes.
    @param msg string: Mensagem ou identificador do evento.
    @param dados any: Dados complementares.
    @param fnEBot function: Função que verifica se a entidade é um bot.
]]
function EventBroadcaster.ParaTodos(assentos, msg, dados, fnEBot)
    for _, jog in pairs(assentos) do
        if not fnEBot(jog) then
            Eventos.GameStatusEvent:FireClient(jog, msg, dados)
        end
    end
end

--[[
    Envia uma mensagem de status e dados especificamente para um jogador,
    desde que não seja um Bot.
    @param jogador Player: O jogador destino.
    @param msg string: Mensagem ou identificador do evento.
    @param dados any: Dados complementares.
    @param fnEBot function: Função que verifica se a entidade é um bot.
]]
function EventBroadcaster.ParaJogador(jogador, msg, dados, fnEBot)
    if jogador and not fnEBot(jogador) then
        Eventos.GameStatusEvent:FireClient(jogador, msg, dados)
    end
end

--[[
    Notifica um jogador sobre as cartas que ele recebeu na rodada e informa
    o nome do seu parceiro, ativando a UI de jogo em seguida.
    @param jogador Player: O jogador que está recebendo a mão.
    @param mao table: Lista contendo as cartas do jogador.
    @param vira table: A carta que define a manilha (vira da rodada).
    @param nomeParceiro string: O nome de exibição do parceiro do jogador.
]]
function EventBroadcaster.DistribuirCartas(jogador, mao, vira, nomeParceiro)
    Eventos.DealCards:FireClient(jogador, mao, vira, nomeParceiro)
    Eventos.GameStatusEvent:FireClient(jogador, "SHOW_GAME_UI")
end

--[[
    Atualiza a UI de todos os humanos da partida sobre de quem é a vez atual.
    @param humanos table: Lista de instâncias de jogadores humanos.
    @param nomeVez string: O nome do jogador cuja vez é agora.
    @param numRodada number: O número da queda/rodada atual.
]]
function EventBroadcaster.AtualizarTurno(humanos, nomeVez, numRodada)
    for _, h in ipairs(humanos) do
        Eventos.UpdateTurnEvent:FireClient(h, nomeVez, numRodada)
    end
end

--[[
    Notifica a todos os jogadores humanos da partida que uma carta foi jogada na mesa.
    @param humanos table: Lista de instâncias de jogadores humanos.
    @param nomeExibicao string: O nome de quem jogou a carta.
    @param valor string: O valor da carta.
    @param naipe string: O naipe da carta.
    @param escondida boolean: Indica se a carta foi jogada virada para baixo (coberta).
    @param skin string: O ID ou nome da skin da carta usada pelo jogador.
]]
function EventBroadcaster.CartaJogada(humanos, nomeExibicao, valor, naipe, escondida, skin)
    for _, h in ipairs(humanos) do
        Eventos.CardPlayedOnTable:FireClient(h, nomeExibicao, valor, naipe, escondida, skin)
    end
end

--[[
    Solicita ao cliente do jogador uma ação específica (ex: escolher o corte do baralho
    ou responder a um truco).
    @param jogador Player: O jogador humano que deve responder.
    @param tipo string: O identificador da ação ("EscolhaOCorte", "TrucoChallenge", etc.).
    @param dados any: Parâmetros extras para a ação solicitada (como limites de tempo).
]]
function EventBroadcaster.PedirAcao(jogador, tipo, dados)
    Eventos.RequestAction:FireClient(jogador, tipo, dados)
end

--[[
    Transmite um sinal ou emote visual de um remetente para todos os humanos da partida.
    Usado para comunicação secreta (blefe/sinais) entre a equipe.
    @param humanos table: Lista de instâncias de jogadores humanos.
    @param remetente Player: O jogador que enviou o sinal.
    @param tipo string: Qual o tipo de sinal ("Sinal_Mao", "Sinal_Olhar", etc.).
]]
function EventBroadcaster.SinalEmote(humanos, remetente, tipo)
    for _, h in ipairs(humanos) do
        Eventos.SignalEvent:FireClient(h, remetente, tipo)
    end
end

return EventBroadcaster
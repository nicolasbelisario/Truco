local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local EventBroadcaster = {}

-- (I) Interface mínima — Match só precisa dessas funções
function EventBroadcaster.ParaTodos(assentos, msg, dados, fnEBot)
    for _, jog in pairs(assentos) do
        if not fnEBot(jog) then
            Eventos.GameStatusEvent:FireClient(jog, msg, dados)
        end
    end
end

function EventBroadcaster.ParaJogador(jogador, msg, dados, fnEBot)
    if jogador and not fnEBot(jogador) then
        Eventos.GameStatusEvent:FireClient(jogador, msg, dados)
    end
end

function EventBroadcaster.DistribuirCartas(jogador, mao, vira, nomeParceiro)
    Eventos.DealCards:FireClient(jogador, mao, vira, nomeParceiro)
    Eventos.GameStatusEvent:FireClient(jogador, "SHOW_GAME_UI")
end

function EventBroadcaster.AtualizarTurno(humanos, nomeVez, numRodada)
    for _, h in ipairs(humanos) do
        Eventos.UpdateTurnEvent:FireClient(h, nomeVez, numRodada)
    end
end

function EventBroadcaster.CartaJogada(humanos, nomeExibicao, valor, naipe, escondida, skin)
    for _, h in ipairs(humanos) do
        Eventos.CardPlayedOnTable:FireClient(h, nomeExibicao, valor, naipe, escondida, skin)
    end
end

function EventBroadcaster.PedirAcao(jogador, tipo, dados)
    Eventos.RequestAction:FireClient(jogador, tipo, dados)
end

function EventBroadcaster.SinalEmote(humanos, remetente, tipo)
    for _, h in ipairs(humanos) do
        Eventos.SignalEvent:FireClient(h, remetente, tipo)
    end
end

return EventBroadcaster
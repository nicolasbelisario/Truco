local GerenciadorRegras = {}

-- [MÉTODO] Retorna a pontuação numérica (força) de uma carta
function GerenciadorRegras.CalcularForcaCarta(dadosCarta)
    if dadosCarta.IsHidden == true then
        return 0 -- Carta encoberta sempre perde
    end

    -- Se for manilha, a força é 100 + a força da manilha (Zap = 104, Copas = 103...)
    if dadosCarta.ManilhaStrength > 0 then
        return 100 + dadosCarta.ManilhaStrength
    end

    return dadosCarta.Strength or 0
end

-- [MÉTODO] Avalia todas as 4 cartas jogadas e devolve quem ganhou
function GerenciadorRegras.ObterVencedorRodada(cartasJogadas)
    local vencedor = nil
    local equipeMaior = nil
    local maiorForca = 0
    local empatou = false 

    for _, jogada in ipairs(cartasJogadas) do
        local forcaAtual = GerenciadorRegras.CalcularForcaCarta(jogada)

        if forcaAtual > maiorForca then
            maiorForca = forcaAtual
            vencedor = jogada.Player
            equipeMaior = jogada.Team
            empatou = false
        elseif forcaAtual == maiorForca and maiorForca > 0 then
            -- Se dois parceiros da mesma equipe empatarem na maior carta, NÃO é empate (canga):
            -- a equipe deles continua vencendo com o primeiro parceiro que jogou.
            if not (jogada.Team ~= nil and equipeMaior ~= nil and jogada.Team == equipeMaior) then
                empatou = true
            end
        end
    end

    if maiorForca <= 0 or empatou then
        return "DRAW"
    else
        return vencedor
    end
end

return GerenciadorRegras
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
    local maiorForca = -1
    local empatou = false 

    for _, jogada in pairs(cartasJogadas) do
        -- A 'jogada' agora contém o objeto da carta completo
        local forcaAtual = GerenciadorRegras.CalcularForcaCarta(jogada)

        if forcaAtual > maiorForca then
            maiorForca = forcaAtual
            vencedor = jogada.Player
            empatou = false
        elseif forcaAtual == maiorForca and maiorForca > 0 then
            -- Empate só acontece se a força for a mesma e maior que zero (não pode empatar com carta virada)
            empatou = true
            -- Em caso de empate, o vencedor é temporariamente nulo até que todas as cartas sejam verificadas.
            -- A lógica de desempate (canga) é tratada no RoundManager com o histórico de quedas.
        end
    end

    if empatou then return "DRAW" else return vencedor end
end

return GerenciadorRegras
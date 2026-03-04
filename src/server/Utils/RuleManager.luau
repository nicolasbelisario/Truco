local GerenciadorRegras = {}

-- Ordem base de força (do mais fraco para o mais forte, Truco Paulista)
local ORDEM_VALOR = {
    ["4"] = 1, ["5"] = 2, ["6"] = 3, ["7"] = 4,
    ["Q"] = 5, ["J"] = 6, ["K"] = 7, ["A"] = 8,
    ["2"] = 9, ["3"] = 10
}

local ORDEM_NAIPE = {
    ["Ouros"] = 1, ["Espadas"] = 2, ["Copas"] = 3, ["Paus"] = 4
}

-- [MÉTODO INTERNO] Acha qual é a Manilha (próxima carta depois do Vira)
local function ObterValorManilha(valorVira)
    local valores = {"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"}
    for i, valor in ipairs(valores) do
        if valor == valorVira then
            if i == #valores then return valores[1] end -- Se vira é 3, manilha é 4
            return valores[i+1]
        end
    end
    return "4"
end

-- [MÉTODO] Retorna a pontuação numérica (força) de uma carta
function GerenciadorRegras.CalcularForcaCarta(dadosCarta, valorVira)
    if dadosCarta.IsHidden == true then
        return 0 -- Carta encoberta sempre perde
    end

    local valor = dadosCarta.Value 
    local naipe = dadosCarta.Suit
    local valorManilha = ObterValorManilha(valorVira)

    -- Se for manilha, soma 100 + a força do naipe (ZAP = 104, Copas = 103...)
    if valor == valorManilha then
        local forcaNaipe = ORDEM_NAIPE[naipe] or 0
        return 100 + forcaNaipe
    end

    return ORDEM_VALOR[valor] or 0
end

-- [MÉTODO] Avalia todas as 4 cartas jogadas e devolve quem ganhou
function GerenciadorRegras.ObterVencedorRodada(cartasJogadas, valorVira)
    local vencedor = nil
    local maiorForca = -1
    local empatou = false 

    for _, jogada in pairs(cartasJogadas) do
        local forcaAtual = GerenciadorRegras.CalcularForcaCarta(jogada, valorVira)

        if forcaAtual > maiorForca then
            maiorForca = forcaAtual
            vencedor = jogada.Player
            empatou = false
        elseif forcaAtual == maiorForca then
            if maiorForca > 0 then
                empatou = true
                vencedor = nil 
            end
        end
    end

    if empatou then return "DRAW" else return vencedor end
end

return GerenciadorRegras
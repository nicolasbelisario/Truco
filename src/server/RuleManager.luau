local RuleManager = {}

local PowerSequence = {"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"}
local SuitPower = { ["Ouros"] = 1, ["Espadas"] = 2, ["Copas"] = 3, ["Paus"] = 4 }

-- Determina qual carta é a manilha baseado no Vira
function RuleManager.GetManilhaValue(viraValue)
    local index = table.find(PowerSequence, viraValue)
    if not index then return "4" end -- Fallback de segurança
    return index == #PowerSequence and PowerSequence[1] or PowerSequence[index + 1]
end

-- Calcula a força absoluta de uma carta (0-10 para normais, 100+ para manilhas)
function RuleManager.GetCardPower(cardValue, cardSuit, viraValue)
    local manilhaValue = RuleManager.GetManilhaValue(viraValue)
    
    if cardValue == manilhaValue then
        -- É manilha: base 100 + força do naipe (Paus > Copas > Espadas > Ouros)
        return 100 + SuitPower[cardSuit]
    else
        -- Carta normal: valor da sequência
        return table.find(PowerSequence, cardValue) or 0
    end
end

-- Retorna o índice (na lista de cartas jogadas) da carta vencedora
function RuleManager.DetermineWinner(playedCards, viraValue)
    local winnerIndex = 1
    local highestPower = -1
    local draws = false -- Cangalha/Empate

    for i, card in ipairs(playedCards) do
        local power = RuleManager.GetCardPower(card.Value, card.Suit, viraValue)
        if power > highestPower then
            highestPower = power
            winnerIndex = i
            draws = false
        elseif power == highestPower then
            draws = true
        end
    end

    return draws and "CANGALHOU" or winnerIndex
end

return RuleManager
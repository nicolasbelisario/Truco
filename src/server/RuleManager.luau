-- src/shared/RuleManager.luau
local RuleManager = {}

local PowerSequence = {"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"}
local SuitPower = { ["Ouros"] = 1, ["Espadas"] = 2, ["Copas"] = 3, ["Paus"] = 4 }

function RuleManager.GetManilhaValue(viraValue)
    local index = table.find(PowerSequence, viraValue)
    return index == #PowerSequence and PowerSequence[1] or PowerSequence[index + 1]
end

function RuleManager.GetCardPower(cardValue, cardSuit, viraValue)
    local manilhaValue = RuleManager.GetManilhaValue(viraValue)
    
    if cardValue == manilhaValue then
        -- É manilha, o poder é altíssimo + peso do naipe
        return 100 + SuitPower[cardSuit]
    else
        -- Não é manilha, usa apenas a sequência normal
        return table.find(PowerSequence, cardValue)
    end
end

-- Retorna o índice do vencedor (1 a 4)
function RuleManager.DetermineWinner(playedCards, viraValue)
    local winnerIndex = 1
    local highestPower = -1
    local draws = false

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
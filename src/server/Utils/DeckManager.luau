local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local DeckManager = {}

-- Cria e RETORNA um novo baralho
function DeckManager.CreateDeck()
    local deck = {}
    for _, suit in ipairs(CardSettings.Suits) do
        for _, value in ipairs(CardSettings.Values) do
            table.insert(deck, {
                Value = value,
                Suit = suit
            })
        end
    end
    return deck
end

-- Recebe o baralho específico da mesa para embaralhar
function DeckManager.Shuffle(deck)
    if not deck then return end
    local rng = Random.new()
    for i = #deck, 2, -1 do
        local j = rng:NextInteger(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

-- Recebe o baralho específico da mesa para cortar
function DeckManager.Cut(deck, numCuts)
    if not deck then return end
    if numCuts < 1 or numCuts > 3 then numCuts = 1 end
    
    local size = #deck
    if size < 10 then return end 

    for i = 1, numCuts do
        local minPoint = 5
        local maxPoint = size - 5
        
        if minPoint < maxPoint then
            local cutPoint = math.random(minPoint, maxPoint)
            
            -- Move a parte de cima para uma tabela temporária
            local topPart = table.move(deck, 1, cutPoint, 1, {})
            -- Move a parte de baixo para outra tabela
            local bottomPart = table.move(deck, cutPoint + 1, size, 1, {})
            
            -- Reconstrói o deck invertido (baixo -> cima)
            -- Limpa o deck original mantendo a referência
            table.clear(deck)
            
            for _, card in ipairs(bottomPart) do table.insert(deck, card) end
            for _, card in ipairs(topPart) do table.insert(deck, card) end
        end
    end
    -- print("Baralho cortado " .. numCuts .. " vezes.")
end

return DeckManager
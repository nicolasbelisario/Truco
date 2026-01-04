local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local DeckManager = {}
local currentDeck = {}

-- Cria um baralho novo de 40 cartas baseado nas configurações
function DeckManager.CreateDeck()
    currentDeck = {}
    for _, suit in ipairs(CardSettings.Suits) do
        for _, value in ipairs(CardSettings.Values) do
            table.insert(currentDeck, {
                Value = value,
                Suit = suit
            })
        end
    end
    return currentDeck
end

-- Algoritmo Fisher-Yates para embaralhamento real
function DeckManager.Shuffle()
    local rng = Random.new()
    for i = #currentDeck, 2, -1 do
        local j = rng:NextInteger(1, i)
        currentDeck[i], currentDeck[j] = currentDeck[j], currentDeck[i]
    end
end

-- Realiza o corte do baralho (simula dividir em pilhas e inverter)
function DeckManager.Cut(numCuts)
    if numCuts < 1 or numCuts > 3 then numCuts = 1 end
    
    local size = #currentDeck
    if size < 10 then return end 

    for i = 1, numCuts do
        local minPoint = 5
        local maxPoint = size - 5
        
        if minPoint < maxPoint then
            local cutPoint = math.random(minPoint, maxPoint)
            local topPart = table.move(currentDeck, 1, cutPoint, 1, {})
            local bottomPart = table.move(currentDeck, cutPoint + 1, size, 1, {})
            
            -- Inverte: o que estava embaixo vai para cima
            currentDeck = {}
            for _, card in ipairs(bottomPart) do table.insert(currentDeck, card) end
            for _, card in ipairs(topPart) do table.insert(currentDeck, card) end
        end
    end
    print("Baralho cortado " .. numCuts .. " vezes.")
end

function DeckManager.GetCurrentDeck()
    return currentDeck
end

return DeckManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CardSettings = require(Shared:WaitForChild("CardSettings"))

local DeckManager = {}
local currentDeck = {}

-- Gera um baralho novo de 40 cartas
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
	print("Baralho criado com 40 cartas.")
	return currentDeck
end

-- Embaralhamento usando o algoritmo Fisher-Yates
function DeckManager.Shuffle()
	local rng = Random.new()
	for i = #currentDeck, 2, -1 do
		local j = rng:NextInteger(1, i)
		currentDeck[i], currentDeck[j] = currentDeck[j], currentDeck[i]
	end
	print("Baralho embaralhado.")
end

-- Lógica de Corte (1, 2 ou 3 vezes)
-- O 'numCuts' define em quantas partes o jogador divide o baralho
function DeckManager.Cut(numCuts)
    if numCuts < 1 or numCuts > 3 then numCuts = 1 end
    
    local size = #currentDeck
    if size < 10 then return end -- Segurança para baralhos incompletos

    for i = 1, numCuts do
        -- Garante que o ponto de corte seja sempre válido dentro do baralho
        local minPoint = 5
        local maxPoint = size - 5
        
        if minPoint < maxPoint then
            local cutPoint = math.random(minPoint, maxPoint)
            local topPart = table.move(currentDeck, 1, cutPoint, 1, {})
            local bottomPart = table.move(currentDeck, cutPoint + 1, size, 1, {})
            
            -- Inverte as partes
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
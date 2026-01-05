local RuleManager = {}

-- Ordem de força (do mais fraco para o mais forte)
-- 4, 5, 6, 7, Q, J, K, A, 2, 3
local RANK_ORDER = {
	["4"] = 1, ["5"] = 2, ["6"] = 3, ["7"] = 4,
	["Q"] = 5, ["J"] = 6, ["K"] = 7, ["A"] = 8,
	["2"] = 9, ["3"] = 10
}

local SUIT_ORDER = {
	["Ouros"] = 1, ["Espadas"] = 2, ["Copas"] = 3, ["Paus"] = 4
}

-- Função auxiliar para pegar a manilha
local function GetManilhaRank(viraRank)
	local ranks = {"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"}
	for i, rank in ipairs(ranks) do
		if rank == viraRank then
			if i == #ranks then return ranks[1] end
			return ranks[i+1]
		end
	end
	return "4"
end

--[[ 
    Calcula força.
    Agora aceita a tabela direta (Value/Suit) em vez de card.Rank.
]]
function RuleManager.GetCardPower(cardData, viraRank)
	if cardData.IsHidden == true then
		return 0 
	end

	local rank = cardData.Value -- MUDANÇA: 'Value' em vez de 'Rank' para bater com o GameManager
	local suit = cardData.Suit
	
	local manilhaRank = GetManilhaRank(viraRank)

	if rank == manilhaRank then
		local suitPower = SUIT_ORDER[suit] or 0
		return 100 + suitPower
	end

	return RANK_ORDER[rank] or 0
end

--[[
    Determina o vencedor.
    cardsPlayed é uma lista: { {Player=..., Value=..., Suit=..., IsHidden=...}, ... }
]]
function RuleManager.GetRoundWinner(cardsPlayed, viraRank)
	local winner = nil
	local highestPower = -1
	local isDraw = false 

	for _, play in pairs(cardsPlayed) do
		-- O próprio 'play' já contém Value e Suit inseridos pelo GameManager
		local currentPower = RuleManager.GetCardPower(play, viraRank)

		print(string.format("Jogador: %s | Carta: %s de %s (Hidden: %s) | Força: %d", 
			play.Player.Name, play.Value, play.Suit, tostring(play.IsHidden), currentPower))

		if currentPower > highestPower then
			highestPower = currentPower
			winner = play.Player
			isDraw = false
		elseif currentPower == highestPower then
			if highestPower > 0 then
				isDraw = true
				winner = nil 
			end
		end
	end

	if isDraw then
		return "DRAW"
	else
		return winner -- Retorna o OBJETO Player
	end
end

return RuleManager
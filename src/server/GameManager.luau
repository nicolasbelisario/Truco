local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local DeckManager = require(script.Parent:WaitForChild("DeckManager"))
local RuleManager = require(script.Parent:WaitForChild("RuleManager"))

local GameManager = {}

-- Estado Global
local trucoState = {
	currentValue = 1,     -- Valor VALENDO na mesa agora
	pendingValue = 0,     -- Valor sendo PROPOSTO (durante o pedido)
	callerTeam = nil,     -- Quem pediu o aumento atual
	waitingResponse = false,
	challengeId = 0,
	votes = {}
}

local currentState = GameConfig.States.WAITING
local dealerIndex = 1 
local currentTurnIndex = 1
local currentVira = nil
local scores = { TeamA = 0, TeamB = 0 }
local tricksWon = { TeamA = 0, TeamB = 0 }
local cardsInTable = {}
local handValue = 1

-- Funções Auxiliares
local function getTeamOfPlayer(player)
	local _, seatedPlayers = SeatManager.GetSeatedPlayers()
	for name, p in pairs(seatedPlayers) do
		if p == player then
			local seatNum = tonumber(name:match("%d+"))
			return (seatNum % 2 == 1) and "A" or "B"
		end
	end
	return nil
end

local function getPlayerNameBySeat(seatName)
	local _, seatedPlayers = SeatManager.GetSeatedPlayers()
	local player = seatedPlayers[seatName]
	return player and player.Name or seatName
end

local function getPartner(player)
	local _, seatedPlayers = SeatManager.GetSeatedPlayers()
	local myTeam = getTeamOfPlayer(player)
	for _, p in pairs(seatedPlayers) do
		if p ~= player and getTeamOfPlayer(p) == myTeam then
			return p
		end
	end
	return nil
end

local function getCurrentTrickNumber()
	return tricksWon.TeamA + tricksWon.TeamB + 1
end

-- --- CICLO DE VIDA DO JOGO ---

function GameManager.GetState() return currentState end

function GameManager.SetState(newState)
	currentState = newState
	Events.GameStatusEvent:FireAllClients(newState, 0)
end

function GameManager.StartCountdown()
	if currentState ~= GameConfig.States.WAITING then return end
	GameManager.SetState(GameConfig.States.COUNTDOWN)
	for i = GameConfig.COUNTDOWN_TIME, 0, -1 do
		local count, _ = SeatManager.GetSeatedPlayers()
		if count < 4 then
			GameManager.SetState(GameConfig.States.WAITING)
			GameManager.NotifySeatedPlayers("WAITING", 0)
			return
		end
		GameManager.NotifySeatedPlayers("COUNTDOWN", i)
		task.wait(1)
	end
	GameManager.BeginGame()
end

function GameManager.BeginGame()
	scores.TeamA = 0
	scores.TeamB = 0
	dealerIndex = math.random(1, 4)
	
	local _, players = SeatManager.GetSeatedPlayers()
	for _, player in pairs(players) do
		SeatManager.SetJumpLock(player, true)
		Events.GameStatusEvent:FireClient(player, "SHOW_SCOREBOARD")
		Events.GameStatusEvent:FireClient(player, "UPDATE_SCORE", scores)
	end

	GameManager.StartNewRound()
end

-- --- LÓGICA DE PARTIDA ---

function GameManager.StartNewRound()
	trucoState.waitingResponse = false
	trucoState.callerTeam = nil
	trucoState.currentValue = 1
	trucoState.pendingValue = 0
	trucoState.votes = {} 
	
	tricksWon.TeamA = 0
	tricksWon.TeamB = 0
	cardsInTable = {}
	handValue = 1

	Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", 1)
	-- No início da rodada, TODOS podem pedir Truco
	Events.GameStatusEvent:FireAllClients("SHOW_TRUCO_BTN", 0)

	DeckManager.CreateDeck()
	DeckManager.Shuffle()
	GameManager.SetState(GameConfig.States.CUTTING)

	local roles = GameManager.GetRoles()
	local _, players = SeatManager.GetSeatedPlayers()
	local cortePlayer = players[roles.Corte]

	if cortePlayer then
		Events.RequestAction:FireClient(cortePlayer, "EscolhaOCorte", GameConfig.CUT_TIME_LIMIT)
		task.delay(GameConfig.CUT_TIME_LIMIT + 1, function()
			if currentState == GameConfig.States.CUTTING then
				GameManager.DistributeCards()
			end
		end)
	else
		GameManager.DistributeCards()
	end
end

function GameManager.GetRoles()
	local cutIndex = (dealerIndex % 4) + 1 		
	local handIndex = (dealerIndex - 2) % 4 + 1 	
	return {Dealer = "Cadeira" .. dealerIndex, Corte = "Cadeira" .. cutIndex, Mao = "Cadeira" .. handIndex}
end

Events.GameStatusEvent.OnServerEvent:Connect(function(player, action, value)
	if action == "CutAction" and currentState == GameConfig.States.CUTTING then
		DeckManager.Cut(value)
		GameManager.DistributeCards()
	end
end)

function GameManager.DistributeCards()
	GameManager.SetState(GameConfig.States.DEALING)
	local deck = DeckManager.GetCurrentDeck()
	currentVira = table.remove(deck, 1)
	local _, players = SeatManager.GetSeatedPlayers()

	for _, player in pairs(players) do
		local mao = { table.remove(deck, 1), table.remove(deck, 1), table.remove(deck, 1) }
		
		local partnerName = "Ninguém"
		local partnerPlayer = getPartner(player)
		if partnerPlayer then
			partnerName = partnerPlayer.Name
		end

		Events.DealCards:FireClient(player, mao, currentVira, partnerName) 
		Events.GameStatusEvent:FireClient(player, "SHOW_GAME_UI")
	end

	task.wait(1)
	GameManager.SetState(GameConfig.States.PLAYING)
	local roles = GameManager.GetRoles()
	currentTurnIndex = tonumber(string.match(roles.Mao, "%d+"))
	Events.UpdateTurnEvent:FireAllClients(getPlayerNameBySeat(roles.Mao), getCurrentTrickNumber())
end

Events.PlayCardEvent.OnServerEvent:Connect(function(player, value, suit, isHidden) 
	if currentState ~= GameConfig.States.PLAYING then return end
	local _, seatedPlayers = SeatManager.GetSeatedPlayers()
	if seatedPlayers["Cadeira" .. currentTurnIndex] ~= player then return end

	if getCurrentTrickNumber() == 1 then
		isHidden = false
	end

	table.insert(cardsInTable, {
		Player = player, 
		Value = value, 
		Suit = suit, 
		IsHidden = isHidden
	})
	
	Events.CardPlayedOnTable:FireAllClients(player.Name, value, suit, isHidden)
	
	if #cardsInTable == 4 then
		task.wait(1.5)
		GameManager.EvaluateTrick()
	else
		currentTurnIndex = (currentTurnIndex - 2) % 4 + 1
		Events.UpdateTurnEvent:FireAllClients(getPlayerNameBySeat("Cadeira" .. currentTurnIndex), getCurrentTrickNumber())
	end
end)

function GameManager.EvaluateTrick()
	local winnerResult = RuleManager.GetRoundWinner(cardsInTable, currentVira.Value)
	
	if winnerResult == "DRAW" then
		local winnerPlayer = cardsInTable[1].Player
		local team = getTeamOfPlayer(winnerPlayer)
		if team == "A" then tricksWon.TeamA += 1 else tricksWon.TeamB += 1 end
		
		local _, seated = SeatManager.GetSeatedPlayers()
		for seatName, p in pairs(seated) do
			if p == winnerPlayer then
				currentTurnIndex = tonumber(seatName:match("%d+"))
				break
			end
		end

	elseif typeof(winnerResult) == "Instance" and winnerResult:IsA("Player") then
		local winnerPlayer = winnerResult
		local team = getTeamOfPlayer(winnerPlayer)
		if team == "A" then tricksWon.TeamA += 1 else tricksWon.TeamB += 1 end
		
		local _, seated = SeatManager.GetSeatedPlayers()
		for seatName, p in pairs(seated) do
			if p == winnerPlayer then
				currentTurnIndex = tonumber(seatName:match("%d+"))
				break
			end
		end
	end
	
	cardsInTable = {}

	if tricksWon.TeamA >= 2 then
		GameManager.WinHand("A")
	elseif tricksWon.TeamB >= 2 then
		GameManager.WinHand("B")
	else
		Events.GameStatusEvent:FireAllClients("CLEAR_TABLE", { TeamA = tricksWon.TeamA, TeamB = tricksWon.TeamB })
		task.wait(1)
		Events.UpdateTurnEvent:FireAllClients(getPlayerNameBySeat("Cadeira" .. currentTurnIndex), getCurrentTrickNumber())
	end
end

function GameManager.WinHand(teamWinner)
	if teamWinner == "A" then scores.TeamA += handValue else scores.TeamB += handValue end
	Events.GameStatusEvent:FireAllClients("TEAM_"..teamWinner.."_WON_HAND", handValue)
	Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
	task.wait(3)
	GameManager.ResetOrNext()
end

-- Substitua a função ResetOrNext antiga por esta:
function GameManager.ResetOrNext()
	-- Verifica se alguém atingiu 12 ou mais pontos
	if scores.TeamA >= 12 or scores.TeamB >= 12 then
		
		-- Descobre qual time ganhou
		local winningTeam = (scores.TeamA >= 12) and "A" or "B"
		
		-- Coleta os nomes dos vencedores
		local winnerNames = {}
		local _, seated = SeatManager.GetSeatedPlayers()
		
		for _, p in pairs(seated) do
			if getTeamOfPlayer(p) == winningTeam then
				table.insert(winnerNames, p.Name)
			end
		end
		
		-- Garante que tem nome (caso esteja testando sozinho)
		local p1 = winnerNames[1] or "Fantasma"
		local p2 = winnerNames[2] or "Ninguém"
		
		-- Monta a frase da vitória
		local victoryMessage = p1 .. " e " .. p2 .. " Ganharam a Partida!!!"
		
		-- Envia para todos os clientes
		Events.GameStatusEvent:FireAllClients("MATCH_WON", victoryMessage)
		
		-- Espera 10 segundos de celebração antes de resetar tudo
		task.wait(10)
		
		-- Reseta o jogo
		GameManager.SetState(GameConfig.States.WAITING)
		local _, players = SeatManager.GetSeatedPlayers()
		for _, player in pairs(players) do
			Events.GameStatusEvent:FireClient(player, "HIDE_GAME_UI")
			Events.GameStatusEvent:FireClient(player, "HIDE_SCOREBOARD")
			SeatManager.SetJumpLock(player, false)
		end
		scores.TeamA = 0
		scores.TeamB = 0
	else
		-- Segue o jogo normal
		dealerIndex = (dealerIndex - 2) % 4 + 1
		GameManager.StartNewRound()
	end
end

function GameManager.NotifySeatedPlayers(msg, val)
	local _, p = SeatManager.GetSeatedPlayers()
	for _, player in pairs(p) do
		Events.GameStatusEvent:FireClient(player, msg, val)
	end
end

-- --- SISTEMA DE TRUCO (VOTAÇÃO + TIMER) ---

function GameManager.StartTrucoTimer(challengeId, targetTeam)
	task.delay(15, function()
		if trucoState.challengeId == challengeId and trucoState.waitingResponse then
			print("Tempo esgotado! Vencedor por WO.")
			trucoState.waitingResponse = false
			
			-- Se o tempo acabar, quem ganha é quem pediu (o valor ANTERIOR ao pedido, pois não foi aceito)
			-- Na verdade, regra de Truco: se estourar o tempo, é como se corresse.
			local winnerTeam = (targetTeam == "A") and "B" or "A"
			-- Ganha o valor que estava valendo ANTES do pedido atual
			handValue = trucoState.currentValue 
			
			Events.GameStatusEvent:FireAllClients("TRUCO_TIMEOUT", 0)
			GameManager.WinHand(winnerTeam)
		end
	end)
end

Events.TrucoEvent.OnServerEvent:Connect(function(player, action, subAction)
	if currentState ~= GameConfig.States.PLAYING then return end
	
	local _, seatedPlayers = SeatManager.GetSeatedPlayers()
	local myTeam = getTeamOfPlayer(player)

	-- -------------------------
	-- PEDIR / AUMENTAR
	-- -------------------------
	if action == "Request" then
		-- Verifica se pode pedir
		if trucoState.waitingResponse or trucoState.callerTeam == myTeam then return end
		if trucoState.currentValue >= 12 then return end

		-- Se o valor atual for 1, o próximo é 3. Senão, soma 3.
		local nextValue = (trucoState.currentValue == 1) and 3 or (trucoState.currentValue + 3)
		
		trucoState.waitingResponse = true
		trucoState.callerTeam = myTeam
		trucoState.pendingValue = nextValue -- Valor proposto
		trucoState.votes = {}
		trucoState.challengeId = os.time()
		
		local targetTeam = (myTeam == "A") and "B" or "A"
		GameManager.StartTrucoTimer(trucoState.challengeId, targetTeam)

		Events.GameStatusEvent:FireAllClients("TRUCO_CALLED", nextValue)

		-- Mostra menu para o time rival, esconde botão de quem pediu
		for _, p in pairs(seatedPlayers) do
			local pTeam = getTeamOfPlayer(p)
			if pTeam ~= myTeam then
				Events.RequestAction:FireClient(p, "TrucoChallenge", {
					Value = nextValue, 
					Caller = player.Name,
					TimeLimit = 15
				})
			else
				Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
			end
		end

	-- -------------------------
	-- RESPONDER (Aceitar/Correr/Aumentar)
	-- -------------------------
	elseif action == "Response" then
		if not trucoState.waitingResponse then return end
		
		trucoState.votes[player] = subAction
		local partner = getPartner(player)
		
		if partner then
			Events.GameStatusEvent:FireClient(partner, "PARTNER_VOTED", subAction)
		end
		
		local partnerVote = partner and trucoState.votes[partner]
		
		-- Se os dois votaram igual (ou se estiver jogando 1x1 e o partner for nil, entra aqui tbm)
		if partnerVote == subAction or partner == nil then
			trucoState.waitingResponse = false
			trucoState.votes = {}
			
			if subAction == "Aceitar" then
				-- Confirma o novo valor
				trucoState.currentValue = trucoState.pendingValue
				handValue = trucoState.currentValue
				trucoState.callerTeam = nil
				
				Events.GameStatusEvent:FireAllClients("TRUCO_ACEITO", handValue)
				Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", handValue)
				
				-- ATUALIZA A VEZ DA JOGADA (Visual)
				local currentPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
				Events.UpdateTurnEvent:FireAllClients(currentPlayerName, getCurrentTrickNumber())

				-- CORREÇÃO CRUCIAL: TROCA DE PERMISSÃO
				-- O time que ACEITOU ganha o direito de pedir o próximo aumento.
				-- O time que PEDIU perde o direito.
				local acceptingTeam = getTeamOfPlayer(player)
				for _, p in pairs(seatedPlayers) do
					if getTeamOfPlayer(p) == acceptingTeam then
						Events.GameStatusEvent:FireClient(p, "SHOW_TRUCO_BTN")
					else
						Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
					end
				end

			elseif subAction == "Correr" then
				-- Se correr, perde a mão. O vencedor ganha o valor ANTERIOR ao pedido.
				local winnerTeam = (myTeam == "A") and "B" or "A"
				-- Ex: Jogo vale 1. Pediu Truco (3). Correu. Ganha 1.
				-- Ex: Jogo vale 3. Pediu Seis (6). Correu. Ganha 3.
				handValue = trucoState.currentValue 
				GameManager.WinHand(winnerTeam)

			elseif subAction == "Aumentar" then
				-- Cálculo do Repique (ex: Pediu 3 -> Responde 6)
				-- O valor proposto atual é trucoState.pendingValue
				local nextRaise = trucoState.pendingValue + 3
				if nextRaise > 12 then return end

				-- Aumenta a aposta na pilha
				-- Nota: Não atualizamos 'currentValue' ainda, só quando aceitarem.
				trucoState.pendingValue = nextRaise
				
				trucoState.callerTeam = myTeam -- Agora quem pede é quem respondeu
				trucoState.waitingResponse = true
				trucoState.votes = {}
				trucoState.challengeId = os.time()
				
				local newTargetTeam = (myTeam == "A") and "B" or "A"
				GameManager.StartTrucoTimer(trucoState.challengeId, newTargetTeam)

				Events.GameStatusEvent:FireAllClients("TRUCO_CALLED", nextRaise)

				for _, p in pairs(seatedPlayers) do
					local pTeam = getTeamOfPlayer(p)
					if pTeam ~= myTeam then
						Events.RequestAction:FireClient(p, "TrucoChallenge", {
							Value = nextRaise,
							Caller = player.Name,
							TimeLimit = 15
						})
					else
						Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
					end
				end
			end
		else
			 -- Aguardando o parceiro votar
			 Events.GameStatusEvent:FireClient(player, "WAITING_PARTNER", 0)
		end
	end
end)

return GameManager
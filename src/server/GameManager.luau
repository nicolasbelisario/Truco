local trucoState = {
    currentValue = 1,     -- Valor atual (1, 3, 6, 9, 12)
    callerTeam = nil,      -- Qual time pediu por último ("A" ou "B")
    waitingResponse = false
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local DeckManager = require(script.Parent:WaitForChild("DeckManager"))
local RuleManager = require(script.Parent:WaitForChild("RuleManager"))

local GameManager = {}
local currentState = GameConfig.States.WAITING
local dealerIndex = 1 
local currentTurnIndex = 1
local currentVira = nil

-- Placar da Partida e Rodadas
local scores = { TeamA = 0, TeamB = 0 }
local tricksWon = { TeamA = 0, TeamB = 0 } -- Quedas na mão atual (máximo 3)
local cardsInTable = {} -- Cartas jogadas na queda atual
local handValue = 1 -- Valor da mão (sobe se houver Truco)

-- Função Auxiliar para pegar o time do jogador
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

function GameManager.GetState() 
    return currentState 
end

local function getPartnerName(player)
    local _, seated = SeatManager.GetSeatedPlayers()
    local mySeatNum = 0
    for name, p in pairs(seated) do
        if p == player then mySeatNum = tonumber(name:match("%d+")) break end
    end
    
    local partnerSeat = (mySeatNum <= 2) and (mySeatNum + 2) or (mySeatNum - 2)
    local partner = seated["Cadeira"..partnerSeat]
    return partner and partner.Name or "Ninguém"
end

function GameManager.SetState(newState)
    currentState = newState
    Events.GameStatusEvent:FireAllClients(newState, 0)
end

local function getPlayerNameBySeat(seatName)
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    local player = seatedPlayers[seatName]
    return player and player.Name or seatName
end

function GameManager.GetRoles()
    local cutIndex = (dealerIndex % 4) + 1
    local handIndex = ((dealerIndex - 2 + 4) % 4) + 1 
    return {
        Dealer = "Cadeira" .. dealerIndex,
        Corte = "Cadeira" .. cutIndex,
        Mao = "Cadeira" .. handIndex
    }
end

function GameManager.StartCountdown()
    if currentState ~= GameConfig.States.WAITING then return end
    GameManager.SetState(GameConfig.States.COUNTDOWN)
    
    for i = GameConfig.COUNTDOWN_TIME, 0, -1 do
        local count, _ = SeatManager.GetSeatedPlayers()
        if count < GameConfig.MAX_PLAYERS then
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
    end

    GameManager.StartNewRound()
end

function GameManager.StartNewRound()
    trucoState.waitingResponse = false
    trucoState.callerTeam = nil
    trucoState.currentValue = 1

    tricksWon.TeamA = 0
    tricksWon.TeamB = 0
    cardsInTable = {}
    handValue = 1

    trucoState.currentValue = 1
    trucoState.callerTeam = nil
    trucoState.waitingResponse = false
    Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", 1)

    DeckManager.CreateDeck()
    DeckManager.Shuffle()

    GameManager.SetState(GameConfig.States.CUTTING)

    local roles = GameManager.GetRoles()
    local _, players = SeatManager.GetSeatedPlayers()
    local cortePlayer = players[roles.Corte]

    if cortePlayer then
        Events.RequestAction:FireClient(cortePlayer, "EscolhaOCorte", GameConfig.CUT_TIME_LIMIT)
        task.delay(GameConfig.CUT_TIME_LIMIT, function()
            if currentState == GameConfig.States.CUTTING then
                GameManager.DistributeCards()
            end
        end)
    else
        GameManager.DistributeCards()
    end
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
    if not deck or #deck < 13 then
        warn("[DistributeCards] Deck inválido ou insuficiente")
        return
    end

    currentVira = table.remove(deck, 1)

    local _, players = SeatManager.GetSeatedPlayers()

    for _, player in pairs(players) do
        local mao = {
            table.remove(deck, 1),
            table.remove(deck, 1),
            table.remove(deck, 1)
        }

        Events.DealCards:FireClient(
            player,
            mao,
            currentVira,
            getPartnerName(player)
        )

        Events.GameStatusEvent:FireClient(player, "SHOW_GAME_UI")
    end

    task.wait(1)

    GameManager.SetState(GameConfig.States.PLAYING)

    local roles = GameManager.GetRoles()
    currentTurnIndex = tonumber(string.match(roles.Mao, "%d+"))

    local playerName = getPlayerNameBySeat(roles.Mao)
    Events.UpdateTurnEvent:FireAllClients(playerName)
end


Events.PlayCardEvent.OnServerEvent:Connect(function(player, value, suit)
    if currentState ~= GameConfig.States.PLAYING then return end
    
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    if seatedPlayers["Cadeira" .. currentTurnIndex] ~= player then return end

    table.insert(cardsInTable, {Player = player, Value = value, Suit = suit})
    Events.CardPlayedOnTable:FireAllClients(player.Name, value, suit)
    
    if #cardsInTable == 4 then
        task.wait(1.5)
        GameManager.EvaluateTrick()
    else
        currentTurnIndex = (currentTurnIndex % 4) + 1
        local nextPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
        Events.UpdateTurnEvent:FireAllClients(nextPlayerName)
    end
end)

function GameManager.EvaluateTrick()
    local result = RuleManager.DetermineWinner(cardsInTable, currentVira.Value)
    
    if result == "CANGALHOU" then
        print("Empate na queda!")
    else
        if result == 1 or result == 3 then
            tricksWon.TeamA += 1
        else
            tricksWon.TeamB += 1
        end
        currentTurnIndex = result
    end
    
    cardsInTable = {}

    if tricksWon.TeamA >= 2 then
        scores.TeamA += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_A_WON_HAND", handValue)
        Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
        task.wait(2)
        GameManager.ResetOrNext()
    elseif tricksWon.TeamB >= 2 then
        scores.TeamB += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_B_WON_HAND", handValue)
        Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
        task.wait(2)
        GameManager.ResetOrNext()
    else
        Events.GameStatusEvent:FireAllClients("CLEAR_TABLE", {
            TeamA = tricksWon.TeamA, 
            TeamB = tricksWon.TeamB
        })
        task.wait(1)
        local nextPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
        Events.UpdateTurnEvent:FireAllClients(nextPlayerName)
    end
end

function GameManager.ResetOrNext()
    if scores.TeamA >= 12 or scores.TeamB >= 12 then
        GameManager.SetState(GameConfig.States.WAITING)
        local _, players = SeatManager.GetSeatedPlayers()
        for _, player in pairs(players) do
            Events.GameStatusEvent:FireClient(player, "HIDE_GAME_UI")
        end
        scores.TeamA = 0
        scores.TeamB = 0
    else
        dealerIndex = (dealerIndex % 4) + 1
        task.wait(3)
        GameManager.StartNewRound()
    end
end

function GameManager.NotifySeatedPlayers(msg, val)
    local _, p = SeatManager.GetSeatedPlayers()
    for _, player in pairs(p) do
        Events.GameStatusEvent:FireClient(player, msg, val)
    end
end

Events.TrucoEvent.OnServerEvent:Connect(function(player, action, subAction)
    if currentState ~= GameConfig.States.PLAYING then return end
    
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    local myTeam = getTeamOfPlayer(player)

    if action == "Request" then
        if trucoState.waitingResponse or trucoState.callerTeam == myTeam then return end
        if trucoState.currentValue >= 12 then return end

        local nextValue = 3
        if trucoState.currentValue == 1 then nextValue = 3
        elseif trucoState.currentValue == 3 then nextValue = 6
        elseif trucoState.currentValue == 6 then nextValue = 9
        elseif trucoState.currentValue == 9 then nextValue = 12
        end

        trucoState.waitingResponse = true
        trucoState.callerTeam = myTeam 
        
        for _, p in pairs(seatedPlayers) do
            local pTeam = getTeamOfPlayer(p)
            if pTeam ~= myTeam then
                local increaseValue = (nextValue < 12) and (nextValue + 3) or nil
                Events.RequestAction:FireClient(p, "TrucoChallenge", {
                    Value = nextValue, 
                    NextRaise = increaseValue, 
                    Caller = player.Name
                })
            else
                Events.GameStatusEvent:FireClient(p, "Seu time pediu " .. nextValue .. "!")
                Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
            end
        end

    elseif action == "Response" then
        if not trucoState.waitingResponse then return end
        
        if subAction == "Aceitar" then
            if trucoState.currentValue == 1 then 
                trucoState.currentValue = 3
            else 
                trucoState.currentValue = trucoState.currentValue + 3 
            end
            
            handValue = trucoState.currentValue
            trucoState.waitingResponse = false
            
            Events.GameStatusEvent:FireAllClients("TRUCO_ACEITO", handValue)
            
            task.delay(1.5, function()
                local currentPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
                Events.UpdateTurnEvent:FireAllClients(currentPlayerName)
                Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", handValue)
            end)

        elseif subAction == "Correr" then
            local winnerTeam = (myTeam == "A") and "B" or "A"
            trucoState.waitingResponse = false
            GameManager.ForceWinHand(winnerTeam)

        elseif subAction == "Aumentar" then
            -- Define próximo valor
            local nextValue
            if trucoState.currentValue == 1 then nextValue = 3
            elseif trucoState.currentValue == 3 then nextValue = 6
            elseif trucoState.currentValue == 6 then nextValue = 9
            elseif trucoState.currentValue == 9 then nextValue = 12
            end

            trucoState.currentValue = nextValue
            trucoState.callerTeam = myTeam
            trucoState.waitingResponse = true
            handValue = nextValue

            -- Envia desafio para o OUTRO time
            for _, p in pairs(seatedPlayers) do
                local pTeam = getTeamOfPlayer(p)
                if pTeam ~= myTeam then
                    Events.RequestAction:FireClient(p, "TrucoChallenge", {
                        Value = nextValue,
                        Caller = player.Name
                    })
                else
                    Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
                end
            end

            Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", nextValue)
        end
    end
end)

function GameManager.ForceWinHand(team)
    if team == "A" then scores.TeamA += handValue else scores.TeamB += handValue end
    Events.GameStatusEvent:FireAllClients("TEAM_"..team.."_WON_HAND", handValue)
    Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
    task.wait(2)
    GameManager.ResetOrNext()
end

function GameManager.RequestTruco(player)
    if trucoState.waitingResponse then
        return -- já tem pedido pendente
    end

    local team = SeatManager.GetPlayerTeam(player)
    local nextValue = GameManager.GetNextTrucoValue()

    trucoState.waitingResponse = true
    trucoState.callerTeam = team
    trucoState.currentValue = nextValue

    local targetTeam = getOppositeTeam(team)
    local targetPlayers = SeatManager.GetPlayersByTeam(targetTeam)

    for _, p in pairs(targetPlayers) do
        Events.ShowTrucoChallenge:FireClient(p, nextValue, player.Name)
    end
end

function GameManager.AcceptTruco(player)
    if not trucoState.waitingResponse then return end

    trucoState.waitingResponse = false
    trucoState.callerTeam = nil

    handValue = trucoState.currentValue

    Events.GameStatusEvent:FireAllClients(
        "UPDATE_ROUND_VALUE",
        handValue
    )
end

function GameManager.RunFromTruco(player)
    if not trucoState.waitingResponse then return end

    local losingTeam = SeatManager.GetPlayerTeam(player)
    local winningTeam = getOppositeTeam(losingTeam)

    GameManager.EndHand(winningTeam)

    trucoState.waitingResponse = false
    trucoState.callerTeam = nil
end

function GameManager.RequestRaise(player)
    if not trucoState.waitingResponse then return end

    local team = SeatManager.GetPlayerTeam(player)

    if team ~= getOppositeTeam(trucoState.callerTeam) then
        return -- só quem recebeu pode aumentar
    end

    trucoState.waitingResponse = false
    GameManager.RequestTruco(player)
end

function GameManager.EndHand(winningTeam)
    trucoState.waitingResponse = false
    trucoState.callerTeam = nil
    trucoState.currentValue = 1

    ScoreManager.AddPoint(winningTeam, handValue)

    GameManager.StartNewRound()
end


return GameManager
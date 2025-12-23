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

function GameManager.GetState() 
    return currentState 
end

local function getPartnerName(player)
    local _, seated = SeatManager.GetSeatedPlayers()
    local mySeatNum = 0
    for name, p in pairs(seated) do
        if p == player then mySeatNum = tonumber(name:match("%d+")) break end
    end
    
    -- Duplas: 1-3 e 2-4
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

-- Determina quem é o Dealer, quem Corta e quem é o Mão
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
    end

    GameManager.StartNewRound()
end

function GameManager.StartNewRound()
    tricksWon.TeamA = 0
    tricksWon.TeamB = 0
    cardsInTable = {}
    handValue = 1
    
    GameManager.SetState(GameConfig.States.SHUFFLING)
    task.wait(2)

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
    
    DeckManager.CreateDeck()
    DeckManager.Shuffle()
    
    local deck = DeckManager.GetCurrentDeck()
    currentVira = table.remove(deck, 1)
    local _, players = SeatManager.GetSeatedPlayers()
    
    for seatName, player in pairs(players) do
        local mao = {
            table.remove(deck, 1), 
            table.remove(deck, 1), 
            table.remove(deck, 1)
        }
        local partner = getPartnerName(player)
        Events.DealCards:FireClient(player, mao, currentVira, partner)
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
        -- O vencedor da queda anterior começa a próxima
        if result == 1 or result == 3 then
            tricksWon.TeamA += 1
        else
            tricksWon.TeamB += 1
        end
        currentTurnIndex = result
    end
    
    cardsInTable = {}

    -- VERIFICAÇÃO DE VITÓRIA DA MÃO
    if tricksWon.TeamA >= 2 then
        scores.TeamA += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_A_WON_HAND", handValue)
        task.wait(2)
        GameManager.ResetOrNext()
    elseif tricksWon.TeamB >= 2 then
        scores.TeamB += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_B_WON_HAND", handValue)
        task.wait(2)
        GameManager.ResetOrNext()
    else
        -- Continua a próxima queda
        local nextPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
        Events.UpdateTurnEvent:FireAllClients(nextPlayerName)
    end

    -- Envia o placar de quedas atualizado para limpar a mesa visual
    Events.GameStatusEvent:FireAllClients("CLEAR_TABLE", {
        TeamA = tricksWon.TeamA, 
        TeamB = tricksWon.TeamB
    })
end

function GameManager.ResetOrNext()
    print("Placar: A=" .. scores.TeamA .. " | B=" .. scores.TeamB)
    
    if scores.TeamA >= 12 or scores.TeamB >= 12 then
        GameManager.SetState(GameConfig.States.WAITING)
        -- Aqui você daria as recompensas em dinheiro/pontos
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

return GameManager

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local Events = ReplicatedStorage:WaitForChild("Events")
-- local GameConfig = require(Shared:WaitForChild("GameConfig"))
-- local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
-- local DeckManager = require(script.Parent:WaitForChild("DeckManager"))
-- local RuleManager = require(script.Parent:WaitForChild("RuleManager"))

-- local GameManager = {}
-- local currentState = GameConfig.States.WAITING
-- local dealerIndex = 1 
-- local currentTurnIndex = 1 

-- local teamPoints = { TeamA = 0, TeamB = 0 }
-- local roundWins = { TeamA = 0, TeamB = 0 }
-- local cardsPlayedThisRound = {}

-- function GameManager.GetState() return currentState end

-- function GameManager.SetState(newState)
--     currentState = newState
--     Events.GameStatusEvent:FireAllClients(newState, 0)
-- end

-- function GameManager.StartCountdown()
--     if currentState ~= GameConfig.States.WAITING then return end
--     GameManager.SetState(GameConfig.States.COUNTDOWN)
--     for i = GameConfig.COUNTDOWN_TIME, 0, -1 do
--         local count, _ = SeatManager.GetSeatedPlayers()
--         if count < GameConfig.MAX_PLAYERS then
--             GameManager.SetState(GameConfig.States.WAITING)
--             GameManager.NotifySeatedPlayers("Contagem Cancelada", 0)
--             return
--         end
--         GameManager.NotifySeatedPlayers("COUNTDOWN", i)
--         task.wait(1)
--     end
--     GameManager.BeginGame()
-- end

-- function GameManager.BeginGame()
--     GameManager.SetState(GameConfig.States.SHUFFLING)
--     local _, players = SeatManager.GetSeatedPlayers()
--     for _, player in pairs(players) do SeatManager.SetJumpLock(player, true) end
--     GameManager.SelectInitialDealer()
--     GameManager.StartShuffling()
-- end

-- function GameManager.SelectInitialDealer()
--     dealerIndex = math.random(1, 4)
-- end

-- function GameManager.GetRoles()
--     local cutIndex = (dealerIndex % 4) + 1
--     local handIndex = ((dealerIndex - 2 + 4) % 4) + 1 
--     return {
--         Dealer = "Cadeira" .. dealerIndex,
--         Corte = "Cadeira" .. cutIndex,
--         Mao = "Cadeira" .. handIndex
--     }
-- end

-- function GameManager.StartShuffling()
--     GameManager.NotifySeatedPlayers("SHUFFLING", 0)
--     task.wait(2)
--     GameManager.SetState(GameConfig.States.CUTTING)
--     local roles = GameManager.GetRoles()
--     local _, players = SeatManager.GetSeatedPlayers()
--     local cortePlayer = players[roles.Corte]
--     if cortePlayer then
--         Events.RequestAction:FireClient(cortePlayer, "EscolhaOCorte", GameConfig.CUT_TIME_LIMIT)
--         task.delay(GameConfig.CUT_TIME_LIMIT, function()
--             if currentState == GameConfig.States.CUTTING then GameManager.DistributeCards() end
--         end)
--     else
--         GameManager.DistributeCards()
--     end
-- end

-- function GameManager.DistributeCards()
--     if currentState == GameConfig.States.DEALING then return end
--     GameManager.SetState(GameConfig.States.DEALING)
    
--     DeckManager.CreateDeck()
--     DeckManager.Shuffle()
--     local deck = DeckManager.GetCurrentDeck()
--     local vira = table.remove(deck, 1)
--     local _, players = SeatManager.GetSeatedPlayers()
    
--     for _, player in pairs(players) do
--         local mao = {table.remove(deck, 1), table.remove(deck, 1), table.remove(deck, 1)}
--         Events.DealCards:FireClient(player, mao, vira)
--     end
    
--     task.wait(1)
--     GameManager.SetState(GameConfig.States.PLAYING)
    
--     local roles = GameManager.GetRoles()
--     local handSeat = roles.Mao 
--     currentTurnIndex = tonumber(string.match(handSeat, "%d+"))
--     Events.UpdateTurnEvent:FireAllClients(handSeat)
-- end

-- Events.PlayCardEvent.OnServerEvent:Connect(function(player, cardValue, cardSuit)
--     if currentState ~= GameConfig.States.PLAYING then return end
--     local _, seatedPlayers = SeatManager.GetSeatedPlayers()
--     local seatName = "Cadeira" .. currentTurnIndex
    
--     if player == seatedPlayers[seatName] then
--         GameManager.SpawnCardOnTable(player, cardValue, cardSuit)
--         Events.CardPlayedOnTable:FireAllClients(player.Name, cardValue, cardSuit)
        
--         currentTurnIndex = (currentTurnIndex % 4) + 1
--         Events.UpdateTurnEvent:FireAllClients("Cadeira" .. currentTurnIndex)
--     end
-- end)

-- function GameManager.SpawnCardOnTable(player, value, suit)
--     local mesa = workspace.MesaTruco:FindFirstChild("CartasNaMesa")
--     local cardPart = Instance.new("Part")
--     cardPart.Size = Vector3.new(1.2, 0.1, 1.8)
--     cardPart.Parent = mesa
--     cardPart.CFrame = player.Character.PrimaryPart.CFrame * CFrame.new(0, -1, -3)
--     cardPart.Position = Vector3.new(cardPart.Position.X, 4.5, cardPart.Position.Z)
--     local gui = Instance.new("SurfaceGui", cardPart)
--     gui.Face = Enum.NormalId.Top
--     local label = Instance.new("TextLabel", gui)
--     label.Size = UDim2.new(1, 0, 1, 0)
--     label.Text = value .. "\n" .. suit
--     label.TextSize = 30
-- end

-- function GameManager.NotifySeatedPlayers(message, value)
--     local _, players = SeatManager.GetSeatedPlayers()
--     for _, player in pairs(players) do
--         Events.GameStatusEvent:FireClient(player, message, value)
--     end
-- end

-- function GameManager.EvaluateRound()
--     local winner = RuleManager.DetermineWinner(cardsPlayedThisRound, currentVira)
    
--     -- Lógica simplificada de atribuição:
--     -- Se winner for 1 ou 3 -> TeamA ganhou a queda
--     -- Se winner for 2 ou 4 -> TeamB ganhou a queda
    
--     -- Se um time chegar a 2 quedas vencidas:
--     -- teamPoints[vencedor] += valorDoTruco (1, 3, 6, 9 ou 12)
--     -- Resetar roundWins
    
--     if teamPoints.TeamA >= 12 or teamPoints.TeamB >= 12 then
--         print("FIM DE JOGO!")
--         -- Aqui você chamaria o sistema de recompensas/moedas
--     end
-- end

-- return GameManager
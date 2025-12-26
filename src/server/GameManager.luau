local trucoState = {
    currentValue = 1,
    callerTeam = nil,
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
        Events.GameStatusEvent:FireClient(player, "SHOW_SCOREBOARD")
    end

    GameManager.StartNewRound()
end

function GameManager.StartNewRound()
    tricksWon.TeamA = 0
    tricksWon.TeamB = 0
    cardsInTable = {}
    handValue = 1
    
    trucoState.currentValue = 1
    trucoState.callerTeam = nil
    trucoState.waitingResponse = false
    -- Opcional: Avisar a UI para voltar a exibir "VALE: 1"
    Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", 1)

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
        if result == 1 or result == 3 then
            tricksWon.TeamA += 1
        else
            tricksWon.TeamB += 1
        end
        currentTurnIndex = result
    end
    
    cardsInTable = {} -- Limpa os dados do servidor imediatamente

    if tricksWon.TeamA >= 2 then
        scores.TeamA += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_A_WON_HAND", handValue)
        -- ADICIONE ESTA LINHA: Atualiza o placar global (0x0)
        Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
        task.wait(2)
        GameManager.ResetOrNext()
    elseif tricksWon.TeamB >= 2 then
        scores.TeamB += handValue
        Events.GameStatusEvent:FireAllClients("TEAM_B_WON_HAND", handValue)
        -- ADICIONE ESTA LINHA: Atualiza o placar global (0x0)
        Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
        task.wait(2)
        GameManager.ResetOrNext()
    else
        -- Se a mão não acabou, apenas limpa a mesa visual dos jogadores
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
    print("Placar: A=" .. scores.TeamA .. " | B=" .. scores.TeamB)
    
    if scores.TeamA >= 12 or scores.TeamB >= 12 then
        GameManager.SetState(GameConfig.States.WAITING)
        -- Avisa todos para esconderem a UI de jogo
        local _, players = SeatManager.GetSeatedPlayers()
        for _, player in pairs(players) do
            Events.GameStatusEvent:FireClient(player, "HIDE_GAME_UI")
        end
        
        -- Reset dos pontos para a próxima partida
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
    local playerSeatNum = 0
    for name, p in pairs(seatedPlayers) do
        if p == player then playerSeatNum = tonumber(name:match("%d+")) break end
    end
    local myTeam = (playerSeatNum % 2 == 1) and "A" or "B"

    if action == "Request" then
        -- Não pode pedir truco se já houver um pedido pendente ou se for do mesmo time
        if trucoState.waitingResponse or trucoState.callerTeam == myTeam then return end
        if trucoState.currentValue >= 12 then return end

        local nextValue = trucoState.currentValue == 1 and 3 or trucoState.currentValue + 3
        trucoState.waitingResponse = true
        trucoState.callerTeam = myTeam
        
        -- Notifica os oponentes que eles precisam decidir
        for _, p in pairs(seatedPlayers) do
            local pSeat = 0
            for name, ps in pairs(seatedPlayers) do if ps == p then pSeat = tonumber(name:match("%d+")) end end
            local pTeam = (pSeat % 2 == 1) and "A" or "B"
            
            if pTeam ~= myTeam then
                Events.RequestAction:FireClient(p, "TrucoChallenge", {Value = nextValue, Caller = player.Name})
            else
                Events.GameStatusEvent:FireClient(p, "Você pediu " .. nextValue .. "!")
            end
        end

    elseif action == "Response" then
        if not trucoState.waitingResponse then return end
        
        if subAction == "Aceitar" then
            -- 1. Atualiza os valores lógicos
            trucoState.currentValue = (trucoState.currentValue == 1) and 3 or (trucoState.currentValue + 3)
            handValue = trucoState.currentValue
            trucoState.waitingResponse = false
            
            -- 2. Notifica todos que foi aceito (isso muda o texto central temporariamente)
            Events.GameStatusEvent:FireAllClients("TRUCO_ACEITO", handValue)
            
            -- 3. LOGICA NOVA: Aguarda 1.5s para os jogadores lerem e então restaura a interface
            task.delay(1.5, function()
                -- Recupera o nome de quem é a vez agora (currentTurnIndex deve ser global no GameManager)
                local currentPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
                
                -- Faz o texto central voltar a dizer "Vez de: [Nome]"
                Events.UpdateTurnEvent:FireAllClients(currentPlayerName)
                
                -- Atualiza o novo display de valor fixo (ex: "VALE: 3")
                Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", handValue)
            end)
            
        elseif subAction == "Correr" then
            -- Time que correu perde a mão. O time que pediu ganha o valor ATUAL da mão
            local winnerTeam = (myTeam == "A") and "B" or "A"
            trucoState.waitingResponse = false
            GameManager.ForceWinHand(winnerTeam)
            
        elseif subAction == "Aumentar" then
            -- Lógica recursiva: quem recebeu o truco agora pede o próximo nível
            trucoState.waitingResponse = false -- Reseta para permitir o novo pedido
            -- Simula um novo pedido vindo deste jogador para o próximo nível
            -- (Necessário ajustar a lógica para o próximo nível ser 6, 9, 12)
        end
    end
end)

function GameManager.ForceWinHand(team)
    if team == "A" then scores.TeamA += handValue else scores.TeamB += handValue end
    
    -- Notifica vitória da mão e ATUALIZA O PLACAR GLOBAL
    Events.GameStatusEvent:FireAllClients("TEAM_"..team.."_WON_HAND", handValue)
    Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
    
    task.wait(2)
    GameManager.ResetOrNext()
end

return GameManager
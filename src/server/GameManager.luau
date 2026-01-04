local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeatManager = require(script.Parent:WaitForChild("SeatManager"))
local DeckManager = require(script.Parent:WaitForChild("DeckManager"))
local RuleManager = require(script.Parent:WaitForChild("RuleManager"))

local GameManager = {}

-- Estado Global da Partida
local trucoState = {
    currentValue = 1,
    callerTeam = nil,
    waitingResponse = false
}

local currentState = GameConfig.States.WAITING
local dealerIndex = 1 
local currentTurnIndex = 1
local currentVira = nil

-- Placar
local scores = { TeamA = 0, TeamB = 0 }
local tricksWon = { TeamA = 0, TeamB = 0 } -- Quedas na mão atual
local cardsInTable = {} -- Cartas na mesa
local handValue = 1

-- --- UTILITÁRIOS ---

-- Retorna "A" ou "B" baseado no jogador
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

local function getOppositeTeam(team)
    return team == "A" and "B" or "A"
end

local function getPlayerNameBySeat(seatName)
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    local player = seatedPlayers[seatName]
    return player and player.Name or seatName
end

-- Retorna o nome do parceiro (Assento oposto)
local function getPartnerName(player)
    local _, seated = SeatManager.GetSeatedPlayers()
    local mySeatNum = 0
    for name, p in pairs(seated) do
        if p == player then mySeatNum = tonumber(name:match("%d+")) break end
    end
    
    local partnerSeatNum = (mySeatNum <= 2) and (mySeatNum + 2) or (mySeatNum - 2)
    local partner = seated["Cadeira"..partnerSeatNum]
    return partner and partner.Name or "Ninguém"
end

-- --- CICLO DE VIDA DO JOGO ---

function GameManager.GetState() return currentState end

function GameManager.SetState(newState)
    currentState = newState
    Events.GameStatusEvent:FireAllClients(newState, 0)
end

-- Define quem dá as cartas, quem corta e quem começa (sentido anti-horário)
-- Dealer -> (Corte = Dealer + 1) -> (Mão/Start = Dealer + 1) no Anti-Horário?
-- Padrão: Mão é a direita do Dealer (sentido anti-horário)
function GameManager.GetRoles()
    -- Sentido Anti-Horário: 1 <- 2 <- 3 <- 4
    -- Se Dealer é 1, Mão é 4. Corte é 2 (quem está a esquerda corta, quem está a direita joga)
    
    local cutIndex = (dealerIndex % 4) + 1         -- Vizinho da Esquerda (Sentido horário) corta
    local handIndex = (dealerIndex - 2) % 4 + 1    -- Vizinho da Direita (Sentido anti-horário) começa
    
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
    dealerIndex = math.random(1, 4) -- Primeiro dealer aleatório

    local _, players = SeatManager.GetSeatedPlayers()
    for _, player in pairs(players) do
        SeatManager.SetJumpLock(player, true)
        Events.GameStatusEvent:FireClient(player, "SHOW_SCOREBOARD")
    end

    GameManager.StartNewRound()
end

function GameManager.StartNewRound()
    -- Reset de variáveis da mão
    trucoState.waitingResponse = false
    trucoState.callerTeam = nil
    trucoState.currentValue = 1
    tricksWon.TeamA = 0
    tricksWon.TeamB = 0
    cardsInTable = {}
    handValue = 1

    Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", 1)

    DeckManager.CreateDeck()
    DeckManager.Shuffle()

    GameManager.SetState(GameConfig.States.CUTTING)

    local roles = GameManager.GetRoles()
    local _, players = SeatManager.GetSeatedPlayers()
    local cortePlayer = players[roles.Corte]

    -- Solicita corte ou pula se jogador não estiver (fallback)
    if cortePlayer then
        Events.RequestAction:FireClient(cortePlayer, "EscolhaOCorte", GameConfig.CUT_TIME_LIMIT)
        
        -- Timeout de segurança
        task.delay(GameConfig.CUT_TIME_LIMIT + 1, function()
            if currentState == GameConfig.States.CUTTING then
                GameManager.DistributeCards()
            end
        end)
    else
        GameManager.DistributeCards()
    end
end

-- Recebe ação de corte
Events.GameStatusEvent.OnServerEvent:Connect(function(player, action, value)
    if action == "CutAction" and currentState == GameConfig.States.CUTTING then
        DeckManager.Cut(value)
        GameManager.DistributeCards()
    end
end)

function GameManager.DistributeCards()
    GameManager.SetState(GameConfig.States.DEALING)

    local deck = DeckManager.GetCurrentDeck()
    if not deck or #deck < 13 then return end

    currentVira = table.remove(deck, 1)
    local _, players = SeatManager.GetSeatedPlayers()

    for _, player in pairs(players) do
        local mao = { table.remove(deck, 1), table.remove(deck, 1), table.remove(deck, 1) }
        Events.DealCards:FireClient(player, mao, currentVira, getPartnerName(player))
        Events.GameStatusEvent:FireClient(player, "SHOW_GAME_UI")
    end

    task.wait(1)
    GameManager.SetState(GameConfig.States.PLAYING)

    local roles = GameManager.GetRoles()
    currentTurnIndex = tonumber(string.match(roles.Mao, "%d+"))

    local playerName = getPlayerNameBySeat(roles.Mao)
    Events.UpdateTurnEvent:FireAllClients(playerName)
end

-- --- LÓGICA DE JOGO ---

Events.PlayCardEvent.OnServerEvent:Connect(function(player, value, suit)
    if currentState ~= GameConfig.States.PLAYING then return end
    
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    if seatedPlayers["Cadeira" .. currentTurnIndex] ~= player then return end -- Não é a vez dele

    table.insert(cardsInTable, {Player = player, Value = value, Suit = suit})
    Events.CardPlayedOnTable:FireAllClients(player.Name, value, suit)
    
    if #cardsInTable == 4 then
        -- Fim da queda (todos jogaram)
        task.wait(1.5)
        GameManager.EvaluateTrick()
    else
        -- Próximo jogador (Sentido Anti-Horário)
        -- Fórmula: (Index - 2) % 4 + 1
        -- Ex: 1 -> 4, 4 -> 3, 3 -> 2, 2 -> 1
        currentTurnIndex = (currentTurnIndex - 2) % 4 + 1
        
        local nextPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
        Events.UpdateTurnEvent:FireAllClients(nextPlayerName)
    end
end)

function GameManager.EvaluateTrick()
    local resultIndex = RuleManager.DetermineWinner(cardsInTable, currentVira.Value)
    local winnerTeam = nil

    if resultIndex == "CANGALHOU" then
        print("Empate na queda!")
        -- Regra de empate (simplificada): Ninguém pontua queda, quem fez a primeira ganha, etc.
        -- Para Truco Paulista: A maior carta da próxima rodada decide, ou quem fez a primeira.
        -- Implementação básica: Quem 'tornou' (o último a empatar) começa? Ou o mão?
        -- Vou manter quem começou a queda como o próximo turno por simplicidade no código atual.
        local firstPlayer = cardsInTable[1].Player
        winnerTeam = "DRAW"
    else
        local winnerPlayer = cardsInTable[resultIndex].Player
        local _, seated = SeatManager.GetSeatedPlayers()
        
        -- Descobre a cadeira do vencedor para ele começar a próxima
        for seatName, p in pairs(seated) do
            if p == winnerPlayer then
                currentTurnIndex = tonumber(seatName:match("%d+"))
                break
            end
        end

        winnerTeam = getTeamOfPlayer(winnerPlayer)
        if winnerTeam == "A" then tricksWon.TeamA += 1 else tricksWon.TeamB += 1 end
    end
    
    cardsInTable = {} -- Limpa mesa

    -- Verificação de Vitória da Mão
    if tricksWon.TeamA >= 2 then
        GameManager.WinHand("A")
    elseif tricksWon.TeamB >= 2 then
        GameManager.WinHand("B")
    else
        -- Continua para próxima queda
        Events.GameStatusEvent:FireAllClients("CLEAR_TABLE", { TeamA = tricksWon.TeamA, TeamB = tricksWon.TeamB })
        task.wait(1)
        local nextPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
        Events.UpdateTurnEvent:FireAllClients(nextPlayerName)
    end
end

function GameManager.WinHand(teamWinner)
    if teamWinner == "A" then scores.TeamA += handValue else scores.TeamB += handValue end
    
    Events.GameStatusEvent:FireAllClients("TEAM_"..teamWinner.."_WON_HAND", handValue)
    Events.GameStatusEvent:FireAllClients("UPDATE_SCORE", scores)
    
    task.wait(3)
    GameManager.ResetOrNext()
end

function GameManager.ResetOrNext()
    if scores.TeamA >= 12 or scores.TeamB >= 12 then
        -- FIM DE JOGO
        GameManager.SetState(GameConfig.States.WAITING)
        local _, players = SeatManager.GetSeatedPlayers()
        for _, player in pairs(players) do
            Events.GameStatusEvent:FireClient(player, "HIDE_GAME_UI")
            SeatManager.SetJumpLock(player, false) -- Libera jogadores
        end
        scores.TeamA = 0
        scores.TeamB = 0
    else
        -- Próxima Mão: Dealer passa para a direita (sentido anti-horário)
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

-- --- SISTEMA DE TRUCO ---

Events.TrucoEvent.OnServerEvent:Connect(function(player, action, subAction)
    if currentState ~= GameConfig.States.PLAYING then return end
    
    local _, seatedPlayers = SeatManager.GetSeatedPlayers()
    local myTeam = getTeamOfPlayer(player)

    if action == "Request" then
        -- Validações
        if trucoState.waitingResponse or trucoState.callerTeam == myTeam then return end
        if trucoState.currentValue >= 12 then return end

        local nextValue = (trucoState.currentValue == 1) and 3 or (trucoState.currentValue + 3)
        
        trucoState.waitingResponse = true
        trucoState.callerTeam = myTeam 
        
        -- Envia desafio para o time oposto
        Events.GameStatusEvent:FireAllClients("TRUCO_CALLED", nextValue)

        for _, p in pairs(seatedPlayers) do
            local pTeam = getTeamOfPlayer(p)
            if pTeam ~= myTeam then
                -- Inimigos recebem a caixa de decisão
                Events.RequestAction:FireClient(p, "TrucoChallenge", {
                    Value = nextValue, 
                    Caller = player.Name
                })
            else
                -- Aliados apenas veem o aviso e bloqueiam seu botão
                Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
            end
        end

    elseif action == "Response" then
        if not trucoState.waitingResponse then return end
        -- O jogador que respondeu valida se é do time que está sendo desafiado? Sim, idealmente.
        
        if subAction == "Aceitar" then
            -- Atualiza valor
            trucoState.currentValue = (trucoState.currentValue == 1) and 3 or (trucoState.currentValue + 3)
            handValue = trucoState.currentValue
            trucoState.waitingResponse = false
            trucoState.callerTeam = nil -- Reseta quem pediu para permitir repique
            
            Events.GameStatusEvent:FireAllClients("TRUCO_ACEITO", handValue)
            Events.GameStatusEvent:FireAllClients("UPDATE_ROUND_VALUE", handValue)
            
            -- Retorna o turno para quem estava jogando
            local currentPlayerName = getPlayerNameBySeat("Cadeira" .. currentTurnIndex)
            Events.UpdateTurnEvent:FireAllClients(currentPlayerName)

        elseif subAction == "Correr" then
            trucoState.waitingResponse = false
            -- O time que correu perde, o outro ganha o valor ATUAL (antes do aumento)
            -- Mas no Truco, se correr do Truco (3), o adversário leva 1. Se correr do 6, leva 3.
            local pointsToWin = trucoState.currentValue 
            local winnerTeam = (myTeam == "A") and "B" or "A" -- Quem correu perdeu
            
            -- Se fugiu do aumento, o valor da mão é o valor que estava valendo
            handValue = pointsToWin
            GameManager.WinHand(winnerTeam)

        elseif subAction == "Aumentar" then
            -- Lógica de Repique (6, 9, 12)
            local proposedValue = (trucoState.currentValue == 1) and 3 or (trucoState.currentValue + 3)
            
            -- Agora queremos aumentar o proposedValue para o próximo
            local nextRaise = proposedValue + 3
            if nextRaise > 12 then return end

            trucoState.currentValue = proposedValue -- Confirma o pedido anterior implicitamente ao aumentar
            trucoState.callerTeam = myTeam -- Inverte quem está pedindo
            
            -- Notifica todos
            Events.GameStatusEvent:FireAllClients("TRUCO_CALLED", nextRaise)

            for _, p in pairs(seatedPlayers) do
                local pTeam = getTeamOfPlayer(p)
                if pTeam ~= myTeam then -- Agora o time original recebe o desafio
                    Events.RequestAction:FireClient(p, "TrucoChallenge", {
                        Value = nextRaise,
                        Caller = player.Name
                    })
                else
                    Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
                end
            end
        end
    end
end)

return GameManager
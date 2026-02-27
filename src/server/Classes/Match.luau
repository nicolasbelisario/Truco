local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")

local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CardSettings = require(Shared:WaitForChild("CardSettings"))
local DeckManager = require(script.Parent.Parent.Utils:WaitForChild("DeckManager"))
local RuleManager = require(script.Parent.Parent.Utils:WaitForChild("RuleManager"))
local Bot = require(script.Parent:WaitForChild("Bot"))
local BotDummyTemplate = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotDummy")

local Match = {}
Match.__index = Match

function Match.new(model, botSeatsList)
    local self = setmetatable({}, Match)
    self.Model = model
    self.BotSeats = botSeatsList or {} 
    self.UseBots = (#self.BotSeats > 0)
    self.State = "WAITING"
    self.Seats = {} 
    self.Scores = { TeamA = 0, TeamB = 0 }
    self.CurrentDeck = {}
    self.HandValue = 1
    self.CurrentVira = nil
    self.DealerSeatIndex = 1
    self.CurrentTurnSeatIndex = 1
    
    self.TrucoState = {
        CurrentValue = 1,
        PendingValue = 0,
        CallerTeam = nil,
        WaitingResponse = false,
        ChallengeId = 0,
        Votes = {}
    }
    
    self.CardsInTable = {}
    self.TricksWon = { TeamA = 0, TeamB = 0 }
    
    self:SetupSeats()
    if self.UseBots then self:InitializeBots() end
    return self
end

function Match:GetNextSeatIndex(currentIndex) return (currentIndex - 2) % 4 + 1 end

function Match:SetupSeats()
    local cadeirasFolder = self.Model:WaitForChild("Cadeiras")
    for _, child in ipairs(cadeirasFolder:GetChildren()) do
        local seatObject = child:FindFirstChildWhichIsA("Seat") or (child:IsA("Seat") and child)
        if seatObject then
            local seatNameId = child.Name 
            seatObject:GetPropertyChangedSignal("Occupant"):Connect(function()
                self:HandleOccupantChange(seatObject, seatNameId)
            end)
        end
    end
    task.spawn(function()
        while task.wait(1) do
            if self.State == "WAITING" and self:CountPlayers() == 4 then self:StartCountdown() end
        end
    end)
end

function Match:InitializeBots()
    local botNamesMap = {[1]="Bot 1", [2]="Bot Rival 1", [3]="Bot Parceiro", [4]="Bot Rival 2"}
    for _, seatIndex in ipairs(self.BotSeats) do
        local seatName = "Cadeira" .. seatIndex
        local displayName = botNamesMap[seatIndex] or ("Bot " .. seatIndex)
        local fakeBot = Bot.new(displayName, seatName, self)
        self.Seats[seatName] = fakeBot
        self:SpawnVisualBot(seatName, displayName)
    end
end

function Match:SpawnVisualBot(seatName, displayName)
    local seatModel = self.Model:WaitForChild("Cadeiras"):FindFirstChild(seatName)
    if not seatModel then return end
    local seatPart = seatModel:FindFirstChildWhichIsA("Seat") or seatModel
    local visualBot = BotDummyTemplate:Clone()
    visualBot.Name = displayName 
    local humanoid = visualBot:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false 
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer 
        humanoid.DisplayName = displayName
    end
    visualBot.Parent = seatModel 
    if seatPart and humanoid then
        visualBot:SetPrimaryPartCFrame(seatPart.CFrame + Vector3.new(0, 2, 0))
        seatPart:Sit(humanoid)
        task.delay(0.2, function()
            for _, part in ipairs(visualBot:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true; part.CanCollide = false end
            end
        end)
    end
end

function Match:HandleOccupantChange(seat, seatName)
    local humanoid = seat.Occupant
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
        if player then
            local seatNum = tonumber(seatName:match("%d+"))
            if self.UseBots and table.find(self.BotSeats, seatNum) then humanoid.Jump = true; return end
            self.Seats[seatName] = player
            if self.OnPlayerJoin then self.OnPlayerJoin(player) end
            self:NetworkFire(player, "SHOW_SCOREBOARD")
            self:NetworkFire(player, "UPDATE_SCORE", self.Scores)
            self:NetworkFire(player, "WAITING", 0) 
        end
    else
        local oldPlayer = self.Seats[seatName]
        if oldPlayer and typeof(oldPlayer) == "Instance" then 
            if self.OnPlayerLeave then self.OnPlayerLeave(oldPlayer) end
            self:NetworkFire(oldPlayer, "HIDE_GAME_UI")
            self.Seats[seatName] = nil
            if self.State ~= "WAITING" then self:ResetMatch("Jogador saiu!") end
        end
    end
end

function Match:SetPlayersJumpable(canJump)
    for _, player in pairs(self.Seats) do
        if not self:IsBot(player) and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum then hum.UseJumpPower = true; hum.JumpPower = canJump and 50 or 0 end
        end
    end
end

function Match:StartCountdown()
    self.State = "COUNTDOWN"
    for i = 5, 0, -1 do
        if self:CountPlayers() < 4 then self.State = "WAITING"; self:Broadcast("WAITING", 0); return end
        self:Broadcast("COUNTDOWN", i); task.wait(1)
    end
    self:BeginGame()
end

function Match:BeginGame()
    self:SetPlayersJumpable(false)
    self.Scores = {TeamA = 0, TeamB = 0}
    self.DealerSeatIndex = math.random(1, 4)
    self:StartNewRound()
end

function Match:StartNewRound()
    self.TrucoState = { CurrentValue = 1, PendingValue = 0, CallerTeam = nil, WaitingResponse = false, ChallengeId = 0, Votes = {} }
    self.TricksWon = { TeamA = 0, TeamB = 0 }
    self.CardsInTable = {}
    self.HandValue = 1
    self:Broadcast("UPDATE_ROUND_VALUE", 1)
    self:Broadcast("SHOW_TRUCO_BTN", 0)
    self.CurrentDeck = DeckManager.CreateDeck() 
    DeckManager.Shuffle(self.CurrentDeck)
    self.State = "CUTTING"
    self:Broadcast("CUTTING", 0) 
    local roles = self:GetRoles()
    local cutter = self:GetPlayerBySeat(roles.Corte)
    if self:IsBot(cutter) then task.delay(1.5, function() cutter:AutoCut() end)
    elseif cutter then Events.RequestAction:FireClient(cutter, "EscolhaOCorte", 10) end
    task.delay(11, function() if self.State == "CUTTING" then self:DistributeCards() end end)
end

function Match:PlayerCutDeck(player, amount)
    if self.State ~= "CUTTING" then return end
    local roles = self:GetRoles()
    if self:GetPlayerBySeat(roles.Corte) == player then
        DeckManager.Cut(self.CurrentDeck, amount)
        self:DistributeCards()
    end
end

function Match:DistributeCards()
    self.State = "DEALING"
    self:Broadcast("DEALING", 0)
    self.CurrentVira = table.remove(self.CurrentDeck, 1)
    for i = 1, 4 do
        local seatName = "Cadeira"..i
        local p = self.Seats[seatName]
        local hand = {table.remove(self.CurrentDeck,1), table.remove(self.CurrentDeck,1), table.remove(self.CurrentDeck,1)}
        local partner = self:GetPartner(p)
        local partnerName = self:IsBot(partner) and "Bot" or (partner and partner.Name or "...")
        if self:IsBot(p) then p:ReceiveHand(hand, self.CurrentVira)
        else Events.DealCards:FireClient(p, hand, self.CurrentVira, partnerName); Events.GameStatusEvent:FireClient(p, "SHOW_GAME_UI") end
    end
    task.wait(1)
    self.State = "PLAYING"
    local roles = self:GetRoles()
    self.CurrentTurnSeatIndex = tonumber(roles.Mao:match("%d+"))
    self:AdvanceTurn()
end

function Match:AdvanceTurn()
    local currentSeat = "Cadeira"..self.CurrentTurnSeatIndex
    local currentPlayer = self.Seats[currentSeat]
    if not currentPlayer then return end
    local pName = self:IsBot(currentPlayer) and "Bot" or currentPlayer.Name
    local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
    for _, humanPlayer in ipairs(self:GetHumanPlayers()) do Events.UpdateTurnEvent:FireClient(humanPlayer, pName, trickNum) end
    if self:IsBot(currentPlayer) then currentPlayer:MyTurn(trickNum, self.CurrentVira, self.CardsInTable, self.HandValue, self.TrucoState.CurrentValue) end
end

function Match:PlayerPlayCard(player, val, suit, hidden)
    -- >>> BLOQUEIO CRÍTICO DE CARTA <<<
    -- Enquanto WaitingResponse for true, NENHUMA carta entra na mesa.
    if self.TrucoState.WaitingResponse then return end
    if self.State ~= "PLAYING" then return end
    
    local turnPlayer = self.Seats["Cadeira"..self.CurrentTurnSeatIndex]
    if turnPlayer ~= player then return end
    
    local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
    if trickNum == 1 then hidden = false end 
    table.insert(self.CardsInTable, { Player = player, Value = val, Suit = suit, IsHidden = hidden })
    
    local pName = player.Name 
    for _, humanPlayer in ipairs(self:GetHumanPlayers()) do
        Events.CardPlayedOnTable:FireClient(humanPlayer, pName, val, suit, hidden)
    end
    
    if #self.CardsInTable >= 4 then
        task.wait(1.5)
        self:EvaluateTrick()
    else
        self.CurrentTurnSeatIndex = self:GetNextSeatIndex(self.CurrentTurnSeatIndex)
        self:AdvanceTurn()
    end
end

function Match:EvaluateTrick()
    local winner = RuleManager.GetRoundWinner(self.CardsInTable, self.CurrentVira.Value)
    local winnerTeam = nil
    if winner == "DRAW" then
        local firstPlayer = self.CardsInTable[1].Player
        winnerTeam = self:GetTeam(firstPlayer)
        self:SetTurnToPlayer(firstPlayer)
    else
        winnerTeam = self:GetTeam(winner)
        self:SetTurnToPlayer(winner)
    end
    self.TricksWon["Team"..winnerTeam] += 1
    self.CardsInTable = {} 
    self:Broadcast("CLEAR_TABLE", {TeamA = self.TricksWon.TeamA, TeamB = self.TricksWon.TeamB})
    if self.TricksWon["Team"..winnerTeam] >= 2 then self:WinHand(winnerTeam)
    else task.wait(1); self:AdvanceTurn() end
end

function Match:GetTeamNames(teamId)
    local names = {}
    for _, p in pairs(self.Seats) do
        if self:GetTeam(p) == teamId then
            table.insert(names, p.Name) -- Pega o nome do Player ou do Bot
        end
    end
    
    if #names == 0 then return "Ninguém" end
    -- Junta os nomes com " e ". Ex: "Player1 e Player2"
    return table.concat(names, " e ")
end

function Match:WinHand(teamWinner)
    self.State = "SCORING" 
    self.TrucoState.WaitingResponse = false
    self.TrucoState.ChallengeId += 1 

    -- Pontuação
    if teamWinner == "A" then self.Scores.TeamA += self.HandValue else self.Scores.TeamB += self.HandValue end
    
    -- 1. Pega os nomes da dupla vencedora da MÃO
    local roundWinnerNames = self:GetTeamNames(teamWinner)
    
    -- Envia um objeto com Valor E Nomes. 
    -- Ex: data = { Value = 1, Names = "Joao e Bot 1" }
    self:Broadcast("TEAM_"..teamWinner.."_WON_HAND", {Value = self.HandValue, Names = roundWinnerNames})
    
    self:Broadcast("UPDATE_SCORE", self.Scores)
    
    task.wait(3)
    
    -- Verifica Fim de Jogo (Partida)
    if self.Scores.TeamA >= 12 or self.Scores.TeamB >= 12 then
        local winningTeam = (self.Scores.TeamA >= 12) and "A" or "B"
        
        -- 2. Pega os nomes da dupla vencedora da PARTIDA
        local matchWinnerNames = self:GetTeamNames(winningTeam)
        local winnerMsg = matchWinnerNames .. " Venceram!"
        
        self:Broadcast("MATCH_WON", winnerMsg)
        
        task.wait(8)
        self:ResetMatch("Nova Partida")
    else
        self.DealerSeatIndex = (self.DealerSeatIndex % 4) + 1
        self:StartNewRound()
    end
end

-- --- SISTEMA DE TRUCO (CORRIGIDO) ---

function Match:HandleTrucoAction(player, action, subAction)
    local myTeam = self:GetTeam(player)
    
    -- >>> PEDIR TRUCO (REQUEST) <<<
    if action == "Request" then
        if self.TrucoState.WaitingResponse or self.TrucoState.CallerTeam == myTeam then return end
        
        local nextVal = (self.TrucoState.CurrentValue == 1) and 3 or (self.TrucoState.CurrentValue + 3)
        if nextVal > 12 then return end
        
        self.TrucoState.WaitingResponse = true
        self.TrucoState.CallerTeam = myTeam
        self.TrucoState.PendingValue = nextVal
        self.TrucoState.Votes = {}
        self.TrucoState.ChallengeId = self.TrucoState.ChallengeId + 1 -- Novo ID para timer
        
        self:Broadcast("TRUCO_CALLED", nextVal)
        local enemyTeam = (myTeam == "A") and "B" or "A"
        self:RequestTrucoResponse(enemyTeam, nextVal, player)
        
    -- >>> RESPONDER TRUCO (RESPONSE) <<<
    elseif action == "Response" then
        if not self.TrucoState.WaitingResponse then return end
        if myTeam == self.TrucoState.CallerTeam then return end 

        self.TrucoState.Votes[player] = subAction
        local partner = self:GetPartner(player)
        
        -- Função interna para processar a decisão final da dupla
        local function executeTeamDecision(decision)
            if decision == "Aceitar" then
                self:ResolveTruco(true, false)
            elseif decision == "Correr" then
                self:ResolveTruco(false, true)
            elseif decision == "Aumentar" then
                -- >>> LÓGICA DE AUMENTO CORRIGIDA <<<
                -- 1. Aceita o valor anterior (ex: valia 1, pediram 3 -> agora vale 3 oficial)
                self.TrucoState.CurrentValue = self.TrucoState.PendingValue
                self.HandValue = self.TrucoState.CurrentValue
                self:Broadcast("UPDATE_ROUND_VALUE", self.HandValue)
                
                -- 2. Calcula o NOVO valor (ex: quer 6)
                local nextVal = self.TrucoState.CurrentValue + 3
                if nextVal > 12 then nextVal = 12 end

                -- 3. Inverte os papéis: Quem respondeu agora é quem pede (CallerTeam)
                self.TrucoState.CallerTeam = myTeam
                self.TrucoState.PendingValue = nextVal
                self.TrucoState.Votes = {} -- Reseta votos
                self.TrucoState.WaitingResponse = true -- CONTINUA ESPERANDO (Trava cartas)
                self.TrucoState.ChallengeId = self.TrucoState.ChallengeId + 1 -- Reseta Timer
                
                -- 4. Notifica todos do aumento
                self:Broadcast("TRUCO_CALLED", nextVal)
                
                -- 5. Chama o outro time para responder
                local enemyTeam = (myTeam == "A") and "B" or "A"
                self:RequestTrucoResponse(enemyTeam, nextVal, player)
            end
        end

        -- Lógica de Parceiro / Bot
        local partnerIsBot = self:IsBot(partner)
        if partnerIsBot or not partner then
            executeTeamDecision(subAction)
            return
        end

        local partnerVote = self.TrucoState.Votes[partner]
        Events.GameStatusEvent:FireClient(partner, "PARTNER_VOTED", subAction)
        Events.GameStatusEvent:FireClient(player, "WAITING_PARTNER", 0)
        
        if partnerVote == subAction then
            executeTeamDecision(subAction)
        end
    end
end

function Match:ResolveTruco(accepted, ranAway)
    self.TrucoState.WaitingResponse = false
    self.TrucoState.ChallengeId += 1 -- Invalida timers
    self:Broadcast("HIDE_TRUCO_BTN", 0)
    
    if ranAway then
        local winnerTeam = (self.TrucoState.CallerTeam == "A") and "A" or "B"
        -- Se correu, ganha o valor que estava valendo ANTES do último pedido
        self.HandValue = self.TrucoState.CurrentValue 
        self:WinHand(winnerTeam)
    elseif accepted then
        self.TrucoState.CurrentValue = self.TrucoState.PendingValue
        self.HandValue = self.TrucoState.CurrentValue
        self:Broadcast("TRUCO_ACEITO", self.HandValue)
        self:Broadcast("UPDATE_ROUND_VALUE", self.HandValue)
        
        local acceptorTeam = (self.TrucoState.CallerTeam == "A") and "B" or "A"
        self:UpdateTrucoButtons(acceptorTeam)

        -- Retoma o fluxo do jogo (Bot joga se for a vez dele)
        local currentSeat = "Cadeira"..self.CurrentTurnSeatIndex
        local currentPlayer = self.Seats[currentSeat]
        if self:IsBot(currentPlayer) then
            local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
            task.delay(1.5, function()
                if self.State == "PLAYING" and not self.TrucoState.WaitingResponse then
                     currentPlayer:MyTurn(trickNum, self.CurrentVira, self.CardsInTable, self.HandValue, self.TrucoState.CurrentValue)
                end
            end)
        end
    end
end

function Match:RequestTrucoResponse(targetTeam, val, requester)
    local currentChallengeId = self.TrucoState.ChallengeId
    local TIME_LIMIT = 15

    task.delay(TIME_LIMIT, function()
        if self.TrucoState.WaitingResponse and self.TrucoState.ChallengeId == currentChallengeId then
            print("Tempo Esgotado! Auto-Fuga.")
            self:Broadcast("TRUCO_TIMEOUT", 0)
            self:ResolveTruco(false, true)
        end
    end)

    local teamHasHuman = false
    for _, p in pairs(self.Seats) do
        if not self:IsBot(p) and self:GetTeam(p) == targetTeam then teamHasHuman = true; break end
    end

    for seatName, p in pairs(self.Seats) do
        local pTeam = self:GetTeam(p)
        if self:IsBot(p) then
            if pTeam == targetTeam and not teamHasHuman then
                task.delay(math.random(1, 3), function() p:DecideTruco(val, self.HandValue) end)
            end
            continue
        end
        if pTeam == targetTeam then
            local callerName = self:IsBot(requester) and requester.Name or requester.Name
            Events.RequestAction:FireClient(p, "TrucoChallenge", { Value = val, Caller = callerName, TimeLimit = TIME_LIMIT })
        else
            Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
        end
    end
end

-- --- HELPERS (Inalterados, mas incluídos para completude) ---
function Match:Broadcast(msg, data)
    for _, p in pairs(self.Seats) do if not self:IsBot(p) then Events.GameStatusEvent:FireClient(p, msg, data) end end
end
function Match:NetworkFire(player, msg, data)
    if player and not self:IsBot(player) then Events.GameStatusEvent:FireClient(player, msg, data) end
end
function Match:GetHumanPlayers()
    local t = {}; for _, p in pairs(self.Seats) do if not self:IsBot(p) then table.insert(t, p) end end; return t
end
function Match:IsBot(entity) return (entity and typeof(entity) == "table" and entity.IsBot == true) end
function Match:CountPlayers() local c = 0; for _, _ in pairs(self.Seats) do c += 1 end; return c end
function Match:GetRoles()
    local d = self.DealerSeatIndex; local c = (d % 4) + 1; local m = (d - 2) % 4 + 1; if m <= 0 then m = m + 4 end
    return { Dealer="Cadeira"..d, Corte="Cadeira"..c, Mao="Cadeira"..m }
end
function Match:GetPlayerBySeat(name) return self.Seats[name] end
function Match:GetTeam(player)
    for seatName, p in pairs(self.Seats) do if p == player then local n = tonumber(seatName:match("%d+")); return (n % 2 == 1) and "A" or "B" end end; return "A"
end
function Match:GetPartner(player)
    local myTeam = self:GetTeam(player); for seatName, p in pairs(self.Seats) do if p ~= player and self:GetTeam(p) == myTeam then return p end end; return nil
end
function Match:SetTurnToPlayer(player)
    for seatName, p in pairs(self.Seats) do if p == player then self.CurrentTurnSeatIndex = tonumber(seatName:match("%d+")); break end end
end
function Match:UpdateTrucoButtons(allowedTeam)
    for seatName, p in pairs(self.Seats) do
        if not self:IsBot(p) then
            if self:GetTeam(p) == allowedTeam then Events.GameStatusEvent:FireClient(p, "SHOW_TRUCO_BTN")
            else Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN") end
        end
    end
end
function Match:BroadcastSignal(player, signalType)
    for _, p in pairs(self.Seats) do if not self:IsBot(p) then Events.SignalEvent:FireClient(p, player, signalType) end end
end
function Match:ResetMatch(reason)
    self:SetPlayersJumpable(true); self:Broadcast("HIDE_GAME_UI", 0); self:Broadcast("HIDE_SCOREBOARD", 0); self:Broadcast("UPDATE_STATUS", reason)
    self.State = "WAITING"; self.Scores = {TeamA=0, TeamB=0}
end

return Match
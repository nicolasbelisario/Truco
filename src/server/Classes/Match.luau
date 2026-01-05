local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = ReplicatedStorage:WaitForChild("Events")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CardSettings = require(Shared:WaitForChild("CardSettings"))
local DeckManager = require(script.Parent.Parent.Utils:WaitForChild("DeckManager"))
local RuleManager = require(script.Parent.Parent.Utils:WaitForChild("RuleManager"))
local Bot = require(script.Parent:WaitForChild("Bot"))
local BotDummyTemplate = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotDummy")

local Match = {}
Match.__index = Match

-- Construtor da Classe Match
function Match.new(model, useBots)
    local self = setmetatable({}, Match)
    
    self.Model = model
    self.UseBots = useBots
    
    -- Estado da Partida
    self.State = "WAITING"
    self.Seats = {} -- [SeatPartName] = Player ou BotTable
    self.Scores = { TeamA = 0, TeamB = 0 }
    
    -- Estado da Mão
    self.CurrentDeck = {}
    self.HandValue = 1
    self.CurrentVira = nil
    self.DealerSeatIndex = 1
    self.CurrentTurnSeatIndex = 1
    
    -- Controle de Truco
    self.TrucoState = {
        CurrentValue = 1,
        PendingValue = 0,
        CallerTeam = nil,
        WaitingResponse = false,
        ChallengeId = 0,
        Votes = {}
    }
    
    self.CardsInTable = {} -- {Player=p, Value=v...}
    self.TricksWon = { TeamA = 0, TeamB = 0 }
    
    self:SetupSeats()
    
    if self.UseBots then
        self:InitializeBots()
    end
    
    return self
end

-- Retorna o índice da cadeira à direita (Sentido Anti-Horário: 1 -> 4 -> 3 -> 2)
function Match:GetNextSeatIndex(currentIndex)
    return (currentIndex - 2) % 4 + 1
end

-- Configura as cadeiras físicas (CORRIGIDO PARA SUPORTAR MODELS)
function Match:SetupSeats()
    local cadeirasFolder = self.Model:WaitForChild("Cadeiras")
    
    for _, child in ipairs(cadeirasFolder:GetChildren()) do
        -- O 'child' é o Model "Cadeira1", "Cadeira2", etc.
        -- Precisamos achar o objeto Seat (Assento) lá dentro.
        local seatObject = child:FindFirstChildWhichIsA("Seat")
        
        -- Se o próprio child já for o Seat (caso você não tenha usado Models)
        if child:IsA("Seat") then
            seatObject = child
        end

        if seatObject then
            -- Usamos child.Name ("Cadeira1") como identificador, não o nome do assento interno
            local seatNameId = child.Name 
            
            seatObject:GetPropertyChangedSignal("Occupant"):Connect(function()
                self:HandleOccupantChange(seatObject, seatNameId)
            end)
        end
    end
    
    -- Loop de verificação de início
    task.spawn(function()
        while task.wait(1) do
            if self.State == "WAITING" and self:CountPlayers() == 4 then
                self:StartCountdown()
            end
        end
    end)
end

-- Inicializa Bots nas cadeiras 2, 3 e 4 se for mesa de Bot
-- Substitua a função InitializeBots atual por esta:
function Match:InitializeBots()
    -- Configuração de nomes amigáveis
    local botNames = {
        [2] = "Bot Rival 1",    -- Cadeira 2 (Direita)
        [3] = "Bot Parceiro",   -- Cadeira 3 (Frente/Sua Dupla)
        [4] = "Bot Rival 2"     -- Cadeira 4 (Esquerda)
    }

    -- Assume que o jogador real senta na cadeira 1
    -- Cria bots para 2, 3 e 4
    for i = 2, 4 do
        local seatName = "Cadeira"..i
        local displayName = botNames[i] or ("Bot " .. i)
        
        -- 1. Cria o Cérebro (Lógica) com o nome bonito
        local fakeBot = Bot.new(displayName, seatName, self)
        self.Seats[seatName] = fakeBot
        
        -- 2. Cria o Corpo (Visual) passando o nome
        self:SpawnVisualBot(seatName, displayName)
        
        print(displayName .. " adicionado na " .. seatName)
    end
end

-- Atualize a SpawnVisualBot para aceitar o nome e exibir no Humanoid:
function Match:SpawnVisualBot(seatName, displayName)
    -- 1. Acha a cadeira física no modelo da mesa
    local cadeirasFolder = self.Model:WaitForChild("Cadeiras")
    local seatModel = cadeirasFolder:FindFirstChild(seatName)
    
    if not seatModel then return end
    
    -- Tenta achar um objeto "Seat" ou usa o próprio model/part se for o caso
    local seatPart = seatModel:FindFirstChildWhichIsA("Seat") or seatModel
    
    -- 2. Clona o boneco
    local visualBot = BotDummyTemplate:Clone()
    visualBot.Name = displayName -- Nome do objeto no workspace
    
    if not visualBot.PrimaryPart then
        warn("BotDummy não tem PrimaryPart definida! O script pode falhar.")
    end

    -- 3. Configurações iniciais do Humanoide
    local humanoid = visualBot:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false 
        -- MUDANÇA: Viewer, para mostrar o nome em cima da cabeça
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer 
        humanoid.DisplayName = displayName -- Nome visível em cima da cabeça
    end
    
    -- 4. Parenteia para o Workspace
    visualBot.Parent = seatModel 

    -- 5. Faz o boneco sentar e congela
    if seatPart and humanoid then
        visualBot:SetPrimaryPartCFrame(seatPart.CFrame + Vector3.new(0, 2, 0))
        seatPart:Sit(humanoid)
        
        task.delay(0.2, function()
            for _, part in ipairs(visualBot:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true 
                    part.CanCollide = false 
                end
            end
        end)
    end
end

-- CORRIGIDO: Agora recebe o seatName explícito
function Match:HandleOccupantChange(seat, seatName)
    local humanoid = seat.Occupant
    
    if humanoid then
        local player = game.Players:GetPlayerFromCharacter(humanoid.Parent)
        if player then
            -- Se for mesa de bot e não for a Cadeira 1, expulsa (apenas cadeira 1 é humana)
            if self.UseBots and seatName ~= "Cadeira1" then
                humanoid.Jump = true
                return
            end
            
            self.Seats[seatName] = player
            if self.OnPlayerJoin then self.OnPlayerJoin(player) end
            
            -- Atualiza UI - AGORA DEVE FUNCIONAR O TEXTO
            self:NetworkFire(player, "SHOW_SCOREBOARD")
            self:NetworkFire(player, "UPDATE_SCORE", self.Scores)
            self:NetworkFire(player, "WAITING", 0) 
            print("Jogador detectado e notificado: " .. player.Name)
        end
    else
        -- Jogador saiu
        local oldPlayer = self.Seats[seatName]
        if oldPlayer and typeof(oldPlayer) == "Instance" then -- Não remove bots
            if self.OnPlayerLeave then self.OnPlayerLeave(oldPlayer) end
            self:NetworkFire(oldPlayer, "HIDE_GAME_UI")
            self.Seats[seatName] = nil
            
            -- Se o jogo estava rolando, reseta
            if self.State ~= "WAITING" then
                self:ResetMatch("Jogador saiu!")
            end
        end
    end
end

-- --- LÓGICA DO JOGO ---

-- Função auxiliar para impedir que jogadores levantem
function Match:SetPlayersJumpable(canJump)
    for _, player in pairs(self.Seats) do
        if not self:IsBot(player) and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum then
                -- Se não puder pular, JumpPower = 0. Se puder, volta pro padrão (50)
                hum.UseJumpPower = true
                hum.JumpPower = canJump and 50 or 0
            end
        end
    end
end

function Match:StartCountdown()
    self.State = "COUNTDOWN"
    for i = 5, 0, -1 do
        if self:CountPlayers() < 4 then
            self.State = "WAITING"
            self:Broadcast("WAITING", 0)
            return
        end
        self:Broadcast("COUNTDOWN", i)
        task.wait(1)
    end
    self:BeginGame()
end

function Match:BeginGame()
    self:SetPlayersJumpable(false) -- Ninguém sai da cadeira agora!
    
    self.Scores = {TeamA = 0, TeamB = 0}
    self.DealerSeatIndex = math.random(1, 4)
    self:StartNewRound()
end

function Match:StartNewRound()
    -- Reseta variáveis
    self.TrucoState = { CurrentValue = 1, PendingValue = 0, CallerTeam = nil, WaitingResponse = false, ChallengeId = 0, Votes = {} }
    self.TricksWon = { TeamA = 0, TeamB = 0 }
    self.CardsInTable = {}
    self.HandValue = 1
    
    self:Broadcast("UPDATE_ROUND_VALUE", 1)
    self:Broadcast("SHOW_TRUCO_BTN", 0)
    
    self.CurrentDeck = DeckManager.CreateDeck() 
    DeckManager.Shuffle(self.CurrentDeck)
    
    self.State = "CUTTING"
    
    -- >>> CORREÇÃO AQUI: Avisa a UI para mostrar o texto <<<
    self:Broadcast("CUTTING", 0) 
    
    local roles = self:GetRoles()
    local cutter = self:GetPlayerBySeat(roles.Corte)
    
    -- Se for bot cortando
    if self:IsBot(cutter) then
        task.delay(1.5, function() cutter:AutoCut() end)
    elseif cutter then
        Events.RequestAction:FireClient(cutter, "EscolhaOCorte", 10)
    end
    
    -- Fallback se ninguém cortar
    task.delay(11, function()
        if self.State == "CUTTING" then self:DistributeCards() end
    end)
end

function Match:PlayerCutDeck(player, amount)
    if self.State ~= "CUTTING" then return end
    -- Validação: É a vez dele?
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
    
    -- Distribui
    for i = 1, 4 do
        local seatName = "Cadeira"..i
        local p = self.Seats[seatName]
        local hand = {table.remove(self.CurrentDeck,1), table.remove(self.CurrentDeck,1), table.remove(self.CurrentDeck,1)}
        
        local partner = self:GetPartner(p)
        local partnerName = self:IsBot(partner) and "Bot" or (partner and partner.Name or "...")
        
        if self:IsBot(p) then
            p:ReceiveHand(hand, self.CurrentVira)
        else
            Events.DealCards:FireClient(p, hand, self.CurrentVira, partnerName)
            Events.GameStatusEvent:FireClient(p, "SHOW_GAME_UI")
        end
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
    
    -- Verifica se o jogador existe (pode ser nil se alguém saiu no meio do loop)
    if not currentPlayer then return end

    local pName = self:IsBot(currentPlayer) and "Bot" or currentPlayer.Name
    local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
    
    -- CORREÇÃO: Loop para enviar para cada humano individualmente
    local humans = self:GetHumanPlayers()
    for _, humanPlayer in ipairs(humans) do
        Events.UpdateTurnEvent:FireClient(humanPlayer, pName, trickNum)
    end
    
    -- Se for BOT, pensa e joga
    if self:IsBot(currentPlayer) then
        currentPlayer:MyTurn(trickNum, self.CurrentVira, self.CardsInTable, self.HandValue, self.TrucoState.CurrentValue)
    end
end

function Match:PlayerPlayCard(player, val, suit, hidden)
    -- 1. BLOQUEIO TOTAL SE O TRUCO ESTIVER PENDENTE
    -- Se alguém pediu truco e ainda não foi resolvido (WaitingResponse), NINGUÉM joga.
    if self.TrucoState.WaitingResponse then 
        return 
    end

    -- 2. BLOQUEIO DE ESTADO
    -- Só aceita jogar carta se o estado for estritamente "PLAYING".
    -- Se alguém correu, o estado muda para "SCORING" imediatamente (ver abaixo).
    if self.State ~= "PLAYING" then 
        return 
    end
    
    -- Validação de vez
    local turnPlayer = self.Seats["Cadeira"..self.CurrentTurnSeatIndex]
    if turnPlayer ~= player then return end
    
    -- Lógica normal de jogar a carta...
    local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
    if trickNum == 1 then hidden = false end 
    
    table.insert(self.CardsInTable, { Player = player, Value = val, Suit = suit, IsHidden = hidden })
    
    local pName = player.Name 
    
    local humans = self:GetHumanPlayers()
    for _, humanPlayer in ipairs(humans) do
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
    self.CardsInTable = {} -- Limpa mesa lógica
    
    -- Notifica limpeza visual
    self:Broadcast("CLEAR_TABLE", {TeamA = self.TricksWon.TeamA, TeamB = self.TricksWon.TeamB})
    
    -- Verifica Fim da Mão (Melhor de 3)
    if self.TricksWon["Team"..winnerTeam] >= 2 then
        self:WinHand(winnerTeam)
    else
        task.wait(1)
        self:AdvanceTurn()
    end
end

function Match:WinHand(teamWinner)
    -- >>> CRÍTICO: TRAVA O JOGO IMEDIATAMENTE <<<
    -- Ao mudar para "SCORING", o PlayerPlayCard vai rejeitar qualquer clique
    self.State = "SCORING" 
    self.TrucoState.WaitingResponse = false -- Limpa pendência para não travar o fluxo

    if teamWinner == "A" then self.Scores.TeamA += self.HandValue else self.Scores.TeamB += self.HandValue end
    
    self:Broadcast("TEAM_"..teamWinner.."_WON_HAND", self.HandValue)
    self:Broadcast("UPDATE_SCORE", self.Scores)
    
    -- Agora sim podemos esperar a animação sem medo de bugs
    task.wait(3)
    
    if self.Scores.TeamA >= 12 or self.Scores.TeamB >= 12 then
        local winnerMsg = (self.Scores.TeamA >= 12) and "Dupla A Venceu!" or "Dupla B Venceu!"
        self:Broadcast("MATCH_WON", winnerMsg)
        task.wait(8)
        self:ResetMatch("Nova Partida")
    else
        self.DealerSeatIndex = (self.DealerSeatIndex % 4) + 1
        self:StartNewRound()
    end
end

-- --- SISTEMA DE TRUCO ---

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
        self.TrucoState.Votes = {} -- Limpa votos anteriores
        
        self:Broadcast("TRUCO_CALLED", nextVal)
        
        -- Solicita resposta da equipe oposta
        local enemyTeam = (myTeam == "A") and "B" or "A"
        self:RequestTrucoResponse(enemyTeam, nextVal, player)
        
    -- >>> RESPONDER TRUCO (RESPONSE) <<<
    elseif action == "Response" then
        if not self.TrucoState.WaitingResponse then return end
        
        -- Segurança: Só aceita resposta do time desafiado
        if myTeam == self.TrucoState.CallerTeam then return end 

        -- 1. Registra o voto deste jogador
        self.TrucoState.Votes[player] = subAction
        
        -- Identifica o parceiro
        local partner = self:GetPartner(player)
        local partnerIsBot = self:IsBot(partner)
        
        -- 2. CASO: Parceiro é BOT ou Inexistente
        -- A decisão do humano vale por dois imediatamente
        if partnerIsBot or not partner then
            if subAction == "Aceitar" then
                self:ResolveTruco(true, false)
            elseif subAction == "Correr" then
                self:ResolveTruco(false, true)
            elseif subAction == "Aumentar" then
                self:ResolveTruco(true, false) -- Aceita o atual
                -- Opcional: Aqui você poderia chamar HandleTrucoAction("Request") recursivamente 
                -- se quiser que o aumento seja automático
            end
            return
        end

        -- 3. CASO: Parceiro é HUMANO (Consenso Obrigatório)
        local partnerVote = self.TrucoState.Votes[partner]
        
        -- Avisa o parceiro qual foi a sua escolha (Atualiza texto na tela dele)
        Events.GameStatusEvent:FireClient(partner, "PARTNER_VOTED", subAction)
        
        -- Avisa você mesmo que está esperando (Atualiza texto na sua tela)
        Events.GameStatusEvent:FireClient(player, "WAITING_PARTNER", 0)
        
        -- VERIFICA O CONSENSO
        -- A ação só acontece se o parceiro já votou E votou na MESMA COISA
        if partnerVote == subAction then
            -- Consenso atingido! Executa a ação.
            if subAction == "Aceitar" then
                self:ResolveTruco(true, false)
            elseif subAction == "Correr" then
                self:ResolveTruco(false, true)
            elseif subAction == "Aumentar" then
                self:ResolveTruco(true, false)
            end
        else
            -- Desacordo (Ex: Um quer fugir, outro quer aceitar).
            -- Não faz nada. O jogo fica pausado esperando alguém mudar o voto.
            print("Desacordo na dupla: " .. player.Name .. " quer " .. subAction .. ", Parceiro quer " .. tostring(partnerVote))
        end
    end
end

function Match:ResolveTruco(accepted, ranAway)
    self.TrucoState.WaitingResponse = false
    self:Broadcast("HIDE_TRUCO_BTN", 0) -- Esconde botões de decisão
    
    if ranAway then
        -- O time que correu perde. O outro ganha o valor ANTERIOR.
        local winnerTeam = (self.TrucoState.CallerTeam == "A") and "A" or "B" -- Quem pediu ganha
        self.HandValue = self.TrucoState.CurrentValue -- Valor antigo
        self:WinHand(winnerTeam)
    elseif accepted then
        self.TrucoState.CurrentValue = self.TrucoState.PendingValue
        self.HandValue = self.TrucoState.CurrentValue
        self:Broadcast("TRUCO_ACEITO", self.HandValue)
        self:Broadcast("UPDATE_ROUND_VALUE", self.HandValue)
        
        -- Libera botões de truco para quem aceitou (para poder pedir 6, 9, 12)
        local acceptorTeam = (self.TrucoState.CallerTeam == "A") and "B" or "A"
        self:UpdateTrucoButtons(acceptorTeam)

        -- >>> CORREÇÃO DO TRAVAMENTO <<<
        -- O jogo precisa continuar. Verificamos de quem é a vez atual.
        local currentSeat = "Cadeira"..self.CurrentTurnSeatIndex
        local currentPlayer = self.Seats[currentSeat]

        -- Se for a vez de um Bot, mandamos ele jogar agora (já que o Truco foi resolvido)
        if self:IsBot(currentPlayer) then
            local trickNum = self.TricksWon.TeamA + self.TricksWon.TeamB + 1
            
            -- Pequeno delay para não ser instantâneo após o aceite
            task.delay(1.5, function()
                -- Chamamos MyTurn novamente. 
                -- OBS: O Bot precisa ser inteligente para não pedir Truco de novo imediatamente
                -- se o valor já subiu, mas a lógica aleatória dele deve evitar loop infinito na maioria dos casos.
                currentPlayer:MyTurn(trickNum, self.CurrentVira, self.CardsInTable, self.HandValue, self.TrucoState.CurrentValue)
            end)
        else
            -- Se for a vez de um Humano (ex: Bot pediu, Humano aceitou, mas era vez do Bot... não, pera)
            -- Cenário: Humano Pediu -> Bot Aceitou -> Vez do Humano: A UI do humano já libera a carta.
            -- Cenário: Bot Pediu -> Humano Aceitou -> Vez do Bot: O código acima resolve.
        end
    end
end

-- Substitua a função RequestTrucoResponse inteira por esta:
function Match:RequestTrucoResponse(targetTeam, val, requester)
    -- 1. Descobre se o time alvo tem humanos
    local teamHasHuman = false
    for _, p in pairs(self.Seats) do
        if not self:IsBot(p) and self:GetTeam(p) == targetTeam then
            teamHasHuman = true
            break -- Basta um humano para o time ser considerado "Humano"
        end
    end

    -- 2. Itera sobre todos para mandar a interface ou decidir
    for seatName, p in pairs(self.Seats) do
        local pTeam = self:GetTeam(p)
        
        -- >>> É BOT <<<
        if self:IsBot(p) then
            -- Só decide se for do time alvo E NÃO HOUVER humanos no time dele
            -- (Se tiver humano, o bot fica quieto e deixa o parceiro decidir)
            if pTeam == targetTeam and not teamHasHuman then
                task.delay(math.random(1, 3), function()
                    p:DecideTruco(val, self.HandValue)
                end)
            end
            continue
        end

        -- >>> É HUMANO <<<
        if pTeam == targetTeam then
            -- É do time desafiado: MOSTRA OS BOTÕES
            -- (Isso vai rodar para TODOS os humanos do time. Se tiver 2, os 2 recebem)
            local callerName = self:IsBot(requester) and requester.Name or requester.Name
            
            Events.RequestAction:FireClient(p, "TrucoChallenge", {
                Value = val, 
                Caller = callerName, 
                TimeLimit = 15
            })
        else
            -- É do time que pediu (ou espectador): ESCONDE OS BOTÕES
            Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
        end
    end
end

-- --- HELPERS ---

function Match:Broadcast(msg, data)
    for _, p in pairs(self.Seats) do
        if not self:IsBot(p) then
            Events.GameStatusEvent:FireClient(p, msg, data)
        end
    end
end

function Match:NetworkFire(player, msg, data)
    if player and not self:IsBot(player) then
        Events.GameStatusEvent:FireClient(player, msg, data)
    end
end

function Match:GetHumanPlayers()
    local t = {}
    for _, p in pairs(self.Seats) do
        if not self:IsBot(p) then table.insert(t, p) end
    end
    return t
end

function Match:IsBot(entity)
    return (entity and typeof(entity) == "table" and entity.IsBot == true)
end

function Match:CountPlayers()
    local c = 0
    for _, _ in pairs(self.Seats) do c += 1 end
    return c
end

function Match:GetRoles()
    local d = self.DealerSeatIndex
    local c = (d % 4) + 1
    local m = (d - 2) % 4 + 1
    if m <= 0 then m = m + 4 end
    return { Dealer="Cadeira"..d, Corte="Cadeira"..c, Mao="Cadeira"..m }
end

function Match:GetPlayerBySeat(name) return self.Seats[name] end

function Match:GetTeam(player)
    for seatName, p in pairs(self.Seats) do
        if p == player then
            local n = tonumber(seatName:match("%d+"))
            return (n % 2 == 1) and "A" or "B"
        end
    end
    return "A"
end

function Match:GetPartner(player)
    local myTeam = self:GetTeam(player)
    for seatName, p in pairs(self.Seats) do
        if p ~= player and self:GetTeam(p) == myTeam then return p end
    end
    return nil
end

function Match:SetTurnToPlayer(player)
    for seatName, p in pairs(self.Seats) do
        if p == player then
            self.CurrentTurnSeatIndex = tonumber(seatName:match("%d+"))
            break
        end
    end
end

function Match:UpdateTrucoButtons(allowedTeam)
    for seatName, p in pairs(self.Seats) do
        if not self:IsBot(p) then
            if self:GetTeam(p) == allowedTeam then
                Events.GameStatusEvent:FireClient(p, "SHOW_TRUCO_BTN")
            else
                Events.GameStatusEvent:FireClient(p, "HIDE_TRUCO_BTN")
            end
        end
    end
end

function Match:BroadcastSignal(player, signalType)
    for _, p in pairs(self.Seats) do
        if not self:IsBot(p) then
            Events.SignalEvent:FireClient(p, player, signalType)
        end
    end
end

function Match:ResetMatch(reason)
    self:SetPlayersJumpable(true)
    self:Broadcast("HIDE_GAME_UI", 0)
    self:Broadcast("HIDE_SCOREBOARD", 0)
    self:Broadcast("UPDATE_STATUS", reason)
    self.State = "WAITING"
    self.Scores = {TeamA=0, TeamB=0}
end

return Match
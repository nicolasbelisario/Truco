local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Eventos = ReplicatedStorage:WaitForChild("Events")

local GerenciadorBaralho = require(script.Parent.Parent.Utils:WaitForChild("DeckManager"))
local GerenciadorRegras = require(script.Parent.Parent.Utils:WaitForChild("RuleManager"))
local Bot = require(script.Parent:WaitForChild("Bot"))
local BotDummyTemplate = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotDummy")
local DataManager = require(script.Parent.Parent:WaitForChild("DataManager"))

local Partida = {}
Partida.__index = Partida

-- ==========================================
-- 1. CONFIGURAÇÃO E INICIALIZAÇÃO
-- ==========================================

-- [MÉTODO] Cria uma nova instância de Partida amarrada a um Modelo 3D de Mesa
function Partida.nova(modeloMesa, listaAssentosBots)
    local self = setmetatable({}, Partida)
    self.Modelo = modeloMesa
    self.AssentosBots = listaAssentosBots or {} 
    self.UsaBots = (#self.AssentosBots > 0)
    
    self.Estado = "WAITING" -- WAITING, COUNTDOWN, CUTTING, DEALING, PLAYING, SCORING
    self.Assentos = {} -- Registra quem está em qual cadeira [Ex: "Cadeira1" = Player]
    self.Placar = { TeamA = 0, TeamB = 0 } -- Placar geral (até 12)
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 } -- Placar da rodada (melhor de 3)
    
    self.BaralhoAtual = {}
    self.ValorRodada = 1
    self.ViraAtual = nil
    self.CartasNaMesa = {}
    
    self.IndexDistribuidor = 1 -- Quem dá as cartas (D)
    self.IndexTurnoAtual = 1 -- De quem é a vez (Mão)
    
    self.EstadoTruco = {
        ValorAtual = 1, ValorPendente = 0, EquipePediu = nil, 
        AguardandoResposta = false, IDDesafio = 0, Votos = {}
    }
    
    self:ConfigurarAssentos()
    if self.UsaBots then self:InicializarBots() end
    return self
end

-- [MÉTODO] Monitora as cadeiras físicas para ver quando alguém senta/levanta
function Partida:ConfigurarAssentos()
    local pastaCadeiras = self.Modelo:WaitForChild("Cadeiras")
    for _, filho in ipairs(pastaCadeiras:GetChildren()) do
        local objetoAssento = filho:FindFirstChildWhichIsA("Seat") or (filho:IsA("Seat") and filho)
        if objetoAssento then
            local idCadeira = filho.Name 
            objetoAssento:GetPropertyChangedSignal("Occupant"):Connect(function()
                self:ProcessarMudancaAssento(objetoAssento, idCadeira)
            end)
        end
    end
    
    -- Loop que checa se a mesa encheu para iniciar a contagem
    task.spawn(function()
        while task.wait(1) do
            if self.Estado == "WAITING" and self:ContarJogadores() == 4 then 
                self:IniciarContagem() 
            end
        end
    end)
end

function Partida:InicializarBots()
    local mapaNomes = {[1]="Bot 1", [2]="Bot Rival 1", [3]="Bot Parceiro", [4]="Bot Rival 2"}
    for _, indexAssento in ipairs(self.AssentosBots) do
        local nomeAssento = "Cadeira" .. indexAssento
        local nomeExibicao = mapaNomes[indexAssento] or ("Bot " .. indexAssento)
        
        local novoBot = Bot.novo(nomeExibicao, nomeAssento, self)
        self.Assentos[nomeAssento] = novoBot
        self:GerarBotVisual(nomeAssento, nomeExibicao)
    end
end

-- ==========================================
-- 2. CONTROLE DE JOGADORES
-- ==========================================

function Partida:ProcessarMudancaAssento(assento, nomeAssento)
    local humanoide = assento.Occupant
    if humanoide then
        -- Alguém sentou
        local jogador = game.Players:GetPlayerFromCharacter(humanoide.Parent)
        if jogador then
            local numAssento = tonumber(nomeAssento:match("%d+"))
            
            -- Se for uma cadeira reservada pra bot, expulsa o jogador
            if self.UsaBots and table.find(self.AssentosBots, numAssento) then 
                humanoide.Jump = true; return 
            end
            
            self.Assentos[nomeAssento] = jogador
            if self.OnPlayerJoin then self.OnPlayerJoin(jogador) end
            
            self:EnviarParaJogador(jogador, "SHOW_SCOREBOARD")
            self:EnviarParaJogador(jogador, "UPDATE_SCORE", self.Placar)
            self:EnviarParaJogador(jogador, "WAITING", 0) 
        end
    else
        -- Alguém levantou
        local jogadorAntigo = self.Assentos[nomeAssento]
        if jogadorAntigo and typeof(jogadorAntigo) == "Instance" then 
            if self.OnPlayerLeave then self.OnPlayerLeave(jogadorAntigo) end
            self:EnviarParaJogador(jogadorAntigo, "HIDE_GAME_UI")
            self.Assentos[nomeAssento] = nil
            
            -- Se o jogo já tinha começado, derruba a partida
            if self.Estado ~= "WAITING" then self:ResetarPartida("Jogador saiu!") end
        end
    end
end

-- [MÉTODO] Bloqueia ou libera o pulo para evitar que os jogadores levantem da mesa
function Partida:DefinirPuloJogadores(podePular)
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) and jog.Character then
            local humanoide = jog.Character:FindFirstChild("Humanoid")
            if humanoide then 
                humanoide.UseJumpPower = true
                humanoide.JumpPower = podePular and 50 or 0 
            end
        end
    end
end

-- ==========================================
-- 3. FLUXO DO JOGO E RODADA
-- ==========================================

function Partida:IniciarContagem()
    self.Estado = "COUNTDOWN"
    for i = 5, 0, -1 do
        if self:ContarJogadores() < 4 then 
            self.Estado = "WAITING"
            self:TransmitirTodos("WAITING", 0)
            return 
        end
        self:TransmitirTodos("COUNTDOWN", i)
        task.wait(1)
    end
    self:ComecarJogo()
end

function Partida:ComecarJogo()
    self:DefinirPuloJogadores(false)
    self.Placar = {TeamA = 0, TeamB = 0}
    self.IndexDistribuidor = math.random(1, 4) -- Sorteia quem dá as cartas primeiro
    self:IniciarNovaRodada()
end

function Partida:IniciarNovaRodada()
    self.EstadoTruco = { ValorAtual = 1, ValorPendente = 0, EquipePediu = nil, AguardandoResposta = false, IDDesafio = 0, Votos = {} }
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.CartasNaMesa = {}
    self.ValorRodada = 1
    
    self:TransmitirTodos("UPDATE_ROUND_VALUE", 1)
    self:TransmitirTodos("SHOW_TRUCO_BTN", 0)
    
    self.BaralhoAtual = GerenciadorBaralho.CriarBaralho() 
    GerenciadorBaralho.Embaralhar(self.BaralhoAtual)
    
    self.Estado = "CUTTING"
    self:TransmitirTodos("CUTTING", 0) 
    
    local papeis = self:ObterPapeis()
    local jogadorCorte = self:ObterJogadorPorCadeira(papeis.Corte)
    
    if self:EBot(jogadorCorte) then 
        task.delay(1.5, function() jogadorCorte:CortarAutomatico() end)
    elseif jogadorCorte then 
        Eventos.RequestAction:FireClient(jogadorCorte, "EscolhaOCorte", 10) 
    end
    
    -- Timer de segurança (se o jogador não cortar, corta automático)
    task.delay(11, function() 
        if self.Estado == "CUTTING" then self:DistribuirCartas() end 
    end)
end

function Partida:JogadorCortarBaralho(jogador, quantidade)
    if self.Estado ~= "CUTTING" then return end
    local papeis = self:ObterPapeis()
    if self:ObterJogadorPorCadeira(papeis.Corte) == jogador then
        GerenciadorBaralho.Cortar(self.BaralhoAtual, quantidade)
        self:DistribuirCartas()
    end
end

function Partida:DistribuirCartas()
    self.Estado = "DEALING"
    self:TransmitirTodos("DEALING", 0)
    
    self.ViraAtual = table.remove(self.BaralhoAtual, 1) -- Tira o Vira
    
    -- Dá 3 cartas pra cada
    for i = 1, 4 do
        local nomeAssento = "Cadeira"..i
        local jogador = self.Assentos[nomeAssento]
        local mao = {table.remove(self.BaralhoAtual,1), table.remove(self.BaralhoAtual,1), table.remove(self.BaralhoAtual,1)}
        local parceiro = self:ObterParceiro(jogador)
        local nomeParceiro = self:EBot(parceiro) and parceiro.Nome or (parceiro and parceiro.Name or "...")
        
        if self:EBot(jogador) then 
            jogador:ReceberMao(mao, self.ViraAtual)
        else 
            Eventos.DealCards:FireClient(jogador, mao, self.ViraAtual, nomeParceiro)
            Eventos.GameStatusEvent:FireClient(jogador, "SHOW_GAME_UI") 
        end
    end
    
    task.wait(1)
    self.Estado = "PLAYING"
    local papeis = self:ObterPapeis()
    self.IndexTurnoAtual = tonumber(papeis.Mao:match("%d+"))
    self:AvancarTurno()
end

-- ==========================================
-- 4. MECÂNICAS DE JOGADA
-- ==========================================

function Partida:AvancarTurno()
    local jogadorVez = self.Assentos["Cadeira"..self.IndexTurnoAtual]
    if not jogadorVez then return end
    
    local nomeVez = self:EBot(jogadorVez) and jogadorVez.Nome or jogadorVez.Name
    local numRodada = self.QuedasGanhas.TeamA + self.QuedasGanhas.TeamB + 1
    
    for _, humano in ipairs(self:ObterHumanos()) do 
        Eventos.UpdateTurnEvent:FireClient(humano, nomeVez, numRodada) 
    end
    
    if self:EBot(jogadorVez) then 
        jogadorVez:JogarTurno(numRodada, self.ViraAtual, self.CartasNaMesa, self.ValorRodada, self.EstadoTruco.ValorAtual) 
    end
end

function Partida:JogadorJogarCarta(jogador, valor, naipe, escondida)
    -- Trava se estiver aguardando Truco
    if self.EstadoTruco.AguardandoResposta or self.Estado ~= "PLAYING" then return end
    
    local jogadorVez = self.Assentos["Cadeira"..self.IndexTurnoAtual]
    if jogadorVez ~= jogador then return end -- Bloqueia hack de jogar fora da vez
    
    -- Na 1ª queda, não pode esconder carta
    local numRodada = self.QuedasGanhas.TeamA + self.QuedasGanhas.TeamB + 1
    if numRodada == 1 then escondida = false end 
    
    -- ======== LÊ A SKIN DO JOGADOR ========
    local skinUsada = "Padrao"
    if not self:EBot(jogador) then
        skinUsada = DataManager.ObterSkinEquipada(jogador)
    end
    -- ======================================

    table.insert(self.CartasNaMesa, { Player = jogador, Value = valor, Suit = naipe, IsHidden = escondida, Skin = skinUsada })
    
    local nomeExibicao = self:EBot(jogador) and jogador.Nome or jogador.Name 
    for _, humano in ipairs(self:ObterHumanos()) do
        -- Agora enviamos a "skinUsada" no final do evento!
        Eventos.CardPlayedOnTable:FireClient(humano, nomeExibicao, valor, naipe, escondida, skinUsada)
    end
    
    if #self.CartasNaMesa >= 4 then
        task.wait(1.5)
        self:AvaliarQueda()
    else
        self.IndexTurnoAtual = self:ObterProximoIndice(self.IndexTurnoAtual)
        self:AvancarTurno()
    end
end

function Partida:AvaliarQueda()
    local vencedorObj = GerenciadorRegras.ObterVencedorRodada(self.CartasNaMesa, self.ViraAtual.Value)
    local equipeVencedora = nil
    
    if vencedorObj == "DRAW" then
        -- Em caso de empate, quem jogou primeiro puxa a vez
        local primeiroJogar = self.CartasNaMesa[1].Player
        equipeVencedora = self:ObterEquipe(primeiroJogar)
        self:DefinirVezParaJogador(primeiroJogar)
    else
        equipeVencedora = self:ObterEquipe(vencedorObj)
        self:DefinirVezParaJogador(vencedorObj)
    end
    
    self.QuedasGanhas["Team"..equipeVencedora] += 1
    self.CartasNaMesa = {} 
    
    self:TransmitirTodos("CLEAR_TABLE", {TeamA = self.QuedasGanhas.TeamA, TeamB = self.QuedasGanhas.TeamB})
    
    -- Melhor de 3: Venceu 2 quedas, ganha a mão
    if self.QuedasGanhas["Team"..equipeVencedora] >= 2 then 
        self:VencerMao(equipeVencedora)
    else 
        task.wait(1); self:AvancarTurno() 
    end
end

function Partida:VencerMao(equipeVencedora)
    self.Estado = "SCORING" 
    self.EstadoTruco.AguardandoResposta = false
    self.EstadoTruco.IDDesafio += 1 

    -- Aplica os pontos da rodada
    if equipeVencedora == "A" then 
        self.Placar.TeamA += self.ValorRodada 
    else 
        self.Placar.TeamB += self.ValorRodada 
    end
    
    local nomesVencedores = self:ObterNomesEquipe(equipeVencedora)
    self:TransmitirTodos("TEAM_"..equipeVencedora.."_WON_HAND", {Value = self.ValorRodada, Names = nomesVencedores})
    self:TransmitirTodos("UPDATE_SCORE", self.Placar)
    
    task.wait(3)
    
    -- Checa se a partida acabou (12 pontos)
    if self.Placar.TeamA >= 12 or self.Placar.TeamB >= 12 then
        local equipeCampeao = (self.Placar.TeamA >= 12) and "A" or "B"
        local nomesCampeoes = self:ObterNomesEquipe(equipeCampeao)
        
        self:TransmitirTodos("MATCH_WON", nomesCampeoes .. " Venceram!")
        
        -- ========================================================
        -- DISTRIBUIÇÃO DE PONTOS (SISTEMA NOVO)
        -- ========================================================
        local pontosVitoria = self.UsaBots and 30 or 50
        local pontosDerrota = self.UsaBots and 10 or 20

        for nomeAssento, jog in pairs(self.Assentos) do
            if not self:EBot(jog) then
                local equipeDesteJogador = self:ObterEquipe(jog)
                
                if equipeDesteJogador == equipeCampeao then
                    DataManager.AdicionarPontos(jog, pontosVitoria)
                    self:EnviarParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. pontosVitoria .. " Pontos!")
                else
                    DataManager.AdicionarPontos(jog, pontosDerrota)
                    self:EnviarParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. pontosDerrota .. " Pontos de consolação.")
                end
            end
        end
        -- ========================================================
        
        task.wait(8)
        self:ResetarPartida("Nova Partida")
    else
        -- Gira o dealer e começa nova rodada
        self.IndexDistribuidor = (self.IndexDistribuidor % 4) + 1
        self:IniciarNovaRodada()
    end
end

-- ==========================================
-- 5. SISTEMA DE TRUCO
-- ==========================================

function Partida:ProcessarAcaoTruco(jogador, acao, subAcao)
    local minhaEquipe = self:ObterEquipe(jogador)
    
    if acao == "Request" then
        if self.EstadoTruco.AguardandoResposta or self.EstadoTruco.EquipePediu == minhaEquipe then return end
        
        local proximoValor = (self.EstadoTruco.ValorAtual == 1) and 3 or (self.EstadoTruco.ValorAtual + 3)
        if proximoValor > 12 then return end
        
        self.EstadoTruco.AguardandoResposta = true
        self.EstadoTruco.EquipePediu = minhaEquipe
        self.EstadoTruco.ValorPendente = proximoValor
        self.EstadoTruco.Votos = {}
        self.EstadoTruco.IDDesafio += 1 
        
        self:TransmitirTodos("TRUCO_CALLED", proximoValor)
        local equipeInimiga = (minhaEquipe == "A") and "B" or "A"
        self:PedirRespostaTruco(equipeInimiga, proximoValor, jogador)
        
    elseif acao == "Response" then
        if not self.EstadoTruco.AguardandoResposta then return end
        if minhaEquipe == self.EstadoTruco.EquipePediu then return end 

        self.EstadoTruco.Votos[jogador] = subAcao
        local parceiro = self:ObterParceiro(jogador)
        
        -- Processa a decisão
        local function executarDecisao(decisao)
            if decisao == "Aceitar" then
                self:ResolverTruco(true, false)
            elseif decisao == "Correr" then
                self:ResolverTruco(false, true)
            elseif decisao == "Aumentar" then
                self.EstadoTruco.ValorAtual = self.EstadoTruco.ValorPendente
                self.ValorRodada = self.EstadoTruco.ValorAtual
                self:TransmitirTodos("UPDATE_ROUND_VALUE", self.ValorRodada)
                
                local proximoValor = self.EstadoTruco.ValorAtual + 3
                if proximoValor > 12 then proximoValor = 12 end

                self.EstadoTruco.EquipePediu = minhaEquipe
                self.EstadoTruco.ValorPendente = proximoValor
                self.EstadoTruco.Votos = {} 
                self.EstadoTruco.AguardandoResposta = true 
                self.EstadoTruco.IDDesafio += 1 
                
                self:TransmitirTodos("TRUCO_CALLED", proximoValor)
                local equipeInimiga = (minhaEquipe == "A") and "B" or "A"
                self:PedirRespostaTruco(equipeInimiga, proximoValor, jogador)
            end
        end

        if self:EBot(parceiro) or not parceiro then
            executarDecisao(subAcao)
            return
        end

        local votoParceiro = self.EstadoTruco.Votos[parceiro]
        Eventos.GameStatusEvent:FireClient(parceiro, "PARTNER_VOTED", subAcao)
        Eventos.GameStatusEvent:FireClient(jogador, "WAITING_PARTNER", 0)
        
        -- Só resolve se os dois votarem a mesma coisa
        if votoParceiro == subAcao then
            executarDecisao(subAcao)
        end
    end
end

function Partida:ResolverTruco(aceitou, correu)
    self.EstadoTruco.AguardandoResposta = false
    self.EstadoTruco.IDDesafio += 1 
    self:TransmitirTodos("HIDE_TRUCO_BTN", 0)
    
    if correu then
        local equipeVencedora = (self.EstadoTruco.EquipePediu == "A") and "A" or "B"
        local equipeFugitiva = (self.EstadoTruco.EquipePediu == "A") and "B" or "A"
        
        -- Pega o nome de quem fugiu e avisa todos
        local nomesFugitivos = self:ObterNomesEquipe(equipeFugitiva)
        self:TransmitirTodos("TRUCO_FUGIU", nomesFugitivos)
        
        -- Se correu, ganha o valor que estava valendo ANTES de pedirem
        self.ValorRodada = self.EstadoTruco.ValorAtual 
        
        -- Pausa de 2 segundos para a galera ler a mensagem de fuga
        task.wait(2)
        
        self:VencerMao(equipeVencedora)
    elseif aceitou then
        self.EstadoTruco.ValorAtual = self.EstadoTruco.ValorPendente
        self.ValorRodada = self.EstadoTruco.ValorAtual
        self:TransmitirTodos("TRUCO_ACEITO", self.ValorRodada)
        self:TransmitirTodos("UPDATE_ROUND_VALUE", self.ValorRodada)
        
        local equipeQueAceitou = (self.EstadoTruco.EquipePediu == "A") and "B" or "A"
        self:AtualizarBotoesTruco(equipeQueAceitou)

        -- Retoma o fluxo para bots caso seja a vez deles
        local jogadorVez = self.Assentos["Cadeira"..self.IndexTurnoAtual]
        if self:EBot(jogadorVez) then
            local numRodada = self.QuedasGanhas.TeamA + self.QuedasGanhas.TeamB + 1
            task.delay(1.5, function()
                if self.Estado == "PLAYING" and not self.EstadoTruco.AguardandoResposta then
                     jogadorVez:JogarTurno(numRodada, self.ViraAtual, self.CartasNaMesa, self.ValorRodada, self.EstadoTruco.ValorAtual)
                end
            end)
        end
    end
end

function Partida:PedirRespostaTruco(equipeAlvo, valor, quemPediu)
    local idDesafioAtual = self.EstadoTruco.IDDesafio
    local TEMPO_LIMITE = 15

    task.delay(TEMPO_LIMITE, function()
        if self.EstadoTruco.AguardandoResposta and self.EstadoTruco.IDDesafio == idDesafioAtual then
            self:TransmitirTodos("TRUCO_TIMEOUT", 0)
            self:ResolverTruco(false, true) -- Foge automaticamente
        end
    end)

    local temHumano = false
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) and self:ObterEquipe(jog) == equipeAlvo then temHumano = true; break end
    end

    for nomeAssento, jog in pairs(self.Assentos) do
        local equipeJog = self:ObterEquipe(jog)
        if self:EBot(jog) then
            -- Se a equipe só tiver bot, o bot decide sozinho
            if equipeJog == equipeAlvo and not temHumano then
                task.delay(math.random(1, 3), function() jog:DecidirTruco(valor, self.ValorRodada) end)
            end
            continue
        end
        
        if equipeJog == equipeAlvo then
            local nomeExibicao = self:EBot(quemPediu) and quemPediu.Nome or quemPediu.Name
            Eventos.RequestAction:FireClient(jog, "TrucoChallenge", { Value = valor, Caller = nomeExibicao, TimeLimit = TEMPO_LIMITE })
        else
            Eventos.GameStatusEvent:FireClient(jog, "HIDE_TRUCO_BTN")
        end
    end
end

-- ==========================================
-- 6. FUNÇÕES AUXILIARES (HELPERS)
-- ==========================================

function Partida:TransmitirTodos(msg, dados)
    for _, jog in pairs(self.Assentos) do if not self:EBot(jog) then Eventos.GameStatusEvent:FireClient(jog, msg, dados) end end
end

function Partida:EnviarParaJogador(jogador, msg, dados)
    if jogador and not self:EBot(jogador) then Eventos.GameStatusEvent:FireClient(jogador, msg, dados) end
end

function Partida:ObterHumanos()
    local t = {}; for _, jog in pairs(self.Assentos) do if not self:EBot(jog) then table.insert(t, jog) end end; return t
end

function Partida:EBot(entidade) 
    return (entidade and typeof(entidade) == "table" and entidade.EBot == true) 
end

function Partida:ContarJogadores() 
    local c = 0; for _, _ in pairs(self.Assentos) do c += 1 end; return c 
end

function Partida:ObterProximoIndice(atual) 
    return (atual - 2) % 4 + 1 
end

function Partida:ObterPapeis()
    local d = self.IndexDistribuidor; local c = (d % 4) + 1; local m = (d - 2) % 4 + 1; if m <= 0 then m = m + 4 end
    return { Dealer="Cadeira"..d, Corte="Cadeira"..c, Mao="Cadeira"..m }
end

function Partida:ObterJogadorPorCadeira(nome) return self.Assentos[nome] end

function Partida:ObterEquipe(jogador)
    for nomeAssento, jog in pairs(self.Assentos) do 
        if jog == jogador then 
            local n = tonumber(nomeAssento:match("%d+")); return (n % 2 == 1) and "A" or "B" 
        end 
    end; return "A"
end

function Partida:ObterParceiro(jogador)
    local minhaEq = self:ObterEquipe(jogador); 
    for nomeAssento, jog in pairs(self.Assentos) do 
        if jog ~= jogador and self:ObterEquipe(jog) == minhaEq then return jog end 
    end; return nil
end

function Partida:DefinirVezParaJogador(jogador)
    for nomeAssento, jog in pairs(self.Assentos) do 
        if jog == jogador then self.IndexTurnoAtual = tonumber(nomeAssento:match("%d+")); break end 
    end
end

function Partida:ObterNomesEquipe(idEquipe)
    local nomes = {}
    for _, jog in pairs(self.Assentos) do
        if self:ObterEquipe(jog) == idEquipe then
            table.insert(nomes, self:EBot(jog) and jog.Nome or jog.Name)
        end
    end
    if #nomes == 0 then return "Ninguém" end
    return table.concat(nomes, " e ")
end

function Partida:AtualizarBotoesTruco(equipePermitida)
    for nomeAssento, jog in pairs(self.Assentos) do
        if not self:EBot(jog) then
            if self:ObterEquipe(jog) == equipePermitida then Eventos.GameStatusEvent:FireClient(jog, "SHOW_TRUCO_BTN")
            else Eventos.GameStatusEvent:FireClient(jog, "HIDE_TRUCO_BTN") end
        end
    end
end

function Partida:TransmitirSinal(jogador, tipoSinal)
    for _, jog in pairs(self.Assentos) do if not self:EBot(jog) then Eventos.SignalEvent:FireClient(jog, jogador, tipoSinal) end end
end

function Partida:ResetarPartida(motivo)
    self:DefinirPuloJogadores(true)
    self:TransmitirTodos("HIDE_GAME_UI", 0); self:TransmitirTodos("HIDE_SCOREBOARD", 0); self:TransmitirTodos("UPDATE_STATUS", motivo)
    self.Estado = "WAITING"; self.Placar = {TeamA=0, TeamB=0}
end

-- Método Visual Remanescente
function Partida:GerarBotVisual(nomeAssento, nomeExibicao)
    local modeloAssento = self.Modelo:WaitForChild("Cadeiras"):FindFirstChild(nomeAssento)
    if not modeloAssento then return end
    local banco = modeloAssento:FindFirstChildWhichIsA("Seat") or modeloAssento
    local botVisual = BotDummyTemplate:Clone()
    botVisual.Name = nomeExibicao 
    local humanoide = botVisual:FindFirstChild("Humanoid")
    if humanoide then
        humanoide.PlatformStand = false 
        humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer 
        humanoide.DisplayName = nomeExibicao
    end
    botVisual.Parent = modeloAssento 
    if banco and humanoide then
        botVisual:SetPrimaryPartCFrame(banco.CFrame + Vector3.new(0, 2, 0))
        banco:Sit(humanoide)
        task.delay(0.2, function()
            for _, parte in ipairs(botVisual:GetDescendants()) do
                if parte:IsA("BasePart") then parte.Anchored = true; parte.CanCollide = false end
            end
        end)
    end
end

return Partida
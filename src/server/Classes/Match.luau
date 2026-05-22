local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventBroadcaster = require(script.Parent:WaitForChild("EventBroadcaster"))
local TrucoHandler = require(script.Parent:WaitForChild("TrucoHandler"))
local RoundManager = require(script.Parent:WaitForChild("RoundManager"))
local Bot = require(script.Parent:WaitForChild("Bot"))
local DataManager = require(script.Parent.Parent:WaitForChild("DataManager"))

local BotDummyTemplate = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotDummy")

local Partida = {}
Partida.__index = Partida

function Partida.nova(modeloMesa, listaAssentosBots)
    local self = setmetatable({}, Partida)
    
    self.Modelo = modeloMesa
    self.AssentosBots = listaAssentosBots or {} 
    self.UsaBots = (#self.AssentosBots > 0)
    
    self.Estado = "WAITING"
    self.Assentos = {}
    self.Placar = { TeamA = 0, TeamB = 0 }

    -- [CORREÇÃO 3] Mantém o contexto de self encapsulado corretamente:
    self.VerificarBot = function(jog) return self:EBot(jog) end
    
    self.TrucoHandler = TrucoHandler.novo(self)
    self.RoundManager = RoundManager.novo(self)
    
    self:ConfigurarAssentos()
    if self.UsaBots then self:InicializarBots() end
    
    return self
end

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

function Partida:ProcessarMudancaAssento(assento, nomeAssento)
    local humanoide = assento.Occupant
    if humanoide then
        local jogador = game.Players:GetPlayerFromCharacter(humanoide.Parent)
        if jogador then
            local numAssento = tonumber(nomeAssento:match("%d+"))
            if self.UsaBots and table.find(self.AssentosBots, numAssento) then 
                humanoide.Jump = true; return 
            end
            
            self.Assentos[nomeAssento] = jogador
            if self.OnPlayerJoin then self.OnPlayerJoin(jogador) end
            
            EventBroadcaster.ParaJogador(jogador, "SHOW_SCOREBOARD", nil, self.VerificarBot)
            EventBroadcaster.ParaJogador(jogador, "UPDATE_SCORE", self.Placar, self.VerificarBot)
            EventBroadcaster.ParaJogador(jogador, "WAITING", 0, self.VerificarBot) 
        end
    else
        local jogadorAntigo = self.Assentos[nomeAssento]
        if jogadorAntigo and typeof(jogadorAntigo) == "Instance" then 
            if self.OnPlayerLeave then self.OnPlayerLeave(jogadorAntigo) end
            EventBroadcaster.ParaJogador(jogadorAntigo, "HIDE_GAME_UI", nil, self.VerificarBot)
            self.Assentos[nomeAssento] = nil
            
            if self.Estado ~= "WAITING" then self:ResetarPartida("Jogador saiu!") end
        end
    end
end

function Partida:DefinirPuloJogadores(podePular)
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) and jog.Character then
            local hum = jog.Character:FindFirstChild("Humanoid")
            if hum then 
                hum.UseJumpPower = true
                hum.JumpPower = podePular and 50 or 0 
            end
        end
    end
end

function Partida:IniciarContagem()
    self.Estado = "COUNTDOWN"
    for i = 5, 0, -1 do
        if self:ContarJogadores() < 4 then 
            self.Estado = "WAITING"
            EventBroadcaster.ParaTodos(self.Assentos, "WAITING", 0, self.VerificarBot)
            return 
        end
        EventBroadcaster.ParaTodos(self.Assentos, "COUNTDOWN", i, self.VerificarBot)
        task.wait(1)
    end
    self:ComecarJogo()
end

function Partida:ComecarJogo()
    self:DefinirPuloJogadores(false)
    self.Placar = {TeamA = 0, TeamB = 0}
    self.RoundManager.IndexDistribuidor = math.random(1, 4)
    self.RoundManager:IniciarNovaRodada()
end

function Partida:ResetarPartida(motivo)
    self:DefinirPuloJogadores(true)
    EventBroadcaster.ParaTodos(self.Assentos, "HIDE_GAME_UI", 0, self.VerificarBot)
    EventBroadcaster.ParaTodos(self.Assentos, "HIDE_SCOREBOARD", 0, self.VerificarBot)
    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_STATUS", motivo, self.VerificarBot)
    self.Estado = "WAITING"
    self.Placar = {TeamA=0, TeamB=0}
    self.RoundManager:ResetarEstado()
    self.TrucoHandler:Resetar()
end

function Partida:JogadorJogarCarta(jogador, valor, naipe, escondida)
    local skinUsada = self:EBot(jogador) and "Padrao" or DataManager.ObterSkinEquipada(jogador)
    self.RoundManager:JogarCarta(jogador, valor, naipe, escondida, skinUsada)
end

function Partida:ProcessarAcaoTruco(jogador, acao, subAcao)
    if acao == "Request" then
        self.TrucoHandler:ProcessarRequest(jogador)
    elseif acao == "Response" then
        self.TrucoHandler:ProcessarResponse(jogador, subAcao)
    end
end

function Partida:JogadorCortarBaralho(jogador, quantidade)
    self.RoundManager:CortarBaralho(jogador, quantidade)
end

function Partida:TransmitirSinal(jogador, tipoSinal)
    EventBroadcaster.SinalEmote(self:ObterHumanos(), jogador, tipoSinal)
end

function Partida:FinalizarMao(equipeVencedora, valorRodada)
    self.Estado = "SCORING" 
    self.TrucoHandler.Estado.AguardandoResposta = false

    self.Placar["Team"..equipeVencedora] += valorRodada 
    
    local nomesVencedores = self:ObterNomesEquipe(equipeVencedora)
    EventBroadcaster.ParaTodos(self.Assentos, "TEAM_"..equipeVencedora.."_WON_HAND", {Value = valorRodada, Names = nomesVencedores}, self.VerificarBot)
    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_SCORE", self.Placar, self.VerificarBot)
    
    task.wait(3)
    
    if self.Placar.TeamA >= 12 or self.Placar.TeamB >= 12 then
        local equipeCampeao = (self.Placar.TeamA >= 12) and "A" or "B"
        EventBroadcaster.ParaTodos(self.Assentos, "MATCH_WON", self:ObterNomesEquipe(equipeCampeao) .. " Venceram!", self.VerificarBot)
        
        local ptsVitoria = self.UsaBots and 30 or 50
        local ptsDerrota = self.UsaBots and 10 or 20

        for _, jog in pairs(self.Assentos) do
            if not self:EBot(jog) then
                if self:ObterEquipe(jog) == equipeCampeao then
                    DataManager.AdicionarPontos(jog, ptsVitoria)
                    EventBroadcaster.ParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. ptsVitoria .. " Pontos!", self.VerificarBot)
                else
                    DataManager.AdicionarPontos(jog, ptsDerrota)
                    EventBroadcaster.ParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. ptsDerrota .. " Pontos de consolação.", self.VerificarBot)
                end
            end
        end
        
        task.wait(8)
        self:ResetarPartida("Nova Partida")
    else
        self.RoundManager.IndexDistribuidor = (self.RoundManager.IndexDistribuidor % 4) + 1
        self.RoundManager:IniciarNovaRodada()
    end
end

function Partida:OnTrucoAceito(valorAtualizado, equipeQuePediu)
    self.RoundManager.ValorRodada = valorAtualizado
    
    -- Avisa todos os jogadores (HUDs) que a rodada agora vale mais
    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_ROUND_VALUE", valorAtualizado, self.VerificarBot)
    
    -- Restaura os botões de TRUCO apenas para a equipe que ACEITOU
    local equipeQueAceitou = (equipeQuePediu == "A") and "B" or "A"
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) then
            if self:ObterEquipe(jog) == equipeQueAceitou then
                EventBroadcaster.ParaJogador(jog, "SHOW_TRUCO_BTN", nil, self.VerificarBot)
            else
                EventBroadcaster.ParaJogador(jog, "HIDE_TRUCO_BTN", nil, self.VerificarBot)
            end
        end
    end

    -- Religa o "cérebro" do bot se for a vez dele jogar a carta
    local jogadorVez = self.Assentos["Cadeira"..self.RoundManager.IndexTurnoAtual]
    if self:EBot(jogadorVez) then
        local numRodada = self.RoundManager.QuedasGanhas.TeamA + self.RoundManager.QuedasGanhas.TeamB + 1
        task.delay(1.5, function()
            if self.Estado == "PLAYING" and not self.TrucoHandler.Estado.AguardandoResposta then
                 jogadorVez:JogarTurno(numRodada, self.RoundManager.ViraAtual, self.RoundManager.CartasNaMesa, valorAtualizado, valorAtualizado)
            end
        end)
    end
end

function Partida:OnTrucoCorreu(equipeVencedora, valorAnterior)
    self.RoundManager.ValorRodada = valorAnterior
    self:FinalizarMao(equipeVencedora, valorAnterior)
end

function Partida:OnValorAtualizado(valor)
    self.RoundManager.ValorRodada = valor
end

function Partida:OnObterValorRodada()
    return self.RoundManager.ValorRodada
end

function Partida:EBot(entidade) return (entidade and typeof(entidade) == "table" and entidade.EBot == true) end
function Partida:ContarJogadores() local c = 0; for _ in pairs(self.Assentos) do c += 1 end; return c end
function Partida:ObterJogadorPorCadeira(nome) return self.Assentos[nome] end

function Partida:ObterHumanos()
    local t = {}
    for _, jog in pairs(self.Assentos) do 
        if not self:EBot(jog) then table.insert(t, jog) end 
    end
    return t
end

function Partida:ObterEquipe(jogador)
    for nomeAssento, jog in pairs(self.Assentos) do 
        if jog == jogador then 
            local n = tonumber(nomeAssento:match("%d+"))
            return (n % 2 == 1) and "A" or "B" 
        end 
    end
    return "A"
end

function Partida:ObterParceiro(jogador)
    local minhaEq = self:ObterEquipe(jogador); 
    for _, jog in pairs(self.Assentos) do 
        if jog ~= jogador and self:ObterEquipe(jog) == minhaEq then return jog end 
    end
    return nil
end

function Partida:ObterNomesEquipe(idEquipe)
    local nomes = {}
    for _, jog in pairs(self.Assentos) do
        if self:ObterEquipe(jog) == idEquipe then
            table.insert(nomes, self:EBot(jog) and jog.Nome or jog.Name)
        end
    end
    return #nomes > 0 and table.concat(nomes, " e ") or "Ninguém"
end

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
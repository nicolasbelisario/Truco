local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GerenciadorBaralho = require(script.Parent.Parent.Utils:WaitForChild("DeckManager"))
local GerenciadorRegras = require(script.Parent.Parent.Utils:WaitForChild("RuleManager"))
local EventBroadcaster = require(script.Parent:WaitForChild("EventBroadcaster"))

local RoundManager = {}
RoundManager.__index = RoundManager

function RoundManager.novo(ctx)
    local self = setmetatable({}, RoundManager)
    self.Ctx = ctx 
    self:ResetarEstado()
    return self
end

function RoundManager:ResetarEstado()
    self.BaralhoAtual = {}
    self.CartasNaMesa = {}
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.ViraAtual = nil
    self.ValorRodada = 1
    self.IndexDistribuidor = 1
    self.IndexTurnoAtual = 1
    self.MaosJogadores = {} 
end

function RoundManager:IniciarNovaRodada()
    local ctx = self.Ctx
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.CartasNaMesa = {}
    self.ValorRodada = 1
    self.MaosJogadores = {}
    
    ctx.TrucoHandler:Resetar()
    
    EventBroadcaster.ParaTodos(ctx.Assentos, "UPDATE_ROUND_VALUE", 1, ctx.VerificarBot)
    EventBroadcaster.ParaTodos(ctx.Assentos, "SHOW_TRUCO_BTN", 0, ctx.VerificarBot)
    
    self.BaralhoAtual = GerenciadorBaralho.CriarBaralho() 
    GerenciadorBaralho.Embaralhar(self.BaralhoAtual)
    
    ctx.Estado = "CUTTING"
    EventBroadcaster.ParaTodos(ctx.Assentos, "CUTTING", 0, ctx.VerificarBot) 
    
    local papeis = self:ObterPapeis()
    -- CORREÇÃO: Usando ":" no lugar de "."
    local jogadorCorte = ctx:ObterJogadorPorCadeira(papeis.Corte)
    
    if ctx:EBot(jogadorCorte) then 
        task.delay(1.5, function() self:CortarBaralho(jogadorCorte, 1) end)
    elseif jogadorCorte then 
        EventBroadcaster.PedirAcao(jogadorCorte, "EscolhaOCorte", 10) 
    end
    
    task.delay(11, function() 
        if ctx.Estado == "CUTTING" then self:DistribuirCartas() end 
    end)
end

function RoundManager:CortarBaralho(jogador, quantidade)
    local ctx = self.Ctx
    if ctx.Estado ~= "CUTTING" then return end
    
    local papeis = self:ObterPapeis()
    if ctx:ObterJogadorPorCadeira(papeis.Corte) == jogador then
        GerenciadorBaralho.Cortar(self.BaralhoAtual, quantidade)
        self:DistribuirCartas()
    end
end

function RoundManager:DistribuirCartas()
    local ctx = self.Ctx
    ctx.Estado = "DEALING"
    EventBroadcaster.ParaTodos(ctx.Assentos, "DEALING", 0, ctx.VerificarBot)
    
    self.ViraAtual = table.remove(self.BaralhoAtual, 1)
    
    for i = 1, 4 do
        local nomeAssento = "Cadeira"..i
        local jogador = ctx.Assentos[nomeAssento]
        local mao = {table.remove(self.BaralhoAtual,1), table.remove(self.BaralhoAtual,1), table.remove(self.BaralhoAtual,1)}
        local parceiro = ctx:ObterParceiro(jogador)
        local nomeParceiro = ctx:EBot(parceiro) and parceiro.Nome or (parceiro and parceiro.Name or "...")
        
        self.MaosJogadores[jogador] = {
            {Value = mao[1].Value, Suit = mao[1].Suit},
            {Value = mao[2].Value, Suit = mao[2].Suit},
            {Value = mao[3].Value, Suit = mao[3].Suit}
        }

        if ctx:EBot(jogador) then 
            jogador:ReceberMao(mao, self.ViraAtual)
        elseif jogador then 
            EventBroadcaster.DistribuirCartas(jogador, mao, self.ViraAtual, nomeParceiro)
        end
    end
    
    task.wait(1)
    ctx.Estado = "PLAYING"
    local papeis = self:ObterPapeis()
    self.IndexTurnoAtual = tonumber(papeis.Mao:match("%d+"))
    self:AvancarTurno()
end

function RoundManager:AvancarTurno()
    local ctx = self.Ctx
    local jogadorVez = ctx.Assentos["Cadeira"..self.IndexTurnoAtual]
    if not jogadorVez then return end
    
    local nomeVez = ctx:EBot(jogadorVez) and jogadorVez.Nome or jogadorVez.Name
    local numRodada = self.QuedasGanhas.TeamA + self.QuedasGanhas.TeamB + 1
    
    EventBroadcaster.AtualizarTurno(ctx:ObterHumanos(), nomeVez, numRodada)
    
    if ctx:EBot(jogadorVez) then 
        jogadorVez:JogarTurno(numRodada, self.ViraAtual, self.CartasNaMesa, self.ValorRodada, ctx.TrucoHandler.Estado.ValorAtual) 
    end
end

function RoundManager:JogarCarta(jogador, valor, naipe, escondida, skinUsada)
    local ctx = self.Ctx
    if ctx.TrucoHandler.Estado.AguardandoResposta or ctx.Estado ~= "PLAYING" then return end
    
    local jogadorVez = ctx.Assentos["Cadeira"..self.IndexTurnoAtual]
    if jogadorVez ~= jogador then return end 

    local cartaAutorizada = false
    local maoServidor = self.MaosJogadores[jogador]
    if maoServidor then
        for i, c in ipairs(maoServidor) do
            if c.Value == valor and c.Suit == naipe then
                cartaAutorizada = true
                table.remove(maoServidor, i)
                break
            end
        end
    end

    if not cartaAutorizada then
        warn("ANTICHEAT: O jogador " .. (jogador.Name or "Bot") .. " enviou uma carta inválida: " .. valor .. " de " .. naipe)
        return
    end

    local numRodada = self.QuedasGanhas.TeamA + self.QuedasGanhas.TeamB + 1
    if numRodada == 1 then escondida = false end 

    table.insert(self.CartasNaMesa, { Player = jogador, Value = valor, Suit = naipe, IsHidden = escondida, Skin = skinUsada })
    
    local nomeExibicao = ctx:EBot(jogador) and jogador.Nome or jogador.Name 
    EventBroadcaster.CartaJogada(ctx:ObterHumanos(), nomeExibicao, valor, naipe, escondida, skinUsada)
    
    if #self.CartasNaMesa >= 4 then
        task.wait(1.5)
        self:AvaliarQueda()
    else
        self.IndexTurnoAtual = (self.IndexTurnoAtual - 2) % 4 + 1
        self:AvancarTurno()
    end
end

function RoundManager:AvaliarQueda()
    local ctx = self.Ctx
    local vencedorObj = GerenciadorRegras.ObterVencedorRodada(self.CartasNaMesa, self.ViraAtual.Value)
    local equipeVencedora = nil
    
    if vencedorObj == "DRAW" then
        local primeiroJogar = self.CartasNaMesa[1].Player
        equipeVencedora = ctx:ObterEquipe(primeiroJogar)
        self:DefinirVezParaJogador(primeiroJogar)
    else
        equipeVencedora = ctx:ObterEquipe(vencedorObj)
        self:DefinirVezParaJogador(vencedorObj)
    end
    
    self.QuedasGanhas["Team"..equipeVencedora] += 1
    self.CartasNaMesa = {} 
    
    EventBroadcaster.ParaTodos(ctx.Assentos, "CLEAR_TABLE", {TeamA = self.QuedasGanhas.TeamA, TeamB = self.QuedasGanhas.TeamB}, ctx.VerificarBot)
    
    if self.QuedasGanhas["Team"..equipeVencedora] >= 2 then 
        ctx:FinalizarMao(equipeVencedora, self.ValorRodada)
    else 
        task.wait(1)
        self:AvancarTurno() 
    end
end

function RoundManager:ObterPapeis()
    local d = self.IndexDistribuidor
    local c = (d % 4) + 1
    local m = (d - 2) % 4 + 1
    if m <= 0 then m = m + 4 end
    return { Dealer="Cadeira"..d, Corte="Cadeira"..c, Mao="Cadeira"..m }
end

function RoundManager:DefinirVezParaJogador(jogador)
    for nomeAssento, jog in pairs(self.Ctx.Assentos) do 
        if jog == jogador then 
            self.IndexTurnoAtual = tonumber(nomeAssento:match("%d+"))
            break 
        end 
    end
end

return RoundManager
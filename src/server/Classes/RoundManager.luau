local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GerenciadorBaralho = require(script.Parent.Parent.Utils:WaitForChild("DeckManager"))
local GerenciadorRegras = require(script.Parent.Parent.Utils:WaitForChild("RuleManager"))
local EventBroadcaster = require(script.Parent:WaitForChild("EventBroadcaster"))

local RoundManager = {}
RoundManager.__index = RoundManager

--[[
    Instancia um novo gerenciador de rodadas (Mãos) de Truco.
    @param ctx table: Contexto da Partida (Match).
    @return table: Nova instância do RoundManager.
]]
function RoundManager.novo(ctx)
    local self = setmetatable({}, RoundManager)
    self.Ctx = ctx 
    self:ResetarEstado()
    return self
end

--[[
    Redefine as variáveis internas da rodada para o estado zero,
    usado no fim da partida ou quando o estado precisa ser limpo completamente.
]]
function RoundManager:ResetarEstado()
    self.BaralhoAtual = {}
    self.CartasNaMesa = {}
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.HistoricoQuedas = {}
    self.ViraAtual = nil
    self.ValorRodada = 1
    self.IndexDistribuidor = 1
    self.IndexTurnoAtual = 1
    self.MaosJogadores = {} 
end

--[[
    Inicia uma nova "Mão" (rodada valendo pontos no placar).
    Limpa o estado da rodada, gera um novo baralho, embaralha e define
    quem é o responsável por realizar o corte do baralho (Cutting).
]]
function RoundManager:IniciarNovaRodada()
    local ctx = self.Ctx
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.HistoricoQuedas = {}
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

--[[
    Aplica o corte no baralho caso o jogador que solicitou o corte seja 
    realmente o jogador definido como "Cortador" na rodada atual.
    @param jogador Player/Bot: Quem enviou a ação de corte.
    @param quantidade number: O tipo de corte escolhido.
]]
function RoundManager:CortarBaralho(jogador, quantidade)
    local ctx = self.Ctx
    if ctx.Estado ~= "CUTTING" then return end
    
    local papeis = self:ObterPapeis()
    if ctx:ObterJogadorPorCadeira(papeis.Corte) == jogador then
        GerenciadorBaralho.Cortar(self.BaralhoAtual, quantidade)
        self:DistribuirCartas()
    end
end

--[[
    Remove as cartas do topo do baralho e distribui 3 para cada um dos
    4 jogadores na mesa. Em seguida, vira a carta do meio (O Vira)
    e avança para o início das jogadas (PLAYING).
]]
function RoundManager:DistribuirCartas()
    local ctx = self.Ctx
    ctx.Estado = "DEALING"
    EventBroadcaster.ParaTodos(ctx.Assentos, "DEALING", 0, ctx.VerificarBot)
    
    -- Pega a vira e DEFINE AS MANILHAS para o resto do baralho
    self.ViraAtual = table.remove(self.BaralhoAtual, 1)
    GerenciadorBaralho.DefinirManilhas(self.BaralhoAtual, self.ViraAtual)

    for i = 1, 4 do
        local nomeAssento = "Cadeira"..i
        local jogador = ctx.Assentos[nomeAssento]
        
        -- Distribui as 3 cartas completas para a mão do jogador
        local mao = {table.remove(self.BaralhoAtual, 1), table.remove(self.BaralhoAtual, 1), table.remove(self.BaralhoAtual, 1)}
        self.MaosJogadores[jogador] = mao -- Armazena os objetos de carta completos

        local parceiro = ctx:ObterParceiro(jogador)
        local nomeParceiro = ctx:EBot(parceiro) and parceiro.Nome or (parceiro and parceiro.Name or "...")
        
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

--[[
    Avança a rodada para o próximo jogador (turno), informando aos clientes
    de quem é a vez e engatilhando o bot se for a vez de um.
]]
function RoundManager:AvancarTurno()
    local ctx = self.Ctx
    local jogadorVez = ctx.Assentos["Cadeira"..self.IndexTurnoAtual]
    if not jogadorVez then return end
    
    local nomeVez = ctx:EBot(jogadorVez) and jogadorVez.Nome or jogadorVez.Name
    local numRodada = #self.HistoricoQuedas + 1
    
    EventBroadcaster.AtualizarTurno(ctx:ObterHumanos(), nomeVez, numRodada)
    
    if ctx:EBot(jogadorVez) then 
        jogadorVez:JogarTurno(numRodada, self.ViraAtual, self.CartasNaMesa, self.ValorRodada, ctx.TrucoHandler.Estado.ValorAtual) 
    end
end

--[[
    Recebe e valida a tentativa de um jogador (ou Bot) de jogar uma carta na mesa.
    Verifica se a carta está realmente na mão do jogador (Anti-Cheat).
    Se for a 4ª carta da mesa, aciona a avaliação de quem venceu a queda.
    @param jogador Player/Bot: O jogador que está jogando a carta.
    @param cardId string: O ID único da carta jogada (ex: "Q_Copas").
    @param escondida boolean: Se o jogador decidiu jogar a carta virada para baixo.
    @param skinUsada string: A skin cosmética equipada pelo jogador.
]]
function RoundManager:JogarCarta(jogador, cardId, escondida, skinUsada)
    local ctx = self.Ctx
    if ctx.TrucoHandler.Estado.AguardandoResposta or ctx.Estado ~= "PLAYING" then return end
    
    local jogadorVez = ctx.Assentos["Cadeira"..self.IndexTurnoAtual]
    if jogadorVez ~= jogador then return end 

    local cartaJogada = nil
    local maoServidor = self.MaosJogadores[jogador]
    if maoServidor then
        for i, c in ipairs(maoServidor) do
            if c.idUnico == cardId then
                cartaJogada = table.remove(maoServidor, i)
                break
            end
        end
    end

    if not cartaJogada then
        warn("ANTICHEAT: O jogador " .. (jogador.Name or "Bot") .. " enviou uma carta inválida: " .. cardId)
        return
    end

    local numRodada = #self.HistoricoQuedas + 1
    if numRodada == 1 then escondida = false end 
    
    -- Insere o objeto da carta completo na mesa, com informações adicionais
    table.insert(self.CartasNaMesa, {
        Player = jogador, 
        Value = cartaJogada.Value, 
        Suit = cartaJogada.Suit,
        Strength = cartaJogada.Strength,
        ManilhaStrength = cartaJogada.ManilhaStrength,
        IsHidden = escondida, 
        Skin = skinUsada 
    })
    
    local nomeExibicao = ctx:EBot(jogador) and jogador.Nome or jogador.Name 
    EventBroadcaster.CartaJogada(ctx:ObterHumanos(), nomeExibicao, cartaJogada.Value, cartaJogada.Suit, escondida, skinUsada)
    
    if #self.CartasNaMesa >= 4 then
        task.wait(1.5)
        self:AvaliarQueda()
    else
        self.IndexTurnoAtual = (self.IndexTurnoAtual - 2) % 4 + 1
        self:AvancarTurno()
    end
end

--[[
    Analisa as 4 cartas jogadas na mesa em uma queda e determina o vencedor
    baseado na força das cartas. Adiciona o resultado ao histórico e, se
    uma equipe vencer 2 quedas (ou pela regra de desempate da canga), finaliza a mão.
]]
function RoundManager:AvaliarQueda()
    local ctx = self.Ctx
    local vencedorObj = GerenciadorRegras.ObterVencedorRodada(self.CartasNaMesa)
    local equipeVencedora = nil
    
    if vencedorObj == "DRAW" then
        local primeiroJogar = self.CartasNaMesa[1].Player
        equipeVencedora = "DRAW"
        self:DefinirVezParaJogador(primeiroJogar)
    else
        equipeVencedora = ctx:ObterEquipe(vencedorObj)
        self:DefinirVezParaJogador(vencedorObj)
    end
    
    table.insert(self.HistoricoQuedas, equipeVencedora)
    
    if equipeVencedora ~= "DRAW" then
        self.QuedasGanhas["Team"..equipeVencedora] += 1
    end
    
    self.CartasNaMesa = {} 
    
    EventBroadcaster.ParaTodos(ctx.Assentos, "CLEAR_TABLE", {TeamA = self.QuedasGanhas.TeamA, TeamB = self.QuedasGanhas.TeamB}, ctx.VerificarBot)
    
    local vencedorMao = nil
    local q1, q2, q3 = self.HistoricoQuedas[1], self.HistoricoQuedas[2], self.HistoricoQuedas[3]
    
    -- Lógica para determinar o vencedor da mão (melhor de 3 quedas)
    if self.QuedasGanhas.TeamA >= 2 then
        vencedorMao = "A"
    elseif self.QuedasGanhas.TeamB >= 2 then
        vencedorMao = "B"
    elseif q1 == "DRAW" then
        if q2 == "A" then vencedorMao = "A"
        elseif q2 == "B" then vencedorMao = "B"
        elseif q2 == "DRAW" then
            if q3 == "A" then vencedorMao = "A"
            elseif q3 == "B" then vencedorMao = "B"
            elseif q3 == "DRAW" then vencedorMao = "DRAW" end
        end
    elseif (q1 == "A" and q2 == "B" and q3 == "A") or (q1=="A" and q2=="DRAW" and (q3=="A" or q3=="DRAW")) then
        vencedorMao = "A"
    elseif (q1 == "B" and q2 == "A" and q3 == "B") or (q1=="B" and q2=="DRAW" and (q3=="B" or q3=="DRAW")) then
		vencedorMao = "B"
	end
    
    if vencedorMao then 
        ctx:FinalizarMao(vencedorMao, self.ValorRodada)
    else 
        task.wait(1)
        self:AvancarTurno() 
    end
end

--[[
    Calcula as posições na mesa para determinar quem é o Distribuidor (Dealer),
    quem Corta o baralho (próximo à direita) e quem joga a primeira carta (o Pé/Mão).
    @return table: Dicionário contendo os nomes das cadeiras correspondentes aos papéis.
]]
function RoundManager:ObterPapeis()
    local d = self.IndexDistribuidor
    local c = (d % 4) + 1
    local m = (d - 2) % 4 + 1
    if m <= 0 then m = m + 4 end
    return { Dealer="Cadeira"..d, Corte="Cadeira"..c, Mao="Cadeira"..m }
end

--[[
    Altera o índice de turno para corresponder ao assento (cadeira)
    do jogador especificado, para que ele inicie a próxima rodada/jogada.
    @param jogador Player/Bot: O jogador que deve receber a vez.
]]
function RoundManager:DefinirVezParaJogador(jogador)
    for nomeAssento, jog in pairs(self.Ctx.Assentos) do 
        if jog == jogador then 
            self.IndexTurnoAtual = tonumber(nomeAssento:match("%d+"))
            break 
        end 
    end
end

-------------------------------------------------------------------
-- MÃO DE ONZE / MÃO DE FERRO
-------------------------------------------------------------------

--[[
    Inicia a rodada especial de Mão de Onze.
    A rodada vale 3 pontos e a equipe com 11 pontos deve decidir se joga ou corre.
    @param equipeOnze string: A equipe que está com 11 pontos ("A" ou "B").
]]
function RoundManager:IniciarMaoDeOnze(equipeOnze)
    local ctx = self.Ctx
    self:limparParaNovaRodada(3) -- Limpa o estado e já define que a mão vale 3
    ctx.TrucoHandler:SetTrucoAtivo(false) -- Desativa Truco na Mão de Onze

    -- Prepara o baralho e distribui as cartas para o estado interno
    self:prepararBaralhoEDistribuirInternamente()

    ctx.Estado = "ELEVEN_DECISION"
    
    -- Monta a lista de jogadores da equipe que vai decidir
    local equipeDecisao = {}
    for _, p in pairs(ctx.Assentos) do
        if ctx:ObterEquipe(p) == equipeOnze then
            table.insert(equipeDecisao, p)
        end
    end

    -- Envia para a equipe a notificação para decidir, incluindo as cartas do parceiro
    for _, jogador in ipairs(equipeDecisao) do
        local parceiro = ctx:ObterParceiro(jogador)
        local maoParceiro = self.MaosJogadores[parceiro]
        
        if ctx:EBot(jogador) then
            -- Lógica para o Bot decidir
            task.delay(2, function()
                jogador:DecidirMaoDeOnze(maoParceiro)
            end)
        else
            EventBroadcaster.ParaJogador(jogador, "SHOW_ELEVEN_DECISION", maoParceiro, ctx.VerificarBot)
        end
    end
end

--[[
    Processa a decisão de jogar ou correr da Mão de Onze.
    @param jogador Player/Bot: O jogador que fez a decisão.
    @param decisao string: "JOGAR" ou "CORRER".
]]
function RoundManager:DecidirMaoDeOnze(jogador, decisao)
    local ctx = self.Ctx
    if ctx.Estado ~= "ELEVEN_DECISION" then return end

    local equipeJogador = ctx:ObterEquipe(jogador)
    local equipeOponente = (equipeJogador == "A") and "B" or "A"

    if decisao == "CORRER" then
        -- A equipe correu, oponente ganha 1 ponto.
        ctx:FinalizarMao(equipeOponente, 1)
    elseif decisao == "JOGAR" then
        -- A equipe aceitou jogar, a rodada começa valendo 3 pontos.
        self:iniciarTurnosPosDistribuicao()
    end
    EventBroadcaster.ParaTodos(ctx.Assentos, "HIDE_ELEVEN_DECISION", nil, ctx.VerificarBot)
end

--[[
    Inicia a Mão de Ferro (ambas as equipes com 11 pontos).
    A rodada é jogada no escuro e vale 3 pontos. Truco é desativado.
]]
function RoundManager:IniciarMaoDeFerro()
    local ctx = self.Ctx
    self:limparParaNovaRodada(3) -- Limpa o estado e já define que a mão vale 3
    ctx.TrucoHandler:SetTrucoAtivo(false) -- Desativa Truco na Mão de Ferro

    self:prepararBaralhoEDistribuirInternamente()
    self:iniciarTurnosPosDistribuicao()
end


-------------------------------------------------------------------
-- FUNÇÕES AUXILIARES REATORADAS
-------------------------------------------------------------------

-- Função auxiliar para limpar o estado para uma nova rodada
function RoundManager:limparParaNovaRodada(valor)
    self.QuedasGanhas = { TeamA = 0, TeamB = 0 }
    self.HistoricoQuedas = {}
    self.CartasNaMesa = {}
    self.ValorRodada = valor or 1
    self.MaosJogadores = {}
    
    self.Ctx.TrucoHandler:Resetar()
    EventBroadcaster.ParaTodos(self.Ctx.Assentos, "UPDATE_ROUND_VALUE", self.ValorRodada, self.Ctx.VerificarBot)
end

-- Função auxiliar para preparar e distribuir as cartas internamente
function RoundManager:prepararBaralhoEDistribuirInternamente()
    local ctx = self.Ctx
    self.BaralhoAtual = GerenciadorBaralho.CriarBaralho() 
    GerenciadorBaralho.Embaralhar(self.BaralhoAtual)
    
    -- Simula o corte para remover cartas se necessário, mas sem interação
    GerenciadorBaralho.Cortar(self.BaralhoAtual, 1)
    
    ctx.Estado = "DEALING"
    EventBroadcaster.ParaTodos(ctx.Assentos, "DEALING", 0, ctx.VerificarBot)
    
    self.ViraAtual = table.remove(self.BaralhoAtual, 1)
    GerenciadorBaralho.DefinirManilhas(self.BaralhoAtual, self.ViraAtual)
    
    for i = 1, 4 do
        local nomeAssento = "Cadeira"..i
        local jogador = ctx.Assentos[nomeAssento]
        local mao = {table.remove(self.BaralhoAtual, 1), table.remove(self.BaralhoAtual, 1), table.remove(self.BaralhoAtual, 1)}
        self.MaosJogadores[jogador] = mao
    end
end

-- Função auxiliar para notificar clientes e iniciar os turnos
function RoundManager:iniciarTurnosPosDistribuicao()
    local ctx = self.Ctx
    
    -- Notifica cada jogador de suas cartas
    for i = 1, 4 do
        local nomeAssento = "Cadeira"..i
        local jogador = ctx.Assentos[nomeAssento]
        local mao = self.MaosJogadores[jogador]
        local parceiro = ctx:ObterParceiro(jogador)
        local nomeParceiro = ctx:EBot(parceiro) and parceiro.Nome or (parceiro and parceiro.Name or "...")
        
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

return RoundManager
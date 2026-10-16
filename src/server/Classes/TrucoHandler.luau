local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventBroadcaster = require(script.Parent.EventBroadcaster)
local GameRulesConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("GameRulesConfig"))

local TrucoHandler = {}

TrucoHandler.__index = TrucoHandler

--[[
    Instancia um novo gerenciador de Truco (desafios de pontos).
    @param ctx table: O contexto da partida atual (instância da Match).
    @return table: A nova instância de TrucoHandler.
]]
function TrucoHandler.novo(ctx)
    local self = setmetatable({}, TrucoHandler)
    self.Ctx = ctx
    self:Resetar()
    return self
end

--[[
    Redefine o estado do desafio de Truco para os valores padrão,
    usado quando uma nova rodada começa.
]]
function TrucoHandler:Resetar()
    self.Estado = {
        ValorAtual = 1, ValorPendente = 0, EquipePediu = nil,
        AguardandoResposta = false, IDDesafio = 0, Votos = {}
    }
    self.TrucoAtivo = true -- Permite Truco por padrão
end

--[[
    Ativa ou desativa a possibilidade de pedir Truco na rodada.
    Usado para Mão de Onze e Mão de Ferro.
    @param ativo boolean: Se o truco deve estar ativo (true) ou não (false).
]]
function TrucoHandler:SetTrucoAtivo(ativo)
    self.TrucoAtivo = ativo
    if not ativo then
        EventBroadcaster.ParaTodos(self.Ctx.Assentos, "HIDE_TRUCO_BTN", 0, self.Ctx.VerificarBot)
    end
end

--[[
    Processa um pedido de Truco vindo de um jogador. Verifica se é válido e 
    transmite o desafio para a equipe adversária.
    @param jogador Player/Bot: O jogador que está pedindo Truco.
]]
function TrucoHandler:ProcessarRequest(jogador)
    if not self.TrucoAtivo then return end -- Mão de Onze/Ferro não tem truco

    local ctx = self.Ctx
    local minha = ctx:ObterEquipe(jogador)
    if self.Estado.AguardandoResposta or self.Estado.EquipePediu == minha then return end

    local prox = (self.Estado.ValorAtual == 1) and 3 or (self.Estado.ValorAtual + 3)
    if prox > 12 then return end

    self.Estado.AguardandoResposta = true
    self.Estado.EquipePediu = minha
    self.Estado.ValorPendente = prox
    self.Estado.Votos = {}
    self.Estado.IDDesafio += 1

    EventBroadcaster.ParaTodos(ctx.Assentos, "TRUCO_CALLED", prox, ctx.VerificarBot)
    self:_PedirResposta((minha == "A") and "B" or "A", prox, jogador)
end

--[[
    Processa a resposta de um jogador ao desafio de Truco.
    Pode ser "Aceitar", "Correr" ou "Aumentar".
    Se houver um parceiro humano, aguarda a resposta do parceiro para tomar a decisão se os votos combinarem.
    @param jogador Player/Bot: O jogador que está respondendo.
    @param subAcao string: A decisão do jogador ("Aceitar", "Correr", "Aumentar").
]]
function TrucoHandler:ProcessarResponse(jogador, subAcao)
    if not self.Estado.AguardandoResposta then return end
    local ctx = self.Ctx
    local minha = ctx:ObterEquipe(jogador)
    if minha == self.Estado.EquipePediu then return end

    self.Estado.Votos[jogador] = subAcao
    local parceiro = ctx:ObterParceiro(jogador)

    local function executar(decisao)
        if decisao == "Aceitar" then
            self:_Resolver(true, false)
        elseif decisao == "Correr" then
            self:_Resolver(false, true)
        elseif decisao == "Aumentar" then
            self.Estado.ValorAtual = self.Estado.ValorPendente
            ctx:OnValorAtualizado(self.Estado.ValorAtual)
            local prox = math.min(self.Estado.ValorAtual + 3, 12)
            self.Estado.EquipePediu = minha
            self.Estado.ValorPendente = prox
            self.Estado.Votos = {}
            self.Estado.IDDesafio += 1
            EventBroadcaster.ParaTodos(ctx.Assentos, "TRUCO_CALLED", prox, ctx.VerificarBot)
            self:_PedirResposta((minha == "A") and "B" or "A", prox, jogador)
        end
    end

    if ctx:EBot(parceiro) or not parceiro then
        executar(subAcao)
        return
    end

    local votoParceiro = self.Estado.Votos[parceiro]
    EventBroadcaster.ParaJogador(parceiro, "PARTNER_VOTED", subAcao, ctx.VerificarBot)
    EventBroadcaster.ParaJogador(jogador, "WAITING_PARTNER", 0, ctx.VerificarBot)
    if votoParceiro == subAcao then executar(subAcao) end
end

--[[
    Resolve internamente o fim do desafio de Truco, notificando a partida sobre o desfecho
    e aplicando as consequências (atualizar valor ou finalizar rodada se correram).
    @param aceitou boolean: Se a equipe alvo aceitou o Truco.
    @param correu boolean: Se a equipe alvo correu/fugiu do Truco.
]]
function TrucoHandler:_Resolver(aceitou, correu)
    local ctx = self.Ctx
    self.Estado.AguardandoResposta = false
    self.Estado.IDDesafio += 1
    EventBroadcaster.ParaTodos(ctx.Assentos, "HIDE_TRUCO_BTN", 0, ctx.VerificarBot)

    if correu then
        local venc = self.Estado.EquipePediu
        local fug  = (venc == "A") and "B" or "A"
        EventBroadcaster.ParaTodos(ctx.Assentos, "TRUCO_FUGIU", ctx:ObterNomesEquipe(fug), ctx.VerificarBot)
        task.wait(2)
        ctx:OnTrucoCorreu(venc, self.Estado.ValorAtual)
    elseif aceitou then
        self.Estado.ValorAtual = self.Estado.ValorPendente
        ctx:OnTrucoAceito(self.Estado.ValorAtual, self.Estado.EquipePediu)
        EventBroadcaster.ParaTodos(ctx.Assentos, "TRUCO_ACEITO", self.Estado.ValorAtual, ctx.VerificarBot)
    end
end

--[[
    Função interna para disparar a solicitação visual de resposta ao Truco para a equipe desafiada.
    Também gerencia o timeout de resposta (tempo esgotado faz a equipe correr).
    @param equipeAlvo string: A equipe que está sendo desafiada ("A" ou "B").
    @param valor number: O valor do Truco que está sendo pedido.
    @param quemPediu Player/Bot: O jogador que gritou o Truco.
]]
function TrucoHandler:_PedirResposta(equipeAlvo, valor, quemPediu)
    local ctx = self.Ctx
    local idAtual = self.Estado.IDDesafio
    local TEMPO = GameRulesConfig.Tempos.LimiteRespostaTruco


    task.delay(TEMPO, function()
        if self.Estado.AguardandoResposta and self.Estado.IDDesafio == idAtual then
            EventBroadcaster.ParaTodos(ctx.Assentos, "TRUCO_TIMEOUT", 0, ctx.VerificarBot)
            self:_Resolver(false, true)
        end
    end)

    local temHumano = false
    for _, jog in pairs(ctx.Assentos) do
        if not ctx:EBot(jog) and ctx:ObterEquipe(jog) == equipeAlvo then
            temHumano = true; break
        end
    end

    for _, jog in pairs(ctx.Assentos) do
        if ctx:EBot(jog) then
            if ctx:ObterEquipe(jog) == equipeAlvo and not temHumano then
                task.delay(math.random(1, 3), function()
                    jog:DecidirTruco(valor, ctx:OnObterValorRodada())
                end)
            end
        elseif ctx:ObterEquipe(jog) == equipeAlvo then
            local nomeExib = ctx:EBot(quemPediu) and quemPediu.Nome or quemPediu.Name
            EventBroadcaster.PedirAcao(jog, "TrucoChallenge", {Value = valor, Caller = nomeExib, TimeLimit = TEMPO})
        else
            EventBroadcaster.ParaJogador(jog, "HIDE_TRUCO_BTN", nil, ctx.VerificarBot)
        end
    end
end

return TrucoHandler
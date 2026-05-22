local EventBroadcaster = require(script.Parent.EventBroadcaster)

local TrucoHandler = {}
TrucoHandler.__index = TrucoHandler

function TrucoHandler.novo(ctx)
    local self = setmetatable({}, TrucoHandler)
    self.Ctx = ctx
    self:Resetar()
    return self
end

function TrucoHandler:Resetar()
    self.Estado = {
        ValorAtual = 1, ValorPendente = 0, EquipePediu = nil,
        AguardandoResposta = false, IDDesafio = 0, Votos = {}
    }
end

function TrucoHandler:ProcessarRequest(jogador)
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

function TrucoHandler:_PedirResposta(equipeAlvo, valor, quemPediu)
    local ctx = self.Ctx
    local idAtual = self.Estado.IDDesafio
    local TEMPO = 15

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
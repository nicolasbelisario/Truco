local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataManager = require(script.Parent.DataManager)

local RobuxManager = {} -- Criando a tabela do módulo

-- (O) Aberto: adicionar novos produtos só nesta tabela
local PRODUTOS_PONTOS = { [3554291316]=100, [3554291580]=500 }
local DOACOES         = { [3549774213]=true, [3549774425]=true }

MarketplaceService.ProcessReceipt = function(info)
    local jogador = Players:GetPlayerByUserId(info.PlayerId)
    if not jogador then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local pts = PRODUTOS_PONTOS[info.ProductId]
    if pts then
        DataManager.AdicionarPontos(jogador, pts)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    if DOACOES[info.ProductId] then
        print("Doação recebida de " .. jogador.Name)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

return RobuxManager -- OBRIGATÓRIO: Retornando o módulo no final!
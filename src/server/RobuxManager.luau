local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataManager = require(script.Parent.DataManager)
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("EconomyConfig"))

local RobuxManager = {}

local PRODUTOS_PONTOS = EconomyConfig.ProdutosPontosMap
local DOACOES         = EconomyConfig.DoacoesMap


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
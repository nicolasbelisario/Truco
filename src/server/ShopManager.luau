local Eventos = game.ReplicatedStorage:WaitForChild("Events")
local DataManager = require(script.Parent.DataManager)

local ShopManager = {}

-- (O) Aberto para adicionar skins sem modificar a lógica de compra
local PRECOS = { ["Padrao"]=0, ["Rosa"]=200, ["Nacional"]=300, ["Estrela"]=300 }

Eventos.ShopActionEvent.OnServerEvent:Connect(function(jogador, acao, idSkin)
    local dados = DataManager.ObterDados(jogador)
    if not dados then return end

    if acao == "Comprar" then
        local preco = PRECOS[idSkin]
        if preco and dados.Pontos >= preco and not table.find(dados.SkinsCompradas, idSkin) then
            DataManager.AdicionarPontos(jogador, -preco)
            table.insert(dados.SkinsCompradas, idSkin)
            DataManager.Sincronizar(jogador)
        end

    elseif acao == "Equipar" then
        if table.find(dados.SkinsCompradas, idSkin) then
            dados.SkinEquipada = idSkin
            DataManager.Sincronizar(jogador)
        end
    end
end)

return ShopManager
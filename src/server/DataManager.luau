local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Eventos = ReplicatedStorage:WaitForChild("Events")

-- Cria o banco de dados
local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")

local DataManager = {}
local dadosSessao = {} -- Armazena os dados dos jogadores online
local salvandoSessao = {} -- Trava para evitar duplo salvamento no Studio

-- Estrutura inicial para um jogador novo
local DADOS_PADRAO = {
    Pontos = 0,
    SkinsCompradas = {"Padrao"}, 
    SkinEquipada = "Padrao"
}

-- [MÉTODO] Carrega os dados quando o jogador entra no servidor
function DataManager.CarregarDados(jogador)
    local sucesso, dadosSalvos = pcall(function()
        return TrucoDataStore:GetAsync(jogador.UserId)
    end)

    if sucesso then
        if dadosSalvos then
            dadosSessao[jogador] = dadosSalvos
        else
            -- É a primeira vez do jogador no jogo!
            dadosSessao[jogador] = {
                Pontos = DADOS_PADRAO.Pontos,
                SkinsCompradas = {table.unpack(DADOS_PADRAO.SkinsCompradas)},
                SkinEquipada = DADOS_PADRAO.SkinEquipada
            }
        end
        print("Dados carregados para:", jogador.Name)

        -- ===================================================
        -- CRIAÇÃO DO PLACAR VISUAL DO ROBLOX (LEADERSTATS)
        -- ===================================================
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats" -- Esse nome precisa ser exato para o Roblox reconhecer
        leaderstats.Parent = jogador

        local pontosVisual = Instance.new("IntValue")
        pontosVisual.Name = "Pontos" -- Nome da coluna que aparece na tela
        pontosVisual.Value = dadosSessao[jogador].Pontos -- Inicia com os pontos salvos
        pontosVisual.Parent = leaderstats
        -- ===================================================

        DataManager.SincronizarComCliente(jogador)
    else
        warn("Erro ao carregar dados de " .. jogador.Name)
    end
end

-- [MÉTODO] Salva os dados quando o jogador sai
function DataManager.SalvarDados(jogador)
    if salvandoSessao[jogador] then return end
    salvandoSessao[jogador] = true
    
    local dados = dadosSessao[jogador]
    if dados then
        local sucesso, erro = pcall(function()
            TrucoDataStore:SetAsync(jogador.UserId, dados)
        end)
        
        if sucesso then
            print("Dados salvos com sucesso para:", jogador.Name)
        else
            warn("Erro ao salvar dados de " .. jogador.Name .. ": " .. tostring(erro))
        end
        
        dadosSessao[jogador] = nil 
    end
end

-- [MÉTODO] Atualiza o cliente sobre seus dados
function DataManager.SincronizarComCliente(jogador)
    local dados = dadosSessao[jogador]
    if dados then
        Eventos.SyncDataEvent:FireClient(jogador, dados)
    end
end

-- [MÉTODO] Adiciona pontos a um jogador
function DataManager.AdicionarPontos(jogador, quantidade)
    local dados = dadosSessao[jogador]
    if dados then
        dados.Pontos += quantidade
        DataManager.SincronizarComCliente(jogador) 

        -- ===================================================
        -- ATUALIZA O PLACAR VISUAL (LEADERSTATS) NA HORA
        -- ===================================================
        local leaderstats = jogador:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Pontos") then
            leaderstats.Pontos.Value = dados.Pontos
        end
        -- ===================================================
    end
end

-- [MÉTODO] Retorna qual skin o jogador está usando agora
function DataManager.ObterSkinEquipada(jogador)
    local dados = dadosSessao[jogador]
    if dados then
        return dados.SkinEquipada
    end
    return "Padrao"
end

-- ========================================================
-- SISTEMA DE LOJA (COMPRAS E EQUIPAMENTOS)
-- ========================================================

-- Tabela de preços oficial do Servidor (Segurança contra hacks)
local PRECOS_SKINS = {
    ["Padrao"] = 0,
    ["Rosa"] = 200,
    ["Nacional"] = 300,
    ["Estrela"] = 300,
}

Eventos.ShopActionEvent.OnServerEvent:Connect(function(jogador, acao, idSkin)
    local dados = dadosSessao[jogador]
    if not dados then return end

    if acao == "Comprar" then
        local preco = PRECOS_SKINS[idSkin]
        
        -- Checa se a skin existe, se tem pontos e se JÁ NÃO TEM a skin
        if preco and dados.Pontos >= preco and not table.find(dados.SkinsCompradas, idSkin) then
            dados.Pontos -= preco
            table.insert(dados.SkinsCompradas, idSkin)
            print(jogador.Name .. " comprou a skin: " .. idSkin)
            
            -- Atualiza o placar nativo
            local leaderstats = jogador:FindFirstChild("leaderstats")
            if leaderstats and leaderstats:FindFirstChild("Pontos") then
                leaderstats.Pontos.Value = dados.Pontos
            end
            
            DataManager.SincronizarComCliente(jogador)
            
            -- Opcional: Tocar um som de compra (Ka-Ching) no cliente seria legal!
        end
        
    elseif acao == "Equipar" then
        -- Só equipa se ele realmente possuir a skin
        if table.find(dados.SkinsCompradas, idSkin) then
            dados.SkinEquipada = idSkin
            print(jogador.Name .. " equipou a skin: " .. idSkin)
            DataManager.SincronizarComCliente(jogador)
        end
    end
end)

-- ========================================================
-- PAINEL ADMIN (SÓ PARA O DESENVOLVEDOR)
-- ========================================================
local NOME_ADMIN = "Nick0369me" -- Seu nick exato no Roblox

Eventos:WaitForChild("AdminActionEvent").OnServerEvent:Connect(function(jogadorLogado, acao, alvoNome, quantidadeStr)
    -- Trava de segurança absoluta: Se não for você, ignora!
    if jogadorLogado.Name ~= NOME_ADMIN then return end

    local jogadorAlvo = Players:FindFirstChild(alvoNome)
    if not jogadorAlvo then return end

    local quantidade = tonumber(quantidadeStr) or 0

    if acao == "Adicionar" then
        DataManager.AdicionarPontos(jogadorAlvo, quantidade)
        print("ADMIN: Deu " .. quantidade .. " pontos para " .. alvoNome)
    elseif acao == "Remover" then
        DataManager.AdicionarPontos(jogadorAlvo, -quantidade)
        print("ADMIN: Tirou " .. quantidade .. " pontos de " .. alvoNome)
    end
end)


-- ========================================================
-- SISTEMA DE COMPRAS COM ROBUX (PROCESSAMENTO DE RECIBOS)
-- ========================================================

-- Mapeamento: [ID do Produto de Desenvolvedor] = Quantidade de Pontos que o jogador ganha
local PRODUTOS_DE_PONTOS = {
    [3554291316] = 100, -- Substitua pelo ID real do pacote de 100 pontos
    [3554291580] = 500, -- Substitua pelo ID real do pacote de 500 pontos
}

-- IDs das doações (só precisamos saber para confirmar a compra e agradecer)
local IDs_DOACOES = {
    [3549774213] = true,
    [3549774425] = true,
}

MarketplaceService.ProcessReceipt = function(infoRecibo)
    -- Descobre quem fez a compra
    local jogador = Players:GetPlayerByUserId(infoRecibo.PlayerId)
    
    if not jogador then
        -- Se o jogador saiu do jogo antes da compra terminar, manda o Roblox tentar de novo depois
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local idProduto = infoRecibo.ProductId

    -- 1. Verifica se foi um pacote de Pontos
    local pontosParaDar = PRODUTOS_DE_PONTOS[idProduto]
    if pontosParaDar then
        DataManager.AdicionarPontos(jogador, pontosParaDar)
        print("Sucesso! " .. jogador.Name .. " comprou " .. pontosParaDar .. " pontos com Robux.")
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- 2. Verifica se foi uma Doação
    if IDs_DOACOES[idProduto] then
        print("Sucesso! " .. jogador.Name .. " fez uma doação. Muito obrigado!")
        -- Aqui você poderia dar um emblema, soltar fogos de artifício, etc.
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- Se chegou aqui, o ID não está cadastrado em lugar nenhum
    warn("Produto não reconhecido comprado: " .. tostring(idProduto))
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Conexões automáticas de entrada e saída
Players.PlayerAdded:Connect(DataManager.CarregarDados)
Players.PlayerRemoving:Connect(DataManager.SalvarDados)

-- Segurança: Salva todos se o servidor desligar de repente
game:BindToClose(function()
    for _, jogador in ipairs(Players:GetPlayers()) do
        DataManager.SalvarDados(jogador)
    end
end)

return DataManager
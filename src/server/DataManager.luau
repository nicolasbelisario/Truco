local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
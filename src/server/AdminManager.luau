local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Eventos = ReplicatedStorage:WaitForChild("Events")
local DataManager = require(script.Parent:WaitForChild("DataManager"))

local AdminManager = {}

-- [CORREÇÃO 4] Segurança Absoluta - Coloque seu UserId abaixo!
-- Ele garante que, mesmo que você troque de Nickname, continue sendo o Admin.
local MEU_USER_ID_AQUI = 164867918 -- << SUBSTITUA AQUI PELO SEU USERID 

Eventos:WaitForChild("AdminActionEvent").OnServerEvent:Connect(function(jogadorLogado, acao, alvoNome, quantidadeStr)
    -- Trava de segurança: Agora checa o UserId do Player
    if jogadorLogado.UserId ~= MEU_USER_ID_AQUI then 
        warn("Tentativa de uso de Admin bloqueada pelo usuário: " .. jogadorLogado.Name)
        return 
    end

    local jogadorAlvo = Players:FindFirstChild(alvoNome)
    if not jogadorAlvo then 
        warn("ADMIN: Jogador '" .. tostring(alvoNome) .. "' não encontrado no servidor.")
        return 
    end

    local quantidade = tonumber(quantidadeStr) or 0

    if acao == "Adicionar" then
        DataManager.AdicionarPontos(jogadorAlvo, quantidade)
        print("ADMIN: Concedeu " .. quantidade .. " pontos para " .. alvoNome)
        
    elseif acao == "Remover" then
        DataManager.AdicionarPontos(jogadorAlvo, -quantidade)
        print("ADMIN: Removeu " .. quantidade .. " pontos de " .. alvoNome)
        
    end
end)

return AdminManager
--[[
    IMPORTAÇÃO COMPLETA DE APOIADORES (ROBUX GASTOS)
    Truco Paulista - Lista Oficial de Compradores

    Como executar no Roblox Studio:
    1. Abra a Command Bar (View > Command Bar).
    2. Cole todo o código abaixo e pressione Enter.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local ODS_Robux      = DataStoreService:GetOrderedDataStore("Leaderboard_Robux_v1")

-- Lista consolidada oficial de apoiadores
local apoiadores = {
    [4471355203] = 70,
    [1119349072] = 60,
    [546685816]  = 40,
    [1143493251] = 30,
    [9100609112] = 30,
    [175720753]  = 10,
}

print("================================================================")
print("💎 [APOIADORES] Inserindo lista completa no Leaderboard...")
print("================================================================")

local totalSucessos = 0

for userId, totalRobux in pairs(apoiadores) do
    local keyName = tostring(userId)

    -- 1. Grava no ranking global do Leaderboard
    local okODS, errODS = pcall(function()
        ODS_Robux:SetAsync(keyName, totalRobux)
    end)

    -- 2. Atualiza o perfil individual do jogador no TrucoData_v1
    local okData, errData = pcall(function()
        local dados = TrucoDataStore:GetAsync(userId) or {
            Pontos = 0,
            SkinsCompradas = {"Padrao"},
            SkinEquipada = "Padrao"
        }
        dados.RobuxGasto = math.max(dados.RobuxGasto or 0, totalRobux)
        TrucoDataStore:SetAsync(userId, dados)
    end)

    local nome = "Jogador"
    pcall(function()
        nome = Players:GetNameFromUserIdAsync(userId)
    end)

    if okODS and okData then
        totalSucessos += 1
        print(string.format("✅ [%d] %s (UserId: %d) -> %d Robux cadastrado com sucesso!",
            totalSucessos, nome, userId, totalRobux))
    else
        warn(string.format("⚠️ Erro para UserId %d: ODS=%s, DataStore=%s",
            userId, tostring(errODS), tostring(errData)))
    end

    task.wait(0.4)
end

print("================================================================")
print(string.format("🎉 [CONCLUÍDO] %d apoiadores cadastrados com sucesso no ranking!", totalSucessos))
print("================================================================")

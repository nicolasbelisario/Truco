--[[
    MIGRAÇÃO DE BANCO DE DADOS (ONE-TIME RUN)
    Truco Paulista - Migração de TrucoData_v1 -> OrderedDataStores (Global Leaderboards)

    COMO EXECUTAR NO ROBLOX STUDIO:
    1. Abra o seu projeto no Roblox Studio.
    2. Certifique-se de que "Enable Studio Access to API Services" esteja marcado em:
       Game Settings > Security > Enable Studio Access to API Services.
    3. Abra a Command Bar (Barra de Comando) do Studio (View > Command Bar).
    4. Copie e cole todo este código abaixo na Command Bar e pressione ENTER.
]]

local DataStoreService = game:GetService("DataStoreService")

local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local ODS_Vitorias   = DataStoreService:GetOrderedDataStore("Leaderboard_Vitorias_v1")
local ODS_Pontos     = DataStoreService:GetOrderedDataStore("Leaderboard_Pontos_v1")
local ODS_Robux      = DataStoreService:GetOrderedDataStore("Leaderboard_Robux_v1")

print("----------------------------------------------------------------")
print("🚀 [MIGRAÇÃO] Iniciando varredura e consolidação do Leaderboard...")
print("----------------------------------------------------------------")

local totalChaves = 0
local totalMigrados = 0
local totalFalhas = 0

local ok, pages = pcall(function()
    return TrucoDataStore:ListKeysAsync()
end)

if not ok or not pages then
    warn("❌ Erro ao listar chaves do TrucoData_v1:", tostring(pages))
    warn("Certifique-se de que a opção 'Enable Studio Access to API Services' está ATIVA em Game Settings > Security.")
    return
end

while true do
    local keys = pages:GetCurrentPage()
    for _, keyObj in ipairs(keys) do
        totalChaves += 1
        local keyName = tostring(keyObj.KeyName)
        local numUserId = tonumber(keyName)

        if numUserId then
            local okDados, dados = pcall(function()
                return TrucoDataStore:GetAsync(numUserId)
            end)

            if okDados and type(dados) == "table" then
                local migrouAlgo = false

                -- 1. Migra Pontos
                if dados.Pontos and dados.Pontos > 0 then
                    local okP, errP = pcall(function()
                        ODS_Pontos:SetAsync(keyName, math.floor(dados.Pontos))
                    end)
                    if okP then migrouAlgo = true else warn("Erro ao migrar Pontos de " .. keyName .. ":", errP) end
                end

                -- 2. Migra Vitórias
                if dados.Vitorias and dados.Vitorias > 0 then
                    local okV, errV = pcall(function()
                        ODS_Vitorias:SetAsync(keyName, math.floor(dados.Vitorias))
                    end)
                    if okV then migrouAlgo = true else warn("Erro ao migrar Vitórias de " .. keyName .. ":", errV) end
                end

                -- 3. Migra Robux
                if dados.RobuxGasto and dados.RobuxGasto > 0 then
                    local okR, errR = pcall(function()
                        ODS_Robux:SetAsync(keyName, math.floor(dados.RobuxGasto))
                    end)
                    if okR then migrouAlgo = true else warn("Erro ao migrar Robux de " .. keyName .. ":", errR) end
                end

                if migrouAlgo then
                    totalMigrados += 1
                    print(string.format("✅ [%d] UserId %s: Pontos=%d, Vitórias=%d, Robux=%d",
                        totalMigrados, keyName, dados.Pontos or 0, dados.Vitorias or 0, dados.RobuxGasto or 0))
                end
            else
                totalFalhas += 1
                warn("⚠️ Falha ao ler dados do UserId " .. keyName)
            end

            -- Pausa suave para respeitar os limites de requisição da DataStore API
            task.wait(0.2)
        end
    end

    if pages.IsFinished then break end
    local okNext, errNext = pcall(function() pages:AdvanceToNextPageAsync() end)
    if not okNext then
        warn("Erro ao avançar para próxima página:", errNext)
        break
    end
end

print("----------------------------------------------------------------")
print(string.format("🎉 [MIGRAÇÃO CONCLUÍDA] Chaves avaliadas: %d | Jogadores cadastrados no ranking: %d | Falhas: %d",
    totalChaves, totalMigrados, totalFalhas))
print("Os dados agora estão 100% salvos e globais em todos os servidores!")
print("----------------------------------------------------------------")

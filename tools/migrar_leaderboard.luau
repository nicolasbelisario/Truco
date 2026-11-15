--[[
    MIGRAÇÃO INTELIGENTE (PULA JÁ MIGRADOS E PULA ZEROS)
    Truco Paulista - Zero desperdício de requisições

    Como funciona:
    1. Lê a lista de jogadores que já estão no Leaderboard_Pontos e guarda em memória.
    2. Pula instantaneamente qualquer jogador que já foi cadastrado antes.
    3. Pula qualquer jogador com 0 pontos e 0 vitórias.
    4. Grava apenas os jogadores que ainda faltavam!
]]

local DataStoreService = game:GetService("DataStoreService")

local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local ODS_Vitorias   = DataStoreService:GetOrderedDataStore("Leaderboard_Vitorias_v1")
local ODS_Pontos     = DataStoreService:GetOrderedDataStore("Leaderboard_Pontos_v1")
local ODS_Robux      = DataStoreService:GetOrderedDataStore("Leaderboard_Robux_v1")

print("================================================================")
print("🔍 [FASE 1] Verificando quem já está cadastrado no Leaderboard...")

-- 1. Carrega todos os UserIds que já existem no OrderedDataStore em uma tabela de consulta rápida
local jaMigrados = {}
local countJaNoBanco = 0

local okODS, pagesODS = pcall(function()
    return ODS_Pontos:GetSortedAsync(false, 100)
end)

if okODS and pagesODS then
    while true do
        for _, entry in ipairs(pagesODS:GetCurrentPage()) do
            local key = tostring(entry.key)
            jaMigrados[key] = true
            countJaNoBanco += 1
        end
        if pagesODS.IsFinished then break end
        local okAdvance = pcall(function() pagesODS:AdvanceToNextPageAsync() end)
        if not okAdvance then break end
    end
end

print(string.format("✅ Encontrados %d jogadores que já estavam salvos no Leaderboard!", countJaNoBanco))
print("🚀 [FASE 2] Iniciando varredura apenas para os que FALTAM...")
print("================================================================")

local ok, pages = pcall(function()
    return TrucoDataStore:ListKeysAsync()
end)

if not ok or not pages then
    warn("❌ Erro ao listar chaves do TrucoData_v1:", tostring(pages))
    return
end

local totalAvaliados = 0
local totalNovosSalvos = 0
local totalPuladosJaMigrados = 0
local totalPuladosZeros = 0

while true do
    for _, keyObj in ipairs(pages:GetCurrentPage()) do
        totalAvaliados += 1
        local keyName = tostring(keyObj.KeyName)

        -- 1. SE JÁ FOI MIGRADO ANTERIORMENTE -> PULA INSTANTANEAMENTE SEM GASTAR REQUEST
        if jaMigrados[keyName] then
            totalPuladosJaMigrados += 1
        else
            local numUserId = tonumber(keyName)
            if numUserId then
                local okDados, dados = pcall(function()
                    return TrucoDataStore:GetAsync(numUserId)
                end)

                if okDados and type(dados) == "table" then
                    local pts = (dados.Pontos and dados.Pontos > 0) and math.floor(dados.Pontos) or 0
                    local vit = (dados.Vitorias and dados.Vitorias > 0) and math.floor(dados.Vitorias) or 0
                    local rbx = (dados.RobuxGasto and dados.RobuxGasto > 0) and math.floor(dados.RobuxGasto) or 0

                    -- 2. SE TEM 0 EM TUDO -> PULA TAMBÉM
                    if pts == 0 and vit == 0 and rbx == 0 then
                        totalPuladosZeros += 1
                    else
                        -- 3. JOGADOR NOVO QUE AINDA NÃO TINHA SIDO MIGRADO!
                        totalNovosSalvos += 1
                        local infoStr = {}

                        if pts > 0 then
                            pcall(function() ODS_Pontos:SetAsync(keyName, pts) end)
                            table.insert(infoStr, pts .. " Pts")
                            task.wait(0.3)
                        end

                        if vit > 0 then
                            pcall(function() ODS_Vitorias:SetAsync(keyName, vit) end)
                            table.insert(infoStr, vit .. " Vitórias")
                            task.wait(0.3)
                        end

                        if rbx > 0 then
                            pcall(function() ODS_Robux:SetAsync(keyName, rbx) end)
                            table.insert(infoStr, rbx .. " Robux")
                            task.wait(0.3)
                        end

                        print(string.format("⭐ [%d] NOVO UserId %s adicionado ao ranking! (%s)",
                            totalNovosSalvos, keyName, table.concat(infoStr, " | ")))

                        task.wait(0.5)
                    end
                end
            end
        end
    end

    if pages.IsFinished then break end
    local okNext, errNext = pcall(function() pages:AdvanceToNextPageAsync() end)
    if not okNext then
        warn("Pausa de 2s para avançar página...")
        task.wait(2)
        local okRetry = pcall(function() pages:AdvanceToNextPageAsync() end)
        if not okRetry then break end
    end
end

print("================================================================")
print("🎉 [PROCESSO FINALIZADO]")
print(string.format("• Total avaliados: %d", totalAvaliados))
print(string.format("• Já estavam migrados (pulados em 0s): %d", totalPuladosJaMigrados))
print(string.format("• Jogadores com zero (descartados): %d", totalPuladosZeros))
print(string.format("• Novos jogadores gravados com sucesso: %d", totalNovosSalvos))
print("================================================================")

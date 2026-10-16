local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local DataManager = {}
local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local sessao = {}
local salvando = {}

local PADRAO = {
    Pontos = 0,
    Vitorias = 0,
    Derrotas = 0,
    PartidasJogadas = 0,
    RobuxGasto = 0,
    SkinsCompradas = {"Padrao"},
    SkinEquipada = "Padrao"
}

-- Callback opcional para LeaderboardManager registrar estatísticas
DataManager.OnStatChanged = nil

function DataManager.CarregarDados(jogador)
    local ok, dados = pcall(function() return TrucoDataStore:GetAsync(jogador.UserId) end)
    if ok then
        local d = dados or {}
        sessao[jogador] = {
            Pontos = d.Pontos or PADRAO.Pontos,
            Vitorias = d.Vitorias or PADRAO.Vitorias,
            Derrotas = d.Derrotas or PADRAO.Derrotas,
            PartidasJogadas = d.PartidasJogadas or PADRAO.PartidasJogadas,
            RobuxGasto = d.RobuxGasto or PADRAO.RobuxGasto,
            SkinsCompradas = d.SkinsCompradas or {table.unpack(PADRAO.SkinsCompradas)},
            SkinEquipada = d.SkinEquipada or PADRAO.SkinEquipada
        }
        DataManager._CriarLeaderstats(jogador)
        DataManager.Sincronizar(jogador)
        
        if DataManager.OnStatChanged then
            DataManager.OnStatChanged(jogador, sessao[jogador])
        end
    else
        warn("Erro ao carregar dados de " .. jogador.Name)
    end
end

function DataManager.SalvarDados(jogador)
    if salvando[jogador] then return end
    salvando[jogador] = true
    local dados = sessao[jogador]
    if dados then
        pcall(function() TrucoDataStore:SetAsync(jogador.UserId, dados) end)
        if DataManager.OnStatChanged then
            DataManager.OnStatChanged(jogador, dados)
        end
        sessao[jogador] = nil
    end
end

function DataManager.Sincronizar(jogador)
    local dados = sessao[jogador]
    if dados then Eventos.SyncDataEvent:FireClient(jogador, dados) end
end

function DataManager.AdicionarPontos(jogador, qtd)
    local dados = sessao[jogador]
    if not dados then return end
    dados.Pontos += qtd
    local ls = jogador:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Pontos") then ls.Pontos.Value = dados.Pontos end
    DataManager.Sincronizar(jogador)
    if DataManager.OnStatChanged then
        DataManager.OnStatChanged(jogador, dados)
    end
end

function DataManager.RegistrarResultadoPartida(jogador, venceu)
    local dados = sessao[jogador]
    if not dados then return end
    dados.PartidasJogadas += 1
    if venceu then
        dados.Vitorias += 1
        local ls = jogador:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Vitórias") then ls["Vitórias"].Value = dados.Vitorias end
    else
        dados.Derrotas += 1
    end
    DataManager.Sincronizar(jogador)
    if DataManager.OnStatChanged then
        DataManager.OnStatChanged(jogador, dados)
    end
end

function DataManager.RegistrarGastoRobux(jogador, quantia)
    local dados = sessao[jogador]
    if not dados then return end
    dados.RobuxGasto += (quantia or 0)
    DataManager.Sincronizar(jogador)
    if DataManager.OnStatChanged then
        DataManager.OnStatChanged(jogador, dados)
    end
end

function DataManager.ObterDados(jogador) return sessao[jogador] end
function DataManager.ObterSkinEquipada(jogador)
    return sessao[jogador] and sessao[jogador].SkinEquipada or "Padrao"
end

function DataManager._CriarLeaderstats(jogador)
    local dados = sessao[jogador]
    if not dados then return end
    local ls = jogador:FindFirstChild("leaderstats") or Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = jogador
    
    local pts = ls:FindFirstChild("Pontos") or Instance.new("IntValue")
    pts.Name = "Pontos"
    pts.Value = dados.Pontos
    pts.Parent = ls

    local vits = ls:FindFirstChild("Vitórias") or Instance.new("IntValue")
    vits.Name = "Vitórias"
    vits.Value = dados.Vitorias
    vits.Parent = ls
end

Players.PlayerAdded:Connect(DataManager.CarregarDados)
Players.PlayerRemoving:Connect(DataManager.SalvarDados)
game:BindToClose(function()
    for _, j in ipairs(Players:GetPlayers()) do DataManager.SalvarDados(j) end
end)

return DataManager
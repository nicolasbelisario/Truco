local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local DataManager = {}
local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local sessao = {}
local carregando = {}
local salvando = {}
local naoSalvar = {}

local PADRAO = {
    Pontos = 0,
    Vitorias = 0,
    Derrotas = 0,
    PartidasJogadas = 0,
    RobuxGasto = 0,
    SkinsCompradas = {"Padrao"},
    SkinEquipada = "Padrao",
    TutorialVisto = false,
}

local function garantirTutorialEvent()
    local existente = Eventos:FindFirstChild("TutorialEvent")
    if existente then return existente end
    local novo = Instance.new("RemoteEvent")
    novo.Name = "TutorialEvent"
    novo.Parent = Eventos
    return novo
end

local tutorialEvent = garantirTutorialEvent()

-- Callback opcional para LeaderboardManager registrar estatísticas
DataManager.OnStatChanged = nil

function DataManager.CarregarDados(jogador)
    if sessao[jogador] or carregando[jogador] then return end
    carregando[jogador] = true
    jogador:SetAttribute("SkinEquipada", PADRAO.SkinEquipada)
    local ok, dados = pcall(function() return TrucoDataStore:GetAsync(jogador.UserId) end)
    carregando[jogador] = nil
    if not jogador.Parent then return end
    if ok then
        local d = dados or {}
        local partidasJogadas = d.PartidasJogadas or PADRAO.PartidasJogadas
        -- Veteranos de antes da Issue #8 (já possuem partidas registradas) não recebem onboarding intrusivo
        local tutorialVisto = (d.TutorialVisto == true) or (d.TutorialVisto == nil and partidasJogadas > 0)

        sessao[jogador] = {
            Pontos = d.Pontos or PADRAO.Pontos,
            Vitorias = d.Vitorias or PADRAO.Vitorias,
            Derrotas = d.Derrotas or PADRAO.Derrotas,
            PartidasJogadas = partidasJogadas,
            RobuxGasto = d.RobuxGasto or PADRAO.RobuxGasto,
            SkinsCompradas = d.SkinsCompradas or {table.unpack(PADRAO.SkinsCompradas)},
            SkinEquipada = d.SkinEquipada or PADRAO.SkinEquipada,
            TutorialVisto = tutorialVisto,
        }
        naoSalvar[jogador] = nil
        DataManager._CriarLeaderstats(jogador)
        DataManager.Sincronizar(jogador)
        
        if DataManager.OnStatChanged then
            DataManager.OnStatChanged(jogador, sessao[jogador])
        end
    else
        warn("Erro ao carregar dados de " .. jogador.Name)
        if RunService:IsStudio() then
            -- Fallback apenas em ambiente de teste local no Studio (sem sobrescrever DataStore)
            naoSalvar[jogador] = true
            sessao[jogador] = {
                Pontos = PADRAO.Pontos,
                Vitorias = PADRAO.Vitorias,
                Derrotas = PADRAO.Derrotas,
                PartidasJogadas = PADRAO.PartidasJogadas,
                RobuxGasto = PADRAO.RobuxGasto,
                SkinsCompradas = {table.unpack(PADRAO.SkinsCompradas)},
                SkinEquipada = PADRAO.SkinEquipada,
                TutorialVisto = PADRAO.TutorialVisto,
            }
            DataManager._CriarLeaderstats(jogador)
            DataManager.Sincronizar(jogador)
        end
    end
end

function DataManager.SalvarDados(jogador)
    if salvando[jogador] then return end
    salvando[jogador] = true
    local dados = sessao[jogador]
    if dados then
        if not naoSalvar[jogador] then
            pcall(function() TrucoDataStore:SetAsync(jogador.UserId, dados) end)
            if DataManager.OnStatChanged then
                DataManager.OnStatChanged(jogador, dados)
            end
        end
        sessao[jogador] = nil
        naoSalvar[jogador] = nil
    end
    salvando[jogador] = nil
end

function DataManager.MarcarTutorialVisto(jogador, visto)
    local dados = sessao[jogador]
    if not dados then return end
    local novoEstado = (visto ~= false)
    if dados.TutorialVisto == novoEstado then return end
    dados.TutorialVisto = novoEstado
    DataManager.Sincronizar(jogador)
end

tutorialEvent.OnServerEvent:Connect(function(jogador, acao)
    if acao == "MarcarVisto" then
        DataManager.MarcarTutorialVisto(jogador, true)
    elseif acao == "SolicitarSync" then
        if sessao[jogador] then
            DataManager.Sincronizar(jogador)
        else
            DataManager.CarregarDados(jogador)
        end
    end
end)

function DataManager.Sincronizar(jogador)
    local dados = sessao[jogador]
    if dados then
        jogador:SetAttribute("SkinEquipada", dados.SkinEquipada or PADRAO.SkinEquipada)
        Eventos.SyncDataEvent:FireClient(jogador, dados)
    end
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
for _, j in ipairs(Players:GetPlayers()) do
    task.spawn(DataManager.CarregarDados, j)
end
Players.PlayerRemoving:Connect(DataManager.SalvarDados)
game:BindToClose(function()
    for _, j in ipairs(Players:GetPlayers()) do DataManager.SalvarDados(j) end
end)

return DataManager
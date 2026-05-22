local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Eventos = game.ReplicatedStorage:WaitForChild("Events")

local DataManager = {}
local TrucoDataStore = DataStoreService:GetDataStore("TrucoData_v1")
local sessao = {}
local salvando = {}

local PADRAO = { Pontos = 0, SkinsCompradas = {"Padrao"}, SkinEquipada = "Padrao" }

function DataManager.CarregarDados(jogador)
    local ok, dados = pcall(function() return TrucoDataStore:GetAsync(jogador.UserId) end)
    if ok then
        sessao[jogador] = dados or {
            Pontos = PADRAO.Pontos,
            SkinsCompradas = {table.unpack(PADRAO.SkinsCompradas)},
            SkinEquipada = PADRAO.SkinEquipada
        }
        DataManager._CriarLeaderstats(jogador)
        DataManager.Sincronizar(jogador)
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
end

function DataManager.ObterDados(jogador) return sessao[jogador] end
function DataManager.ObterSkinEquipada(jogador)
    return sessao[jogador] and sessao[jogador].SkinEquipada or "Padrao"
end

function DataManager._CriarLeaderstats(jogador)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = jogador
    local pts = Instance.new("IntValue")
    pts.Name = "Pontos"
    pts.Value = sessao[jogador].Pontos
    pts.Parent = ls
end

Players.PlayerAdded:Connect(DataManager.CarregarDados)
Players.PlayerRemoving:Connect(DataManager.SalvarDados)
game:BindToClose(function()
    for _, j in ipairs(Players:GetPlayers()) do DataManager.SalvarDados(j) end
end)

return DataManager
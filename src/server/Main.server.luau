local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableManager = require(script.Parent:WaitForChild("TableManager"))

-- Inicializa o sistema de mesas procurando na pasta definida
local mesasFolder = workspace:WaitForChild("MesasFolder") -- Crie essa pasta no Workspace!
TableManager.Init(mesasFolder)

print("Servidor de Truco Iniciado com Sucesso!")
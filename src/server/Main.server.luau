local GerenciadorMesas = require(script.Parent:WaitForChild("TableManager"))
local DataManager = require(script.Parent:WaitForChild("DataManager"))
local pastaMesas = workspace:WaitForChild("MesasFolder") 

GerenciadorMesas.Inicializar(pastaMesas)

print("Servidor de Truco Iniciado com Sucesso!")
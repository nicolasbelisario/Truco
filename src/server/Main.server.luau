local GerenciadorMesas = require(script.Parent:WaitForChild("TableManager"))

-- Inicializa o sistema buscando a pasta "MesasFolder" no Workspace
local pastaMesas = workspace:WaitForChild("MesasFolder") 
GerenciadorMesas.Inicializar(pastaMesas)

print("Servidor de Truco Iniciado com Sucesso!")
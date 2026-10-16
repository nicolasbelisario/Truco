local GerenciadorMesas = require(script.Parent:WaitForChild("TableManager"))

require(script.Parent:WaitForChild("DataManager"))
require(script.Parent:WaitForChild("ShopManager"))
require(script.Parent:WaitForChild("RobuxManager"))
require(script.Parent:WaitForChild("AdminManager"))
require(script.Parent:WaitForChild("LeaderboardManager"))

local pastaMesas = workspace:WaitForChild("MesasFolder") 
GerenciadorMesas.Inicializar(pastaMesas)

print("Servidor de Truco (Refatorado SOLID) Iniciado com Sucesso!")
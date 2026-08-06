local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Eventos = ReplicatedStorage:WaitForChild("Events")
local Partida = require(script.Parent.Classes:WaitForChild("Match"))

local GerenciadorMesas = {}
local listaMesas = {} -- Associa o Modelo 3D à Classe Partida
local jogadorParaMesa = {} -- Associa o Jogador à Partida que ele está jogando

-- CONFIGURAÇÃO DOS BOTS POR NOME DA MESA (PvE)
local CONFIG_BOTS = {
    ["MesaPvE_Solo"] = {2, 3, 4}, -- 1 Humano vs 3 Bots
    ["MesaPvE_Dupla"] = {2, 4},   -- 2 Humanos vs 2 Bots
    ["MesaPvE_Trio"] = {4},       -- 3 Humanos vs 1 Bot
}

-- [MÉTODO] Lê todas as mesas do mapa e cria as instâncias lógicas
function GerenciadorMesas.Inicializar(pasta)
    for _, modeloMesa in ipairs(pasta:GetChildren()) do
        
        local cadeirasBot = CONFIG_BOTS[modeloMesa.Name] or {}
        local partida = Partida.nova(modeloMesa, cadeirasBot)
        
        listaMesas[modeloMesa] = partida
        
        -- Callbacks para registrar qual jogador está em qual mesa
        partida.OnPlayerJoin = function(jogador)
            jogadorParaMesa[jogador] = partida
        end
        
        partida.OnPlayerLeave = function(jogador)
            jogadorParaMesa[jogador] = nil
        end
    end
    
    GerenciadorMesas.ConfigurarRede()
end

-- [MÉTODO] Recebe as ações dos clientes e redireciona para a mesa correta
function GerenciadorMesas.ConfigurarRede()
    
    Eventos.PlayCardEvent.OnServerEvent:Connect(function(jogador, cardId, escondida)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:JogadorJogarCarta(jogador, cardId, escondida) end
    end)

    Eventos.TrucoEvent.OnServerEvent:Connect(function(jogador, acao, subAcao)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:ProcessarAcaoTruco(jogador, acao, subAcao) end
    end)
    
    Eventos.GameStatusEvent.OnServerEvent:Connect(function(jogador, acao, valor)
        local partida = jogadorParaMesa[jogador]
        if partida then
            if acao == "CutAction" then
                partida:JogadorCortarBaralho(jogador, valor)
            elseif acao == "HandOfElevenDecision" then
                partida:JogadorDecidirMaoDeOnze(jogador, valor)
            end
        end
    end)
    
    Eventos.SignalEvent.OnServerEvent:Connect(function(jogador, tipoSinal)
        local partida = jogadorParaMesa[jogador]
        if partida then partida:TransmitirSinal(jogador, tipoSinal) end
    end)
end

return GerenciadorMesas
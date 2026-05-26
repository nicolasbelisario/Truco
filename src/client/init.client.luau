local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local jogadorLocal = Players.LocalPlayer

-- Módulos do Cliente
local GerenciadorUI = require(script:WaitForChild("UI"):WaitForChild("UIManager"))
local VisuaisMesa = require(script:WaitForChild("TableVisuals"))
local Eventos = ReplicatedStorage:WaitForChild("Events")

-- Variáveis de Estado do Jogador
local parceiroAtual = "Ninguém"
local minhaEquipe = "A"
local ultimoTempoEmote = 0
local TEMPO_ESPERA_EMOTE = 3
local trucoPendente = false

-- Inicializa a Interface de Usuário
GerenciadorUI.Inicializar()

-- [MÉTODO] Atualiza o status de sentar do jogador para registrar em qual mesa ele está
local function atualizarStatusAssento(estaSentado)
    GerenciadorUI.DefinirSentado(estaSentado)
    
    if estaSentado then
        local personagem = jogadorLocal.Character
        if personagem and personagem:FindFirstChild("Humanoid") and personagem.Humanoid.SeatPart then
            local assento = personagem.Humanoid.SeatPart
            local nomeAssento = assento.Parent.Name -- Ex: Cadeira1
            local modeloMesa = assento.Parent.Parent.Parent 
            
            print("Sentei na mesa:", modeloMesa.Name) 
            VisuaisMesa.DefinirMesaAtual(modeloMesa)
            GerenciadorUI.DefinirMeuAssento(nomeAssento)
            
            -- Define a equipe baseada no número da cadeira (Ímpar = A, Par = B)
            local numAssento = tonumber(nomeAssento:match("%d+"))
            if numAssento then
                minhaEquipe = (numAssento % 2 == 1) and "A" or "B"
            end
        end
    else
        -- Remove a referência da mesa quando o jogador levanta
        VisuaisMesa.DefinirMesaAtual(nil)
    end
end

-- Monitora quando o personagem é criado para checar quando ele senta
jogadorLocal.CharacterAdded:Connect(function(personagem)
    local humanoide = personagem:WaitForChild("Humanoid")
    humanoide:GetPropertyChangedSignal("Sit"):Connect(function() 
        atualizarStatusAssento(humanoide.Sit) 
    end)
end)

if jogadorLocal.Character and jogadorLocal.Character:FindFirstChild("Humanoid") then
    atualizarStatusAssento(jogadorLocal.Character.Humanoid.Sit)
end

-- ==========================================
-- EVENTOS DE AÇÕES SOLICITADAS PELO SERVIDOR
-- ==========================================
Eventos.RequestAction.OnClientEvent:Connect(function(tipoAcao, dados)
    if tipoAcao == "EscolhaOCorte" then 
        GerenciadorUI.MostrarOpcoesCorte(dados) 
    elseif tipoAcao == "TrucoChallenge" then
        GerenciadorUI.MostrarDesafioTruco(dados.Value, dados.Caller, dados.TimeLimit)
    end
end)

-- ==========================================
-- EVENTOS DE STATUS GERAL DO JOGO
-- ==========================================
Eventos.GameStatusEvent.OnClientEvent:Connect(function(mensagem, dados)
    
    -- --- BLOCO DE TRUCO ---
    if mensagem == "TRUCO_CALLED" then
        trucoPendente = true 
        GerenciadorUI.OcultarDesafioTruco() 
        GerenciadorUI.AtualizarStatus("TRUCO! Vale " .. dados, 0)
        GerenciadorUI.TocarSom("Truco")

    elseif mensagem == "TRUCO_TIMEOUT" then
        trucoPendente = false
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.AtualizarStatus("Tempo esgotado!", 0)

    elseif mensagem == "TRUCO_ACEITO" then
        trucoPendente = false
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.ResetarCamera()
        GerenciadorUI.AtualizarStatus("TRUCO ACEITO! Vale " .. dados, 0)

    elseif mensagem == "TRUCO_FUGIU" then
        trucoPendente = false
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.ResetarCamera()
        
        -- O servidor nos enviou os nomes de quem fugiu na variável "dados"
        GerenciadorUI.MostrarAvisoFuga(dados .. " correram!")
        
        -- Se quiser, pode colocar um som aqui depois, tipo: GerenciadorUI.TocarSom("Galinha")

    elseif mensagem == "PARTNER_VOTED" then
        GerenciadorUI.AtualizarStatusDesafio("Parceiro quer: " .. string.upper(dados))
    
    elseif mensagem == "WAITING_PARTNER" then
        GerenciadorUI.AtualizarStatusDesafio("Aguardando seu parceiro...")
        
    elseif mensagem == "HIDE_TRUCO_BTN" then
        GerenciadorUI.PermitirTruco(false)
        GerenciadorUI.OcultarDesafioTruco()
        
    elseif mensagem == "SHOW_TRUCO_BTN" then
        GerenciadorUI.PermitirTruco(true)

    -- --- BLOCO DE RODADA E RESULTADOS ---
    elseif mensagem == "DEALING" then
        GerenciadorUI.OcultarMenuCorte()
        GerenciadorUI.TocarSom("Shuffle")

    elseif mensagem == "TEAM_A_WON_HAND" or mensagem == "TEAM_B_WON_HAND" or mensagem == "DRAW_HAND" then
        trucoPendente = false 
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.ResetarCamera()
        
        local textoVencedor = ""
        if mensagem == "DRAW_HAND" then
            textoVencedor = "Mão Empatada! Ninguém pontuou."
        elseif type(dados) == "table" and dados.Names then
            textoVencedor = dados.Names .. " ganharam a mão!"
        else
            textoVencedor = (mensagem == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        end
        
        GerenciadorUI.MostrarVencedorRodada(textoVencedor)

    -- --- BLOCO DE ATUALIZAÇÃO DE MESA ---
    elseif mensagem == "CLEAR_TABLE" then
        local minhasQuedas = (minhaEquipe == "A") and dados.TeamA or dados.TeamB
        local quedasInimigas = (minhaEquipe == "A") and dados.TeamB or dados.TeamA
        GerenciadorUI.AtualizarEstatisticasRodada(parceiroAtual, minhasQuedas, quedasInimigas)
        
        GerenciadorUI.LimparMesa()
        VisuaisMesa.LimparMesa()

    elseif mensagem == "UPDATE_SCORE" then
        local meusPontos = (minhaEquipe == "A") and dados.TeamA or dados.TeamB
        local pontosInimigos = (minhaEquipe == "A") and dados.TeamB or dados.TeamA
        GerenciadorUI.AtualizarPlacar(meusPontos, pontosInimigos)
        
    elseif mensagem == "UPDATE_ROUND_VALUE" then
        GerenciadorUI.AtualizarValorRodada(dados)

    elseif mensagem == "SHOW_SCOREBOARD" then
        GerenciadorUI.MostrarPlacar()

    elseif mensagem == "HIDE_SCOREBOARD" then
        GerenciadorUI.OcultarPlacar()
        
    elseif mensagem == "HIDE_GAME_UI" then
        GerenciadorUI.ResetTotal()

    elseif mensagem == "SHOW_GAME_UI" then
        GerenciadorUI.DefinirVisibilidadeUIJogo(true)

    elseif mensagem == "MATCH_WON" then
        GerenciadorUI.MostrarVencedorPartida(dados)
        GerenciadorUI.TocarSom("Victory")
        
    elseif mensagem == "CUTTING" then
        GerenciadorUI.AtualizarStatus("Aguardando corte...", 0)
        
    else
        GerenciadorUI.AtualizarStatus(mensagem, dados)
    end
end)

-- ==========================================
-- EVENTOS DE CARTAS (MÃO, TURNO, JOGADA)
-- ==========================================
Eventos.DealCards.OnClientEvent:Connect(function(mao, vira, nomeParceiro)
    if nomeParceiro then parceiroAtual = nomeParceiro end
    
    GerenciadorUI.LimparMao() 
    GerenciadorUI.LimparMesa()
    VisuaisMesa.LimparMesa()
    
    GerenciadorUI.DefinirVira(vira.Value, vira.Suit)
    GerenciadorUI.AtualizarEstatisticasRodada(parceiroAtual, 0, 0)
    
    for _, carta in ipairs(mao) do
        GerenciadorUI.AdicionarCartaMao(carta.Value, carta.Suit)
    end
end)

Eventos.UpdateTurnEvent.OnClientEvent:Connect(function(nomeJogador, numeroQueda)
    GerenciadorUI.AtualizarTurno(nomeJogador, numeroQueda)
end)

Eventos.CardPlayedOnTable.OnClientEvent:Connect(function(nomeJogador, valor, naipe, estaEscondida, nomeSkin)
    -- Passa a skin pra UI 2D
    GerenciadorUI.AdicionarCartaJogadaUI(nomeJogador, valor, naipe, estaEscondida, nomeSkin)
    GerenciadorUI.TocarSom("CardPlay")
    
    -- Passa a skin pra Mesa 3D
    local jogador = Players:FindFirstChild(nomeJogador)
    if jogador then
        VisuaisMesa.GerarCarta(jogador, valor, naipe, estaEscondida, nomeSkin)
    else
        VisuaisMesa.GerarCarta(nomeJogador, valor, naipe, estaEscondida, nomeSkin)
    end
end)

-- Sincroniza os dados do Banco de Dados com a Interface Visual
Eventos.SyncDataEvent.OnClientEvent:Connect(function(dados)
    GerenciadorUI.AtualizarDadosJogador(dados)
end)

-- ==========================================
-- SINAIS (EMOTES) E INPUTS
-- ==========================================
local function tentarEnviarSinal(tipoSinal)
    local agora = tick()
    if agora - ultimoTempoEmote >= TEMPO_ESPERA_EMOTE then
        ultimoTempoEmote = agora
        Eventos.SignalEvent:FireServer(tipoSinal)
    end
end

GerenciadorUI.DefinirCallbackEmote(tentarEnviarSinal)

Eventos.SignalEvent.OnClientEvent:Connect(function(remetente, tipoSinal)
    if typeof(remetente) == "Instance" and remetente:IsA("Player") then
        GerenciadorUI.MostrarSinal(remetente, tipoSinal)
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q then 
        tentarEnviarSinal("Sinal_Mao")
    elseif input.KeyCode == Enum.KeyCode.E then 
        tentarEnviarSinal("Sinal_Olhar") 
    end
end)

-- ==========================================
-- SISTEMA DE MÚSICA DE FUNDO (BGM)
-- ==========================================
local SoundService = game:GetService("SoundService")

local playlist = {
    "rbxassetid://1845341094", "rbxassetid://1848354536", 
    "rbxassetid://1837429944", "rbxassetid://9043887091", 
    "rbxassetid://1838457617"
}

local objetoMusica = Instance.new("Sound")
objetoMusica.Name = "BackgroundMusic"
objetoMusica.Parent = SoundService
objetoMusica.Volume = 0.3 
objetoMusica.Looped = false 

local function tocarProximaMusica()
    local idAleatorio = playlist[math.random(1, #playlist)]
    objetoMusica.SoundId = idAleatorio
    
    if not objetoMusica.IsLoaded then
        objetoMusica.Loaded:Wait()
    end
    objetoMusica:Play()
end

objetoMusica.Ended:Connect(tocarProximaMusica)
task.spawn(tocarProximaMusica)

-- ==========================================
-- SISTEMA DE ZONA DO TUTORIAL
-- ==========================================
local RunService = game:GetService("RunService")
local zonaTutorial = workspace.Tutorial:WaitForChild("ZonaTutorial", 10) -- Espera carregar o círculo verde
local RAIO_ZONA = 8 -- Tamanho do raio em studs (ajuste conforme o tamanho do seu círculo)

local jogadorNaZona = false

if zonaTutorial then
    -- Roda uma verificação a cada 0.5 segundos (muito leve para o PC)
    task.spawn(function()
        while task.wait(0.5) do
            local personagem = jogadorLocal.Character
            if personagem and personagem:FindFirstChild("HumanoidRootPart") then
                local hrp = personagem.HumanoidRootPart
                
                -- Ignora o eixo Y (altura) para que um pulo não feche o menu
                local posJogador = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                local posZona = Vector3.new(zonaTutorial.Position.X, 0, zonaTutorial.Position.Z)
                
                local distancia = (posJogador - posZona).Magnitude
                
                if distancia <= RAIO_ZONA then
                    if not jogadorNaZona then
                        jogadorNaZona = true
                        GerenciadorUI.MostrarTutorial(true)
                    end
                else
                    if jogadorNaZona then
                        jogadorNaZona = false
                        GerenciadorUI.MostrarTutorial(false)
                    end
                end
            end
        end
    end)
else
    warn("Não foi possível encontrar a 'ZonaTutorial' no Workspace.")
end
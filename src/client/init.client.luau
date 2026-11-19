local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local jogadorLocal = Players.LocalPlayer

-- Módulos do Cliente
local GerenciadorUI = require(script:WaitForChild("UI"):WaitForChild("UIManager"))
local SoundManager = require(script:WaitForChild("UI"):WaitForChild("SoundManager"))
local VisuaisMesa = require(script:WaitForChild("TableVisuals"))
local CardSettings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CardSettings"))
local Eventos = ReplicatedStorage:WaitForChild("Events")

-- Variáveis de Estado do Jogador
local parceiroAtual = "Ninguém"
local minhaEquipe = "A"
local ultimoTempoEmote = 0
local TEMPO_ESPERA_EMOTE = 3
local trucoPendente = false
local placarAtual = { meus = 0, inimigos = 0 }
local quedasAnteriores = { nossas = 0, inimigas = 0 }
local historicoQuedasAtual = {}
local skinEquipadaLocal = "Padrao"
local valorManilhaAtual = nil
local ultimoSomResultado = 0
local ultimaMesaRegistrada = nil
local ultimoAssentoRegistrado = nil
local baloesMesasVisiveis = true

-- Oculta ou restaura localmente todos os BillboardStatusMesa das mesas para manter a visão limpa durante a partida
local function definirVisibilidadeBaloesMesas(visivel)
    if baloesMesasVisiveis == visivel then return end
    baloesMesasVisiveis = visivel
    local pastaMesas = workspace:FindFirstChild("MesasFolder")
    if not pastaMesas then return end
    for _, desc in ipairs(pastaMesas:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Name == "BillboardStatusMesa" then
            desc.Enabled = visivel
        end
    end
end

task.spawn(function()
    local pastaMesas = workspace:WaitForChild("MesasFolder", 10)
    if not pastaMesas then return end
    pastaMesas.DescendantAdded:Connect(function(desc)
        if desc:IsA("BillboardGui") and desc.Name == "BillboardStatusMesa" then
            desc.Enabled = baloesMesasVisiveis
        end
    end)
end)

-- Inicializa a Interface de Usuário e Áudio Centralizado (D-04)
GerenciadorUI.Inicializar()
SoundManager.Inicializar()
GerenciadorUI.AoMudarModoCamera(function(cameraLivre)
    VisuaisMesa.DefinirOcultarMaoLocal(not cameraLivre)
end)

-- [MÉTODO] Atualiza o status de sentar do jogador para registrar em qual mesa ele está
local function atualizarStatusAssento(estaSentado)
    if estaSentado then
        local personagem = jogadorLocal.Character
        local humanoide = personagem and personagem:FindFirstChild("Humanoid")
        local assento = humanoide and humanoide.SeatPart
        if assento and assento.Parent and assento.Parent.Parent then
            local nomeAssento = assento.Parent.Name -- Ex: Cadeira1
            local modeloMesa = assento.Parent.Parent.Parent
            if ultimaMesaRegistrada == modeloMesa and ultimoAssentoRegistrado == nomeAssento then
                return
            end
            ultimaMesaRegistrada = modeloMesa
            ultimoAssentoRegistrado = nomeAssento

            print("Sentei na mesa:", modeloMesa.Name)
            local numAssento = tonumber(nomeAssento:match("%d+"))
            if numAssento then
                minhaEquipe = (numAssento % 2 == 1) and "A" or "B"
            end

            VisuaisMesa.DefinirMesaAtual(modeloMesa, nomeAssento)
            GerenciadorUI.DefinirMesaAtual(modeloMesa)
            GerenciadorUI.DefinirMeuAssento(nomeAssento)
            GerenciadorUI.DefinirSentado(true)
            ProximityPromptService.Enabled = false
        end
    else
        ultimaMesaRegistrada = nil
        ultimoAssentoRegistrado = nil
        VisuaisMesa.DefinirMesaAtual(nil)
        GerenciadorUI.DefinirMesaAtual(nil)
        GerenciadorUI.DefinirSentado(false)
        ProximityPromptService.Enabled = true
        definirVisibilidadeBaloesMesas(true)
    end
end

local function monitorarPersonagemAssento(personagem)
    local humanoide = personagem:WaitForChild("Humanoid")
    humanoide:GetPropertyChangedSignal("Sit"):Connect(function()
        atualizarStatusAssento(humanoide.Sit)
    end)
    humanoide:GetPropertyChangedSignal("SeatPart"):Connect(function()
        if humanoide.Sit and humanoide.SeatPart then
            atualizarStatusAssento(true)
        end
    end)
    if humanoide.Sit and humanoide.SeatPart then
        atualizarStatusAssento(true)
    end
end

-- Monitora quando o personagem é criado para checar quando ele senta
jogadorLocal.CharacterAdded:Connect(monitorarPersonagemAssento)

if jogadorLocal.Character and jogadorLocal.Character:FindFirstChild("Humanoid") then
    monitorarPersonagemAssento(jogadorLocal.Character)
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
        GerenciadorUI.TocarSom("TrucoAccept")

    elseif mensagem == "TRUCO_FUGIU" then
        trucoPendente = false
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.ResetarCamera()
        
        -- O servidor nos enviou os nomes de quem fugiu na variável "dados"
        GerenciadorUI.MostrarAvisoFuga(dados .. " correram!")
        GerenciadorUI.TocarSom("TrucoFlee")
        ultimoSomResultado = tick()

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
        definirVisibilidadeBaloesMesas(false)
        GerenciadorUI.OcultarMenuCorte()
        GerenciadorUI.FocarCameraMesa()
        GerenciadorUI.TocarSom("Shuffle")
        local emMaoEspecial = (placarAtual.meus == 11 or placarAtual.inimigos == 11)
            and placarAtual.meus < 12 and placarAtual.inimigos < 12
        GerenciadorUI.DefinirModoTensao(emMaoEspecial)

    elseif mensagem == "TEAM_A_WON_HAND" or mensagem == "TEAM_B_WON_HAND" or mensagem == "DRAW_HAND" then
        trucoPendente = false 
        GerenciadorUI.OcultarDesafioTruco()
        GerenciadorUI.ResetarCamera()
        GerenciadorUI.LimparMao()
        VisuaisMesa.LimparPartida()
        
        local textoVencedor = ""
        if mensagem == "DRAW_HAND" then
            textoVencedor = "Mão Empatada! Ninguém pontuou."
        elseif type(dados) == "table" and dados.Names then
            textoVencedor = dados.Names .. " ganharam a mão!"
        else
            textoVencedor = (mensagem == "TEAM_A_WON_HAND") and "DUPLA A" or "DUPLA B"
        end
        
        if mensagem ~= "DRAW_HAND" and (tick() - ultimoSomResultado) > 0.5 then
            local equipeVencedoraMao = (mensagem == "TEAM_A_WON_HAND") and "A" or "B"
            GerenciadorUI.TocarSom((equipeVencedoraMao == minhaEquipe) and "RoundWin" or "RoundLose")
            ultimoSomResultado = tick()
        end

        GerenciadorUI.MostrarVencedorRodada(textoVencedor)

    -- --- BLOCO DE ATUALIZAÇÃO DE MESA ---
    elseif mensagem == "CLEAR_TABLE" then
        local minhasQuedas = (minhaEquipe == "A") and dados.TeamA or dados.TeamB
        local quedasInimigas = (minhaEquipe == "A") and dados.TeamB or dados.TeamA

        local vencedorQueda = dados.Winner
        if not vencedorQueda then
            if minhasQuedas > quedasAnteriores.nossas then
                vencedorQueda = minhaEquipe
            elseif quedasInimigas > quedasAnteriores.inimigas then
                vencedorQueda = (minhaEquipe == "A") and "B" or "A"
            end
        end

        if vencedorQueda == minhaEquipe then
            GerenciadorUI.TocarSom("RoundWin")
            ultimoSomResultado = tick()
        elseif vencedorQueda == "A" or vencedorQueda == "B" then
            GerenciadorUI.TocarSom("RoundLose")
            ultimoSomResultado = tick()
        end

        quedasAnteriores.nossas = minhasQuedas
        quedasAnteriores.inimigas = quedasInimigas

        if type(dados.Historico) == "table" then
            historicoQuedasAtual = {}
            for _, eq in ipairs(dados.Historico) do
                if eq == "DRAW" then
                    table.insert(historicoQuedasAtual, "CANGA")
                elseif eq == minhaEquipe then
                    table.insert(historicoQuedasAtual, "NOS")
                else
                    table.insert(historicoQuedasAtual, "ELES")
                end
            end
        else
            if vencedorQueda == "DRAW" then
                table.insert(historicoQuedasAtual, "CANGA")
            elseif vencedorQueda == minhaEquipe then
                table.insert(historicoQuedasAtual, "NOS")
            elseif vencedorQueda == "A" or vencedorQueda == "B" then
                table.insert(historicoQuedasAtual, "ELES")
            end
        end

        GerenciadorUI.AtualizarEstatisticasRodada(parceiroAtual, minhasQuedas, quedasInimigas, historicoQuedasAtual)
        
        GerenciadorUI.LimparMesa()
        VisuaisMesa.LimparMesa()

    elseif mensagem == "UPDATE_SCORE" then
        local meusPontos = (minhaEquipe == "A") and dados.TeamA or dados.TeamB
        local pontosInimigos = (minhaEquipe == "A") and dados.TeamB or dados.TeamA
        placarAtual.meus = meusPontos
        placarAtual.inimigos = pontosInimigos
        if meusPontos == 0 and pontosInimigos == 0 then
            GerenciadorUI.DefinirModoTensao(false)
        end
        GerenciadorUI.AtualizarPlacar(meusPontos, pontosInimigos)
        
    elseif mensagem == "UPDATE_ROUND_VALUE" then
        GerenciadorUI.AtualizarValorRodada(dados)

    elseif mensagem == "SHOW_SCOREBOARD" then
        GerenciadorUI.MostrarPlacar()

    elseif mensagem == "HIDE_SCOREBOARD" then
        GerenciadorUI.OcultarPlacar()
        
    elseif mensagem == "HIDE_GAME_UI" then
        definirVisibilidadeBaloesMesas(true)
        quedasAnteriores = { nossas = 0, inimigas = 0 }
        historicoQuedasAtual = {}
        valorManilhaAtual = nil
        GerenciadorUI.DefinirModoTensao(false)
        VisuaisMesa.LimparPartida()
        GerenciadorUI.ResetTotal()

    elseif mensagem == "SHOW_GAME_UI" then
        definirVisibilidadeBaloesMesas(false)
        GerenciadorUI.DefinirVisibilidadeUIJogo(true)

    elseif mensagem == "MATCH_WON" then
        GerenciadorUI.DefinirModoTensao(false)
        GerenciadorUI.MostrarVencedorPartida(dados)
        if placarAtual.meus >= placarAtual.inimigos then
            GerenciadorUI.TocarSom("Victory")
        else
            GerenciadorUI.TocarSom("Defeat")
        end
        
    elseif mensagem == "CUTTING" then
        definirVisibilidadeBaloesMesas(false)
        historicoQuedasAtual = {}
        GerenciadorUI.LimparMao()
        VisuaisMesa.LimparPartida()
        GerenciadorUI.AtualizarEstatisticasRodada(parceiroAtual, 0, 0, historicoQuedasAtual)
        GerenciadorUI.AtualizarStatus("Aguardando corte...", 0)
        
    elseif mensagem == "SHOW_ELEVEN_DECISION" then
        definirVisibilidadeBaloesMesas(false)
        GerenciadorUI.MostrarDecisaoMaoDeOnze(dados)
        GerenciadorUI.DefinirModoTensao(true)

    elseif mensagem == "HIDE_ELEVEN_DECISION" then
        GerenciadorUI.OcultarDecisaoMaoDeOnze()
        
    else
        GerenciadorUI.AtualizarStatus(mensagem, dados)
    end
end)

-- ==========================================
-- EVENTOS DE CARTAS (MÃO, TURNO, JOGADA)
-- ==========================================
Eventos.DealCards.OnClientEvent:Connect(function(mao, vira, nomeParceiro)
    if nomeParceiro then parceiroAtual = nomeParceiro end
    quedasAnteriores = { nossas = 0, inimigas = 0 }
    historicoQuedasAtual = {}

    local idxVira = vira and table.find(CardSettings.Values, vira.Value)
    if idxVira then
        valorManilhaAtual = CardSettings.Values[(idxVira % #CardSettings.Values) + 1]
    else
        valorManilhaAtual = nil
    end

    local emMaoEspecial = (placarAtual.meus == 11 or placarAtual.inimigos == 11)
        and placarAtual.meus < 12 and placarAtual.inimigos < 12
    GerenciadorUI.DefinirModoTensao(emMaoEspecial)
    
    GerenciadorUI.LimparMao() 
    GerenciadorUI.LimparMesa()
    VisuaisMesa.LimparMesa()
    
    GerenciadorUI.DefinirVira(vira.Value, vira.Suit)
    VisuaisMesa.DefinirMonteEVira(vira.Value, vira.Suit, skinEquipadaLocal)
    VisuaisMesa.InicializarMaosAvatares()
    GerenciadorUI.FocarCameraMesa()
    GerenciadorUI.AtualizarEstatisticasRodada(parceiroAtual, 0, 0, historicoQuedasAtual)
    
    for _, carta in ipairs(mao) do
        GerenciadorUI.AdicionarCartaMao(carta)
    end
end)

Eventos.UpdateTurnEvent.OnClientEvent:Connect(function(nomeJogador, numeroQueda)
    VisuaisMesa.AtualizarTurno(nomeJogador)
    GerenciadorUI.AtualizarTurno(nomeJogador, numeroQueda)
end)

Eventos.CardPlayedOnTable.OnClientEvent:Connect(function(nomeJogador, valor, naipe, estaEscondida, nomeSkin)
    -- Passa a skin pra UI 2D
    GerenciadorUI.AdicionarCartaJogadaUI(nomeJogador, valor, naipe, estaEscondida, nomeSkin)
    if not estaEscondida and valorManilhaAtual and valor == valorManilhaAtual then
        GerenciadorUI.TocarSom("ZapImpact")
    else
        GerenciadorUI.TocarSom("CardPlay")
    end
    
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
    skinEquipadaLocal = (dados and dados.SkinEquipada) or "Padrao"
    VisuaisMesa.AtualizarSkinVira(skinEquipadaLocal)
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

-- BGM e SFX centralizados e gerenciados por SoundManager (D-04 / RN-16)

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
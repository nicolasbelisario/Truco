local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventBroadcaster = require(script.Parent:WaitForChild("EventBroadcaster"))
local TrucoHandler = require(script.Parent:WaitForChild("TrucoHandler"))
local RoundManager = require(script.Parent:WaitForChild("RoundManager"))
local Bot = require(script.Parent:WaitForChild("Bot"))
local DataManager = require(script.Parent.Parent:WaitForChild("DataManager"))
local AvatarManager = require(script.Parent.Parent.Utils:WaitForChild("AvatarManager"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("EconomyConfig"))
local GameRulesConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("GameRulesConfig"))

local BotDummyTemplate = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BotDummy")

local ESTADOS_ATIVOS = {
    CUTTING = true,
    DEALING = true,
    PLAYING = true,
    ELEVEN_DECISION = true,
    SCORING = true,
}

local COR_PVP      = Color3.fromRGB(39, 174, 96)
local COR_PRIVADA  = Color3.fromRGB(240, 160, 40)
local COR_SOLO     = Color3.fromRGB(52, 152, 219)
local COR_DUPLA    = Color3.fromRGB(155, 89, 182)
local COR_TRIO     = Color3.fromRGB(26, 188, 156)
local COR_EM_JOGO  = Color3.fromRGB(235, 165, 45)
local COR_BG_PLACA = Color3.fromRGB(18, 18, 24)

local Partida = {}
Partida.__index = Partida

--[[
    Instancia uma nova Partida (Match) vinculada a um modelo 3D de mesa no mundo.
    @param modeloMesa Instance: O modelo 3D da mesa de Truco.
    @param listaAssentosBots table: Uma lista (opcional) de índices indicando quais cadeiras serão preenchidas por Bots.
    @param tipoMesa string: (Opcional) Identificador de modo ("PvP", "MesaPvE_Solo", "MesaPvE_Dupla", "MesaPvE_Trio").
    @return table: A nova instância da Partida.
]]
function Partida.nova(modeloMesa, listaAssentosBots, tipoMesa)
    local self = setmetatable({}, Partida)

    self.Modelo = modeloMesa
    self.AssentosBots = listaAssentosBots or {}
    self.UsaBots = (#self.AssentosBots > 0)
    self.TipoMesa = tipoMesa or (self.UsaBots and "PvE" or "PvP")

    self.Estado = "WAITING"
    self.Assentos = {}
    self.AssentosObjetos = {}
    self.PromptsAssentos = {}
    self.BotsTemporarios = {}
    self.Placar = { TeamA = 0, TeamB = 0 }
    self.IDPartida = 1

    -- Metadados de Matchmaking / Salas Públicas e Privadas (UC-15)
    self.SalaCustom = false
    self.NomeSala = nil
    self.SalaPrivada = false
    self.CodigoSala = nil
    self.AnfitriaoUserId = nil
    self.AnfitriaoNome = nil
    self.JogadoresAutorizados = {}
    self.BillboardRefs = nil

    -- [CORREÇÃO 3] Mantém o contexto de self encapsulado corretamente:
    self.VerificarBot = function(jog) return self:EBot(jog) end

    self.TrucoHandler = TrucoHandler.novo(self)
    self.RoundManager = RoundManager.novo(self)

    self:ConfigurarAssentos()
    if self.UsaBots then self:InicializarBots() end
    self:CriarBillboardMesa()
    self:AtualizarEstadoVisualMesa()

    return self
end

--[[
    Retorna o rótulo curto de modo e a cor de destaque da mesa para BillboardGui e UI de Salas.
]]
function Partida:ObterInfoModo()
    local qtdBots = #self.AssentosBots
    if qtdBots == 3 then
        return "SOLO 1v3", "🤖 SOLO 1v3", COR_SOLO
    elseif qtdBots == 2 then
        return "DUPLA 2v2", "👥 DUPLA 2v2", COR_DUPLA
    elseif qtdBots == 1 then
        return "TRIO 3v1", "🎯 TRIO 3v1", COR_TRIO
    end
    if self.SalaPrivada then
        return "PVP 4P", "🔒 PRIVADA", COR_PRIVADA
    end
    return "PVP 4P", "⚔️ PVP 4P", COR_PVP
end

function Partida:ObterRotuloModo()
    local rotulo = self:ObterInfoModo()
    return rotulo
end

function Partida:ObterNomeExibicao()
    if self.SalaCustom and self.NomeSala and self.NomeSala ~= "" then
        return self.NomeSala
    end
    local num = self.Modelo.Name:match("(%d+)$")
    local modo = self:ObterRotuloModo()
    if num then
        return "Mesa " .. num .. " (" .. modo .. ")"
    end
    return self.Modelo.Name
end

function Partida:EstaEmPartidaAtiva()
    return ESTADOS_ATIVOS[self.Estado] == true
end

function Partida:EAssentoBotPermanente(numAssento)
    return self.UsaBots and table.find(self.AssentosBots, numAssento) ~= nil
end

--[[
    Configura ou limpa metadados de sala pública/privada em mesas PvP vazias.
]]
function Partida:ConfigurarSala(anfitriao, nomeSala, privada, codigo)
    self.SalaCustom = true
    self.NomeSala = nomeSala
    self.SalaPrivada = privada == true
    self.CodigoSala = self.SalaPrivada and tostring(codigo) or nil
    self.AnfitriaoUserId = anfitriao and anfitriao.UserId or nil
    self.AnfitriaoNome = anfitriao and anfitriao.Name or nil
    self.JogadoresAutorizados = {}
    if anfitriao then
        self.JogadoresAutorizados[anfitriao.UserId] = true
    end
    self:AtualizarEstadoVisualMesa()
end

function Partida:LimparConfiguracaoSala()
    if not self.SalaCustom then return end
    self.SalaCustom = false
    self.NomeSala = nil
    self.SalaPrivada = false
    self.CodigoSala = nil
    self.AnfitriaoUserId = nil
    self.AnfitriaoNome = nil
    self.JogadoresAutorizados = {}
    self:AtualizarEstadoVisualMesa()
end

function Partida:AutorizarJogador(jogador, codigoFornecido)
    if not self.SalaPrivada then return true end
    if not jogador then return false end
    if self.JogadoresAutorizados[jogador.UserId] then return true end
    if codigoFornecido and tostring(codigoFornecido) == tostring(self.CodigoSala) then
        self.JogadoresAutorizados[jogador.UserId] = true
        return true
    end
    return false
end

--[[
    Retorna a primeira cadeira disponível para um humano sentar, ou nil se cheia/indisponível.
]]
function Partida:ObterPrimeiraCadeiraLivre()
    if self.Estado ~= "WAITING" then return nil end
    for i = 1, 4 do
        local nomeAssento = "Cadeira" .. i
        if not self:EAssentoBotPermanente(i) and self.Assentos[nomeAssento] == nil then
            local assento = self.AssentosObjetos[nomeAssento]
            if assento and assento.Occupant == nil then
                return nomeAssento
            end
        end
    end
    return nil
end

--[[
    Retorna resumo serializável da mesa para a lista de Salas / Matchmaking.
]]
function Partida:ObterResumoSala()
    local modoCurto, modoBadge = self:ObterInfoModo()
    local ocupados = self:ContarJogadores()
    local humanos = self:ContarHumanos()
    local bots = ocupados - humanos
    local temVaga = (self.Estado == "WAITING") and (self:ObterPrimeiraCadeiraLivre() ~= nil)

    return {
        Id = self.Modelo.Name,
        Nome = self.Modelo.Name,
        NomeExibicao = self:ObterNomeExibicao(),
        TipoMesa = self.TipoMesa,
        Modo = modoCurto,
        ModoBadge = modoBadge,
        UsaBots = self.UsaBots,
        Ocupados = ocupados,
        MaxJogadores = GameRulesConfig.MAX_PLAYERS,
        Humanos = humanos,
        Bots = bots,
        BotsTemporarios = self:ContarBotsTemporarios(),
        Estado = self.Estado,
        PlacarA = self.Placar.TeamA,
        PlacarB = self.Placar.TeamB,
        ValorRodada = self.RoundManager and self.RoundManager.ValorRodada or 1,
        Privada = self.SalaPrivada,
        SalaCustom = self.SalaCustom,
        Anfitriao = self.AnfitriaoNome,
        TemVaga = temVaga,
    }
end

--[[
    Vasculha o modelo 3D da mesa em busca de objetos "Seat" (cadeiras),
    configura ProximityPrompts (evitando sentar por colisão acidental)
    e vincula eventos para detectar quando jogadores sentam ou levantam.
]]
function Partida:ConfigurarAssentos()
    local pastaCadeiras = self.Modelo:WaitForChild("Cadeiras")
    for _, filho in ipairs(pastaCadeiras:GetChildren()) do
        local objetoAssento = filho:FindFirstChildWhichIsA("Seat") or (filho:IsA("Seat") and filho)
        if objetoAssento then
            local idCadeira = filho.Name
            local numAssento = tonumber(idCadeira:match("%d+"))
            local ehBotFixo = numAssento and self:EAssentoBotPermanente(numAssento)

            self.AssentosObjetos[idCadeira] = objetoAssento

            -- Desativa toque automático no Seat para impedir sentar acidentalmente ao esbarrar (UC-15)
            objetoAssento.CanTouch = false
            objetoAssento.Disabled = ehBotFixo == true

            -- Remove prompts duplicados caso já existam no modelo
            local promptAntigo = objetoAssento:FindFirstChild("PromptSentar")
            if promptAntigo then promptAntigo:Destroy() end

            if not ehBotFixo then
                local prompt = Instance.new("ProximityPrompt")
                prompt.Name = "PromptSentar"
                prompt.ActionText = "Sentar na Mesa"
                prompt.ObjectText = self:ObterRotuloModo()
                prompt.KeyboardKeyCode = Enum.KeyCode.E
                prompt.HoldDuration = 0
                prompt.MaxActivationDistance = 8
                prompt.RequiresLineOfSight = false
                prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
                prompt.Parent = objetoAssento

                prompt.Triggered:Connect(function(jogador)
                    self:TentarSentarViaPrompt(jogador, idCadeira)
                end)

                self.PromptsAssentos[idCadeira] = prompt
            end

            objetoAssento:GetPropertyChangedSignal("Occupant"):Connect(function()
                self:ProcessarMudancaAssento(objetoAssento, idCadeira)
            end)
        end
    end

    task.spawn(function()
        while task.wait(1) do
            if self.Estado == "WAITING" and self:ContarJogadores() == 4 then
                self:IniciarContagem()
            end
        end
    end)
end

--[[
    Cria o BillboardGui dinâmico acima da mesa exibindo modo, vagas e placar ao vivo.
]]
function Partida:CriarBillboardMesa()
    local modeloMesa = self.Modelo:FindFirstChild("Mesa")
    local alvoAdornee = (modeloMesa and modeloMesa:FindFirstChild("Topo"))
        or self.Modelo.PrimaryPart
        or self.Modelo:FindFirstChildWhichIsA("BasePart", true)
    if not alvoAdornee then return end

    local antigo = alvoAdornee:FindFirstChild("BillboardStatusMesa")
    if antigo then antigo:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "BillboardStatusMesa"
    bb.Adornee = alvoAdornee
    bb.Size = UDim2.new(7.8, 0, 2.9, 0)
    bb.StudsOffset = Vector3.new(0, 6.2, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 80
    bb.LightInfluence = 0
    bb.Parent = alvoAdornee

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = COR_BG_PLACA
    card.BackgroundTransparency = 0.14
    card.BorderSizePixel = 0
    card.Parent = bb
    Instance.new("UICorner", card).CornerRadius = UDim.new(0.16, 0)

    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness = 2.2
    stroke.Color = COR_PVP
    stroke.Transparency = 0.1

    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0.08, 0)
    pad.PaddingBottom = UDim.new(0.08, 0)
    pad.PaddingLeft = UDim.new(0.07, 0)
    pad.PaddingRight = UDim.new(0.07, 0)

    local lblModo = Instance.new("TextLabel")
    lblModo.Name = "LblModo"
    lblModo.Size = UDim2.new(1, 0, 0.30, 0)
    lblModo.Position = UDim2.new(0, 0, 0, 0)
    lblModo.BackgroundTransparency = 1
    lblModo.Font = Enum.Font.GothamBlack
    lblModo.TextScaled = true
    lblModo.TextColor3 = COR_PVP
    lblModo.Text = "⚔️ PVP 4P"
    lblModo.Parent = card

    local lblPrincipal = Instance.new("TextLabel")
    lblPrincipal.Name = "LblPrincipal"
    lblPrincipal.Size = UDim2.new(1, 0, 0.42, 0)
    lblPrincipal.Position = UDim2.new(0, 0, 0.30, 0)
    lblPrincipal.BackgroundTransparency = 1
    lblPrincipal.Font = Enum.Font.GothamBlack
    lblPrincipal.TextScaled = true
    lblPrincipal.TextColor3 = Color3.new(1, 1, 1)
    lblPrincipal.Text = "🪑 0/4  •  4 vagas"
    lblPrincipal.Parent = card

    local lblSub = Instance.new("TextLabel")
    lblSub.Name = "LblSub"
    lblSub.Size = UDim2.new(1, 0, 0.26, 0)
    lblSub.Position = UDim2.new(0, 0, 0.74, 0)
    lblSub.BackgroundTransparency = 1
    lblSub.Font = Enum.Font.GothamMedium
    lblSub.TextScaled = true
    lblSub.TextColor3 = Color3.fromRGB(185, 190, 205)
    lblSub.Text = "Pressione [E] na cadeira"
    lblSub.Parent = card

    self.BillboardRefs = {
        Gui = bb,
        Card = card,
        Stroke = stroke,
        LblModo = lblModo,
        LblPrincipal = lblPrincipal,
        LblSub = lblSub,
    }
end

--[[
    Atualiza textos, cores e contadores do BillboardGui da mesa.
]]
function Partida:AtualizarBillboardMesa()
    local refs = self.BillboardRefs
    if not refs or not refs.Gui or not refs.Gui.Parent then return end

    local _, modoBadge, corModo = self:ObterInfoModo()
    local ocupados = self:ContarJogadores()
    local livres = math.max(0, GameRulesConfig.MAX_PLAYERS - ocupados)

    if self.SalaCustom and self.NomeSala and self.NomeSala ~= "" then
        refs.LblModo.Text = modoBadge .. "  •  " .. self.NomeSala
    else
        refs.LblModo.Text = modoBadge
    end

    if self.Estado == "WAITING" then
        refs.Stroke.Color = corModo
        refs.LblModo.TextColor3 = corModo

        local sufixoVagas = (livres == 1) and "1 vaga!" or (tostring(livres) .. " vagas")
        refs.LblPrincipal.Text = string.format("🪑 %d/4  •  %s", ocupados, sufixoVagas)
        refs.LblPrincipal.TextColor3 = (livres == 1) and Color3.fromRGB(255, 220, 80) or Color3.new(1, 1, 1)

        if self.SalaPrivada then
            refs.LblSub.Text = "🔒 Mesa Privada • Entre pelo menu Mesas"
            refs.LblSub.TextColor3 = Color3.fromRGB(255, 210, 120)
        elseif ocupados > 0 and not self.UsaBots then
            refs.LblSub.Text = "Aguardando jogadores • [E] Sentar"
            refs.LblSub.TextColor3 = Color3.fromRGB(145, 235, 175)
        else
            refs.LblSub.Text = "Aberta • [E] na cadeira ou Jogar Agora"
            refs.LblSub.TextColor3 = Color3.fromRGB(185, 190, 205)
        end
    elseif self.Estado == "COUNTDOWN" then
        refs.Stroke.Color = COR_EM_JOGO
        refs.LblModo.TextColor3 = COR_EM_JOGO
        refs.LblPrincipal.Text = "⏱️ INICIANDO  •  4/4"
        refs.LblPrincipal.TextColor3 = Color3.fromRGB(255, 225, 100)
        refs.LblSub.Text = "Preparando baralho..."
        refs.LblSub.TextColor3 = Color3.fromRGB(215, 215, 225)
    else
        refs.Stroke.Color = COR_EM_JOGO
        refs.LblModo.TextColor3 = COR_EM_JOGO
        refs.LblPrincipal.Text = string.format("🃏 %d x %d", self.Placar.TeamA, self.Placar.TeamB)
        refs.LblPrincipal.TextColor3 = Color3.new(1, 1, 1)

        local valorMao = self.RoundManager and self.RoundManager.ValorRodada or 1
        local infoSub
        if self.Placar.TeamA == 11 and self.Placar.TeamB == 11 then
            infoSub = "⚔️ Mão de Ferro • Vale 3"
        elseif self.Estado == "ELEVEN_DECISION" or self.Placar.TeamA == 11 or self.Placar.TeamB == 11 then
            infoSub = "🔥 Mão de Onze • Vale 3"
        else
            infoSub = "Em jogo • Vale " .. tostring(valorMao) .. (valorMao == 1 and " pt" or " pts")
        end

        local qtdSub = self:ContarBotsTemporarios()
        if qtdSub > 0 then
            infoSub = infoSub .. " • 🤖 Sub"
        end
        refs.LblSub.Text = infoSub
        refs.LblSub.TextColor3 = Color3.fromRGB(240, 200, 120)
    end
end

--[[
    Habilita/desabilita ProximityPrompts conforme estado da partida e ocupação das cadeiras.
]]
function Partida:AtualizarPromptsAssentos()
    local modoCurto = self:ObterRotuloModo()
    local objText = (self.SalaCustom and self.NomeSala and self.NomeSala ~= "")
        and (self.NomeSala .. " • " .. modoCurto)
        or modoCurto

    for idCadeira, prompt in pairs(self.PromptsAssentos) do
        if prompt and prompt.Parent then
            local livre = (self.Estado == "WAITING") and (self.Assentos[idCadeira] == nil)
            prompt.Enabled = livre
            prompt.ObjectText = objText
            prompt.ActionText = self.SalaPrivada and "Mesa Privada (Menu Mesas)" or "Sentar na Mesa"
        end
    end
end

--[[
    Sincroniza BillboardGui, ProximityPrompts e notifica o TableManager sobre mudanças na mesa.
]]
function Partida:AtualizarEstadoVisualMesa()
    self:AtualizarBillboardMesa()
    self:AtualizarPromptsAssentos()
    if self.OnStateChanged then
        self.OnStateChanged(self)
    end
end

--[[
    Manipula o acionamento do ProximityPrompt de uma cadeira.
]]
function Partida:TentarSentarViaPrompt(jogador, nomeAssento)
    if self.SalaPrivada and not self:AutorizarJogador(jogador, nil) then
        EventBroadcaster.ParaJogador(
            jogador,
            "UPDATE_STATUS",
            "Mesa privada! Use o botão MESAS e informe o código para entrar.",
            self.VerificarBot
        )
        return
    end
    self:SentarJogadorNoAssento(jogador, nomeAssento, nil)
end

--[[
    Posiciona e senta um jogador humano em uma cadeira específica de forma autoritativa.
    Usado por ProximityPrompt, Quick Play ("Jogar Agora") e Painel de Salas.
]]
function Partida:SentarJogadorNoAssento(jogador, nomeAssento, codigoFornecido)
    if not jogador or not jogador.Parent then
        return false, "Jogador inválido."
    end
    if self.Estado ~= "WAITING" then
        return false, "Esta mesa já está em partida."
    end

    if self.CanPlayerJoin then
        local permitido, motivoBloqueio = self.CanPlayerJoin(jogador, self)
        if not permitido then
            return false, motivoBloqueio or "Você já está em uma partida ativa."
        end
    end

    if not self:AutorizarJogador(jogador, codigoFornecido) then
        return false, "Código inválido para esta mesa privada."
    end

    local alvoCadeira = nomeAssento or self:ObterPrimeiraCadeiraLivre()
    if not alvoCadeira then
        return false, "Esta mesa está lotada."
    end

    local numAssento = tonumber(alvoCadeira:match("%d+"))
    if numAssento and self:EAssentoBotPermanente(numAssento) then
        return false, "Esta cadeira é reservada para um Bot."
    end
    if self.Assentos[alvoCadeira] ~= nil then
        return false, "Esta cadeira já está ocupada."
    end

    local assento = self.AssentosObjetos[alvoCadeira]
    if not assento or assento.Occupant ~= nil then
        return false, "Assento indisponível."
    end

    local personagem = jogador.Character
    local humanoide = personagem and personagem:FindFirstChildOfClass("Humanoid")
    local hrp = personagem and personagem:FindFirstChild("HumanoidRootPart")
    if not (personagem and humanoide and hrp and humanoide.Health > 0) then
        return false, "Aguarde seu personagem carregar para sentar."
    end

    -- Se o jogador já está sentado em outra cadeira em WAITING, levanta antes de transferir
    if humanoide.SeatPart and humanoide.SeatPart ~= assento then
        humanoide.Sit = false
        task.wait(0.08)
        if self.Estado ~= "WAITING" or self.Assentos[alvoCadeira] ~= nil or assento.Occupant ~= nil then
            return false, "A cadeira foi ocupada. Tente novamente."
        end
    end

    assento.Disabled = false
    personagem:PivotTo(assento.CFrame * CFrame.new(0, 2.2, 0))
    assento:Sit(humanoide)

    return true, "Você entrou em " .. self:ObterNomeExibicao() .. "!"
end

--[[
    Cria e posiciona as instâncias de Bots nos assentos definidos durante a
    criação da partida. Também invoca a geração dos avatares físicos para eles.
]]
function Partida:InicializarBots()
    local mapaNomes = {[1]="Bot 1", [2]="Bot Rival 1", [3]="Bot Parceiro", [4]="Bot Rival 2"}
    for _, indexAssento in ipairs(self.AssentosBots) do
        local nomeAssento = "Cadeira" .. indexAssento
        local nomeExibicao = mapaNomes[indexAssento] or ("Bot " .. indexAssento)

        local novoBot = Bot.novo(nomeExibicao, nomeAssento, self, nil, false)
        self.Assentos[nomeAssento] = novoBot
        self:GerarBotVisual(nomeAssento, nomeExibicao)
    end
end

--[[
    Localiza o nome da cadeira ocupada por um jogador (humano ou bot).
]]
function Partida:ObterNomeAssentoDoJogador(jogador)
    for nomeAssento, jog in pairs(self.Assentos) do
        if jog == jogador then
            return nomeAssento
        end
    end
    return nil
end

--[[
    Disparado quando alguém senta ou levanta de uma cadeira da mesa.
    Trata a entrada de novos jogadores (mostrando a UI) e a saída de jogadores
    (acionando Bot Drop-in em partida ativa se ainda houver humanos na mesa).
    @param assento Seat: A instância do assento que teve mudança de ocupante.
    @param nomeAssento string: O nome do assento (ex: "Cadeira1").
]]
function Partida:ProcessarMudancaAssento(assento, nomeAssento)
    local humanoide = assento.Occupant
    if humanoide then
        local jogador = Players:GetPlayerFromCharacter(humanoide.Parent)
        if jogador then
            local numAssento = tonumber(nomeAssento:match("%d+"))
            if (numAssento and self:EAssentoBotPermanente(numAssento))
                or self.Estado ~= "WAITING"
                or (self.SalaPrivada and not self:AutorizarJogador(jogador, nil)) then
                humanoide.Jump = true
                humanoide.Sit = false
                return
            end

            self.Assentos[nomeAssento] = jogador
            if self.OnPlayerJoin then self.OnPlayerJoin(jogador) end

            EventBroadcaster.ParaJogador(jogador, "SHOW_SCOREBOARD", nil, self.VerificarBot)
            EventBroadcaster.ParaJogador(jogador, "UPDATE_SCORE", self.Placar, self.VerificarBot)
            EventBroadcaster.ParaJogador(jogador, "WAITING", 0, self.VerificarBot)

            self:AtualizarEstadoVisualMesa()

            if self.Estado == "WAITING" and self:ContarJogadores() == 4 then
                task.spawn(function()
                    self:IniciarContagem()
                end)
            end
        end
    else
        local jogadorAntigo = self.Assentos[nomeAssento]
        if jogadorAntigo and typeof(jogadorAntigo) == "Instance" then
            self:_TratarSaidaHumanoDoAssento(nomeAssento, jogadorAntigo)
        end
    end
end

--[[
    Garante tratamento idempotente da saída de um jogador (via PlayerRemoving ou levantar do Seat).
]]
function Partida:ProcessarSaidaJogador(jogador)
    if not jogador then return end
    local nomeAssento = self:ObterNomeAssentoDoJogador(jogador)
    if nomeAssento then
        self:_TratarSaidaHumanoDoAssento(nomeAssento, jogador)
    end
end

function Partida:_TratarSaidaHumanoDoAssento(nomeAssento, jogadorAntigo)
    if self.Assentos[nomeAssento] ~= jogadorAntigo then return end

    if self.OnPlayerLeave then self.OnPlayerLeave(jogadorAntigo) end
    if jogadorAntigo.Parent == Players then
        EventBroadcaster.ParaJogador(jogadorAntigo, "HIDE_GAME_UI", nil, self.VerificarBot)
        EventBroadcaster.ParaJogador(jogadorAntigo, "HIDE_SCOREBOARD", nil, self.VerificarBot)
    end
    self.Assentos[nomeAssento] = nil

    if self:EstaEmPartidaAtiva() then
        local humanosRestantes = self:ContarHumanos()
        if humanosRestantes <= 0 then
            self:ResetarPartida("Todos os jogadores saíram.")
        else
            -- Bot Substituto Anti-Abandono (Drop-in — UC-15)
            self:SubstituirPorBotTemporario(nomeAssento, jogadorAntigo)
        end
    else
        if self.Estado == "WAITING" and self:ContarHumanos() == 0 then
            self:LimparConfiguracaoSala()
        end
        self:AtualizarEstadoVisualMesa()
    end
end

--[[
    Substitui um jogador humano que saiu/desconectou durante partida ativa por um Bot temporário,
    preservando cartas na mão, cartas na mesa, estado de Truco e turnos sem abortar a partida.
]]
function Partida:SubstituirPorBotTemporario(nomeAssento, jogadorAntigo)
    local nomeBot = "[BOT] " .. (jogadorAntigo.Name or "Sub")
    local botTemp = Bot.novo(nomeBot, nomeAssento, self, nil, true)

    self.Assentos[nomeAssento] = botTemp
    self.BotsTemporarios[nomeAssento] = botTemp

    local assento = self.AssentosObjetos[nomeAssento]
    if assento then
        assento.Disabled = true
    end

    self:GerarBotVisual(nomeAssento, nomeBot)

    -- Transfere estado da rodada e do Truco para o Bot substituto
    self.RoundManager:SubstituirJogador(jogadorAntigo, botTemp, nomeAssento)
    self.TrucoHandler:SubstituirJogador(jogadorAntigo, botTemp)

    EventBroadcaster.ParaTodos(
        self.Assentos,
        "UPDATE_STATUS",
        (jogadorAntigo.Name or "Jogador") .. " saiu. " .. nomeBot .. " assumiu a cadeira!",
        self.VerificarBot
    )

    self:AtualizarEstadoVisualMesa()
end

--[[
    Remove todos os Bots temporários (drop-in) e seus modelos 3D ao encerrar/resetar a partida,
    liberando as cadeiras novamente para jogadores humanos.
]]
function Partida:RemoverBotsTemporarios()
    local pastaCadeiras = self.Modelo:FindFirstChild("Cadeiras")

    for nomeAssento, botTemp in pairs(self.BotsTemporarios) do
        if self.Assentos[nomeAssento] == botTemp then
            self.Assentos[nomeAssento] = nil
        end

        if pastaCadeiras then
            local modeloAssento = pastaCadeiras:FindFirstChild(nomeAssento)
            if modeloAssento then
                local botVisual = modeloAssento:FindFirstChild(botTemp.Nome)
                if botVisual then
                    botVisual:Destroy()
                end
            end
        end

        local assento = self.AssentosObjetos[nomeAssento]
        if assento then
            for _, filho in ipairs(assento:GetChildren()) do
                if filho.Name == "SeatWeld" or filho:IsA("WeldConstraint") then
                    filho:Destroy()
                end
            end
            assento.Disabled = false
            assento.CanTouch = false
        end
    end

    self.BotsTemporarios = {}
end

--[[
    Ativa ou desativa a capacidade de pular dos jogadores na mesa.
    Usado para prender o jogador na cadeira durante a partida.
    @param podePular boolean: Se o jogador deve ser capaz de pular (true) ou não (false).
]]
function Partida:DefinirPuloJogadores(podePular)
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) and jog.Character then
            local hum = jog.Character:FindFirstChild("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = podePular and 50 or 0
            end
        end
    end
end

--[[
    Inicia uma contagem regressiva de 5 segundos antes de começar o jogo.
    Se algum jogador levantar durante a contagem, ela é cancelada e volta a esperar.
]]
function Partida:IniciarContagem()
    if self.Estado ~= "WAITING" then return end
    self.Estado = "COUNTDOWN"
    self:AtualizarEstadoVisualMesa()

    for i = 5, 0, -1 do
        if self:ContarJogadores() < 4 then
            self.Estado = "WAITING"
            EventBroadcaster.ParaTodos(self.Assentos, "WAITING", 0, self.VerificarBot)
            self:AtualizarEstadoVisualMesa()
            return
        end
        EventBroadcaster.ParaTodos(self.Assentos, "COUNTDOWN", i, self.VerificarBot)
        task.wait(1)
    end

    if self.Estado ~= "COUNTDOWN" or self:ContarJogadores() < 4 then
        self.Estado = "WAITING"
        self:AtualizarEstadoVisualMesa()
        return
    end

    self:ComecarJogo()
end

--[[
    Marca o início real da partida. Zera o placar, trava os jogadores nas cadeiras,
    sorteia o primeiro distribuidor (dealer) e inicia a primeira rodada.
]]
function Partida:ComecarJogo()
    self.IDPartida = (self.IDPartida or 0) + 1
    self:DefinirPuloJogadores(false)
    self.Placar = {TeamA = 0, TeamB = 0}
    self.RoundManager.IndexDistribuidor = math.random(1, 4)

    -- Aplica as skins dos amigos nos bots de forma assíncrona
    task.spawn(function() self:DefinirSkinsDosBots() end)

    self:VerificarProximaRodada()
    self:AtualizarEstadoVisualMesa()
end

--[[
    Busca e aplica skins de amigos dos jogadores humanos aos bots da partida.
    A lógica varia conforme a quantidade de jogadores.
]]
function Partida:DefinirSkinsDosBots()
    local humanos = self:ObterHumanos()
    local bots = {}
    for _, p in pairs(self.Assentos) do if self:EBot(p) and not p.Temporario then table.insert(bots, p) end end
    if #bots == 0 or #humanos == 0 then return end

    local avatares = {}
    local amigosUsados = {}

    if #humanos == 1 then
        avatares, amigosUsados = AvatarManager.GetRandomFriendAvatars(humanos, 3)
    elseif #humanos == 2 then
        for _, bot in ipairs(bots) do
            local parceiroHumano = self:ObterParceiro(bot)
            if parceiroHumano and not self:EBot(parceiroHumano) then
                local avatarAmigo, novosUsados = AvatarManager.GetRandomFriendAvatars({parceiroHumano}, 1, amigosUsados)
                if #avatarAmigo > 0 then
                    table.insert(avatares, avatarAmigo[1])
                    amigosUsados = novosUsados
                end
            end
        end
    elseif #humanos == 3 then
        local jogadorAleatorio = {humanos[math.random(1, #humanos)]}
        avatares, amigosUsados = AvatarManager.GetRandomFriendAvatars(jogadorAleatorio, 1)
    end

    if #avatares > 0 then
        for i, bot in ipairs(bots) do
            if avatares[i] then
                local assentoBot = self.Modelo:FindFirstChild("Cadeiras"):FindFirstChild(bot.NomeAssento)
                if assentoBot then
                    local botVisual = assentoBot:FindFirstChild(bot.Nome)
                    if botVisual and botVisual:FindFirstChild("Humanoid") then
                        pcall(function()
                            botVisual.Humanoid:ApplyDescription(avatares[i])
                        end)
                        local banco = assentoBot:FindFirstChildWhichIsA("Seat")
                        if banco then
                            self:SentarBotNoBanco(botVisual, banco)
                        end
                    end
                end
            end
        end
    end
end

--[[
    Verifica o placar e decide se a próxima rodada é normal ou uma Mão de Onze.
]]
function Partida:VerificarProximaRodada()
    local scoreA = self.Placar.TeamA
    local scoreB = self.Placar.TeamB

    -- Condição de Mão de Onze
    if (scoreA == 11 and scoreB < 11) or (scoreB == 11 and scoreA < 11) then
        local equipeOnze = (scoreA == 11) and "A" or "B"
        self.RoundManager:IniciarMaoDeOnze(equipeOnze)
    -- Condição de Mão de Ferro (ambos com 11)
    elseif scoreA == 11 and scoreB == 11 then
        self.RoundManager:IniciarMaoDeFerro()
    else
        self.RoundManager:IniciarNovaRodada()
    end
end

--[[
    Encerra a partida imediatamente, limpando a mesa, removendo bots temporários,
    restaurando a interface dos jogadores e destravando os pulos.
    @param motivo string: Mensagem a ser exibida como motivo do fim da partida.
]]
function Partida:ResetarPartida(motivo)
    self.IDPartida = (self.IDPartida or 0) + 1
    self:DefinirPuloJogadores(true)
    EventBroadcaster.ParaTodos(self.Assentos, "HIDE_GAME_UI", 0, self.VerificarBot)
    EventBroadcaster.ParaTodos(self.Assentos, "HIDE_SCOREBOARD", 0, self.VerificarBot)
    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_STATUS", motivo, self.VerificarBot)
    self.Estado = "WAITING"
    self.Placar = {TeamA = 0, TeamB = 0}
    self.RoundManager:ResetarEstado()
    self.TrucoHandler:Resetar()

    -- Remove quaisquer Bots substitutos temporários de anti-abandono
    self:RemoverBotsTemporarios()

    -- Reseta a aparência dos bots permanentes para a padrão
    for _, bot in pairs(self.Assentos) do
        if self:EBot(bot) then
            local assentoBot = self.Modelo:FindFirstChild("Cadeiras"):FindFirstChild(bot.NomeAssento)
            if assentoBot then
                local botVisual = assentoBot:FindFirstChild(bot.Nome)
                if botVisual then
                    local templateLimpo = BotDummyTemplate:Clone()
                    local humanoidLimpo = templateLimpo:FindFirstChild("Humanoid")
                    if humanoidLimpo then
                        pcall(function()
                            botVisual.Humanoid:ApplyDescription(humanoidLimpo:GetAppliedDescription())
                        end)
                        local banco = assentoBot:FindFirstChildWhichIsA("Seat")
                        if banco then
                            self:SentarBotNoBanco(botVisual, banco)
                        end
                    end
                    templateLimpo:Destroy()
                end
            end
        end
    end

    if self:ContarHumanos() == 0 then
        self:LimparConfiguracaoSala()
    end

    self:AtualizarEstadoVisualMesa()
end

--[[
    Delega a ação de jogar uma carta para o gerenciador da rodada.
    @param jogador Player/Bot: O jogador que enviou a carta.
    @param cardId string: O ID único da carta.
    @param escondida boolean: Se a carta deve ser jogada coberta.
]]
function Partida:JogadorJogarCarta(jogador, cardId, escondida)
    local skinUsada = self:EBot(jogador) and "Padrao" or DataManager.ObterSkinEquipada(jogador)
    self.RoundManager:JogarCarta(jogador, cardId, escondida, skinUsada)
end

--[[
    Roteia as ações relacionadas ao Truco (pedir, aceitar, correr, aumentar)
    para o TrucoHandler.
    @param jogador Player/Bot: O jogador que realizou a ação.
    @param acao string: O tipo da ação ("Request" ou "Response").
    @param subAcao string: (Opcional) A resposta ("Aceitar", "Correr", "Aumentar").
]]
function Partida:ProcessarAcaoTruco(jogador, acao, subAcao)
    if acao == "Request" then
        self.TrucoHandler:ProcessarRequest(jogador)
    elseif acao == "Response" then
        self.TrucoHandler:ProcessarResponse(jogador, subAcao)
    end
end

--[[
    Delega a decisão da Mão de Onze para o RoundManager.
    @param jogador Player: O jogador que tomou a decisão.
    @param decisao string: "JOGAR" ou "CORRER".
]]
function Partida:JogadorDecidirMaoDeOnze(jogador, decisao)
    self.RoundManager:DecidirMaoDeOnze(jogador, decisao)
end

--[[
    Delega a ação de cortar o baralho para o gerenciador da rodada.
    @param jogador Player/Bot: O jogador que está cortando.
    @param quantidade number: O número correspondente ao tipo de corte.
]]
function Partida:JogadorCortarBaralho(jogador, quantidade)
    self.RoundManager:CortarBaralho(jogador, quantidade)
end

--[[
    Delega a transmissão de um sinal/emote visual para o EventBroadcaster.
    @param jogador Player: O remetente do sinal.
    @param tipoSinal string: Qual sinal foi emitido ("Sinal_Mao", "Sinal_Olhar").
]]
function Partida:TransmitirSinal(jogador, tipoSinal)
    EventBroadcaster.SinalEmote(self:ObterHumanos(), jogador, tipoSinal)
end

--[[
    Acionada quando uma Mão (conjunto de 3 quedas) acaba.
    Calcula os pontos da equipe vencedora, notifica os clientes e verifica se
    alguma equipe alcançou os 12 pontos para vencer a partida inteira.
    @param equipeVencedora string: A equipe que ganhou a mão ("A", "B" ou "DRAW").
    @param valorRodada number: Quantos pontos a mão estava valendo.
]]
function Partida:FinalizarMao(equipeVencedora, valorRodada)
    self.Estado = "SCORING"
    self.TrucoHandler.Estado.AguardandoResposta = false

    if equipeVencedora == "DRAW" then
        EventBroadcaster.ParaTodos(self.Assentos, "DRAW_HAND", {Value = 0}, self.VerificarBot)
    else
        self.Placar["Team"..equipeVencedora] += valorRodada
        local nomesVencedores = self:ObterNomesEquipe(equipeVencedora)
        EventBroadcaster.ParaTodos(self.Assentos, "TEAM_"..equipeVencedora.."_WON_HAND", {Value = valorRodada, Names = nomesVencedores}, self.VerificarBot)
    end

    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_SCORE", self.Placar, self.VerificarBot)
    self:AtualizarEstadoVisualMesa()

    local idPartidaAtual = self.IDPartida
    task.wait(3)
    if self.IDPartida ~= idPartidaAtual or self.Estado ~= "SCORING" then return end

    local ptsMaximo = GameRulesConfig.PONTOS_VITORIA_PARTIDA
    if self.Placar.TeamA >= ptsMaximo or self.Placar.TeamB >= ptsMaximo then
        local equipeCampeao = (self.Placar.TeamA >= ptsMaximo) and "A" or "B"
        EventBroadcaster.ParaTodos(self.Assentos, "MATCH_WON", self:ObterNomesEquipe(equipeCampeao) .. " Venceram!", self.VerificarBot)

        local configRecompensa = self.UsaBots and EconomyConfig.Recompensas.PvE or EconomyConfig.Recompensas.PvP
        local ptsVitoria = configRecompensa.Vitoria
        local ptsDerrota = configRecompensa.Derrota

        for _, jog in pairs(self.Assentos) do
            if not self:EBot(jog) then
                if self:ObterEquipe(jog) == equipeCampeao then
                    DataManager.AdicionarPontos(jog, ptsVitoria)
                    DataManager.RegistrarResultadoPartida(jog, true)
                    EventBroadcaster.ParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. ptsVitoria .. " Pontos!", self.VerificarBot)
                else
                    DataManager.AdicionarPontos(jog, ptsDerrota)
                    DataManager.RegistrarResultadoPartida(jog, false)
                    EventBroadcaster.ParaJogador(jog, "UPDATE_STATUS", "Você ganhou +" .. ptsDerrota .. " Pontos de consolação.", self.VerificarBot)
                end
            end
        end

        task.wait(GameRulesConfig.Tempos.EsperaFinalizacaoPartida)
        if self.IDPartida ~= idPartidaAtual then return end
        self:ResetarPartida("Nova Partida")
    else
        self.RoundManager.IndexDistribuidor = (self.RoundManager.IndexDistribuidor % 4) + 1
        self:VerificarProximaRodada()
    end
end

--[[
    Callback acionado pelo TrucoHandler quando um pedido de Truco é aceito.
    Atualiza o valor da rodada na partida e notifica a interface gráfica dos jogadores.
    @param valorAtualizado number: O novo valor em pontos da rodada.
    @param equipeQuePediu string: A equipe que solicitou o aumento ("A" ou "B").
]]
function Partida:OnTrucoAceito(valorAtualizado, equipeQuePediu)
    self.RoundManager.ValorRodada = valorAtualizado

    -- Avisa todos os jogadores (HUDs) que a rodada agora vale mais
    EventBroadcaster.ParaTodos(self.Assentos, "UPDATE_ROUND_VALUE", valorAtualizado, self.VerificarBot)
    self:AtualizarEstadoVisualMesa()

    -- Restaura os botões de TRUCO apenas para a equipe que ACEITOU
    local equipeQueAceitou = (equipeQuePediu == "A") and "B" or "A"
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) then
            if self:ObterEquipe(jog) == equipeQueAceitou then
                EventBroadcaster.ParaJogador(jog, "SHOW_TRUCO_BTN", nil, self.VerificarBot)
            else
                EventBroadcaster.ParaJogador(jog, "HIDE_TRUCO_BTN", nil, self.VerificarBot)
            end
        end
    end

    -- Religa o "cérebro" do bot se for a vez dele jogar a carta
    local jogadorVez = self.Assentos["Cadeira"..self.RoundManager.IndexTurnoAtual]
    if self:EBot(jogadorVez) then
        local numRodada = self.RoundManager.QuedasGanhas.TeamA + self.RoundManager.QuedasGanhas.TeamB + 1
        task.delay(1.5, function()
            if self.Estado == "PLAYING" and not self.TrucoHandler.Estado.AguardandoResposta then
                jogadorVez:JogarTurno(numRodada, self.RoundManager.ViraAtual, self.RoundManager.CartasNaMesa, valorAtualizado, valorAtualizado)
            end
        end)
    end
end

--[[
    Callback acionado pelo TrucoHandler quando uma equipe foge do Truco.
    Encerra a mão atual e dá os pontos do valor *anterior* para a equipe vencedora.
    @param equipeVencedora string: A equipe que pediu o truco e venceu por W.O.
    @param valorAnterior number: O valor que a rodada valia antes de fugirem.
]]
function Partida:OnTrucoCorreu(equipeVencedora, valorAnterior)
    self.RoundManager.ValorRodada = valorAnterior
    self:FinalizarMao(equipeVencedora, valorAnterior)
end

--[[
    Atualiza o valor da rodada na partida diretamente.
    @param valor number: O novo valor da rodada.
]]
function Partida:OnValorAtualizado(valor)
    self.RoundManager.ValorRodada = valor
    self:AtualizarEstadoVisualMesa()
end

--[[
    Retorna o valor atual da rodada em andamento.
    @return number: O valor da rodada (1, 3, 6, 9 ou 12).
]]
function Partida:OnObterValorRodada()
    return self.RoundManager.ValorRodada
end

--[[
    Verifica de forma segura se a entidade fornecida é um Bot do sistema.
    @param entidade any: O objeto a ser verificado.
    @return boolean: Verdadeiro se for Bot, Falso caso contrário.
]]
function Partida:EBot(entidade) return (entidade and typeof(entidade) == "table" and entidade.EBot == true) end

--[[
    Conta o número total de ocupantes atuais nas cadeiras da mesa (Humanos + Bots).
    @return number: O número de jogadores sentados.
]]
function Partida:ContarJogadores() local c = 0; for _ in pairs(self.Assentos) do c += 1 end; return c end

function Partida:ContarHumanos()
    local c = 0
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) then c += 1 end
    end
    return c
end

function Partida:ContarBotsTemporarios()
    local c = 0
    for _ in pairs(self.BotsTemporarios) do c += 1 end
    return c
end

--[[
    Recupera o jogador (ou Bot) que está sentado em uma cadeira específica.
    @param nome string: O nome do assento (ex: "Cadeira2").
    @return any: A entidade que ocupa a cadeira, ou nil se estiver vazia.
]]
function Partida:ObterJogadorPorCadeira(nome) return self.Assentos[nome] end

--[[
    Gera uma lista apenas com os jogadores humanos sentados na mesa, excluindo os Bots.
    @return table: Uma lista de instâncias de Player.
]]
function Partida:ObterHumanos()
    local t = {}
    for _, jog in pairs(self.Assentos) do
        if not self:EBot(jog) then table.insert(t, jog) end
    end
    return t
end

--[[
    Determina a equipe de um jogador com base na numeração de sua cadeira.
    Cadeiras ímpares (1 e 3) pertencem à Equipe A, cadeiras pares (2 e 4) à Equipe B.
    @param jogador Player/Bot: O jogador a ter a equipe consultada.
    @return string: O identificador da equipe ("A" ou "B").
]]
function Partida:ObterEquipe(jogador)
    for nomeAssento, jog in pairs(self.Assentos) do
        if jog == jogador then
            local n = tonumber(nomeAssento:match("%d+"))
            return (n % 2 == 1) and "A" or "B"
        end
    end
    return "A"
end

--[[
    Localiza o parceiro (companheiro de equipe) de um jogador específico.
    @param jogador Player/Bot: O jogador que estamos analisando.
    @return any: A entidade parceira, ou nil se não for encontrada.
]]
function Partida:ObterParceiro(jogador)
    local minhaEq = self:ObterEquipe(jogador)
    for _, jog in pairs(self.Assentos) do
        if jog ~= jogador and self:ObterEquipe(jog) == minhaEq then return jog end
    end
    return nil
end

--[[
    Gera uma string formatada contendo os nomes de todos os integrantes de uma equipe.
    Exemplo: "João e Nick".
    @param idEquipe string: O identificador da equipe ("A" ou "B").
    @return string: Os nomes concatenados dos jogadores.
]]
function Partida:ObterNomesEquipe(idEquipe)
    local nomes = {}
    for _, jog in pairs(self.Assentos) do
        if self:ObterEquipe(jog) == idEquipe then
            table.insert(nomes, self:EBot(jog) and jog.Nome or jog.Name)
        end
    end
    return #nomes > 0 and table.concat(nomes, " e ") or "Ninguém"
end

--[[
    Senta e anima o avatar 3D do Bot no banco correspondente com a pose de sentar correta.
    Garante que o bot fique fixado na cadeira, com animação ativa e sem colidir com acessórios/cenário.
]]
function Partida:SentarBotNoBanco(botVisual, banco)
    local humanoide = botVisual:FindFirstChild("Humanoid")
    local hrp = botVisual:FindFirstChild("HumanoidRootPart")
    if not (banco and humanoide and hrp) then return end

    -- 1. Remove qualquer SeatWeld ou Weld antigo para evitar acúmulo de transformações
    for _, filho in ipairs(banco:GetChildren()) do
        if filho.Name == "SeatWeld" or filho:IsA("WeldConstraint") then
            filho:Destroy()
        end
    end

    -- 2. Desativa colisão e massa de todas as partes e acessórios (impede que chapéus/halos empurrem o bot pro ar)
    for _, parte in ipairs(botVisual:GetDescendants()) do
        if parte:IsA("BasePart") then
            parte.Anchored = false
            parte.CanCollide = false
            parte.Massless = true
        end
    end

    -- 3. Posiciona o HumanoidRootPart exatamente onde ele deve sentar (0.65 studs acima da superfície da cadeira)
    local alturaSuperficie = banco.Size.Y / 2
    local offsetSentado = 0.65
    local seatTopCFrame = banco.CFrame * CFrame.new(0, alturaSuperficie, 0)
    local hrpCFrameAlvo = seatTopCFrame * CFrame.new(0, offsetSentado, 0)

    botVisual:PivotTo(hrpCFrameAlvo)

    -- 4. Cria a fixação rígida (Weld) direta entre o banco e o HumanoidRootPart
    local weld = Instance.new("Weld")
    weld.Name = "SeatWeld"
    weld.Part0 = banco
    weld.Part1 = hrp
    weld.C0 = CFrame.new(0, alturaSuperficie, 0)
    weld.C1 = CFrame.new(0, -offsetSentado, 0)
    weld.Parent = banco

    -- 5. Atualiza o estado do Humanoid
    humanoide.Sit = true
    humanoide:ChangeState(Enum.HumanoidStateType.Seated)

    -- 6. Toca a animação oficial de Sentar R15 (SitAnim)
    local animator = humanoide:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoide)
    local anim = Instance.new("Animation")
    anim.AnimationId = "http://www.roblox.com/asset/?id=2506281703"
    local track = animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play()
end

function Partida:GerarBotVisual(nomeAssento, nomeExibicao)
    local modeloAssento = self.Modelo:WaitForChild("Cadeiras"):FindFirstChild(nomeAssento)
    if not modeloAssento then return end

    local banco = modeloAssento:FindFirstChildWhichIsA("Seat") or modeloAssento
    local botVisual = BotDummyTemplate:Clone()
    botVisual.Name = nomeExibicao

    local humanoide = botVisual:FindFirstChild("Humanoid")
    if humanoide then
        humanoide.PlatformStand = false
        humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        humanoide.DisplayName = nomeExibicao
    end

    botVisual.Parent = modeloAssento
    if banco and humanoide then
        self:SentarBotNoBanco(botVisual, banco)
    end
end

return Partida

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BotConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("BotConfig"))

local Bot = {}
Bot.__index = Bot

-- [MÉTODO] Cria uma nova instância de um Bot na cadeira especificada
function Bot.novo(nome, nomeAssento, instanciaPartida, dificuldade)
    local self = setmetatable({}, Bot)
    self.Nome = nome -- Nome de exibição (ex: "Bot Rival 1")
    self.NomeAssento = nomeAssento -- "Cadeira2", "Cadeira3", etc.
    self.Partida = instanciaPartida -- Referência à mesa/partida atual
    self.Dificuldade = dificuldade or BotConfig.DificuldadeAtiva
    self.Mao = {} -- Cartas do bot
    self.EBot = true -- Identificador para o sistema saber que não é humano
    self.Character = nil -- Bots não têm avatar físico complexo no servidor
    return self
end


-- [MÉTODO] Salva as cartas que o Bot recebeu na rodada
function Bot:ReceberMao(cartas, vira)
    self.Mao = cartas
    -- Aqui você poderia adicionar lógica pro bot analisar se a mão é forte ou fraca
end

-- [MÉTODO] Faz o bot cortar o baralho automaticamente quando for a vez dele
function Bot:CortarAutomatico()
    if self.Partida then
        self.Partida:JogadorCortarBaralho(self, BotConfig.CortePadrao)
    end
end

-- [MÉTODO] Lógica principal de turno: O bot pensa e joga uma carta
function Bot:JogarTurno(numeroQueda, vira, cartasNaMesa, valorMao, valorTruco)
    local cfgDificuldade = BotConfig.Dificuldades[self.Dificuldade] or BotConfig.Dificuldades.Normal
    local tempoMin = BotConfig.TempoPensamento.MinSegundos
    local tempoMax = BotConfig.TempoPensamento.MaxSegundos

    -- Simula um tempo de "pensamento"
    task.delay(tempoMin + math.random() * (tempoMax - tempoMin), function()
        if not self.Partida or self.Partida.Estado ~= "PLAYING" then return end
        if #self.Mao == 0 then return end
        
        -- 1. Chance de pedir Truco (Blefe ou mão boa)
        if valorMao == 1 and math.random() < cfgDificuldade.ChanceTrucoMaoBase then
            self.Partida:ProcessarAcaoTruco(self, "Request")
            return
        end
        
        -- 2. Escolher a Carta
        local indexAleatorio = math.random(1, #self.Mao)
        local cartaEscolhida = self.Mao[indexAleatorio]
        
        -- 3. Decidir se joga Coberta (Escondida)
        local esconderCarta = false
        if numeroQueda > 1 and math.random() < cfgDificuldade.ChanceEsconderCarta then
            esconderCarta = true
        end
        
        -- Joga a carta na mesa
        self.Partida:JogadorJogarCarta(self, cartaEscolhida.idUnico, esconderCarta)
    end)
end

-- [MÉTODO] Decide se aceita ou foge quando alguém pede Truco
function Bot:DecidirTruco(valorProposto, valorAtual)
    local cfgDificuldade = BotConfig.Dificuldades[self.Dificuldade] or BotConfig.Dificuldades.Normal
    local tempoMin = BotConfig.TempoRespostaTruco.MinSegundos
    local tempoMax = BotConfig.TempoRespostaTruco.MaxSegundos

    task.delay(tempoMin + math.random() * (tempoMax - tempoMin), function()
        if not self.Partida then return end
        local chance = math.random()
        if chance < cfgDificuldade.ChanceAceitarTruco then
            self.Partida:ProcessarAcaoTruco(self, "Response", "Aceitar")
        else
            self.Partida:ProcessarAcaoTruco(self, "Response", "Correr")
        end
    end)
end

-- [MÉTODO] Decide se joga ou corre na Mão de Onze
function Bot:DecidirMaoDeOnze(maoParceiro)
    local cfgDificuldade = BotConfig.Dificuldades[self.Dificuldade] or BotConfig.Dificuldades.Normal
    local minForca = cfgDificuldade.MinManilhaStrengthMaoDeOnze

    local todasAsCartas = {}
    for _, c in ipairs(self.Mao) do table.insert(todasAsCartas, c) end
    for _, c in ipairs(maoParceiro) do table.insert(todasAsCartas, c) end

    local temManilhaForte = false
    for _, carta in ipairs(todasAsCartas) do
        if carta.ManilhaStrength and carta.ManilhaStrength >= minForca then
            temManilhaForte = true
            break
        end
    end
    
    if temManilhaForte then
        self.Partida:JogadorDecidirMaoDeOnze(self, "JOGAR")
    else
        self.Partida:JogadorDecidirMaoDeOnze(self, "CORRER")
    end
end


return Bot
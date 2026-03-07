local Bot = {}
Bot.__index = Bot

-- [MÉTODO] Cria uma nova instância de um Bot na cadeira especificada
function Bot.novo(nome, nomeAssento, instanciaPartida)
    local self = setmetatable({}, Bot)
    self.Nome = nome -- Nome de exibição (ex: "Bot Rival 1")
    self.NomeAssento = nomeAssento -- "Cadeira2", "Cadeira3", etc.
    self.Partida = instanciaPartida -- Referência à mesa/partida atual
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
        self.Partida:JogadorCortarBaralho(self, 1) -- Corta 1x por padrão
    end
end

-- [MÉTODO] Lógica principal de turno: O bot pensa e joga uma carta
function Bot:JogarTurno(numeroQueda, vira, cartasNaMesa, valorMao, valorTruco)
    -- Simula um tempo de "pensamento" (1.5 a 3 segundos)
    task.delay(math.random(1.5, 3), function()
        if not self.Partida or self.Partida.Estado ~= "PLAYING" then return end
        if #self.Mao == 0 then return end
        
        -- 1. Chance de pedir Truco (Blefe ou mão boa)
        -- Regra atual: 10% de chance de pedir truco se a mão ainda vale 1
        if valorMao == 1 and math.random() < 1 then
            self.Partida:ProcessarAcaoTruco(self, "Request")
            return
        end
        
        -- 2. Escolher a Carta
        local indexAleatorio = math.random(1, #self.Mao)
        local cartaEscolhida = table.remove(self.Mao, indexAleatorio)
        
        -- 3. Decidir se joga Coberta (Escondida)
        local esconderCarta = false
        if numeroQueda > 1 and math.random() < 0.05 then
            esconderCarta = true -- 5% de chance de esconder da 2ª queda em diante
        end
        
        -- Joga a carta na mesa
        self.Partida:JogadorJogarCarta(self, cartaEscolhida.Value, cartaEscolhida.Suit, esconderCarta)
    end)
end

-- [MÉTODO] Decide se aceita ou foge quando alguém pede Truco
function Bot:DecidirTruco(valorProposto, valorAtual)
    -- Lógica simples: 60% de chance de aceitar, 40% de fugir
    local chance = math.random()
    if chance > 0.4 then
        self.Partida:ProcessarAcaoTruco(self, "Response", "Aceitar")
    else
        self.Partida:ProcessarAcaoTruco(self, "Response", "Correr")
    end
end

return Bot
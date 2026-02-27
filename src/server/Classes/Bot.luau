local Bot = {}
Bot.__index = Bot

function Bot.new(name, seatName, matchInstance)
    local self = setmetatable({}, Bot)
    self.Name = name
    self.SeatName = seatName -- "Cadeira2", etc
    self.Match = matchInstance
    self.Hand = {}
    self.IsBot = true
    self.Character = nil -- Bots não têm corpo físico neste exemplo simples, mas o client precisa tratar isso
    return self
end

function Bot:ReceiveHand(cards, vira)
    self.Hand = cards
    -- O bot poderia analisar a força da mão aqui
end

function Bot:AutoCut()
    -- Simplesmente corta 1x
    if self.Match then
        self.Match:PlayerCutDeck(self, 1)
    end
end

function Bot:MyTurn(trickNumber, vira, tableCards, handValue, trucoValue)
    -- Simula "pensar"
    task.delay(math.random(1.5, 3), function()
        if not self.Match or self.Match.State ~= "PLAYING" then return end
        if #self.Hand == 0 then return end
        if not self.Match or #self.Hand == 0 then return end
        
        -- 1. Chance de pedir Truco aleatoriamente (se a mão for boa ou blefe)
        -- Regra simples: 10% de chance se não vale muito ainda
        if handValue == 1 and math.random() < 0.1 then
            self.Match:HandleTrucoAction(self, "Request")
            return
        end
        
        -- 2. Jogar Carta
        -- Escolhe uma carta aleatória da mão (Pode melhorar para jogar a mais forte/fraca)
        local index = math.random(1, #self.Hand)
        local card = table.remove(self.Hand, index)
        
        -- Se for a primeira rodada, joga normal. Se for 2 ou 3, tenta esconder (jogar coberta) raramente
        local hide = false
        if trickNumber > 1 and math.random() < 0.05 then
            hide = true
        end
        
        self.Match:PlayerPlayCard(self, card.Value, card.Suit, hide)
    end)
end

function Bot:DecideTruco(proposedValue, currentValue)
    -- Lógica simples de aceitar/correr
    local r = math.random()
    if r > 0.4 then
        self.Match:HandleTrucoAction(self, "Response", "Aceitar")
    else
        self.Match:HandleTrucoAction(self, "Response", "Correr")
    end
end

return Bot
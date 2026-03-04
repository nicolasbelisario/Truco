local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfiguracoesCartas = require(Shared:WaitForChild("CardSettings"))

local GerenciadorBaralho = {}

-- [MÉTODO] Cria e RETORNA um novo baralho com todas as cartas válidas
function GerenciadorBaralho.CriarBaralho()
    local baralho = {}
    for _, naipe in ipairs(ConfiguracoesCartas.Suits) do
        for _, valor in ipairs(ConfiguracoesCartas.Values) do
            table.insert(baralho, {
                Value = valor,
                Suit = naipe
            })
        end
    end
    return baralho
end

-- [MÉTODO] Recebe a tabela do baralho atual e bagunça a ordem (Embaralha)
function GerenciadorBaralho.Embaralhar(baralho)
    if not baralho then return end
    local rng = Random.new()
    for i = #baralho, 2, -1 do
        local j = rng:NextInteger(1, i)
        baralho[i], baralho[j] = baralho[j], baralho[i]
    end
end

-- [MÉTODO] Corta o baralho movendo parte dele do topo para o fundo
function GerenciadorBaralho.Cortar(baralho, numCortes)
    if not baralho then return end
    if numCortes < 1 or numCortes > 3 then numCortes = 1 end
    
    local tamanho = #baralho
    if tamanho < 10 then return end 

    for i = 1, numCortes do
        local minPonto = 5
        local maxPonto = tamanho - 5
        
        if minPonto < maxPonto then
            local pontoCorte = math.random(minPonto, maxPonto)
            
            -- Divide em duas partes
            local topo = table.move(baralho, 1, pontoCorte, 1, {})
            local fundo = table.move(baralho, pontoCorte + 1, tamanho, 1, {})
            
            -- Limpa o baralho sem quebrar a referência de memória
            table.clear(baralho)
            
            -- Monta de volta invertido
            for _, carta in ipairs(fundo) do table.insert(baralho, carta) end
            for _, carta in ipairs(topo) do table.insert(baralho, carta) end
        end
    end
end

return GerenciadorBaralho
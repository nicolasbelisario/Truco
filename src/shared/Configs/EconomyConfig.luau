--[[
    EconomyConfig.luau
    Fonte Única da Verdade para Economia, Loja e Recompensas.
    Compartilhado entre Servidor e Cliente (ReplicatedStorage.Shared.Configs.EconomyConfig)
]]

local EconomyConfig = {
    -- Recompensas de pontos concedidas ao final de cada partida
    Recompensas = {
        PvP = {
            Vitoria = 50,
            Derrota = 20,
        },
        PvE = {
            Vitoria = 30,
            Derrota = 10,
        }
    },

    -- Skin padrão concedida automaticamente a todo jogador
    SkinPadraoId = "Padrao",

    -- Catálogo oficial de Skins de Cartas (compradas com Pontos do jogo)
    Skins = {
        {
            Id = "Padrao",
            Nome = "Baralho Clássico",
            Preco = 0,
            Desc = "O bom e velho Truco raiz.",
        },
        {
            Id = "Rosa",
            Nome = "Baralho Rosa",
            Preco = 200,
            Desc = "Para quem gosta de um jogo fofinho.",
        },
        {
            Id = "Nacional",
            Nome = "Baralho Nacional",
            Preco = 300,
            Desc = "Baralho 100% patriota.",
        },
        {
            Id = "Estrela",
            Nome = "Baralho Estelar",
            Preco = 300,
            Desc = "Baralho 100% da Estrela Vermelha.",
        },
    },

    -- Produtos comercializados via Robux (MarketplaceService)
    ProdutosRobux = {
        {
            Nome = "100 Pontos",
            Desc = "Impulsione suas compras!",
            PrecoRobux = "10",
            IdProduto = 3554291316,
            EhGamepass = false,
            PontosConcedidos = 100,
            EhDoacao = false,
        },
        {
            Nome = "500 Pontos",
            Desc = "Fique rico rapidamente!",
            PrecoRobux = "40",
            IdProduto = 3554291580,
            EhGamepass = false,
            PontosConcedidos = 500,
            EhDoacao = false,
        },
        {
            Nome = "Doação 1",
            Desc = "Vai me ajudar a desenvolver o jogo :D",
            PrecoRobux = "15",
            IdProduto = 3549774213,
            EhGamepass = false,
            PontosConcedidos = 0,
            EhDoacao = true,
        },
        {
            Nome = "Doação 2",
            Desc = "Vai me ajudar a desenvolver o jogo :D",
            PrecoRobux = "30",
            IdProduto = 3549774425,
            EhGamepass = false,
            PontosConcedidos = 0,
            EhDoacao = true,
        },
    }
}

-- Mapeamento rápido de Preço por Id de Skin (O(1))
local tabelaPrecos = {}
for _, skin in ipairs(EconomyConfig.Skins) do
    tabelaPrecos[skin.Id] = skin.Preco
end
EconomyConfig.PrecosSkins = tabelaPrecos

-- Mapeamento rápido de Id de Produto para Pontos Concedidos
local tabelaProdutosPontos = {}
local tabelaDoacoes = {}
for _, prod in ipairs(EconomyConfig.ProdutosRobux) do
    if prod.PontosConcedidos > 0 then
        tabelaProdutosPontos[prod.IdProduto] = prod.PontosConcedidos
    end
    if prod.EhDoacao then
        tabelaDoacoes[prod.IdProduto] = true
    end
end
EconomyConfig.ProdutosPontosMap = tabelaProdutosPontos
EconomyConfig.DoacoesMap = tabelaDoacoes

return EconomyConfig

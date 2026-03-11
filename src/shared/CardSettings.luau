local CardSettings = {
    Suits = {"Ouros", "Espadas", "Copas", "Paus"},
    Values = {"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"},
    ManilhaFixa = false,

    -- Linhas (Y) baseadas no Naipe (Começando do 0)
    Row = { 
        ["Ouros"] = 0, ["Espadas"] = 1, ["Copas"] = 2, ["Paus"] = 3 
    },
    
    -- Colunas (X) baseadas no Valor (Começando do 0)
    Column = { 
        ["4"] = 0, ["5"] = 1, ["6"] = 2, ["7"] = 3, ["Q"] = 4, 
        ["J"] = 5, ["K"] = 6, ["A"] = 7, ["2"] = 8, ["3"] = 9 
    },

    -- ========================================================
    -- REGISTRO DE SKINS (COLE SEUS IDs AQUI!)
    -- ========================================================
    Skins = {
        ["Padrao"] = {
            SpriteSheetId = "rbxassetid://71265377205830", 
            CardWidth = 93,
            CardHeight = 133,
        },
        ["Rosa"] = {
            SpriteSheetId = "rbxassetid://72215825993264",
            CardWidth = 93, 
            CardHeight = 133,
        },
        ["Nacional"] = {
            SpriteSheetId = "rbxassetid://120203539916545",
            CardWidth = 93, 
            CardHeight = 133,
        },
        ["Estrela"] = {
            SpriteSheetId = "rbxassetid://122080376953829",
            CardWidth = 93, 
            CardHeight = 133,
        }
    }
}

-- [MÉTODO] Aplica o recorte inteligente da carta usando 1 única imagem
function CardSettings.AplicarSkinCarta(elementoGUI, valor, naipe, escondida, nomeSkin)
    -- Se por acaso pedir uma skin que não existe, cai na Padrao
    nomeSkin = nomeSkin or "Padrao"
    local skin = CardSettings.Skins[nomeSkin] or CardSettings.Skins["Padrao"]
    
    if not skin then return end

    -- Aplica a imagem da Spritesheet
    elementoGUI.Image = skin.SpriteSheetId
    
    if escondida then
        -- O Fundo da carta está na última coluna (Índice 10), Linha 0
        elementoGUI.ImageRectSize = Vector2.new(skin.CardWidth, skin.CardHeight)
        elementoGUI.ImageRectOffset = Vector2.new(10 * skin.CardWidth, 0)
    else
        -- Acha a coordenada exata da frente da carta
        local colunaX = CardSettings.Column[valor] or 0
        local linhaY = CardSettings.Row[naipe] or 0
        
        -- Recorta o retângulo exato
        elementoGUI.ImageRectSize = Vector2.new(skin.CardWidth, skin.CardHeight)
        elementoGUI.ImageRectOffset = Vector2.new(colunaX * skin.CardWidth, linhaY * skin.CardHeight)
    end
end

return CardSettings
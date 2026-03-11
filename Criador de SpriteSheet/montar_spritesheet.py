from PIL import Image
import os

# Configurações reais do seu jogo
LARGURA_CARTA = 93
ALTURA_CARTA = 133
COLUNAS = 11
LINHAS = 4

# Cria o fundo transparente gigante (3500 x 2000)
spritesheet = Image.new("RGBA", (COLUNAS * LARGURA_CARTA, LINHAS * ALTURA_CARTA))

# A ordem exata que você colocou no CardSettings.luau!
naipes = ["Ouros", "Espadas", "Copas", "Paus"]
valores = ["4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"]

print("Montando Spritesheet...")

for y, naipe in enumerate(naipes):
    for x, valor in enumerate(valores):
        nome_arquivo = f"{naipe}_{valor}.png" # Ex: Ouros_4.png
        
        if os.path.exists(nome_arquivo):
            img = Image.open(nome_arquivo)
            # Garante que a imagem tenha o tamanho certo
            img = img.resize((LARGURA_CARTA, ALTURA_CARTA))
            
            # Cola a carta na coordenada exata (X, Y)
            posicao_x = x * LARGURA_CARTA
            posicao_y = y * ALTURA_CARTA
            spritesheet.paste(img, (posicao_x, posicao_y))
            print(f"Adicionado: {nome_arquivo}")
        else:
            print(f"AVISO: {nome_arquivo} não encontrado!")

img_fundo = Image.open("fundo_carta.png").resize((LARGURA_CARTA, ALTURA_CARTA))
spritesheet.paste(img_fundo, (10 * LARGURA_CARTA, 0))

# Salva o arquivo final
spritesheet.save("spritesheet_truco.png")
print("Pronto! Arquivo 'spritesheet_truco.png' gerado com sucesso.")
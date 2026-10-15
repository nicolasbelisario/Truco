# 📖 Glossário — Linguagem Ubíqua do Domínio

> Este glossário define os termos canônicos usados em código, documentação e comunicação do time.
> **Sempre use estes termos** ao discutir o sistema, evitando ambiguidades.

---

## Termos do Domínio do Jogo

| Termo | Definição | Código Relacionado |
|-------|-----------|-------------------|
| **Partida** | Uma sessão completa de Truco entre 4 participantes, terminando quando uma equipe atinge 12 pontos. | `Match.luau` → `Partida` |
| **Mão** | Um ciclo completo de jogo onde cada jogador recebe 3 cartas. Uma partida é composta por múltiplas Mãos. | `RoundManager.luau` |
| **Queda** | Uma rodada dentro de uma Mão. Cada jogador joga 1 carta; a maior vence. Uma Mão tem até 3 Quedas. | `RoundManager:AvaliarQueda()` |
| **Baralho Limpo** | Baralho de 40 cartas sem os 8s, 9s e 10s, usado no Truco Paulista. | `DeckManager.luau` |
| **Vira** | Carta virada na mesa no início de cada Mão que determina as Manilhas daquela Mão. | `RoundManager.ViraAtual` |
| **Manilha** | Uma das 4 cartas mais fortes em uma Mão, determinadas pela Vira. Ordem: Paus (Zap) > Copas > Espadas > Ouros. | `DeckManager:DefinirManilhas()` |
| **Zap** | A Manilha de maior força — a carta de Paus imediatamente superior à Vira. | `ManilhaStrength = 4` |
| **Pica-fumo** | A Manilha de menor força — a carta de Ouros imediatamente superior à Vira. | `ManilhaStrength = 1` |
| **Truco** | Chamada que aumenta o valor da Mão de 1 para 3 pontos. Pode ser escalado: Seis (6), Nove (9), Doze (12). | `TrucoHandler.luau` |
| **Mão de Onze** | Regra especial quando uma equipe atinge 11 pontos: essa equipe vê as cartas do parceiro e decide jogar ou correr. | `RoundManager:IniciarMaoDeOnze()` |
| **Mão de Ferro** | Regra especial quando AMBAS as equipes têm 11 pontos: a Mão é jogada às cegas, valendo 3 pontos. | `RoundManager:IniciarMaoDeFerro()` |
| **Corte** | Ação do jogador à direita do Distribuidor que divide o baralho antes da distribuição. | `RoundManager:CortarBaralho()` |
| **Distribuidor** | Jogador responsável por cortar o baralho e "distribuir" as cartas (em termos de ordem de jogo). | `RoundManager.IndexDistribuidor` |
| **Mão (papel)** | Jogador que joga a primeira carta de uma Queda — o jogador à esquerda do Distribuidor. | `papeis.Mao` em `ObterPapeis()` |
| **Bot** | Jogador controlado por IA no servidor, participando de mesas PvE. | `Bot.luau` |
| **Skin** | Visual cosmético alternativo para o baralho de cartas. Equipável via loja. | `CardSettings.Skins` |
| **Pontos** | Moeda interna do jogo, ganha ao fim de Partidas, usada para comprar Skins. | `DataManager.AdicionarPontos()` |

---

## Termos de Arquitetura / Código

| Termo | Definição |
|-------|-----------|
| **EventBroadcaster** | Módulo servidor responsável por emitir RemoteEvents para os clientes. Centraliza toda comunicação servidor→cliente. |
| **TableManager** | Gerenciador de mesas no servidor. Instancia `Partida` e roteia eventos de rede para a mesa correta do jogador. |
| **Assentos** | Tabela interna da `Partida` que mapeia `"CadeiraX"` → `Player` ou `Bot`. |
| **Estado da Partida** | String enum no servidor: `WAITING`, `COUNTDOWN`, `CUTTING`, `DEALING`, `PLAYING`, `SCORING`, `ELEVEN_DECISION`. |

---

## Termos Proibidos

> Conforme `[RN-09]`, os termos abaixo **NÃO devem aparecer** em código, UI ou comunicações públicas do jogo:

- ❌ `aposta`
- ❌ `gambling`
- ❌ `bet`
- ❌ `stake`

Use em vez disso: **Truco**, **Chamada**, **Desafio**, **Valor da Mão**.

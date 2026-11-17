# 📖 Glossário — Linguagem Ubíqua do Domínio

> Este glossário define os termos canônicos usados em código, documentação e comunicação do time.
> **Sempre use estes termos** ao discutir o sistema, evitando ambiguidades.

---

## Termos do Domínio do Jogo

| Termo | Definição | Código Relacionado |
|-------|-----------|-------------------|
| **Partida** | Sessão completa de Truco entre 4 participantes, terminando quando uma equipe atinge 12 pontos. | `Match.luau` → `Partida` |
| **Mão** | Um ciclo completo de jogo onde cada jogador recebe 3 cartas e disputa até 3 Quedas para pontuar. | `RoundManager.luau` |
| **Queda** | Uma rodada dentro de uma Mão. Cada jogador joga 1 carta; a maior vence. Uma Mão tem até 3 Quedas. | `RoundManager:AvaliarQueda()` |
| **Canga** | Empate na maior carta jogada em uma Queda entre duplas adversárias. | `RuleManager:ObterVencedorRodada()` |
| **Baralho Limpo** | Baralho de 40 cartas sem os 8s, 9s e 10s, usado no Truco Paulista. | `DeckManager.luau` |
| **Vira** | Carta virada na mesa no início de cada Mão que determina as Manilhas daquela Mão. | `RoundManager.ViraAtual` |
| **Manilha** | Uma das 4 cartas mais fortes em uma Mão, determinadas pela Vira. Ordem: Paus (Zap) > Copas > Espadas > Ouros. | `DeckManager:DefinirManilhas()` |
| **Zap** | A Manilha de maior força — a carta de Paus imediatamente superior à Vira. | `ManilhaStrength = 4` |
| **Pica-fumo** | A Manilha de menor força — a carta de Ouros imediatamente superior à Vira. | `ManilhaStrength = 1` |
| **Carta Coberta (Escondida)** | Carta jogada virada para baixo com força `0` (sempre perde). Proibida na 1ª Queda. | `escondida` / `IsHidden` em `RoundManager.luau` |
| **Truco** | Chamada que aumenta o valor da Mão de 1 para 3 pontos. Pode ser escalado: Seis (6), Nove (9), Doze (12). | `TrucoHandler.luau` |
| **Mão de Onze** | Regra especial quando apenas uma equipe atinge 11 pontos: essa equipe vê as cartas do parceiro e decide jogar (3 pts) ou correr (1 pt ao oponente). | `RoundManager:IniciarMaoDeOnze()` |
| **Mão de Ferro** | Regra especial quando AMBAS as equipes têm 11 pontos: a Mão é jogada às cegas, valendo 3 pontos, sem Truco. | `RoundManager:IniciarMaoDeFerro()` |
| **Corte** | Ação do jogador à direita do Distribuidor que divide o baralho (1x, 2x ou 3x) antes da distribuição. | `RoundManager:CortarBaralho()` |
| **Distribuidor (Dealer)** | Jogador de referência da rotação da Mão; o jogador à sua direita corta e o à sua esquerda inicia jogando. | `RoundManager.IndexDistribuidor` |
| **Mão / Pé (papel)** | Jogador que joga a primeira carta da 1ª Queda de uma Mão. | `papeis.Mao` em `ObterPapeis()` |
| **Sinal / Emote** | Sinal visual rápido emitido na mesa (`Sinal_Mao`, `Sinal_Olhar`) para comunicação/blefe entre jogadores. | `SignalEvent`, `UIManager.MostrarSinal()` |
| **Bot** | Jogador controlado por IA no servidor, participando de mesas PvE. | `Bot.luau`, `BotConfig.luau` |
| **Skin** | Visual cosmético alternativo (spritesheet) para o baralho de cartas. Equipável via loja. | `CardSettings.Skins`, `EconomyConfig.Skins` |
| **Pontos** | Moeda interna do jogo, ganha ao fim de Partidas ou pacotes, usada para comprar Skins. | `DataManager.AdicionarPontos()` |
| **Apoiador** | Jogador que adquiriu produtos de Robux/Doação, contabilizado em `RobuxGasto` no ranking. | `RobuxManager.luau`, `LeaderboardManager.luau` |

---

## Termos de Arquitetura / Código / SDD

| Termo | Definição |
|-------|-----------|
| **EventBroadcaster** | Módulo servidor responsável por emitir RemoteEvents para os clientes humanos. Centraliza toda comunicação servidor→cliente. |
| **TableManager** | Gerenciador de mesas no servidor. Instancia `Partida` por modelo 3D e roteia eventos de rede para a mesa correta do jogador. |
| **Assentos** | Tabela interna da `Partida` que mapeia `"Cadeira1"`..`"Cadeira4"` → `Player` ou `Bot`. |
| **Estado da Partida** | String enum no servidor (`GameRulesConfig.States`): `WAITING`, `COUNTDOWN`, `SHUFFLING`, `CUTTING`, `DEALING`, `PLAYING`, `SCORING`, `ELEVEN_DECISION`. |
| **Single Source of Truth (`Configs/`)** | Diretório `src/shared/Configs/` (`EconomyConfig`, `BotConfig`, `GameRulesConfig`) que centraliza constantes e parâmetros compartilhados entre cliente e servidor. |
| **OrderedDataStore (ODS)** | Estrutura do DataStore usada em `LeaderboardManager.luau` para ordenar rankings globais (`Vitórias`, `Pontos`, `Robux`). |
| **Skills SDD** | Pacotes modulares em `.gemini/skills/` (espelhados em `skills/`) contendo invariantes e testes automatizados Python por domínio. |
| **MCP (Model Context Protocol)** | Protocolo que conecta a IA ao **Roblox Studio** (`Roblox_Studio`) e aos **logs em tempo real** (`roblox-studio-logs`). |

---

## Termos Proibidos

> Conforme `[RN-09]`, os termos abaixo **NÃO devem aparecer** em código, UI, configurações ou comunicações públicas do jogo:

- ❌ `aposta` / `apostas`
- ❌ `gambling`
- ❌ `bet` / `betting`
- ❌ `stake`

Use em vez disso: **Truco**, **Chamada**, **Desafio**, **Valor da Mão**, **Valor da Rodada**.

# 🏗️ Arquitetura do Sistema

## Visão Geral

O Truco Paulista segue o modelo **Client-Server obrigatório do Roblox**, onde o servidor é a única fonte de verdade (estado canônico). Clientes apenas exibem informações e enviam intenções ao servidor.

```mermaid
flowchart TD
    subgraph CLIENT["🖥️ Cliente (StarterPlayerScripts)"]
        IC[init.client.luau]
        UIManager
        HandUI
        TrucoUI
        ScoreUI
        ShopUI
        TableUI
        SoundManager
        CameraManager
        TutorialUI
    end

    subgraph SERVER["⚙️ Servidor (ServerScriptService)"]
        MS[Main.server.luau]
        TM[TableManager]
        DM[DataManager]
        RM[RobuxManager]
        SM[ShopManager]
        AM[AdminManager]

        subgraph CLASSES["Classes de Jogo"]
            Match
            RoundManager
            TrucoHandler
            Bot
            EventBroadcaster
        end

        subgraph UTILS["Utilitários"]
            DeckManager
            RuleManager
            AvatarManager
        end
    end

    subgraph SHARED["📦 Shared (ReplicatedStorage)"]
        CardSettings
        GameConfig
        BotDummy
    end

    subgraph EVENTS["🔗 RemoteEvents"]
        PlayCardEvent
        TrucoEvent
        GameStatusEvent
        SignalEvent
        ShopActionEvent
        SyncDataEvent
    end

    IC --> UIManager
    UIManager --> HandUI & TrucoUI & ScoreUI & ShopUI & TableUI

    MS --> TM & DM & RM & AM
    TM --> Match
    Match --> RoundManager & TrucoHandler & Bot & EventBroadcaster
    RoundManager --> DeckManager & RuleManager
    Match --> AvatarManager

    CLIENT -- FireServer --> EVENTS
    EVENTS -- OnServerEvent --> SERVER
    EventBroadcaster -- FireClient --> CLIENT

    SERVER --> SHARED
    CLIENT --> SHARED
```

---

## Módulos e Responsabilidades

### Servidor

| Arquivo | Responsabilidade |
|---------|-----------------|
| `Main.server.luau` | Entry point: inicializa `TableManager`, `DataManager`, `ShopManager` |
| `TableManager.luau` | Cria instâncias de `Partida` para cada mesa 3D, mapeia jogador→mesa, roteia RemoteEvents |
| `DataManager.luau` | Persistência via DataStore: carrega/salva pontos, skins por `UserId` |
| `ShopManager.luau` | Processa compras e equipamentos de skins (via `ShopActionEvent`) |
| `RobuxManager.luau` | Processa compras com Robux via `MarketplaceService` |
| `AdminManager.luau` | Comandos de administrador |
| **`Match.luau`** | Orquestra uma partida completa: assentos, placar, estados, callbacks |
| **`RoundManager.luau`** | Gerencia cada Mão: baralho, distribuição, turnos, quedas, avaliação |
| **`TrucoHandler.luau`** | Gerencia o desafio de Truco: request, response, timeout, votos de dupla |
| **`Bot.luau`** | IA dos bots: jogar carta, decidir truco, decidir Mão de Onze |
| **`EventBroadcaster.luau`** | Centraliza emissão de RemoteEvents para jogadores humanos |
| `DeckManager.luau` | Cria baralho 40 cartas, embaralha, corta, define manilhas |
| `RuleManager.luau` | Calcula força de carta, determina vencedor de uma Queda |
| `AvatarManager.luau` | Busca avatares de amigos para aplicar skins nos bots |

### Cliente

| Arquivo | Responsabilidade |
|---------|-----------------|
| `init.client.luau` | Entry point do cliente: instancia e conecta todos os módulos de UI |
| `UIManager.luau` | Gerencia todas as UIs: qual mostrar, qual esconder por evento de estado |
| `HandUI.luau` | Renderiza as cartas na mão do jogador, clique para jogar |
| `TrucoUI.luau` | Botões e animações de Truco (pedir, aceitar, correr, aumentar) |
| `ScoreUI.luau` | Placar da partida e pontuação de quedas |
| `ShopUI.luau` | Loja de skins (aba Pontos e aba Robux) |
| `TableUI.luau` | Cartas na mesa, vira, animações de distribuição |
| `TableVisuals.luau` | SurfaceGUI das cartas 3D na mesa física |
| `SoundManager.luau` | Gerencia sons e trilha sonora |
| `CameraManager.luau` | Posiciona câmera ao sentar/levantar da mesa |
| `TutorialUI.luau` | UI do tutorial para novos jogadores |

### Shared (ReplicatedStorage)

| Arquivo | Responsabilidade |
|---------|-----------------|
| `CardSettings.luau` | Naipes, valores, mapeamento spritesheet, registro de Skins |
| `GameConfig.luau` | Constantes globais: `MAX_PLAYERS`, tempos, estados, times |
| `BotDummy.rbxm` | Template 3D do avatar do bot |

---

## Fluxo de uma Partida

```mermaid
stateDiagram-v2
    [*] --> WAITING: Mesa criada
    WAITING --> COUNTDOWN: 4 jogadores sentados
    COUNTDOWN --> WAITING: Jogador levanta
    COUNTDOWN --> CUTTING: Contagem encerra
    CUTTING --> DEALING: Corte realizado (ou timeout 10s)
    DEALING --> PLAYING: Cartas distribuídas
    PLAYING --> PLAYING: Carta jogada (< 4 cartas na queda)
    PLAYING --> PLAYING: Queda avaliada (< 2 quedas vencidas)
    PLAYING --> SCORING: Mão encerrada
    SCORING --> CUTTING: Próxima Mão (placar < 12)
    SCORING --> ELEVEN_DECISION: Uma equipe com 11 pts
    ELEVEN_DECISION --> PLAYING: Equipe decide jogar
    ELEVEN_DECISION --> SCORING: Equipe decide correr
    SCORING --> WAITING: Partida encerrada (placar >= 12)
```

---

## Protocolo de Rede (RemoteEvents)

### Cliente → Servidor

| Evento | Payload | Descrição |
|--------|---------|-----------|
| `PlayCardEvent` | `(cardId: string, escondida: boolean)` | Jogar carta |
| `TrucoEvent` | `(acao: "Request"\|"Response", subAcao?: string)` | Ação de Truco |
| `GameStatusEvent` | `(acao: "CutAction"\|"HandOfElevenDecision", valor)` | Corte ou decisão de Mão de Onze |
| `SignalEvent` | `(tipoSinal: string)` | Emote/sinal visual |
| `ShopActionEvent` | `(acao: "Comprar"\|"Equipar", skinId: string)` | Ação na loja |

### Servidor → Cliente (via EventBroadcaster)

| Evento | Descrição |
|--------|-----------|
| `SHOW_SCOREBOARD` | Exibir placar ao sentar |
| `UPDATE_SCORE` | Atualizar placar |
| `WAITING` / `COUNTDOWN` / `CUTTING` / `DEALING` | Mudança de estado |
| `DISTRIBUTE_CARDS` | Receber cartas na mão |
| `CARD_PLAYED` | Carta jogada na mesa |
| `CLEAR_TABLE` | Limpar cartas da mesa após queda |
| `TRUCO_CALLED` | Truco foi pedido |
| `TRUCO_ACEITO` / `TRUCO_FUGIU` | Resposta ao Truco |
| `SHOW_ELEVEN_DECISION` | Mostrar decisão da Mão de Onze |
| `MATCH_WON` | Fim de partida |
| `UPDATE_STATUS` | Mensagem de status na tela |

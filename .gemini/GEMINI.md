# Contexto Primário SDD — Truco Paulista (Roblox)

> Este documento é a **fonte primária de contexto para IAs** (Antigravity, Copilot e agentes SDD).
> Toda especificação detalhada vive em `docs/` e as validações automatizadas vivem em `.gemini/skills/`.

---

## 1. Mapa da Documentação SDD

| Artefato | Caminho | Finalidade |
| :--- | :--- | :--- |
| **Wiki Principal** | [docs/wiki/README.md](../docs/wiki/README.md) | Visão do produto, modos de jogo e quick start |
| **Glossário** | [docs/wiki/GLOSSARY.md](../docs/wiki/GLOSSARY.md) | Linguagem ubíqua canônica do domínio |
| **Arquitetura** | [docs/wiki/ARCHITECTURE.md](../docs/wiki/ARCHITECTURE.md) | Módulos reais, fluxo de estados, rede e contrato 3D |
| **Regras de Negócio** | [docs/wiki/BUSINESS_RULES.md](../docs/wiki/BUSINESS_RULES.md) | Invariantes `RN-01` a `RN-39` e divergências conhecidas |
| **Roadmap & Benchmark** | [docs/wiki/ROBLOX_GROWTH_ROADMAP.md](../docs/wiki/ROBLOX_GROWTH_ROADMAP.md) | Auditoria técnica/visual e plano de evolução Roblox |
| **Use Cases** | [docs/use-cases/UC_INDEX.md](../docs/use-cases/UC_INDEX.md) | Índice de casos de uso implementados e planejados |
| **ADRs** | [docs/ADR/ADR-001_SDD_Setup.md](../docs/ADR/ADR-001_SDD_Setup.md) | Decisões arquiteturais (`ADR-001`, `ADR-002`) |
| **Changelog** | [docs/CHANGELOG.md](../docs/CHANGELOG.md) | Histórico de entregas e mudanças |

---

## 2. Linguagem Ubíqua Canônica (Resumo)

- **Partida (`Match.luau`)**: Sessão completa entre 4 participantes em 2 duplas cruzadas (Cadeiras `1 & 3` vs `2 & 4`) até **12 pontos**.
- **Mão (`RoundManager.luau`)**: Ciclo em que cada jogador recebe 3 cartas e disputa até 3 Quedas para ganhar o valor da Mão (base 1, escalável para 3/6/9/12).
- **Queda**: Uma rodada de 4 cartas jogadas (1 por assento). Melhor de 3 Quedas vence a Mão.
- **Canga**: Empate na maior carta de uma Queda (entre duplas adversárias).
- **Baralho Limpo**: 40 cartas (`4, 5, 6, 7, Q, J, K, A, 2, 3`), sem `8`, `9` e `10`.
- **Vira & Manilha**: Carta virada que define as 4 Manilhas (valor imediatamente superior na ordem padrão; se Vira = `3`, Manilha = `4`). Força fixa: **Paus (Zap) > Copas > Espadas > Ouros (Pica-fumo)**.
- **Carta Coberta (Escondida)**: Carta jogada virada para baixo com força `0`. Proibida na 1ª Queda.
- **Mão de Onze / Mão de Ferro**: Regra especial aos 11 pontos (`11 x <11` vê mão do parceiro e escolhe `JOGAR` por 3 pts ou `CORRER` dando 1 pt; `11 x 11` é jogada no escuro por 3 pts). Truco desativado em ambas.
- **Sinal / Emote**: Comunicação visual de mesa (`Sinal_Mao`, `Sinal_Olhar`) com cooldown de 3s.
- **Pontos & Apoiador**: Moeda interna para comprar Skins cosméticas; compras via Robux acumulam `RobuxGasto` no ranking de Apoiadores.

---

## 3. Regras de Negócio Invariantes (`RN-01` a `RN-39`)

- **Partida & Baralho**: `RN-01` (4 participantes em 2 duplas), `RN-02` (PvP ou PvE `1+3`, `2+2`, `3+1`), `RN-03` (40 cartas), `RN-04` (3 cartas por jogador), `RN-05` (Vira define Manilhas).
- **Hierarquia & Cartas**: `RN-06` (manilha = carta seguinte à Vira), `RN-07` (Zap > Copas > Espadas > Ouros), `RN-08` (`4 < 5 < 6 < 7 < Q < J < K < A < 2 < 3`), `RN-17` (carta coberta = força `0`), `RN-18` (sem carta coberta na 1ª Queda).
- **Pontuação & Quedas**: `RN-10` (Mão inicia em `1`), `RN-11` (`1 -> 3 -> 6 -> 9 -> 12`), `RN-19` (melhor de 3 Quedas), `RN-20` (regras de Canga: empate na 1ª decide na 2ª/3ª; empate entre parceiros da mesma dupla pertence à dupla), `RN-21` (vitória aos `12` pontos).
- **Desafio de Truco**: `RN-22` (apenas em `PLAYING`), `RN-23` (mesma equipe não escala consecutivamente), `RN-24` (`Aceitar`, `Aumentar`, `Correr`), `RN-25` (correr entrega valor anterior), `RN-26` (timeout `15s` = correr automático), `RN-27` (2 humanos exigem votos iguais).
- **Especiais**: `RN-28`/`RN-29` (Mão de Onze), `RN-30` (Mão de Ferro), `RN-31` (Truco desativado em ambas).
- **Economia, Loja & Compliance**:
  - `RN-09` **[CRÍTICO]**: **Proibido** usar os termos `"aposta"`, `"gambling"`, `"bet"` ou `"stake"` em código, configs, UI ou textos públicos.
  - `RN-13`, `RN-14`, `RN-15a`, `RN-15`: Recompensas pós-partida (`PvP`: +50/+20; `PvE`: +30/+10); Pontos compram apenas Skins cosméticas.
  - `RN-32` (`"Padrao"` grátis), `RN-33` (sem reembolso de Pontos), `RN-34` (`ProcessReceipt` idempotente/seguro).
- **Bots, Áudio & Renderização**: `RN-12` (decisão de Bots configurável via `BotConfig`), `RN-16` (BGM em loop + SFX), `RN-17b` (cartas renderizadas em 2D UI e 3D `SurfaceGui`).
- **Segurança, Persistência & Leaderboard**:
  - `RN-35`: Estado canônico **exclusivamente no servidor**.
  - `RN-36`: Validação anti-cheat de turno e propriedade da carta em `MaosJogadores`.
  - `RN-37`: Schema DataStore `TrucoData_v1` (`Pontos`, `Vitorias`, `Derrotas`, `PartidasJogadas`, `RobuxGasto`, `SkinsCompradas`, `SkinEquipada`).
  - `RN-38`: 3 `OrderedDataStore` em `LeaderboardManager.luau` + quadro físico 3D `Workspace.LeaderboardBoard`.
  - `RN-39`: `AdminManager.luau` valida `UserId` no servidor.

---

## 4. Arquitetura Real e Módulos (`src/` via Rojo)

Mapeamento definido em [default.project.json](../default.project.json):

- **Shared (`ReplicatedStorage.Shared` → `src/shared/`)**:
  - `Configs/EconomyConfig.luau` — Single Source of Truth de recompensas, catálogo de Skins e `ProdutosRobux`.
  - `Configs/BotConfig.luau` — Tempos e parâmetros das dificuldades `Facil`, `Normal`, `Dificil`.
  - `Configs/GameRulesConfig.luau` — Limites (`MAX_PLAYERS = 4`, `PONTOS_VITORIA_PARTIDA = 12`), tempos, valores de Mão, `States`, `StateDisplayNames` e `TEAMS`.
  - `CardSettings.luau` — Naipes, valores, spritesheets e `AplicarSkinCarta()`.
  - `GameConfig.luau` — Wrapper de retrocompatibilidade para `GameRulesConfig`.
  - `BotDummy.rbxm` — Template R15 do avatar 3D de Bot.
- **Server (`ServerScriptService` → `src/server/`)**:
  - Serviços Core: `Main.server.luau`, `TableManager.luau`, `DataManager.luau`, `ShopManager.luau`, `RobuxManager.luau`, `LeaderboardManager.luau`, `AdminManager.luau`.
  - `Classes/`: `Match.luau`, `RoundManager.luau`, `TrucoHandler.luau`, `Bot.luau`, `EventBroadcaster.luau`.
  - `Utils/`: `DeckManager.luau`, `RuleManager.luau`, `AvatarManager.luau`.
- **Client (`StarterPlayer.StarterPlayerScripts.Client` → `src/client/`)**:
  - Entrada & Mundo 3D: `init.client.luau`, `TableVisuals.luau`.
  - `UI/`: `UIManager.luau`, `HandUI.luau`, `TableUI.luau`, `TrucoUI.luau`, `ScoreUI.luau`, `ShopUI.luau`, `LeaderboardUI.luau`, `TutorialUI.luau`, `CameraManager.luau`, `SoundManager.luau`.

---

## 5. Protocolo de Rede Real (`ReplicatedStorage.Events`)

- **RemoteEvents**:
  - `PlayCardEvent` (C→S: `cardId, escondida`)
  - `TrucoEvent` (C→S: `"Request" | "Response", subAcao`)
  - `GameStatusEvent` (C→S: `"CutAction" | "HandOfElevenDecision", valor`; S→C: estados e notificações via `EventBroadcaster.ParaTodos` / `ParaJogador`)
  - `RequestAction` (S→C: `"EscolhaOCorte"`, `"TrucoChallenge"`)
  - `DealCards` (S→C: `mao, vira, nomeParceiro`)
  - `UpdateTurnEvent` (S→C: `nomeVez, numRodada`)
  - `CardPlayedOnTable` (S→C: `nomeExibicao, valor, naipe, escondida, skin`)
  - `SignalEvent` (Bidirecional: `tipoSinal` / `remetente, tipoSinal`)
  - `ShopActionEvent` (C→S: `"Comprar" | "Equipar", skinId`)
  - `SyncDataEvent` (S→C: `dados`)
  - `AdminActionEvent` (C→S: `"Adicionar" | "Remover", alvoNome, quantidadeStr`)
- **RemoteFunctions**:
  - `GetLeaderboardData` (C→S: `categoria: "Vitorias" | "Pontos" | "Robux"`)

---

## 6. Contrato do DataModel 3D (`Workspace`)

- `Workspace.MesasFolder`: Modelos de mesa (`Mesa1..4`, `MesaPvE_Solo_1..2`, `MesaPvE_Dupla_1..2`, `MesaPvE_Trio_1..2`, com `Attribute` `TipoMesa`). Cada modelo **deve** conter:
  - `Mesa.Topo` (`BasePart` — referência para `TableVisuals.GerarCarta`)
  - `Cadeiras.Cadeira1..4` (cada uma contendo um `Seat`; `1 & 3` = TeamA, `2 & 4` = TeamB)
  - `CartasNaMesa` (`Folder` para instâncias 3D temporárias)
- `Workspace.LeaderboardBoard`: `BasePart` ou `Model` (com `DisplayPart`/`PrimaryPart`) onde `LeaderboardManager` injeta a `LeaderboardSurfaceGui`.
- `Workspace.Tutorial.ZonaTutorial`: `BasePart` usada para abertura automática do tutorial por proximidade (`RAIO_ZONA = 8`).

---

## 7. Workflow: Rojo, Skills SDD e MCP

1. **Regra de Ouro Rojo**: Nunca edite scripts diretamente dentro do Roblox Studio; toda alteração Luau deve ser feita em `src/` para manter Git + Rojo sincronizados.
2. **Skills SDD (`.gemini/skills/` espelhadas em `skills/`)**:
   - `truco-core-rules`: `python .gemini/skills/truco-core-rules/tests/test_rules.py`
   - `truco-match-flow`: `python .gemini/skills/truco-match-flow/tests/test_match_flow.py`
   - `game-balance-economy`: `python .gemini/skills/game-balance-economy/tests/validate_configs.py`
   Sempre execute os testes relevantes ao alterar regras, fluxo de partida ou `src/shared/Configs/`.
3. **Servidores MCP Ativos**:
   - **`Roblox_Studio`**: Inspecionar hierarquia (`search_game_tree`, `inspect_instance`), capturar viewport (`screen_capture`), executar testes de Play e editar propriedades/modelos 3D do DataModel.
   - **`roblox-studio-logs`** ([mcp.json](../mcp.json)): Ler output e erros em tempo real do Studio (`read_roblox_studio_output`, `check_roblox_errors_and_warnings`, `get_roblox_log_session_info`).

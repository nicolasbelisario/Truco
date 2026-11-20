# 📅 Changelog

> Todas as mudanças notáveis neste projeto são documentadas aqui.
> Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

## [Não Lançado]

### Implementado / Corrigido
- 🎓 **Onboarding de 1ª Sessão, Destaque Automático de Manilhas & Partida Tutorial Scriptada ([Issue #8](https://github.com/nicolasbelisario/Truco/issues/8))**:
  - **Destaque Automático de Manilhas (`CardSettings.luau`, `HandUI.luau`, `ScoreUI.luau`, `TableVisuals.luau`)**: cálculo unificado de Manilhas em `CardSettings`; `HandUI` aplica automaticamente borda brilhante dourada pulsante + selos (`ZAP ♣️`, `COPAS ♥️`, `ESPADAS ♠️`, `OUROS ♦️`) em tempo real; `ScoreUI` exibe badge clara `"Manilha: X"` logo abaixo da Vira (e na tag 3D da mesa).
  - **Persistência `TutorialVisto` (`DataManager.luau`, `default.project.json`)**: flag `TutorialVisto` adicionada ao schema `TrucoData_v1` com auto-migração não-intrusiva para veteranos (`PartidasJogadas > 0`), sincronizada via `TutorialEvent`.
  - **Prompt de Boas-Vindas & Guia `copinhodecocacola` (`GuideAvatar.luau`, `TutorialUI.luau`)**: na 1ª entrada exibe modal *"Gostaria de aprender a jogar?"* com a personagem `Workspace.Tutorial.copinhodecocacola` em `ViewportFrame` 3D, opção discreta de **"Pular Tutorial"**, guia em slides (com atalho **"🤖 TESTAR NA MESA SOLO"** no último slide) e acesso à partida guiada.
  - **Partida Tutorial Scriptada Interativa (`TutorialMatch.luau`, `UIManager.luau`, `TrucoUI.luau`, `TableManager.luau`)**: 2 mãos scriptadas contra bots com highlights pulsantes, explicações curtas da guia `copinhodecocacola` no cantinho, identificação de Manilhas, jogada de cartas, grito de `TRUCO!` e retruco de `SEIS!`, totalmente isolada do servidor e com filtro `PvE_Solo` no QuickPlay.
- 🚀 **Onboarding Rápido ("Jogar Agora"), Matchmaking PvP, ProximityPrompts & Bot Anti-Abandono ([Issue #2](https://github.com/nicolasbelisario/Truco/issues/2) / `UC-15`)**:
  - **Botão "▶ JOGAR AGORA" (Quick Play) & Painel de Salas (`LobbyUI.luau`)**: barra inferior no lobby com Quick Play prioritário (PvP 3/4 > 2/4 > 1/4 > PvE com espera > Solo 1v3 > demais) e modal `"🃏 SALAS"` com filtros (`Todas`, `PvP Públicas`, `PvE`), entrada por código e criação de salas públicas/privadas com auto-início ao atingir 4 jogadores.
  - **`ProximityPrompt` nas Cadeiras + `BillboardGui` Dinâmico (`Match.luau`)**: `Seat.CanTouch = false` elimina sentar por esbarrão, `ProximityPrompt` (`"Sentar na Mesa"`) nas cadeiras livres e `BillboardStatusMesa` acima de `Mesa.Topo` exibindo modo (`SOLO 1v3`, `DUPLA 2v2`, `TRIO 3v1`, `PVP 4P`), vagas (`2/4`) e placar ao vivo (`7 x 4`).
  - **Bot Substituto Anti-Abandono (Drop-in)**: desconexão/saída de humano em partida ativa (`CUTTING`, `DEALING`, `PLAYING`, `ELEVEN_DECISION`, `SCORING`) aciona `Match:SubstituirPorBotTemporario()` quando ainda há humanos na mesa, transferindo mão/mesa/Truco (`RoundManager:SubstituirJogador`, `TrucoHandler:SubstituirJogador`) e limpando bots temporários no reset.
  - **Rede, Documentação e Testes**: `MatchmakingEvent` e `GetRoomsData` adicionados em `default.project.json` e `TableManager.luau`, caso de uso `UC-15` documentado e testes automatizados adicionados em `test_match_flow.py`.
- 🧹 **Cleanup no Studio & Mapeamento de Mesas ([Issue #12](https://github.com/nicolasbelisario/Truco/issues/12))**:
  - Mesas PvE em `Workspace.MesasFolder` renomeadas para nomes únicos (`MesaPvE_Solo_1..2`, `MesaPvE_Dupla_1..2`, `MesaPvE_Trio_1..2`) com `Attribute` `TipoMesa` (`PvP`, `MesaPvE_Solo`, `MesaPvE_Dupla`, `MesaPvE_Trio`).
  - `TableManager.luau` atualizado para resolver `CONFIG_BOTS` por `Attribute("TipoMesa")`, nome exato ou prefixo (retrocompatível).
  - `Workspace.TestBot` órfão removido e `StarterGui.ScreenGui.TextLabel` (`PRÉ-ALPHA`) ajustado para `AnchorPoint (1, 1)`, `Position (1, -16, 1, -12)` e `TextScaled = true`.
  - Seção `Contrato do Mapa 3D` em `docs/wiki/ARCHITECTURE.md` e auditoria em `docs/wiki/ROBLOX_GROWTH_ROADMAP.md` atualizadas.
- 🛠️ **Correção dos 3 Bugs Críticos (`D-01`, `D-02`, `D-03` / Issue #7) & Auditoria SDD**:
  - **Mão de Onze para Humanos (`D-01`)**: Adicionados handlers `SHOW_ELEVEN_DECISION` / `HIDE_ELEVEN_DECISION` em `init.client.luau`, modal completo `PainelMaoDeOnze` em `UIManager.luau`, validação anti-cheat por `EquipeMaoDeOnze` e timeout de segurança de 20s em `RoundManager.luau`.
  - **Regra de Canga / Empate entre Parceiros (`D-02`)**: `RoundManager:JogarCarta()` envia `Team` em `CartasNaMesa`; `RuleManager.ObterVencedorRodada()` mantém a vitória da dupla quando parceiros empatam na maior carta e retorna `"DRAW"` se todas as 4 cartas forem cobertas (`maiorForca <= 0`).
  - **Race Condition de Corte e Delays (`D-03` / Issue #7)**: Adicionados `CorteFoiRealizado` e tokens `IDRodada` (`RoundManager.luau`) e `IDPartida` (`Match.luau`) protegendo `task.delay` e `task.wait`.
  - **Documentação SDD & Testes**: Todos os Use Cases de `UC_INDEX.md` criados/atualizados, `.gemini/GEMINI.md` e `docs/wiki/` sincronizados com o código real e Studio, `ADR-002` e `ROBLOX_GROWTH_ROADMAP.md` adicionados, e suítes Python das Skills expandidas (7 testes em `test_rules.py`, 12 em `test_match_flow.py`, 3 em `validate_configs.py`).
- 🏆 **Sistema de Ranking / Leaderboard Global ([Issue #3](https://github.com/nicolasbelisario/Truco/issues))**:
  - `LeaderboardManager.luau` com 3 `OrderedDataStore` (Vitórias, Pontos, Apoiadores/Robux).
  - Atualização do schema em `DataManager.luau` com persistência de `Vitorias`, `Derrotas`, `PartidasJogadas` e `RobuxGasto`.
  - Quadro físico 3D no mapa (Lobby SurfaceGui) com Top 10 e destaques de pódio.
  - Botão redondo TopBar escuro padrão do Roblox e Modal de Leaderboard completo com abas e card de desempenho próprio.
  - Gatilhos automáticos pós-partida em `Match.luau` e pós-compra em `RobuxManager.luau`.
  - RemoteFunction `GetLeaderboardData` sincronizada via `default.project.json`.

### Planejado
- Sistema de IA dos Bots com estratégia tática real ([Issue #1](https://github.com/nicolasbelisario/Truco/issues/1))
- Sinais clássicos de Truco, chat rápido seguro e animações de mesa ([Issue #4](https://github.com/nicolasbelisario/Truco/issues/4))
- Meta-Progressão: Conquistas, Missões Diárias, Daily Login e Win Streak ([Issue #5](https://github.com/nicolasbelisario/Truco/issues/5))
- Modo Truco Mineiro / Variantes de Regras ([Issue #6](https://github.com/nicolasbelisario/Truco/issues/6))
- Partidas Privadas com Convite de Amigos ([Issue #9](https://github.com/nicolasbelisario/Truco/issues/9))
- Controle unificado de BGM/SFX (`D-04`), sliders de volume e novos SFX ([Issue #10](https://github.com/nicolasbelisario/Truco/issues/10))
- Imersão Tabletop 3D: unificar `TableUI`/`TableVisuals`, monte/Vira 3D e mão em leque ([Issue #13](https://github.com/nicolasbelisario/Truco/issues/13))
- Redesign ambiental do Lobby (Boteco/Praça Paulista) e Pódio 3D Top 3 ([Issue #14](https://github.com/nicolasbelisario/Truco/issues/14))
- Novos cosméticos (Card Slam VFX, Títulos) e VIP Gamepass ([Issue #15](https://github.com/nicolasbelisario/Truco/issues/15))

### Bug Fixes & Ajustes de Cena Planejados
- `CameraManager` não aplica zoom de tensão em Bots (`D-05`) e Vira usa skin fixa ([Issue #11](https://github.com/nicolasbelisario/Truco/issues/11))

## [Skills & MCP Integration] — 2026-10-16

### Adicionado
- 🧠 **Skills Modulares com Testes Automatizados**:
  - `.gemini/skills/truco-core-rules/` + teste unitário desacoplado `test_rules.py`
  - `.gemini/skills/game-balance-economy/` + validador de integridade e compliance `validate_configs.py`
  - `.gemini/skills/truco-match-flow/` + teste de escalonamento de Truco `test_match_flow.py`
  - Espelhamento completo das skills no diretório `skills/` na raiz
- ⚙️ **Extração de Configurações (Single Source of Truth)** em `src/shared/Configs/`:
  - `EconomyConfig.luau` (catálogo oficial de skins, produtos Robux, recompensas PvP/PvE)
  - `BotConfig.luau` (calibração de agressividade, chances de blefe, tempos de reação)
  - `GameRulesConfig.luau` (limites temporais, valores de mão 1/3/6/9/12, estados de jogo)
- 📡 **Servidor MCP de Logs em Tempo Real** (`tools/mcp_roblox_logs/server.py`):
  - Ferramentas `read_roblox_studio_output`, `check_roblox_errors_and_warnings` e `get_roblox_log_session_info`
  - Configuração registrada em `mcp.json` para feedback contínuo

### Refatorado
- `ShopUI.luau` — agora consome dados de skins e produtos de Robux dinamicamente de `EconomyConfig`
- `ShopManager.luau` — valida preços diretamente da tabela unificada `EconomyConfig.PrecosSkins`
- `RobuxManager.luau` — processa produtos via mapas derivados de `EconomyConfig`
- `Bot.luau` — lógica de blefe, carta coberta e decisão de Truco desacoplada com parâmetros de `BotConfig`
- `Match.luau` — recompensas pós-partida e tempos vinculados a `EconomyConfig` e `GameRulesConfig`
- `TrucoHandler.luau` — timeout de resposta parametrizado em `GameRulesConfig`

---

## [SDD Migration] — 2026-10-15


### Adicionado
- 📄 Documentação SDD completa em `docs/`
  - `docs/wiki/README.md` — Wiki principal e índice de navegação
  - `docs/wiki/GLOSSARY.md` — Glossário da linguagem ubíqua do domínio
  - `docs/wiki/ARCHITECTURE.md` — Arquitetura, módulos, diagrama de estados e protocolo de rede
  - `docs/wiki/BUSINESS_RULES.md` — Regras de negócio invariantes (`RN-01` a `RN-36`)
  - `docs/use-cases/UC_INDEX.md` — Índice de Use Cases implementados e planejados
  - `docs/use-cases/UC-04_JogarCarta.md` — Use Case: Jogar Carta
  - `docs/use-cases/UC-05_PedirTruco.md` — Use Case: Pedir Truco
  - `docs/use-cases/UC-09_MaoDeOnze.md` — Use Case: Mão de Onze
  - `docs/CHANGELOG.md` — Este arquivo
  - `docs/ADR/ADR-001_SDD_Setup.md` — Decisão de adotar SDD
- 🐛 10 Issues criadas no GitHub com features e bugs identificados
- 📄 `docs/scripts/create_issues.sh` — Script para recriar as issues no GitHub
- 🗂️ `GEMINI.md` (`.gemini/`) — Regras de contexto já existiam, expandidas para SDD

---

## Versões Anteriores

> O projeto não possuía changelog antes desta migração SDD. O histórico de commits no Git serve como referência para mudanças anteriores.

```
git log --oneline
```

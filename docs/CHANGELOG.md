# 📅 Changelog

> Todas as mudanças notáveis neste projeto são documentadas aqui.
> Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

## [Não Lançado]

### Implementado
- 🏆 **Sistema de Ranking / Leaderboard Global ([Issue #3](https://github.com/nicolasbelisario/Truco/issues))**:
  - `LeaderboardManager.luau` com 3 `OrderedDataStore` (Vitórias, Pontos, Apoiadores/Robux).
  - Atualização do schema em `DataManager.luau` com persistência de `Vitorias`, `Derrotas`, `PartidasJogadas` e `RobuxGasto`.
  - Quadro físico 3D no mapa (Lobby SurfaceGui) com Top 10 e destaques de pódio.
  - Botão redondo TopBar escuro padrão do Roblox e Modal de Leaderboard completo com abas e card de desempenho próprio.
  - Gatilhos automáticos pós-partida em `Match.luau` e pós-compra em `RobuxManager.luau`.
  - RemoteFunction `GetLeaderboardData` sincronizada via `default.project.json`.

### Planejado
- Sistema de IA dos Bots com estratégia real ([Issue #1](https://github.com/nicolasbelisario/Truco/issues))
- Matchmaking / Sala Pública PvP ([Issue #2](https://github.com/nicolasbelisario/Truco/issues))
- Emotes e Chat de Mesa expandido ([Issue #4](https://github.com/nicolasbelisario/Truco/issues))
- Sistema de Conquistas / Achievements ([Issue #5](https://github.com/nicolasbelisario/Truco/issues))
- Modo Truco Mineiro / Variantes de Regras ([Issue #6](https://github.com/nicolasbelisario/Truco/issues))
- Tutorial Interativo In-Game ([Issue #8](https://github.com/nicolasbelisario/Truco/issues))
- Partidas Privadas com Convite de Amigos ([Issue #9](https://github.com/nicolasbelisario/Truco/issues))
- Melhorias de Áudio — SFX e Trilha Sonora ([Issue #10](https://github.com/nicolasbelisario/Truco/issues))

### Bug Fixes Planejados
- Timeout do Corte com condição de corrida ([Issue #7](https://github.com/nicolasbelisario/Truco/issues))

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

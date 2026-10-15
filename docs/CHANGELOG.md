# 📅 Changelog

> Todas as mudanças notáveis neste projeto são documentadas aqui.
> Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

---

## [Não Lançado]

### Planejado
- Sistema de IA dos Bots com estratégia real ([Issue #1](https://github.com/nicolasbelisario/Truco/issues))
- Matchmaking / Sala Pública PvP ([Issue #2](https://github.com/nicolasbelisario/Truco/issues))
- Ranking / Leaderboard Global ([Issue #3](https://github.com/nicolasbelisario/Truco/issues))
- Emotes e Chat de Mesa expandido ([Issue #4](https://github.com/nicolasbelisario/Truco/issues))
- Sistema de Conquistas / Achievements ([Issue #5](https://github.com/nicolasbelisario/Truco/issues))
- Modo Truco Mineiro / Variantes de Regras ([Issue #6](https://github.com/nicolasbelisario/Truco/issues))
- Tutorial Interativo In-Game ([Issue #8](https://github.com/nicolasbelisario/Truco/issues))
- Partidas Privadas com Convite de Amigos ([Issue #9](https://github.com/nicolasbelisario/Truco/issues))
- Melhorias de Áudio — SFX e Trilha Sonora ([Issue #10](https://github.com/nicolasbelisario/Truco/issues))

### Bug Fixes Planejados
- Timeout do Corte com condição de corrida ([Issue #7](https://github.com/nicolasbelisario/Truco/issues))

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

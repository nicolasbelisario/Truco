# 🃏 Truco Paulista — Wiki do Projeto

> Jogo de Truco Paulista multiplayer para a plataforma Roblox, desenvolvido em Luau com **Spec Driven Development (SDD)**, **Rojo** e integração **MCP com Roblox Studio**.

## Índice

| Documento | Descrição |
|-----------|-----------|
| [Arquitetura](./ARCHITECTURE.md) | Módulos reais, fluxo de estados, protocolo de rede, contrato 3D e MCP |
| [Regras de Negócio](./BUSINESS_RULES.md) | Regras invariantes (`RN-01` a `RN-39`) e divergências conhecidas |
| [Glossário](./GLOSSARY.md) | Linguagem ubíqua do domínio e termos proibidos |
| [Roadmap & Benchmark Roblox](./ROBLOX_GROWTH_ROADMAP.md) | Auditoria técnica/mapa e ideias de UI, mapa e features de sucesso |
| [Use Cases](../use-cases/UC_INDEX.md) | Índice completo de casos de uso implementados e planejados |
| [ADRs](../ADR/ADR-001_SDD_Setup.md) | Decisões arquiteturais (`ADR-001`, `ADR-002`) |
| [Changelog](../CHANGELOG.md) | Histórico de mudanças |
| [Issues / Backlog](https://github.com/nicolasbelisario/Truco/issues) | Funcionalidades e correções pendentes |

---

## Visão do Produto

**Truco Paulista** é um jogo de cartas brasileiro para 4 jogadores em duplas, implementado como experiência Roblox. Os jogadores podem jogar contra Bots IA ou outros jogadores humanos, personalizar suas cartas com skins autorais, acompanhar o ranking global e acumular pontos.

### Mesas e Modos de Jogo (`Workspace.MesasFolder`)

| Modelo no Mapa | Quantidade | Composição | Descrição |
|----------------|-----------|-----------|-----------|
| `Mesa1` a `Mesa4` | 4 mesas | 4 humanos | Full PvP local no servidor |
| `MesaPvE_Solo` | 2 mesas | 1 humano + 3 bots | Solo contra 3 bots |
| `MesaPvE_Dupla` | 2 mesas | 2 humanos + 2 bots | Dupla humana vs dupla de bots |
| `MesaPvE_Trio` | 2 mesas | 3 humanos + 1 bot | Quase PvP com 1 bot |

### Stack Técnica

- **Plataforma**: Roblox (Luau)
- **Padrão de Arquitetura**: Client-Server autoritativo com `RemoteEvents` / `RemoteFunction`
- **Configuração Centralizada**: `src/shared/Configs/` (Single Source of Truth)
- **Persistência**: `DataStoreService` (`TrucoData_v1`) + `OrderedDataStore` (`Leaderboard_*_v1`)
- **Build & Sync**: Rojo (`default.project.json`)
- **Qualidade SDD**: Skills em `.gemini/skills/` + MCP `Roblox_Studio` e `roblox-studio-logs`

---

## Quick Start para Desenvolvimento e Validação

```bash
# 1. Sincronizar código com o Roblox Studio via Rojo
rojo serve

# 2. Executar validações automatizadas das Skills SDD
python .gemini/skills/truco-core-rules/tests/test_rules.py
python .gemini/skills/truco-match-flow/tests/test_match_flow.py
python .gemini/skills/game-balance-economy/tests/validate_configs.py
```

> **Pré-requisitos**: Roblox Studio aberto com o plugin Rojo conectado e Python 3 para os validadores SDD e MCP de logs.

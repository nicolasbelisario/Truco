# 🃏 Truco Paulista — Wiki do Projeto

> Jogo de Truco Paulista multiplayer para a plataforma Roblox, desenvolvido em Luau.

## Índice

| Documento | Descrição |
|-----------|-----------|
| [Arquitetura](./ARCHITECTURE.md) | Visão geral da arquitetura, módulos e fluxo de dados |
| [Regras de Negócio](./BUSINESS_RULES.md) | Regras invariantes, validações e casos de borda |
| [Glossário](./GLOSSARY.md) | Linguagem ubíqua do domínio |
| [Use Cases](../use-cases/UC_INDEX.md) | Casos de uso documentados |
| [Changelog](../CHANGELOG.md) | Histórico de mudanças |
| [Issues / Backlog](https://github.com/nicolasbelisario/Truco/issues) | Funcionalidades pendentes |

---

## Visão do Produto

**Truco Paulista** é um jogo de cartas brasileiro para 4 jogadores em duplas, implementado como experiência Roblox. Os jogadores podem jogar contra Bots IA ou outros jogadores humanos, personalizar suas cartas com skins e acumular pontos.

### Modos de Jogo

| Mesa | Composição | Descrição |
|------|-----------|-----------|
| `MesaPvE_Solo` | 1 humano + 3 bots | Solo contra 3 bots |
| `MesaPvE_Dupla` | 2 humanos + 2 bots | Dupla humana vs dupla de bots |
| `MesaPvE_Trio` | 3 humanos + 1 bot | Quase PvP com 1 bot |
| PvP (futuro) | 4 humanos | Full PvP via matchmaking |

### Stack Técnica

- **Plataforma**: Roblox (Luau)
- **Padrão de Arquitetura**: Client-Server com RemoteEvents
- **Persistência**: DataStoreService (`TrucoData_v1`)
- **Build Tool**: Rojo (estrutura `src/`)
- **Linguagem**: Luau (superset de Lua 5.1)

---

## Quick Start para Desenvolvimento

```bash
# Clone o repositório
git clone https://github.com/nicolasbelisario/Truco.git

# Instale Rojo e sincronize com o Roblox Studio
rojo serve
```

> **Pré-requisitos**: Roblox Studio, extensão Rojo instalada no Studio.

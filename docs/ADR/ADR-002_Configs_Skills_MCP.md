# ADR-002 — Configurações Centralizadas, Skills Automatizadas e Integração MCP

**Data**: 2026-10-16 *(atualizado em 2026-11-15)*  
**Status**: ✅ Aceito  
**Decisores**: nicolasbelisario (maintainer)  

---

## Contexto

Após a adoção inicial do SDD ([ADR-001](./ADR-001_SDD_Setup.md)), identificou-se que:
1. Parâmetros de balanceamento (recompensas PvP/PvE, preços de skins, produtos de Robux, tempos de rodada e agressividade de Bots) estavam espalhados em múltiplos scripts de cliente e servidor.
2. As regras de negócio precisavam de validação automática executável localmente sem depender de abertura manual do Roblox Studio para cada checagem simples.
3. Os agentes de IA precisavam de visibilidade direta do output de logs e da hierarquia 3D do Studio para evitar suposições sobre objetos no `Workspace`.

---

## Decisão

1. **Single Source of Truth em `src/shared/Configs/`**:
   - `EconomyConfig.luau` — Recompensas, skins e produtos Robux (`ProdutosPontosMap`, `DoacoesMap`).
   - `BotConfig.luau` — Tempos e dificuldades (`Facil`, `Normal`, `Dificil`).
   - `GameRulesConfig.luau` — Limites numéricos, tempos, valores de Mão, `States` e `TEAMS` (com `GameConfig.luau` preservado como wrapper de retrocompatibilidade).
2. **Skills Modulares SDD (`.gemini/skills/` espelhadas em `skills/`)**:
   - `truco-core-rules` + `tests/test_rules.py`
   - `truco-match-flow` + `tests/test_match_flow.py`
   - `game-balance-economy` + `tests/validate_configs.py`
3. **Integração MCP dupla**:
   - `Roblox_Studio`: inspeção direta do DataModel (`Edit`/`Client`/`Server`), propriedades 3D e capturas de viewport.
   - `roblox-studio-logs` (`tools/mcp_roblox_logs/server.py` registrado em `mcp.json`): monitoramento contínuo de erros e warnings nos logs locais do Roblox Studio.

---

## Consequências

### Positivas
- Alterações de economia, balanceamento de Bots e tempos de partida ocorrem em um único arquivo de configuração compartilhado entre servidor e cliente.
- Regressões de regras do Truco Paulista e violações de compliance (`RN-09`) são detectadas em milissegundos via Python `unittest`.
- IAs conseguem validar o contrato real entre `src/` e o mapa 3D no Roblox Studio via MCP.

### Trade-offs / Cuidados
- Os testes Python das Skills validam espelhos/modelos de regras e configs estáticos (não executam Luau nativo diretamente dentro do Roblox Engine). Testes end-to-end de UI e rede continuam exigindo Playtest no Roblox Studio.
- É necessário manter `.gemini/skills/` e `skills/` sincronizados a cada atualização.

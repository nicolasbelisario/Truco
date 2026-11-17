---
name: game-balance-economy
description: Especificação e invariantes do sistema de economia, catálogo de skins, compras Robux, recompensas por partida, ranking e balanceamento de Bots.
---

# Skill: Economia, Loja & Balanceamento (`game-balance-economy`)

## 1. Propósito do Módulo
Centralizar todas as variáveis de balanceamento do jogo em um diretório único (`src/shared/Configs/`), garantindo que alterações de preços de skins, recompensas por vitória/derrota, produtos de Robux e parâmetros de agressividade de Bots sejam feitas exclusivamente via configuração, sem reescrever lógica funcional de negócio.

---

## 2. Regras de Negócio Inegociáveis (Invariantes)

1. **[RN-09] Proibição de Terminologia de Apostas**:
   - É estritamente vedado o uso dos termos `aposta`, `gambling`, `bet` ou `stake` no catálogo de itens, nomes de produtos ou interfaces.
2. **[RN-13 & RN-14] Recompensas Pós-Partida**:
   - Todo jogador que conclui uma partida recebe recompensa em Pontos.
   - Partidas PvP (sem bots) devem conceder mais pontos do que partidas PvE:
     $$\text{Vitória PvP} = 50 \text{ pts} > \text{Vitória PvE} = 30 \text{ pts}$$
     $$\text{Derrota PvP} = 20 \text{ pts} > \text{Derrota PvE} = 10 \text{ pts}$$
3. **[RN-15] Moeda Fechada**:
   - Os pontos acumulados têm como uso exclusivo o desbloqueio de skins cosméticas de baralhos e cartas.
4. **[RN-32] Skin Gratuita Inicial**:
   - A skin `"Padrao"` deve ter preço $0$ e vir previamente adicionada ao inventário de qualquer jogador recém-cadastrado.
5. **[RN-34] Transações Robux (ProcessReceipt)**:
   - Toda compra via Robux deve retornar `PurchaseGranted` apenas após o crédito seguro dos pontos ou registro de `RobuxGasto` (doações), garantindo rastreamento no ranking de Apoiadores.
6. **[RN-37 & RN-38] Persistência e Ranking Global (OrderedDataStore)**:
   - O `DataManager` persiste `Pontos`, `Vitorias`, `Derrotas`, `PartidasJogadas`, `RobuxGasto`, `SkinsCompradas` e `SkinEquipada` em `TrucoData_v1`.
   - O `LeaderboardManager` sincroniza os 3 `OrderedDataStore` globais (`Vitorias`, `Pontos`, `Robux`) via callback `OnStatChanged` e alimenta tanto o modal (`LeaderboardUI`) quanto o quadro físico 3D (`Workspace.LeaderboardBoard`).

---

## 3. Arquivos de Código Pertencentes a este Módulo
- `src/shared/Configs/EconomyConfig.luau` — Catálogo de skins, produtos Robux e tabelas de recompensas.
- `src/shared/Configs/BotConfig.luau` — Parâmetros de agressividade, tempos de pensamento e blefe.
- `src/shared/Configs/GameRulesConfig.luau` — Limites temporais e escalonamento de pontos.
- `src/server/ShopManager.luau` — Validação e processamento de compra/equipar no servidor.
- `src/server/RobuxManager.luau` — ProcessReceipt de produtos de desenvolvimento e doações.
- `src/server/DataManager.luau` — Persistência no DataStore (`TrucoData_v1`) e disparo de `OnStatChanged`.
- `src/server/LeaderboardManager.luau` — `OrderedDataStore` (Vitórias, Pontos, Apoiadores) e quadro físico 3D.
- `src/client/UI/LeaderboardUI.luau` — Modal de Ranking global com abas e card de desempenho próprio.

---

## 4. Script de Validação e Testes
Valida a consistência de IDs de produtos, preços positivos, skin padrão gratuita e estrutura do catálogo:

- **Caminho**: `.gemini/skills/game-balance-economy/tests/validate_configs.py`
- **Execução**:
  ```bash
  python .gemini/skills/game-balance-economy/tests/validate_configs.py
  ```
- **Critério de Sucesso**: Nenhuma inconsistência de IDs duplicados, termos proibidos ou preços negativos.

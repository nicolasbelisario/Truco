# UC-17 — Visualizar Ranking Global

**Ator Principal**: Jogador  
**Pré-condições**: `LeaderboardManager` inicializado e `GetLeaderboardData` disponível em `ReplicatedStorage.Events`  
**Regras de Negócio**: RN-37, RN-38  

---

## Fluxo Principal — Modal de Ranking na UI

```
1. Jogador clica no botão 🏆 da barra superior esquerda (LeaderboardUI)
2. LeaderboardUI.Abrir() exibe o modal e invoca rfGetLeaderboard:InvokeServer(categoria)
3. Servidor (LeaderboardManager) retorna Top 50 em cache da categoria ("Vitorias", "Pontos" ou "Robux")
   e o bloco MeuDado (Pontos, Vitorias, Derrotas, PartidasJogadas, RobuxGasto)
4. Cliente renderiza lista com avatar, medalhas de pódio (🥇🥈🥉) e card de desempenho no rodapé
5. Jogador pode alternar entre as abas 🏆 Vitórias, ⭐ Pontos e 💎 Apoiadores
```

## Fluxo Secundário — Quadro Físico 3D no Lobby

- `LeaderboardManager._ConfigurarQuadroNoMapa()` injeta uma `SurfaceGui` (`LeaderboardSurfaceGui`) na peça `Workspace.LeaderboardBoard` exibindo o Top 10 de Vitórias, atualizado automaticamente a cada 60 segundos ou após mudança de estatísticas.

---

## Implementação

- [`LeaderboardManager.luau`](../../src/server/LeaderboardManager.luau)
- [`LeaderboardUI.luau`](../../src/client/UI/LeaderboardUI.luau)
- [`DataManager.luau`](../../src/server/DataManager.luau#L39-L102)

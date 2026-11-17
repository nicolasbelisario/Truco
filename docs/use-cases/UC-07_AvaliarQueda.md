# UC-07 — Avaliar Vencedor da Queda

**Ator Principal**: Servidor  
**Pré-condições**: 4 cartas jogadas na queda atual (`#CartasNaMesa == 4`)  
**Regras de Negócio**: RN-06, RN-07, RN-08, RN-17, RN-19, RN-20  

---

## Fluxo Principal

```
1. RoundManager:AvaliarQueda() chama RuleManager.ObterVencedorRodada(CartasNaMesa)
2. RuleManager calcula a força de cada carta:
   - Se IsHidden == true -> força = 0
   - Se ManilhaStrength > 0 -> força = 100 + ManilhaStrength (101..104)
   - Caso contrário -> força = Strength padrão (1..10)
3. Se houver vencedor único: equipeVencedora ("A" ou "B") ganha a queda e vencedor inicia a próxima queda
4. Se retornar "DRAW": primeiro jogador da queda mantém a vez e HistoricoQuedas registra "DRAW"
5. CartasNaMesa é limpa e EventBroadcaster emite CLEAR_TABLE(QuedasGanhas)
6. Avalia se já há vencedor da Mão (melhor de 3 quedas ou regra de Canga)
7. Se não houver vencedor da Mão: aguarda 1s e chama AvancarTurno()
8. Se houver vencedor (ou empate total nas 3 quedas): chama Match:FinalizarMao(vencedorMao, ValorRodada)
```

## Regra de Empate entre Parceiros (`D-02` Corrigido)

- `RoundManager:JogarCarta()` envia `Team = ctx:ObterEquipe(jogador)` em `CartasNaMesa`.
- `RuleManager.ObterVencedorRodada()` só retorna `"DRAW"` se as maiores cartas empatadas pertencerem a **duplas adversárias** ou se todas as cartas forem cobertas (`maiorForca <= 0`). Se parceiros da mesma equipe empatarem na maior carta, vence o primeiro parceiro que a jogou.

---

## Implementação

- [`RoundManager:AvaliarQueda()`](../../src/server/Classes/RoundManager.luau#L233-L287)
- [`RuleManager.CalcularForcaCarta()`](../../src/server/Utils/RuleManager.luau#L4-L15)
- [`RuleManager.ObterVencedorRodada()`](../../src/server/Utils/RuleManager.luau#L18-L46)

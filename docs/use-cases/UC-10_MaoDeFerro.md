# UC-10 — Mão de Ferro

**Ator Principal**: Servidor  
**Pré-condições**: `Placar.TeamA == 11` e `Placar.TeamB == 11` ao chamar `VerificarProximaRodada()`  
**Regras de Negócio**: RN-30, RN-31  

---

## Fluxo Principal

```
1. Match:VerificarProximaRodada() detecta empate em 11 x 11
2. Chama RoundManager:IniciarMaoDeFerro()
3. Servidor limpa rodada definindo ValorRodada = 3 e envia UPDATE_ROUND_VALUE(3)
4. Desativa chamadas de Truco via TrucoHandler:SetTrucoAtivo(false) (emite HIDE_TRUCO_BTN)
5. Prepara baralho, realiza corte padrão interno e distribui 3 cartas por jogador
6. Chama iniciarTurnosPosDistribuicao() diretamente para PLAYING (sem fase de decisão nem corte manual)
7. Dupla que vencer a Mão soma 3 pontos, atingindo 14 (>= 12) e vencendo a partida
```

> [!NOTE]
> Na implementação atual, `iniciarTurnosPosDistribuicao()` envia `DealCards` normalmente aos jogadores humanos, funcionando como uma Mão de 3 pontos direta sem corte manual e sem Truco. O modo "no escuro" completo (esconder as próprias cartas do jogador) é um refinamento visual planejado.

---

## Implementação

- [`Match:VerificarProximaRodada()`](../../src/server/Classes/Match.luau#L238-L239)
- [`RoundManager:IniciarMaoDeFerro()`](../../src/server/Classes/RoundManager.luau#L363-L370)

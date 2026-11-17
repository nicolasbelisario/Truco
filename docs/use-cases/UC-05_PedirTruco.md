# UC-05 — Pedir Truco

**Ator Principal**: Jogador, Bot  
**Pré-condições**: Estado == `PLAYING`, `TrucoAtivo == true`, valor atual < 12  
**Regras de Negócio**: RN-10, RN-11, RN-12, RN-22, RN-23, RN-26  

---

## Fluxo Principal

```
1. Jogador clica no botão de Truco (ou Bot decide pedir via BotConfig)
2. Cliente dispara TrucoEvent("Request")
3. Servidor → TrucoHandler:ProcessarRequest(jogador)
4. Servidor valida:
   a. TrucoAtivo == true (não é Mão de Onze/Ferro)
   b. AguardandoResposta == false (sem pedido em aberto)
   c. EquipePediu != equipe do jogador (mesma equipe não pede duas vezes)
   d. Próximo valor (prox) <= 12
5. Estado atualizado: AguardandoResposta = true, EquipePediu = equipe, ValorPendente = prox, IDDesafio += 1
6. EventBroadcaster emite TRUCO_CALLED(prox) para todos
7. TrucoHandler:_PedirResposta() envia RequestAction("TrucoChallenge") à equipe desafiada
8. Timer de 15s (GameRulesConfig.Tempos.LimiteRespostaTruco) inicia (RN-26)
```

## Escalonamento de Valores

| Valor Atual | Próximo Valor | Chamada |
|-------------|--------------|---------|
| 1 | 3 | Truco |
| 3 | 6 | Seis |
| 6 | 9 | Nove |
| 9 | 12 | Doze |
| 12 | — | Não permitido |

## Fluxos Alternativos

### FA-1: Mão de Onze ou Ferro ativa
- Passo 4a falha → ação ignorada (`TrucoAtivo == false`).

### FA-2: Bot pede Truco
- `Bot:JogarTurno()` decide pedir quando `valorMao == 1` com probabilidade `BotConfig.Dificuldades[dificuldade].ChanceTrucoMaoBase` (10% na dificuldade `Normal`).
- Futuro: avaliar força real da mão ([Issue #1](https://github.com/nicolasbelisario/Truco/issues)).

### FA-3: Timeout sem resposta (15s)
- Se `IDDesafio` permanecer igual após `LimiteRespostaTruco`, `TrucoHandler` emite `TRUCO_TIMEOUT` e chama `_Resolver(false, true)` (equipe desafiada corre automaticamente).

---

## Implementação

- [`TrucoHandler:ProcessarRequest()`](../../src/server/Classes/TrucoHandler.luau#L50-L68)
- [`TrucoHandler:_PedirResposta()`](../../src/server/Classes/TrucoHandler.luau#L147-L181)
- [`GameRulesConfig.luau`](../../src/shared/Configs/GameRulesConfig.luau)
- [`BotConfig.luau`](../../src/shared/Configs/BotConfig.luau)

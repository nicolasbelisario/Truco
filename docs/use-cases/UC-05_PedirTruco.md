# UC-05 — Pedir Truco

**Ator Principal**: Jogador, Bot  
**Pré-condições**: Estado == `PLAYING`, `TrucoAtivo == true`, valor atual < 12  
**Regras de Negócio**: RN-10, RN-11, RN-22, RN-23, RN-24, RN-26  

---

## Fluxo Principal

```
1. Jogador clica no botão de Truco (ou Bot decide pedir)
2. Cliente dispara TrucoEvent("Request")
3. Servidor → TrucoHandler:ProcessarRequest(jogador)
4. Servidor valida:
   a. TrucoAtivo == true (não é Mão de Onze/Ferro)
   b. AguardandoResposta == false (sem pedido em aberto)
   c. EquipePediu != equipe do jogador (mesma equipe não pede duas vezes)
   d. Próximo valor (prox) <= 12
5. Estado atualizado: AguardandoResposta=true, EquipePediu=equipe, IDDesafio++
6. EventBroadcaster emite TRUCO_CALLED(prox) para todos
7. TrucoHandler._PedirResposta() notifica a equipe desafiada
8. Timer de 15s inicia (RN-26) — se expirar, equipe automaticamente corre
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
- Passo 4a falha → ação ignorada (TrucoAtivo == false)

### FA-2: Bot pede Truco
- Servidor chama `Bot:JogarTurno()` que decide com 10% de chance (lógica atual)
- Futuro: avaliar força da mão ([Issue #1](https://github.com/nicolasbelisario/Truco/issues))

### FA-3: Timeout sem resposta (15s)
- TrucoHandler emite `TRUCO_TIMEOUT` para todos
- `_Resolver(false, true)` — equipe desafiada corre automaticamente

---

## Implementação

- [`TrucoHandler:ProcessarRequest()`](../../src/server/Classes/TrucoHandler.luau#L47-L65)
- [`TrucoHandler:_PedirResposta()`](../../src/server/Classes/TrucoHandler.luau#L144-L177)

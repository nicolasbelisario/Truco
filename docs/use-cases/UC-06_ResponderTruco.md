# UC-06 — Responder ao Truco

**Ator Principal**: Jogador, Bot  
**Pré-condições**: `TrucoHandler.Estado.AguardandoResposta == true`  
**Regras de Negócio**: RN-11, RN-24, RN-25, RN-26, RN-27  

---

## Fluxo Principal

```
1. Equipe desafiada recebe RequestAction("TrucoChallenge", {Value, Caller, TimeLimit})
2. Jogador escolhe no modal TrucoUI: "DESCER" (Aceitar), "FUGIR" (Correr) ou "AUMENTAR" (Aumentar)
3. Cliente envia TrucoEvent("Response", subAcao)
4. TrucoHandler:ProcessarResponse() valida que AguardandoResposta == true e jogador pertence à equipe desafiada
5. Se parceiro for Bot (ou ausente): executa a decisão imediatamente
6. Desfecho executado:
   - Aceitar: ValorAtual = ValorPendente, emite TRUCO_ACEITO, libera botão de aumento apenas à equipe que aceitou
   - Correr: emite TRUCO_FUGIU, aguarda 2s, FinalizarMao(equipePediu, ValorAtual anterior)
   - Aumentar: ValorAtual = ValorPendente, escala prox = min(ValorAtual + 3, 12), inverte EquipePediu e reinicia _PedirResposta()
```

## Fluxos Alternativos

### FA-1: Dupla composta por 2 jogadores humanos (`RN-27`)
- Servidor registra `self.Estado.Votos[jogador] = subAcao`.
- Emite `PARTNER_VOTED(subAcao)` para o parceiro e `WAITING_PARTNER(0)` para quem votou.
- A ação só é executada quando `Votos[parceiro] == subAcao`.

### FA-2: Equipe desafiada composta apenas por Bots
- `TrucoHandler:_PedirResposta()` agenda `Bot:DecidirTruco()` (delay de `1–3s` + `BotConfig.TempoRespostaTruco`).
- Bot decide entre `"Aceitar"` e `"Correr"` conforme `ChanceAceitarTruco`.

---

## Implementação

- [`TrucoHandler:ProcessarResponse()`](../../src/server/Classes/TrucoHandler.luau#L77-L113)
- [`TrucoHandler:_Resolver()`](../../src/server/Classes/TrucoHandler.luau#L121-L138)
- [`TrucoUI.luau`](../../src/client/UI/TrucoUI.luau)
- [`Bot:DecidirTruco()`](../../src/server/Classes/Bot.luau#L67-L81)

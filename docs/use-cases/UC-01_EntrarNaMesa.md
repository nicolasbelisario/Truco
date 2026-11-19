# UC-01 — Entrar na Mesa de Jogo

**Ator Principal**: Jogador  
**Pré-condições**: Mesa inicializada em `Workspace.MesasFolder` pelo `TableManager`  
**Regras de Negócio**: RN-01, RN-02, RN-35  

---

## Fluxo Principal

```
1. Jogador entra em uma mesa livre via:
   - ProximityPrompt ("Sentar na Mesa" [E]) em Cadeira1..Cadeira4 (Seat.CanTouch = false evita esbarrões)
   - Botão "▶ JOGAR AGORA" (Quick Play) ou Modal "🃏 SALAS" (ver UC-15)
2. Servidor executa Match:SentarJogadorNoAssento() e detecta alteração em objetoAssento:GetPropertyChangedSignal("Occupant")
3. Match:ProcessarMudancaAssento() valida que a cadeira não é reservada para Bot nem sala privada não autorizada
4. Servidor registra self.Assentos[nomeAssento] = jogador, atualiza BillboardGui/Prompts e executa OnPlayerJoin(jogador)
5. EventBroadcaster envia para o jogador: SHOW_SCOREBOARD, UPDATE_SCORE e WAITING
6. Cliente (init.client.luau) detecta Humanoid.Sit == true, desabilita ProximityPromptService local,
   oculta barra de lobby, define a mesa em TableVisuals e calcula minhaEquipe (ímpar = "A", par = "B")
```

## Fluxos Alternativos

### FA-1: Tentativa de sentar em cadeira de Bot
- Em mesas PvE (`self.UsaBots`), cadeiras de bots possuem `Disabled = true` e não exibem `ProximityPrompt`; se houver tentativa forçada, o servidor força `humanoide.Jump = true` e não ocupa o assento.

### FA-2: Jogador levanta da cadeira ou desconecta
- Em `WAITING` / `COUNTDOWN`: `self.Assentos[nomeAssento]` é limpo, prompts e `BillboardGui` são atualizados (e a contagem é cancelada em `COUNTDOWN`).
- Em partida ativa (`CUTTING`, `DEALING`, `PLAYING`, `ELEVEN_DECISION`, `SCORING`):
  - Se ainda houver **ao menos 1 humano** na mesa, o servidor aciona o **Bot Substituto Anti-Abandono (Drop-in)** via `Match:SubstituirPorBotTemporario()` (ver [UC-15](./UC-15_OnboardingMatchmakingDropIn.md)), permitindo que os demais concluam a partida.
  - Se **0 humanos** restarem, o servidor chama `Match:ResetarPartida("Todos os jogadores saíram.")`.

---

## Implementação

- [`TableManager.Inicializar()`](../../src/server/TableManager.luau#L17-L36)
- [`Match:ConfigurarAssentos()`](../../src/server/Classes/Match.luau#L50-L69)
- [`Match:ProcessarMudancaAssento()`](../../src/server/Classes/Match.luau#L94-L121)
- [`atualizarStatusAssento()`](../../src/client/init.client.luau#L22-L46)

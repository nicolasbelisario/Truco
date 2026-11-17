# UC-01 — Entrar na Mesa de Jogo

**Ator Principal**: Jogador  
**Pré-condições**: Mesa inicializada em `Workspace.MesasFolder` pelo `TableManager`  
**Regras de Negócio**: RN-01, RN-02, RN-35  

---

## Fluxo Principal

```
1. Jogador caminha até uma mesa 3D e senta em uma Seat livre (Cadeira1..Cadeira4)
2. Servidor detecta alteração em objetoAssento:GetPropertyChangedSignal("Occupant")
3. Match:ProcessarMudancaAssento() valida que a cadeira não é reservada para Bot
4. Servidor registra self.Assentos[nomeAssento] = jogador e executa OnPlayerJoin(jogador)
5. EventBroadcaster envia para o jogador: SHOW_SCOREBOARD, UPDATE_SCORE e WAITING
6. Cliente (init.client.luau) detecta Humanoid.Sit == true, define a mesa em TableVisuals
   e calcula minhaEquipe (ímpar = "A", par = "B")
```

## Fluxos Alternativos

### FA-1: Tentativa de sentar em cadeira de Bot
- Em mesas PvE (`self.UsaBots`), se o número da cadeira estiver em `self.AssentosBots`, o servidor força `humanoide.Jump = true` e não ocupa o assento.

### FA-2: Jogador levanta da cadeira
- `assento.Occupant` torna-se `nil` → servidor executa `OnPlayerLeave`, envia `HIDE_GAME_UI` e limpa `self.Assentos[nomeAssento]`.
- Se `self.Estado ~= "WAITING"`, o servidor aborta e chama `Match:ResetarPartida("Jogador saiu!")`, destravando os pulos dos demais.

---

## Implementação

- [`TableManager.Inicializar()`](../../src/server/TableManager.luau#L17-L36)
- [`Match:ConfigurarAssentos()`](../../src/server/Classes/Match.luau#L50-L69)
- [`Match:ProcessarMudancaAssento()`](../../src/server/Classes/Match.luau#L94-L121)
- [`atualizarStatusAssento()`](../../src/client/init.client.luau#L22-L46)

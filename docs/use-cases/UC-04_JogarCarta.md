# UC-04 — Jogar Carta

**Ator Principal**: Jogador, Bot  
**Pré-condições**: Estado da Partida é `PLAYING`, não há Truco aguardando resposta  
**Regras de Negócio**: RN-04, RN-12, RN-17, RN-18, RN-35, RN-36  

---

## Fluxo Principal

```
1. É a vez do Jogador (IndexTurnoAtual == cadeira do Jogador)
2. Jogador seleciona uma carta em sua mão e clica (ou Bot decide via BotConfig)
3. Cliente dispara PlayCardEvent(cardId, escondida)
4. Servidor recebe evento em TableManager → roteia para Partida
5. Partida:JogadorJogarCarta() resolve a skin equipada e chama RoundManager:JogarCarta()
6. Servidor valida:
   a. Estado == "PLAYING"
   b. TrucoHandler.Estado.AguardandoResposta == false
   c. Jogador é o da vez (IndexTurnoAtual)
   d. Carta está na mão do jogador no servidor (anti-cheat RN-36)
7. Carta é inserida em CartasNaMesa com metadados e skin
8. EventBroadcaster.CartaJogada emite CardPlayedOnTable para todos os humanos
9. Se #CartasNaMesa < 4: avança turno em sentido anti-horário e chama AvancarTurno()
10. Se #CartasNaMesa == 4: aguarda 1.5s e chama AvaliarQueda()
```

## Fluxos Alternativos

### FA-1: Carta coberta na 1ª Queda
- Passo 6: `numRodada == 1 → escondida = false` (`RN-18` forçado no servidor e na UI `HandUI`).

### FA-2: Jogador fora de turno ou desafio de Truco ativo
- Passo 6a/6b/6c falha → ação ignorada silenciosamente.

### FA-3: Carta inválida (anti-cheat)
- Passo 6d falha → `warn("ANTICHEAT...")` + retorno sem modificar estado.

### FA-4: Bot é o jogador da vez
- `Bot:JogarTurno()` aguarda `TempoPensamento` (`BotConfig`: `1.5s–3.0s`), pode pedir Truco (`ChanceTrucoMaoBase`) ou escolher carta da mão (com `ChanceEsconderCarta` se `numeroQueda > 1`).

---

## Dados

**Input**: `cardId: string` (ex: `"A_Espadas"`), `escondida: boolean`  
**Output**: Estado atualizado em `CartasNaMesa`, evento `CardPlayedOnTable` emitido

---

## Implementação

- [`RoundManager:JogarCarta()`](../../src/server/Classes/RoundManager.luau#L159-L206)
- [`Bot:JogarTurno()`](../../src/server/Classes/Bot.luau#L35-L64)
- [`BotConfig.luau`](../../src/shared/Configs/BotConfig.luau)
- [`EventBroadcaster.CartaJogada()`](../../src/server/Classes/EventBroadcaster.luau#L71-L75)
- [`HandUI.AdicionarCarta()`](../../src/client/UI/HandUI.luau#L45-L85)

# UC-04 — Jogar Carta

**Ator Principal**: Jogador, Bot  
**Pré-condições**: Estado da Partida é `PLAYING`, não há Truco aguardando resposta  
**Regras de Negócio**: RN-04, RN-17, RN-18, RN-35, RN-36  

---

## Fluxo Principal

```
1. É a vez do Jogador (IndexTurnoAtual == cadeira do Jogador)
2. Jogador seleciona uma carta em sua mão e clica (ou Bot decide)
3. Cliente dispara PlayCardEvent(cardId, escondida)
4. Servidor recebe evento em TableManager → roteia para Partida
5. Partida.JogadorJogarCarta() → RoundManager.JogarCarta()
6. Servidor valida:
   a. Estado == "PLAYING"
   b. TrucoHandler.AguardandoResposta == false
   c. Jogador é o da vez (IndexTurnoAtual)
   d. Carta está na mão do jogador no servidor (anti-cheat RN-36)
7. Carta é inserida em CartasNaMesa com metadados
8. EventBroadcaster emite CARD_PLAYED para todos os humanos
9. Se CartasNaMesa < 4: avança para o próximo jogador
10. Se CartasNaMesa == 4: aguarda 1.5s e chama AvaliarQueda()
```

## Fluxos Alternativos

### FA-1: Carta coberta na 1ª Queda
- Passo 6a: `numRodada == 1 → escondida = false` (RN-18 forçado)

### FA-2: Jogador fora de turno
- Passo 6c falha → ação ignorada silenciosamente

### FA-3: Carta inválida (anti-cheat)
- Passo 6d falha → `warn(ANTICHEAT...)` + retorno sem modificar estado

### FA-4: Bot é o jogador da vez
- Passo 2: `Bot:JogarTurno()` chamado pelo servidor após `AvancarTurno()`
- Bot simula "pensamento" de 1.5–3 segundos antes de jogar

---

## Dados

**Input**: `cardId: string` (ex: `"A_Espadas_1"`), `escondida: boolean`  
**Output**: Estado atualizado em `CartasNaMesa`, evento `CARD_PLAYED` emitido

---

## Implementação

- [`RoundManager:JogarCarta()`](../../src/server/Classes/RoundManager.luau#L159-L206)
- [`Bot:JogarTurno()`](../../src/server/Classes/Bot.luau#L30-L57)
- [`EventBroadcaster.CartaJogada()`](../../src/server/Classes/EventBroadcaster.luau)

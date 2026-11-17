# UC-03 — Distribuir Cartas

**Ator Principal**: Servidor  
**Pré-condições**: Baralho criado/embaralhado e fase `CUTTING` concluída (ou entrada direta via Mão de Onze/Ferro)  
**Regras de Negócio**: RN-03, RN-04, RN-05, RN-06, RN-07  

---

## Fluxo Principal

```
1. RoundManager:DistribuirCartas() altera estado da Partida para DEALING
2. EventBroadcaster envia DEALING(0) (cliente toca som Shuffle e fecha menu de corte)
3. Servidor remove a primeira carta do topo como ViraAtual
4. DeckManager.DefinirManilhas() marca ManilhaStrength (4/3/2/1) nas 4 manilhas da mão
5. Para cada cadeira de 1 a 4:
   a. Remove 3 cartas do baralho e salva em self.MaosJogadores[jogador]
   b. Se Bot: chama Bot:ReceberMao(mao, ViraAtual)
   c. Se Humano: EventBroadcaster.DistribuirCartas envia DealCards(mao, ViraAtual, nomeParceiro)
      e GameStatusEvent("SHOW_GAME_UI")
6. Aguarda 1s, muda estado para PLAYING, define IndexTurnoAtual = Mão (à esquerda do Dealer)
   e chama AvancarTurno()
```

## Fluxos Alternativos

### FA-1: Distribuição interna (Mão de Onze / Mão de Ferro)
- `RoundManager:prepararBaralhoEDistribuirInternamente()` executa o corte padrão e popula `MaosJogadores` antes de liberar a exibição aos clientes (`iniciarTurnosPosDistribuicao()`).

---

## Implementação

- [`RoundManager:DistribuirCartas()`](../../src/server/Classes/RoundManager.luau#L97-L129)
- [`DeckManager.CriarBaralho()`](../../src/server/Utils/DeckManager.luau#L8-L24)
- [`DeckManager.DefinirManilhas()`](../../src/server/Utils/DeckManager.luau#L27-L55)
- [`EventBroadcaster.DistribuirCartas()`](../../src/server/Classes/EventBroadcaster.luau#L45-L48)

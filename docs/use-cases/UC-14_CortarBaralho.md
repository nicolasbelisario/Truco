# UC-14 — Cortar Baralho

**Ator Principal**: Jogador, Bot  
**Pré-condições**: Início de nova Mão normal (`Estado == "CUTTING"`), jogador ocupa a cadeira `Corte` (à direita do Distribuidor)  
**Regras de Negócio**: RN-05, RN-35  

---

## Fluxo Principal

```
1. RoundManager:IniciarNovaRodada() cria e embaralha o baralho e muda Estado para "CUTTING"
2. ObterPapeis() define Corte = (IndexDistribuidor % 4) + 1
3. Se ocupante da cadeira Corte for humano:
   - EventBroadcaster.PedirAcao(jogadorCorte, "EscolhaOCorte", 10) abre menu com botões 1x, 2x, 3x
   - Jogador seleciona quantidade -> cliente dispara GameStatusEvent("CutAction", quantidade)
4. RoundManager:CortarBaralho(jogador, quantidade) valida Estado == "CUTTING" e cadeira == Corte
5. DeckManager.Cortar(BaralhoAtual, quantidade) divide o baralho e chama DistribuirCartas()
```

## Fluxos Alternativos

### FA-1: Bot ocupa a cadeira de Corte
- Servidor agenda `task.delay(1.5)` chamando `CortarBaralho(jogadorCorte, 1)`.

### FA-2: Timeout sem corte manual (11s)
- `task.delay(11)` força `DistribuirCartas()` se `ctx.Estado == "CUTTING"`.

> [!NOTE]
> **Proteção Anti-Race Condition (`Issue #7` / `D-03` Corrigido)**: `RoundManager` utiliza `self.IDRodada` e `self.CorteFoiRealizado` para impedir que o `task.delay(11)` ou o corte automático do Bot disparem `DistribuirCartas()` após o corte manual ou reset da rodada.

---

## Implementação

- [`RoundManager:IniciarNovaRodada()`](../../src/server/Classes/RoundManager.luau#L45-L87)
- [`RoundManager:CortarBaralho()`](../../src/server/Classes/RoundManager.luau#L95-L105)
- [`DeckManager.Cortar()`](../../src/server/Utils/DeckManager.luau#L69-L95)
- [`UIManager._CriarMenuCorte()`](../../src/client/UI/UIManager.luau#L568-L654)

# UC-12 — Equipar Skin

**Ator Principal**: Jogador  
**Pré-condições**: Skin já pertence a `dados.SkinsCompradas` no `DataManager`  
**Regras de Negócio**: RN-32, RN-35, RN-37  

---

## Fluxo Principal

```
1. Jogador abre a aba PONTOS na ShopUI
2. Clica em "EQUIPAR" em uma skin já desbloqueada
3. Cliente dispara ShopActionEvent("Equipar", skin.Id)
4. ShopManager valida no servidor se table.find(dados.SkinsCompradas, idSkin) é verdadeiro
5. Servidor define dados.SkinEquipada = idSkin e chama DataManager.Sincronizar(jogador)
6. SyncDataEvent atualiza ShopUI (botão passa para "EQUIPADO") e HandUI (dadosJogador.SkinEquipada)
7. Nas jogadas seguintes, Match:JogadorJogarCarta() consulta DataManager.ObterSkinEquipada(jogador)
   e envia a skin para renderização 2D (TableUI) e 3D (TableVisuals)
```

---

## Implementação

- [`ShopManager.luau`](../../src/server/ShopManager.luau#L22-L26)
- [`DataManager.ObterSkinEquipada()`](../../src/server/DataManager.luau#L105-L107)
- [`CardSettings.AplicarSkinCarta()`](../../src/shared/CardSettings.luau#L45-L68)
- [`TableVisuals.GerarCarta()`](../../src/client/TableVisuals.luau#L73-L131)

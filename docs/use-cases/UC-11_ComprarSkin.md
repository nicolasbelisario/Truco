# UC-11 — Comprar Skin / Pacotes de Pontos

**Ator Principal**: Jogador  
**Pré-condições**: Dados do jogador carregados em `DataManager`  
**Regras de Negócio**: RN-09, RN-15, RN-32, RN-33, RN-34, RN-37  

---

## Fluxo Principal — Compra de Skin com Pontos

```
1. Jogador abre a Loja pelo ícone 🛒 na barra superior esquerda (ShopUI)
2. Na aba PONTOS, visualiza skins carregadas de EconomyConfig.Skins (prévia A de Espadas)
3. Clica em "<Preco> PTS - COMPRAR" em uma skin ainda não possuída
4. Se saldo local >= Preco, ShopUI dispara ShopActionEvent("Comprar", skin.Id)
5. ShopManager valida no servidor:
   a. Preço existe em EconomyConfig.PrecosSkins[idSkin]
   b. dados.Pontos >= preco
   c. idSkin ainda não está em dados.SkinsCompradas
6. Servidor debita pontos via DataManager.AdicionarPontos(jogador, -preco),
   adiciona idSkin a SkinsCompradas e sincroniza cliente (SyncDataEvent)
7. ShopUI atualiza o saldo e muda o botão da skin para "EQUIPAR"
```

## Fluxos Alternativos

### FA-1: Saldo insuficiente
- No cliente, botão exibe temporariamente `"PONTOS INSUFICIENTES"` por 1.5s; no servidor, requisição é ignorada.

### FA-2: Compra de Pontos ou Doação via Robux (`RN-34`)
- Na aba ROBUX, `ShopUI` exibe itens de `EconomyConfig.ProdutosRobux` e chama `MarketplaceService:PromptProductPurchase()`.
- No servidor, `RobuxManager` (`MarketplaceService.ProcessReceipt`) valida `ProductId` em `ProdutosPontosMap` ou `DoacoesMap`, credita pontos se aplicável, registra `RobuxGasto` no `DataManager` (atualizando o ranking de Apoiadores) e retorna `PurchaseGranted`.

---

## Implementação

- [`ShopManager.luau`](../../src/server/ShopManager.luau)
- [`RobuxManager.luau`](../../src/server/RobuxManager.luau)
- [`EconomyConfig.luau`](../../src/shared/Configs/EconomyConfig.luau)
- [`ShopUI.luau`](../../src/client/UI/ShopUI.luau)

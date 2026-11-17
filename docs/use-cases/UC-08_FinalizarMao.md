# UC-08 — Finalizar Mão

**Ator Principal**: Servidor  
**Pré-condições**: Vencedor da Mão definido por Quedas, Canga ou fuga no Truco/Mão de Onze  
**Regras de Negócio**: RN-13, RN-14, RN-15a, RN-19, RN-21, RN-37, RN-38  

---

## Fluxo Principal

```
1. Match:FinalizarMao(equipeVencedora, valorRodada) altera Estado = "SCORING" e desativa AguardandoResposta
2. Se equipeVencedora == "DRAW": emite DRAW_HAND({Value = 0})
3. Caso contrário: soma valorRodada ao placar da equipe vencedora e emite TEAM_A_WON_HAND ou TEAM_B_WON_HAND
4. Emite UPDATE_SCORE com o placar atualizado e aguarda 3s
5. Verifica se alguma equipe atingiu GameRulesConfig.PONTOS_VITORIA_PARTIDA (12):
   - Se SIM:
     a. Emite MATCH_WON para todos
     b. Lê recompensas de EconomyConfig (PvE: +30/+10, PvP: +50/+20)
     c. Para cada humano: DataManager.AdicionarPontos(), DataManager.RegistrarResultadoPartida()
        (disparando atualização no LeaderboardManager) e envia UPDATE_STATUS com pontos ganhos
     d. Aguarda EsperaFinalizacaoPartida (8s) e chama ResetarPartida("Nova Partida")
   - Se NÃO:
     a. Rotaciona IndexDistribuidor = (IndexDistribuidor % 4) + 1
     b. Chama VerificarProximaRodada() (Normal, Mão de Onze ou Mão de Ferro)
```

---

## Implementação

- [`Match:FinalizarMao()`](../../src/server/Classes/Match.luau#L345-L391)
- [`EconomyConfig.Recompensas`](../../src/shared/Configs/EconomyConfig.luau#L9-L18)
- [`DataManager.RegistrarResultadoPartida()`](../../src/server/DataManager.luau#L77-L92)

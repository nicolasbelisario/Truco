# UC-13 — Emitir Sinal / Emote

**Ator Principal**: Jogador  
**Pré-condições**: Jogador sentado na mesa e fora do cooldown de 3 segundos (`TEMPO_ESPERA_EMOTE`)  
**Regras de Negócio**: RN-35  

---

## Fluxo Principal

```
1. Jogador sentado clica nos botões de emote (🖐️ ou 👀) ou pressiona tecla Q / E
2. Cliente (init.client.luau) valida cooldown local de 3 segundos
3. Cliente dispara SignalEvent(tipoSinal) ("Sinal_Mao" ou "Sinal_Olhar")
4. TableManager roteia para Match:TransmitirSinal(jogador, tipoSinal)
5. EventBroadcaster.SinalEmote retransmite SignalEvent(remetente, tipoSinal) para todos humanos da mesa
6. UIManager.MostrarSinal() exibe BillboardGui (🖐️ ou 👀) na cabeça e Highlight amarelo no avatar por 2s
```

## Fluxos Alternativos

### FA-1: Spam antes de 3 segundos
- `tentarEnviarSinal()` ignora o clique/tecla enquanto `tick() - ultimoTempoEmote < 3`.

---

## Implementação

- [`init.client.luau`](../../src/client/init.client.luau#L223-L246)
- [`UIManager.MostrarSinal()`](../../src/client/UI/UIManager.luau#L753-L777)
- [`Match:TransmitirSinal()`](../../src/server/Classes/Match.luau#L334-L336)
- [`EventBroadcaster.SinalEmote()`](../../src/server/Classes/EventBroadcaster.luau#L95-L99)

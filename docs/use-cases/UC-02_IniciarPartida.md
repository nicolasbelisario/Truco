# UC-02 — Iniciar Partida

**Ator Principal**: Servidor  
**Pré-condições**: `Estado == "WAITING"` e 4 assentos ocupados (`ContarJogadores() == 4`)  
**Regras de Negócio**: RN-01, RN-02, RN-12, RN-35  

---

## Fluxo Principal

```
1. Loop de monitoramento da mesa detecta 4 ocupantes em WAITING
2. Match:IniciarContagem() altera estado para COUNTDOWN
3. Contagem regressiva de 5s até 0s emitindo COUNTDOWN(i) a cada segundo
4. Match:ComecarJogo() trava pulo dos humanos (JumpPower = 0)
5. Zera placar ({TeamA = 0, TeamB = 0}) e sorteia IndexDistribuidor (1..4)
6. Em paralelo, AvatarManager aplica avatares de amigos nos Bots da mesa
7. Match:VerificarProximaRodada() inicia a primeira Mão
```

## Fluxos Alternativos

### FA-1: Jogador sai durante a contagem
- Se `ContarJogadores() < 4` durante o loop de 5 segundos:
  - Estado volta imediatamente para `WAITING`
  - Servidor emite `WAITING(0)` para todos os humanos da mesa e cancela o início.

---

## Implementação

- [`Match:IniciarContagem()`](../../src/server/Classes/Match.luau#L144-L156)
- [`Match:ComecarJogo()`](../../src/server/Classes/Match.luau#L162-L171)
- [`Match:DefinirSkinsDosBots()`](../../src/server/Classes/Match.luau#L177-L223)
- [`AvatarManager.GetRandomFriendAvatars()`](../../src/server/Utils/AvatarManager.luau#L52-L106)

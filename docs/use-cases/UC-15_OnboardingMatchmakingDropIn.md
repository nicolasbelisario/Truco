# UC-15 — Onboarding Rápido ("Jogar Agora"), Matchmaking PvP, ProximityPrompts & Bot Anti-Abandono

**Atores**: Jogador, Bot (Substituto Temporário), Servidor  
**Pré-condições**: Mesas inicializadas em `Workspace.MesasFolder` pelo `TableManager` e UI de Lobby carregada em `LobbyUI`  
**Regras de Negócio**: RN-01, RN-02, RN-09, RN-12, RN-14, RN-15a, RN-35  
**Issue**: [#2](https://github.com/nicolasbelisario/Truco/issues/2)

---

## 1. Fluxo Principal — Quick Play ("Jogar Agora")

```
1. Jogador entra no lobby e vê a barra inferior com os botões "▶ JOGAR AGORA" e "🃏 MESAS"
2. Jogador clica em "▶ JOGAR AGORA"
3. LobbyUI envia MatchmakingEvent:FireServer("QuickPlay")
4. TableManager.ExecutarQuickPlay() avalia todas as mesas públicas em estado WAITING
   com cadeira livre usando a prioridade:
   a) Mesa PvP pública com 3/4 ocupados (início imediato — prioridade 1000)
   b) Mesa PvP pública com 2/4 ocupados (800)
   c) Mesa PvP pública com 1/4 ocupado (600)
   d) Mesa PvE com humanos já aguardando (500+)
   e) Mesa PvE Solo 1v3 livre (início em 5s — 450)
   f) Demais mesas PvE abertas (300/200) → Mesa PvP vazia 0/4 (100)
5. Servidor chama Match:SentarJogadorNoAssento(), posicionando o avatar e executando Seat:Sit(humanoide)
6. Servidor responde MatchmakingEvent:FireClient(jogador, "QuickPlayResult", { Sucesso = true, ... })
7. Cliente oculta a barra de lobby, ativa câmera tabletop e exibe HUD da mesa
```

---

## 2. Fluxo Principal — Interação 3D (`ProximityPrompt` + `BillboardGui`)

```
1. Em Match:ConfigurarAssentos(), todas as cadeiras (Cadeira1..4) recebem Seat.CanTouch = false
   para evitar que o jogador sente acidentalmente ao esbarrar caminhando
2. Cadeiras humanas livres recebem um ProximityPrompt ("Sentar na Mesa", HoldDuration = 0, Tecla [E])
3. Cada mesa exibe um BillboardGui dinâmico (BillboardStatusMesa) acima de Mesa.Topo mostrando:
   - Badge do modo: PVP 4P, SOLO 1v3, DUPLA 2v2, TRIO 3v1 ou 🔒 PRIVADA
   - Em WAITING: ocupação em tempo real (ex: "🪑 2/4 • 2 vagas")
   - Em COUNTDOWN: "⏱️ INICIANDO • 4/4"
   - Em partida ativa: placar ao vivo ("🃏 7 x 4"), valor da mão e selo "🤖 Sub" se houver Bot Drop-in
4. Ao acionar o ProximityPrompt, o servidor valida disponibilidade e autorização de sala privada
   e senta o jogador na cadeira alvo
5. Enquanto o jogador está sentado, ProximityPromptService.Enabled = false no cliente para evitar
   poluição visual e conflito com atalhos de emotes; assim que a partida inicia (CUTTING/DEALING/
   SHOW_GAME_UI/SHOW_ELEVEN_DECISION), todos os BillboardStatusMesa são ocultados localmente para
   manter a visão de jogo limpa, sendo restaurados em HIDE_GAME_UI ou ao levantar da mesa
```

---

## 3. Fluxo Principal — Matchmaking / Salas PvP Públicas e Privadas

```
1. Jogador abre o modal "🃏 MESAS" no lobby (LobbyUI.AbrirSalas)
2. Cliente consulta GetRoomsData:InvokeServer() e passa a receber atualizações em tempo real
   via MatchmakingEvent("RoomListUpdate", listaSalas)
3. Jogador pode filtrar por "Todas", "PvP Públicas" ou "PvE (Bots)" e clicar em "ENTRAR"
4. Para criar uma mesa PvP:
   - Jogador opcionalmente informa um nome e clica em "+ MESA PÚBLICA" ou "🔒 MESA PRIVADA"
   - TableManager.CriarSala() aloca uma mesa PvP vazia (0/4 em WAITING), aplica o nome e,
     se privada, gera um código numérico único de 4 dígitos
   - O criador é sentado automaticamente e recebe o código exibido em PillCodigoSalaPrivada
5. Convidados podem entrar em mesas privadas digitando o código de 4 dígitos na barra de código
   do modal (MatchmakingEvent:FireServer("EntrarPorCodigo", codigo))
6. Quando a 4ª cadeira é ocupada, Match:IniciarContagem() inicia automaticamente a partida (5s)
7. Quando todos os humanos saem de uma sala customizada em WAITING ou após ResetarPartida(),
   a mesa volta ao estado padrão PvP público aberto
```

---

## 4. Fluxo Principal — Bot Substituto Anti-Abandono (Drop-in)

```
1. Durante uma partida ativa (CUTTING, DEALING, PLAYING, ELEVEN_DECISION ou SCORING),
   um jogador humano desconecta (Players.PlayerRemoving) ou deixa o assento
2. Match:_TratarSaidaHumanoDoAssento() verifica quantos jogadores humanos restam na mesa:
   - Se restarem 0 humanos: chama Match:ResetarPartida("Todos os jogadores saíram.")
   - Se restar >= 1 humano: chama Match:SubstituirPorBotTemporario(nomeAssento, jogadorAntigo)
3. SubstituirPorBotTemporario():
   - Instancia um Bot temporário (Temporario = true, Nome = "[BOT] <NomeJogador>")
   - Ocupa self.Assentos[nomeAssento], trava o assento e gera o avatar 3D (BotDummy) na cadeira
   - RoundManager:SubstituirJogador() transfere MaosJogadores, atualiza CartasNaMesa e retoma
     ação pendente (corte em CUTTING, decisão em ELEVEN_DECISION se dupla ficou só com bots,
     ou turno imediato em PLAYING via AvancarTurno)
   - TrucoHandler:SubstituirJogador() limpa votos antigos e destrava desafios pendentes
     (executando voto do parceiro humano restante ou acionando DecidirTruco se dupla só tem bots)
   - Notifica os humanos restantes com UPDATE_STATUS e atualiza o BillboardGui da mesa
4. Ao finalizar/resetar a partida (ResetarPartida), Match:RemoverBotsTemporarios() destrói os
   modelos 3D temporários, remove SeatWelds e libera as cadeiras novamente para humanos
```

---

## Fluxos Alternativos

### FA-1: Todas as mesas ocupadas no Quick Play
- `TableManager.ExecutarQuickPlay()` retorna `{ Sucesso = false, Mensagem = "Todas as mesas estão ocupadas no momento..." }` e `LobbyUI` exibe um toast de aviso sem mover o jogador.

### FA-2: Tentativa de entrar em Sala Privada sem código válido
- Via `ProximityPrompt`: o servidor rejeita o assento e informa para usar o menu `SALAS` com código.
- Via `MatchmakingEvent("EntrarMesa" | "EntrarPorCodigo")`: retorna erro amigável em toast (`"Código inválido para esta sala privada."`).

### FA-3: Jogador em partida ativa tenta usar Quick Play ou trocar de sala
- `TableManager` bloqueia via `CanPlayerJoin` e retorna `"Você já está em uma partida em andamento!"`.

### FA-4: Único humano em mesa PvE Solo sai durante a partida
- Como `humanosRestantes == 0`, o servidor não deixa 4 bots jogando sozinhos — executa `ResetarPartida()` para liberar a mesa imediatamente.

---

## Implementação

- [`TableManager.luau`](../../src/server/TableManager.luau) — Quick Play, criação/entrada em Salas Públicas e Privadas, broadcast `RoomListUpdate` e hook `Players.PlayerRemoving`
- [`Match.luau`](../../src/server/Classes/Match.luau) — `ProximityPrompt` nas cadeiras, `BillboardGui` dinâmico, `SentarJogadorNoAssento()`, `SubstituirPorBotTemporario()` e `RemoverBotsTemporarios()`
- [`RoundManager.luau`](../../src/server/Classes/RoundManager.luau) — `SubstituirJogador()` e timeout seguro na Mão de Onze
- [`TrucoHandler.luau`](../../src/server/Classes/TrucoHandler.luau) — `SubstituirJogador()` para destravar desafios de Truco
- [`Bot.luau`](../../src/server/Classes/Bot.luau) — Flag `Temporario` e guarda `EstaAtivoNaPartida()`
- [`LobbyUI.luau`](../../src/client/UI/LobbyUI.luau) — Barra `"▶ JOGAR AGORA"` + `"🃏 SALAS"`, modal de matchmaking, toast e pill de código privado
- [`UIManager.luau`](../../src/client/UI/UIManager.luau) / [`init.client.luau`](../../src/client/init.client.luau) — Integração com estado sentado e controle de `ProximityPromptService.Enabled`

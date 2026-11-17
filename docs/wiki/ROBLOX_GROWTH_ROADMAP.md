# 🚀 Roadmap de Evolução & Benchmark Roblox — Truco Paulista

> Análise técnica completa do código (`src/`) e do mapa no Roblox Studio (`Workspace` via MCP), combinada com práticas dos jogos de mesa e cartas de maior sucesso no Roblox (*UNO!*, *Liar's Table*, *8 Ball Pool*, *Chess Club*).

---

## 1. Auditoria Técnica e do Mapa Atual (Studio + Código)

### 1.1. Bugs e Gaps Críticos Encontrados

| Severidade | Local | Achado Real | Impacto no Jogador | Status |
|---|---|---|---|---|
| 🔴 **Crítica** | `init.client.luau` / `UIManager.luau` / `RoundManager.luau` | O servidor emitia `SHOW_ELEVEN_DECISION`, sem handler/modal no cliente para humanos decidirem Jogar/Correr na Mão de Onze. | Partida travava em `ELEVEN_DECISION` com humanos. | ✅ Corrigido (`D-01`) |
| 🟠 **Alta** | `RuleManager.luau` / `RoundManager.luau` | `ObterVencedorRodada` retornava `"DRAW"` mesmo se o empate fosse entre **parceiros da mesma dupla**; 4 cartas cobertas (`0`) davam vitória ao 1º jogador. | Quebrava regra oficial do Truco Paulista. | ✅ Corrigido (`D-02`) |
| 🟠 **Alta** | `RoundManager.luau` / `Match.luau` | `task.delay(11)` em `IniciarNovaRodada()` não possuía token cancelável (**Issue #7**) e `task.wait` pós-mão não checava reset da partida. | Risco de race condition ao cortar no limite ou resetar durante delay. | ✅ Corrigido (`D-03`) |
| 🟠 **Alta** | `Workspace.MesasFolder` | Modelos com **nomes duplicados** (`MesaPvE_Solo` x2, `MesaPvE_Dupla` x2, `MesaPvE_Trio` x2), além de `Mesa1`..`Mesa4`. | Dificulta depuração, seleção via scripts/MCP e sinalização individual de mesas. | ✅ Corrigido (Issue #12) |
| 🟡 **Média** | `init.client.luau` + `SoundManager.luau` | O botão `BtnMuteGlobal` altera apenas `SoundManager.AlternarMute()`, não silenciando `BackgroundMusic`. | Jogador muta o jogo mas a música de fundo continua tocando. | ⏳ Aberto (`D-04`) |
| 🟡 **Média** | `CameraManager.luau` | `AplicarTensao(nomeAlvo)` procura apenas em `Players:FindFirstChild(nomeAlvo)`. | Efeito de câmera de tensão não funciona quando um Bot pede Truco. | ⏳ Aberto (`D-05`) |
| 🟡 **Média** | `StarterGui.ScreenGui.TextLabel` | Label `"PRÉ-ALPHA"` posicionado com `Position = {0.876, 0}, {0.920, 0}` e `Size = 200x50` sem `AnchorPoint = (1, 1)` ou `TextScaled`. | Texto aparece cortado na borda direita (`"PRÉ-ALPH"`) em telas menores. | ✅ Corrigido (Issue #12) |
| 🟡 **Média** | `Workspace.TestBot` + `Barreira` | `Workspace.TestBot` (258 descendentes) está posicionado fora da arena principal (`-23.4, 0, 17.1`). | Poluição visual no cenário e aumento desnecessário de instâncias no Workspace. | ✅ Corrigido (Issue #12) |

---

## 2. Benchmarking: O que os Maiores Jogos de Mesa/Cartas do Roblox Fazem

Jogos como *UNO!*, *Liar's Table*, *8 Ball Pool* e *Chess Club* atingem alta retenção (D1/D7) e monetização porque dominam **4 pilares**:

1. **Time-to-Fun < 5 segundos**: O jogador não precisa andar procurando onde sentar nem ler placas longas — entra no lobby, aperta **Jogar Agora** (ou vê placas 3D claras acima das mesas) e já está jogando.
2. **Tabletop Feel (Imersão 3D na Mesa)**: As cartas vivem na mesa 3D e na mão dos avatares, não em grids 2D genéricos que tampam os personagens.
3. **Juice & Feedback Emocional**: Pedir aumento, jogar carta forte (Zap) e vencer mão têm impacto sonoro, visual (VFX/câmera) e animações corporais no avatar.
4. **Loop Social & Meta-Progressão**: Win Streak, missões diárias, cosméticos visíveis para todos na mesa e substituição automática por Bot se alguém cair.

---

## 3. Melhorias de Mapa e Ambientação 3D

Atualmente o mapa é uma caixa cinza com chão xadrez flutuando no vazio e paredes translúcidas (`Workspace.Barreira`). Para elevar o nível para padrão Top Charts:

1. **Temática Autêntica Brasileira ("Boteco / Praça Paulista" ou "Clube de Truco")**:
   - Trocar a caixa flutuante por uma **praça aconchegante ao entardecer** ou **salão de clube brasileiro** (madeira quente, chão de ladrilho hidráulico ou pedra portuguesa, luminárias pendentes sobre cada mesa, plantas, bar/balcão decorativo, TV passando placar ou rádio vintage).
   - Substituir as paredes invisíveis/translúcidas visíveis por cercas vivas, muros baixos de tijolinho ou guarda-corpos integrados ao cenário.
2. **Sinalização Viva Sobre as Mesas (`BillboardGui`)**:
   - Acima de cada mesa em `Workspace.MesasFolder`, exibir modo (`SOLO 1v3`, `DUPLA 2v2`, `PVP 4P`), vagas em tempo real (`2/4 🪑`) e placar da partida em andamento (`7 x 4`).
   - Diferenciar visualmente mesas PvE (toalha azul/madeira) das mesas PvP (toalha verde feltro clássico) e mesas Competitivas/VIP (feltro dourado/preto).
3. **Palco de Pódio 3D para o Top 3 Global**:
   - Evoluir `Workspace.LeaderboardBoard` para um **Pódio 3D** com avatares reais do Top 3 de `ODS_Vitorias` fazendo poses/animações de comemoração (alto impacto social e incentivo competitivo).
4. **Área de Tutorial Integrada e Limpa**:
   - Remover `Workspace.TestBot` solto fora do mapa e o `Text Board` de texto longo/inclinado; transformar a barraquinha do tutorial em um quiosque temático com **NPC interativo via `ProximityPrompt`** que abre o tutorial ou inicia uma mão guiada.

---

## 4. Melhorias de UI/UX (Mobile-First & Clareza)

1. **Remover Redundância 2D vs 3D (`TableUI` vs `TableVisuals`)**:
   - Hoje o jogador vê as cartas jogadas **duas vezes**: no grid `TableUI` no centro da tela e em 3D na mesa (`TableVisuals`). Em celulares, o grid `TableUI` cobre o centro da tela e os outros jogadores.
   - **Solução**: Ao sentar, posicionar a câmera em ângulo isométrico/primeira-pessoa focado no centro da mesa (`tampoMesa`), mantendo apenas as cartas 3D (`TableVisuals`) + um **monte do baralho e a Vira em 3D** sobre a mesa!
2. **Mão em Leque com Destaque Automático de Manilhas (`HandUI`)**:
   - Dispor as 3 cartas em leque suave (`Rotation` `-6°`, `0°`, `+6°`) no rodapé.
   - Destacar automaticamente na mão do jogador qual carta é **Manilha** (borda dourada + selo `ZAP ♣️` / `COPAS ♥️` / `ESPADAS ♠️` / `OUROS ♦️`) e permitir botão direto de *"Jogar Coberta"* ao selecionar carta na 2ª/3ª queda sem menu flutuante descentralizado.
3. **Placar de Quedas Visual (3 Bolinhas)**:
   - Em vez de texto `"Nós: 1 Quedas / Eles: 0 Quedas"`, usar 3 indicadores circulares coloridos (Verde = Nós, Vermelho = Eles, Amarelo = Canga/Empate, Cinza = Pendente), padrão instantaneamente legível em partidas rápidas.
4. **Botão "Jogar Agora" (Quick Play) + `ProximityPrompt` nas Cadeiras**:
   - Adicionar botão principal no fundo-centro do lobby para sentar automaticamente na melhor mesa disponível (PvP com 3/4 ou PvE).
   - Substituir o sentar apenas por toque físico por `ProximityPrompt` nas cadeiras (`"Sentar na Mesa"`), evitando que jogadores esbarrem sem querer em mesas alheias.
5. **Modal Completo de Mão de Onze & Barra de Menu Responsiva**:
   - Implementar a UI de `SHOW_ELEVEN_DECISION` exibindo lado a lado **Suas 3 Cartas** e **Cartas do Parceiro**, com botões grandes `JOGAR (VALE 3)` e `CORRER (+1 P/ ELES)`.
   - Corrigir `SoundManager` para controlar também `BackgroundMusic` e oferecer sliders separados de **Música** e **SFX** em um modal de Configurações.

---

## 5. Ideias de Features, Retenção e Monetização Saudável (Compliant com RN-09)

### Gameplay & Social
- **Drop-in de Bot (Anti-Abandono em PvP)**: Em `Match:ProcessarMudancaAssento`, se um jogador sair no meio da partida, em vez de chamar `ResetarPartida()` e frustrar os outros 3 jogadores, substituir a cadeira por um Bot temporário para concluir a partida (ou permitir substituição).
- **Cartas Físicas na Mão dos Avatares 3D**: Renderizar 1 a 3 cartas (de costas) presas à mão dos avatares sentados na mesa, removendo uma a cada jogada — aumenta muito a imersão 3D.
- **Animações de Avatar + Câmera Dinâmica para Bots e Humanos**: Quando alguém grita **TRUCO / SEIS / NOVE / DOZE**, o avatar bate na mesa ou aponta, um texto 3D estilizado explode acima da mesa e `CameraManager.AplicarTensao` foca tanto em `Player` quanto no modelo 3D de `Bot`.
- **Sinais Clássicos de Truco & Chat Rápido Seguro**: Expandir `SignalEvent` com sinais reais do Truco Paulista (piscar olho = Zap, mostrar língua = Copas, bico = Espadas, sobrancelha = Ouros, "Fui!" / "Vem!") + frases rápidas pré-aprovadas (`"Boa, parceiro!"`, `"Desce o Zap!"`, `"Blefei!"`).
- **Bot com IA Tática Real (Issue #1)**: Contagem de cartas já jogadas, blefe contextual, jogar carta mais fraca suficiente para ganhar ("fazer a primeira" ou "matar por pouco") e guardar manilha para a 3ª queda.

### Retenção & Progressão
- **Daily Login & Missões Diárias**: Recompensas crescentes por dias seguidos e missões simples (*"Vença 3 mãos pedindo Truco"*, *"Ganhe 1 Mão de Ferro"*, *"Jogue 2 partidas PvP"*).
- **Win Streak (Sequência de Vitórias)**: Badge `🔥 5x` acima da cabeça do jogador no lobby e na mesa, com multiplicador bônus de Pontos.
- **Modo Truco Mineiro (Manilha Fixa)**: Aproveitar a flag já existente `CardSettings.ManilhaFixa` para criar mesas temáticas de Truco Mineiro (4 de Paus, 7 de Copas, Ás de Espadas, 7 de Ouros; escala `2 -> 4 -> 6 -> 10 -> 12`).

### Monetização Cosmética (Zero Pay-to-Win)
- **Card Slam VFX (Efeitos de Jogada)**: Partículas e som customizados ao jogar uma Manilha ou Zap (ex.: raio, chamas, impacto dourado, pétalas).
- **Animações de Grito de Truco & Skins de Mesa**: Pacotes visuais que mudam a mesa onde você é o anfitrião ou efeitos exclusivos de comemoração ao vencer a partida.
- **VIP Gamepass**: Bônus de `+50%` Pontos por partida, tag `[VIP]` no chat/mesa, acesso antecipado a skins sazonais e sala VIP decorada.

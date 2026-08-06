# Módulo/Domínio: Truco Paulista Roblox

## 1. Visão Geral e Linguagem Ubíqua (Glossário)
- **Truco Paulista**: Jogo de cartas brasileiro para quatro participantes, jogado em duplas, com o objetivo de atingir uma pontuação predefinida através de rodadas.
- **Baralho Limpo**: Baralho de 40 cartas, excluindo os 8s, 9s e 10s.
- **Vira**: A carta virada na mesa no início de cada mão, que determina as quatro cartas Manilhas daquela mão.
- **Manilha**: As quatro cartas mais fortes do jogo em uma dada mão, definidas pela "Vira". São as cartas imediatamente superiores à Vira na ordem de força padrão, cada uma de um naipe diferente.
- **Multiplicador de Pontos**: Mecanismo pelo qual os jogadores podem aumentar o valor de uma mão em andamento, através de chamadas como "Truco", "Seis", "Nove" e "Doze".
- **Mão de Onze**: Uma regra especial que ocorre quando uma dupla atinge 11 pontos, permitindo-lhes uma decisão estratégica sobre a próxima mão.
- **Bots IA**: Jogadores controlados por inteligência artificial que simulam o comportamento humano no jogo.
- **Skins**: Elementos visuais customizáveis para as cartas e baralhos, adquiridos na loja do jogo.
- **Pontos de Recompensa**: Pontos concedidos aos jogadores ao final de cada partida, utilizados para adquirir skins.

## 2. Regras de Negócio Core (Invariants)
- **[RN-01] [Formato da Partida]**: Uma partida de Truco Paulista sempre envolve 4 participantes, organizados em duas duplas.
- **[RN-02] [Composição da Partida]**: As partidas podem ser compostas por 4 jogadores humanos, ou uma combinação de jogadores humanos e Bots IA (1v3, 2v2, 3v1).
- **[RN-03] [Baralho Padrão]**: O jogo utiliza um baralho limpo de 40 cartas, removendo os 8s, 9s e 10s.
- **[RN-04] [Distribuição de Cartas]**: No início de cada mão, cada jogador recebe exatamente 3 cartas.
- **[RN-05] [Definição da Vira]**: Uma carta é virada na mesa no início de cada mão para determinar as manilhas.
- **[RN-06] [Definição das Manilhas]**: As manilhas são as quatro cartas imediatamente superiores à "Vira" na ordem de força padrão (4, 5, 6, 7, Q, J, K, A, 2, 3).
- **[RN-07] [Força das Manilhas por Naipe]**: A ordem de força das manilhas por naipe é fixa: Paus (Zap) > Copas > Espadas > Ouros (Pica-fumo).
- **[RN-08] [Ordem de Força Padrão]**: A ordem de força padrão das cartas (crescente) é: 4, 5, 6, 7, Q, J, K, A, 2, 3.
- **[RN-09] [Terminologia Proibida]**: O sistema NÃO deve usar os termos "aposta" ou "gambling" na interface ou no código, em conformidade com as diretrizes da plataforma Roblox.
- **[RN-10] [Valor Base da Mão]**: O valor inicial de uma mão é de 1 ponto.
- **[RN-11] [Multiplicadores de Pontos]**: Os valores possíveis para uma mão são: 1 (base), 3 (Truco), 6 (Seis), 9 (Nove) e 12 (Doze).
- **[RN-12] [Decisão dos Bots]**: Bots IA devem tomar decisões de jogada, pedido de truco e resposta a truco com base no estado atual do jogo.
- **[RN-13] [Recompensas Pós-Partida]**: Ao final de cada partida, os jogadores recebem pontos de recompensa/experiência.
- **[RN-14] [Variação de Recompensas]**: A quantidade de pontos de recompensa varia conforme o resultado (vitória/derrota) e o tipo de oponente (vitórias contra jogadores reais concedem mais pontos).
- **[RN-15] [Uso dos Pontos]**: Os pontos acumulados são exclusivamente para a aquisição de skins customizadas de cartas e baralhos na loja do jogo.
- **[RN-16] [Elementos de Áudio]**: O jogo deve incluir trilha sonora em loop e efeitos sonoros (SFX) para eventos chave como distribuição de cartas, descarte, chamadas de Truco e resultados de partida.
- **[RN-17] [Renderização Visual]**: As cartas são renderizadas visualmente em 3D/SurfaceGUI utilizando texturas e skins customizadas.

## 3. Validações e Restrições de Entrada/Saída
- **Entradas válidas**:
    - Ações de jogo (jogar carta, pedir truco, aceitar/aumentar/fugir truco) devem ser realizadas pelo jogador cujo turno está ativo.
    - Uma carta só pode ser jogada se pertencer à mão do jogador e não tiver sido jogada anteriormente na mesma mão.
    - Um pedido de Truco (ou aumento) só pode ser feito se o valor atual da mão permitir um aumento e não houver um pedido pendente da mesma dupla.
    - A seleção de skins na loja deve corresponder a skins existentes e que o jogador possui ou tem pontos suficientes para adquirir.
- **Entradas inválidas**:
    - Tentativa de um jogador de realizar uma ação fora de seu turno.
    - Tentativa de jogar uma carta que não está na mão do jogador ou que já foi jogada.
    - Tentativa de pedir Truco quando o valor máximo da mão já foi atingido (12 pontos).
    - Uso de termos proibidos ("aposta", "gambling") em qualquer entrada de texto do usuário ou configuração do jogo.
    - Tentativa de adquirir uma skin sem pontos suficientes.

## 4. Fluxo de Execução e Casos de Borda (Edge Cases)
- **Caminho Feliz**:
  1. Quatro jogadores (humanos e/ou bots) entram na mesa e a partida é iniciada.
  2. O baralho é embaralhado, e 3 cartas são distribuídas para cada jogador.
  3. Uma carta é virada na mesa para definir as manilhas da mão.
  4. Os jogadores jogam suas cartas em turnos, seguindo a ordem de força e as regras do Truco.
  5. Durante a mão, um jogador pode pedir "Truco", aumentando o valor da mão para 3 pontos.
  6. A dupla adversária pode "Aceitar", "Aumentar" (para Seis, Nove, Doze) ou "Fugir".
  7. A rodada é vencida pela dupla que jogar a carta de maior força.
  8. Os pontos correspondentes ao valor da mão são atribuídos à dupla vencedora.
  9. Novas mãos são jogadas até que uma dupla atinja a pontuação final da partida.
  10. A partida é encerrada, e os pontos de recompensa/experiência são distribuídos aos jogadores.
- **Casos de Borda**:
  - **Mão de Onze (Uma Dupla)**:
    - Se uma dupla atinge 11 pontos e a outra tem menos de 11, a dupla de 11 pode visualizar as cartas do parceiro.
    - Eles devem decidir se "Jogam" a mão (que automaticamente valerá 3 pontos) ou "Fogem" (concedendo 1 ponto à dupla adversária).
  - **Mão de Onze (Ambas as Duplas)**:
    - Se ambas as duplas atingem 11 pontos simultaneamente, a mão é disputada "no escuro" (sem que os parceiros vejam as cartas um do outro) e o valor da mão é automaticamente 3 pontos.
  - **Decisões dos Bots**:
    - Bots devem sempre ter uma lógica de decisão para jogar cartas, pedir truco e responder a truco, mesmo em situações desfavoráveis ou de empate.
  - **Empate de Rodada**:
    - Se houver empate na maior carta jogada em uma rodada, a regra de desempate do Truco Paulista deve ser aplicada (e.g., quem pediu truco primeiro, ou a dupla que venceu a rodada anterior, ou a mão é anulada dependendo da regra específica adotada).

## 5. Diretrizes de Código e Arquitetura (Roblox/Luau)
- **Estruturas de Dados**:
    - `Card`: Tabela contendo `naipe` (string), `valor` (string/int), `forcaAbsoluta` (int para ordenação padrão), `forcaManilha` (int para ordenação de manilhas), `idUnico` (string/int).
    - `PlayerState`: Tabela para cada jogador com `UserId`, `Name`, `Hand` (array de `Card`), `IsBot` (boolean), `CurrentPointsInMatch` (int), `TeamId`.
    - `TeamState`: Tabela para cada dupla com `TeamId`, `Players` (array de `PlayerState`), `PointsInRound` (int), `PointsInMatch` (int).
    - `GameState`: Tabela centralizada no servidor contendo `CurrentVira` (Card), `ActiveManilhas` (array de Card), `CardsOnTable` (array de {`PlayerId`, `Card`}), `CurrentMultiplier` (int), `CurrentTurnPlayerId`, `TrucoCallerTeamId`, `MatchStatus` (enum: "Waiting", "Playing", "Ended"), `RoundNumber`, `HandNumber`.
    - `BotAIConfig`: Tabela com parâmetros de dificuldade e estratégias para bots.
- **Eventos/RemoteEvents**:
    - **Cliente -> Servidor (RemoteFunctions/RemoteEvents)**:
        - `RequestPlayCard(cardId)`: Jogador tenta jogar uma carta.
        - `RequestTruco()`: Jogador pede truco.
        - `RespondTruco(action: "Aceitar" | "Aumentar" | "Fugir")`: Jogador responde a um pedido de truco.
        - `DecideHandOfEleven(action: "Jogar" | "Fugir")`: Jogador toma decisão na Mão de Onze.
        - `PlayerReady()`: Sinaliza que o jogador está pronto para iniciar a partida.
    - **Servidor -> Cliente (RemoteEvents)**:
        - `UpdateGameState(gameStateData)`: Envia o estado completo ou parcial do jogo para todos os clientes.
        - `DisplayCards(cardsInHand)`: Envia as cartas para a mão de um jogador específico.
        - `CardPlayed(playerId, cardData)`: Notifica que uma carta foi jogada.
        - `TrucoRequested(callerPlayerId, currentMultiplier)`: Notifica que truco foi pedido.
        - `TrucoResponse(responderPlayerId, action, newMultiplier)`: Notifica a resposta ao truco.
        - `ShowHandOfElevenDecision(partnerCards)`: Exibe as cartas do parceiro e opções de decisão para a dupla na Mão de Onze.
        - `MatchEnded(winningTeamId, rewards)`: Notifica o fim da partida e as recompensas.
        - `PlaySFX(soundId, volume)`: Dispara efeitos sonoros no cliente.
- **Tratamento de Estado**:
    - O estado canônico da partida deve ser mantido exclusivamente no servidor para evitar cheats e garantir a integridade.
    - Módulos de serviço no `ServerScriptService` (e.g., `GameService`, `PlayerService`, `BotService`, `CardService`) devem gerenciar as transições de estado e a lógica de negócio.
    - `ReplicatedStorage` para `RemoteEvents`, `RemoteFunctions` e módulos compartilhados (e.g., `CardSettings`, `GameConstants`).
    - `StarterPlayerScripts` para a lógica do cliente que interage com a UI e envia ações ao servidor.
    - Utilizar `BindableEvents` e `BindableFunctions` para comunicação interna entre módulos do servidor, promovendo desacoplamento.
    - A renderização visual das cartas e UI deve ser responsabilidade do cliente, que reage às atualizações de estado enviadas pelo servidor.
```
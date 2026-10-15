#!/bin/bash
# Script para criar as Issues do projeto Truco no GitHub
# Execute a partir da raiz do repositório: bash docs/scripts/create_issues.sh
# Pré-requisito: gh CLI autenticado (gh auth login)

echo "🃏 Criando Issues do Truco Paulista no GitHub..."

# ISSUE 1
gh issue create \
  --title "[FEATURE] Sistema de IA dos Bots com Estratégia Real" \
  --label "enhancement,ai,bot" \
  --body "## Descrição
Atualmente os Bots têm uma IA puramente aleatória (jogar carta aleatória, 10% de chance de pedir truco, 60/40 de aceitar/correr). Isso torna o PvE sem desafio e monótono.

## Comportamento Esperado
- Bot avalia a força relativa das cartas na mão (comparando com as manilhas do momento)
- Bot pede Truco apenas quando tem mão forte (ex: 2+ cartas com força >= 7)
- Bot decide aceitar/correr Truco com base no valor das cartas restantes na mão
- Bot na Mão de Onze analisa corretamente o parceiro
- Bot varia estratégia por rodada (queda 1 vs queda 2 vs queda 3)

## Critérios de Aceite
- [ ] Bot avalia \`ManilhaStrength\` e \`Strength\` para priorizar cartas
- [ ] Bot não pede truco com mão fraca (< 2 cartas força > 5)
- [ ] Bot tem pelo menos 3 níveis de dificuldade configuráveis em \`GameConfig\`
- [ ] Bot não joga carta coberta na 1ª queda (já existe, manter)
- [ ] Decisão de Mão de Onze usa lógica além de apenas \`ManilhaStrength >= 3\`

## Referências
- [\`Bot.luau\`](src/server/Classes/Bot.luau) — lógica atual (aleatória)
- [\`GameConfig.luau\`](src/shared/GameConfig.luau) — adicionar dificuldade aqui"

echo "✅ Issue 1 criada"

# ISSUE 2
gh issue create \
  --title "[FEATURE] Sistema de Matchmaking / Sala Pública PvP" \
  --label "enhancement,multiplayer,gameplay" \
  --body "## Descrição
Atualmente não existe forma de jogadores encontrarem partidas PvP sem estarem no mesmo servidor Roblox. Não há lobby, fila de espera ou sistema de matchmaking.

## Comportamento Esperado
- Jogadores podem criar ou entrar em salas públicas listadas
- Sala pública aguarda 4 jogadores e inicia automaticamente
- Sala pode ter código de convite para amigos
- Alternativa: botão de 'Jogo Rápido' que coloca o jogador na fila

## Critérios de Aceite
- [ ] UI de lobby com lista de salas abertas
- [ ] Criação de sala pública e privada (com código)
- [ ] Auto-início da partida ao completar 4 jogadores
- [ ] Jogador pode sair da fila antes de iniciar
- [ ] Integração com \`TableManager\` para roteamento de jogadores

## Referências
- [\`TableManager.luau\`](src/server/TableManager.luau)
- [\`Match.luau\`](src/server/Classes/Match.luau)"

echo "✅ Issue 2 criada"

# ISSUE 3
gh issue create \
  --title "[FEATURE] Sistema de Ranking / Leaderboard Global" \
  --label "enhancement,data,leaderboard" \
  --body "## Descrição
O jogo salva \`Pontos\` por jogador no DataStore, mas não existe leaderboard global, ranking por temporada, ou distinção entre vitórias e derrotas nos dados persistidos.

## Comportamento Esperado
- Leaderboard global exibindo top 10/50 jogadores por pontos
- DataStore expandido para salvar: \`Vitorias\`, \`Derrotas\`, \`PartidasJogadas\`
- UI de ranking acessível no lobby principal
- Ranking por temporada (reset mensal opcional)

## Critérios de Aceite
- [ ] \`DataManager\` salva \`Vitorias\`, \`Derrotas\`, \`PartidasJogadas\`
- [ ] Novo \`OrderedDataStore\` para ranking global
- [ ] UI de leaderboard com paginação (top 50)
- [ ] Jogador vê sua posição no ranking mesmo fora do top 50
- [ ] Atualização do leaderboard a cada 60 segundos

## Referências
- [\`DataManager.luau\`](src/server/DataManager.luau)"

echo "✅ Issue 3 criada"

# ISSUE 4
gh issue create \
  --title "[FEATURE] Emotes e Chat de Jogo Expandido" \
  --label "enhancement,ui,social" \
  --body "## Descrição
O jogo possui \`SignalEvent\` com emotes (\`Sinal_Mao\`, \`Sinal_Olhar\`) mas a UI de emotes é limitada e não existe chat de texto entre jogadores na mesa.

## Comportamento Esperado
- Painel de emotes com ícones clicáveis (pelo menos 6 emotes)
- Chat de texto simples entre os 4 jogadores da mesa (limitado a mensagens pré-definidas para segurança)
- Animações visuais no avatar do jogador ao usar emote
- Emote de 'Truco!' animado sincronizado com o pedido

## Critérios de Aceite
- [ ] Pelo menos 6 tipos de emote com ícone e texto
- [ ] Chat de mesa com mensagens pré-definidas (sem input livre)
- [ ] Emotes têm cooldown de 3 segundos por jogador
- [ ] \`SignalEvent\` expandido para suportar novos tipos de sinal
- [ ] Emotes visíveis para todos os humanos na mesa

## Referências
- [\`TableManager.luau\`](src/server/TableManager.luau) — \`SignalEvent\`
- [\`Match.luau\`](src/server/Classes/Match.luau) — \`TransmitirSinal\`"

echo "✅ Issue 4 criada"

# ISSUE 5
gh issue create \
  --title "[FEATURE] Sistema de Conquistas (Achievements)" \
  --label "enhancement,gamification,data" \
  --body "## Descrição
Não existe sistema de conquistas. Conquistas aumentam o engajamento e retenção de jogadores ao dar metas de longo prazo.

## Comportamento Esperado
- Lista de conquistas desbloqueáveis (ex: 'Vença 10 partidas', 'Vença com mão de ferro', 'Use todos os emotes')
- Badge visual exibido no perfil do jogador no lobby
- Conquistas concedem Pontos como recompensa ao desbloquear
- Progresso de conquista salvo no DataStore

## Critérios de Aceite
- [ ] Módulo \`AchievementManager\` no servidor
- [ ] Pelo menos 10 conquistas iniciais definidas em config
- [ ] Notificação visual no cliente ao desbloquear conquista
- [ ] Conquistas salvas em \`DataStore\` por jogador
- [ ] UI de conquistas acessível na loja ou no lobby"

echo "✅ Issue 5 criada"

# ISSUE 6
gh issue create \
  --title "[FEATURE] Modo Truco Mineiro / Variantes de Regras" \
  --label "enhancement,gameplay,configuration" \
  --body "## Descrição
O jogo implementa apenas Truco Paulista. Adicionar suporte a variantes como Truco Mineiro aumentaria o alcance do jogo.

## Comportamento Esperado
- Seleção de variante de regras ao criar uma mesa
- \`CardSettings.ManilhaFixa\` já existe como flag — implementar lógica
- Diferenças de pontuação e sequência de chamadas por variante

## Critérios de Aceite
- [ ] \`CardSettings.ManilhaFixa = true\` funciona corretamente no \`DeckManager\`
- [ ] \`RuleManager\` suporta lógica de força diferente por variante
- [ ] UI de seleção de variante na criação de mesa
- [ ] Variante salva na configuração da \`Partida\`
- [ ] Tutorial atualizado para cobrir a variante escolhida

## Referências
- [\`CardSettings.luau\`](src/shared/CardSettings.luau) — \`ManilhaFixa\`
- [\`RuleManager.luau\`](src/server/Utils/RuleManager.luau)
- [\`DeckManager.luau\`](src/server/Utils/DeckManager.luau)"

echo "✅ Issue 6 criada"

# ISSUE 7
gh issue create \
  --title "[BUG] Timeout do Corte do Baralho não cancela corretamente" \
  --label "bug,gameplay" \
  --body "## Descrição
Em \`RoundManager:IniciarNovaRodada()\`, existe um \`task.delay(11)\` que força a distribuição se o estado ainda for \`CUTTING\`. Porém, se o jogador cortar o baralho exatamente no 11º segundo, pode haver condição de corrida entre o corte manual e o timeout.

## Comportamento Atual
O \`task.delay(11)\` verifica \`if ctx.Estado == \"CUTTING\" then self:DistribuirCartas() end\`, mas o \`CortarBaralho\` também chama \`DistribuirCartas\` diretamente sem invalidar o timer anterior.

## Comportamento Esperado
- O timeout deve ser cancelável (usar token/flag) quando o corte manual ocorre
- \`DistribuirCartas\` não deve ser chamado duas vezes na mesma rodada

## Critérios de Aceite
- [ ] Adicionar flag \`self.CorteFoiRealizado\` em \`RoundManager\`
- [ ] \`CortarBaralho\` define a flag antes de chamar \`DistribuirCartas\`
- [ ] \`task.delay\` verifica a flag antes de executar
- [ ] Testar cenário onde o corte ocorre no último segundo

## Referências
- [\`RoundManager.luau L70-73\`](src/server/Classes/RoundManager.luau)"

echo "✅ Issue 7 criada"

# ISSUE 8
gh issue create \
  --title "[FEATURE] Tutorial Interativo In-Game" \
  --label "enhancement,ux,tutorial" \
  --body "## Descrição
Existe \`TutorialUI.luau\` no cliente mas não está documentado se está integrado ao fluxo principal. Novos jogadores precisam de um tutorial claro sobre as regras do Truco Paulista.

## Comportamento Esperado
- Tutorial ativado na primeira sessão do jogador (flag no DataStore)
- Ensina regras básicas: força das cartas, manilhas, truco, mão de onze
- Tutorial interativo com mão demonstrativa controlada
- Pode ser revisitado via menu de pausa

## Critérios de Aceite
- [ ] Flag \`TutorialCompleto\` salva no DataStore
- [ ] Tutorial usa cartas reais em mesa de demo
- [ ] Cada etapa tem seta/highlight na UI relevante
- [ ] Botão 'Pular Tutorial' disponível
- [ ] Tutorial funciona na mesa PvE Solo

## Referências
- [\`TutorialUI.luau\`](src/client/UI/TutorialUI.luau)
- [\`DataManager.luau\`](src/server/DataManager.luau)"

echo "✅ Issue 8 criada"

# ISSUE 9
gh issue create \
  --title "[FEATURE] Sistema de Partidas Privadas com Convite de Amigos" \
  --label "enhancement,social,multiplayer" \
  --body "## Descrição
Não existe forma de convidar amigos para uma mesa específica. A API do Roblox permite convites sociais via \`SocialService\`.

## Comportamento Esperado
- Botão 'Convidar Amigo' visível enquanto aguarda na mesa
- Integração com \`SocialService:PromptGameInvite()\` do Roblox
- Mesa reserva assentos para amigos convidados por N segundos
- Código de sala compartilhável via clipboard

## Critérios de Aceite
- [ ] \`SocialService:PromptGameInvite()\` integrado
- [ ] Mesa pode ser marcada como 'privada' via \`TableManager\`
- [ ] Reserva de assento por 30 segundos para convidado
- [ ] UI de convite exibida durante \`WAITING\`"

echo "✅ Issue 9 criada"

# ISSUE 10
gh issue create \
  --title "[FEATURE] Melhorias de Áudio — SFX e Trilha Sonora" \
  --label "enhancement,audio,ux" \
  --body "## Descrição
A regra de negócio \`[RN-16]\` especifica SFX para eventos chave, mas \`SoundManager.luau\` é muito simples (apenas 15 linhas). Faltam efeitos sonoros para a maioria dos eventos do jogo.

## Comportamento Esperado
- SFX para: jogar carta, distribuir cartas, gritar Truco, aceitar/correr Truco, vencer queda, vencer partida, derrota
- Trilha sonora de lobby diferente da música de partida
- Volume configurável pelo jogador (slider na UI)
- Música que aumenta de intensidade na Mão de Onze

## Critérios de Aceite
- [ ] \`SoundManager\` tem pelo menos 7 SFX registrados
- [ ] Volume de música e SFX configuráveis separadamente
- [ ] Configuração de volume salva localmente
- [ ] SFX de Truco sincronizado com a animação na UI
- [ ] Nenhuma música toca durante o tutorial

## Referências
- [\`SoundManager.luau\`](src/client/UI/SoundManager.luau)"

echo "✅ Issue 10 criada"

echo ""
echo "🎉 Todas as 10 issues foram criadas com sucesso!"
echo "Acesse: https://github.com/nicolasbelisario/Truco/issues"

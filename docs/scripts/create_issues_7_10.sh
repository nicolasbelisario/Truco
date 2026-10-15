#!/bin/bash
set -e

gh issue create --repo nicolasbelisario/Truco \
  --title '[BUG] Timeout do Corte do Baralho não cancela corretamente (race condition)' \
  --label 'bug,gameplay' \
  --body 'Em RoundManager:IniciarNovaRodada(), existe um task.delay(11) que força a distribuição se o estado ainda for CUTTING. Se o jogador cortar o baralho exatamente no limite, pode haver condição de corrida.

## Comportamento Atual
task.delay(11) verifica `if ctx.Estado == "CUTTING" then self:DistribuirCartas() end`, mas CortarBaralho também chama DistribuirCartas sem invalidar o timer.

## Comportamento Esperado
- Timeout cancelável via flag quando corte manual ocorre
- DistribuirCartas não chamado duas vezes na mesma rodada

## Critérios de Aceite
- [ ] Adicionar flag `self.CorteFoiRealizado` em RoundManager
- [ ] CortarBaralho define a flag antes de chamar DistribuirCartas
- [ ] task.delay verifica a flag antes de executar

## Referências
- `src/server/Classes/RoundManager.luau` linhas 70-90'
echo "Issue 7 OK"

gh issue create --repo nicolasbelisario/Truco \
  --title '[FEATURE] Tutorial Interativo In-Game' \
  --label 'enhancement,ux,tutorial' \
  --body '## Descrição
Existe TutorialUI.luau no cliente mas não integrado ao fluxo principal. Novos jogadores precisam de um tutorial sobre as regras do Truco Paulista.

## Comportamento Esperado
- Tutorial ativado na primeira sessão do jogador (flag no DataStore)
- Ensina: força das cartas, manilhas, truco, mão de onze
- Tutorial interativo com mão demonstrativa
- Revisitável via menu de pausa

## Critérios de Aceite
- [ ] Flag TutorialCompleto salva no DataStore
- [ ] Tutorial usa cartas reais em mesa de demo
- [ ] Cada etapa tem seta/highlight na UI relevante
- [ ] Botão Pular Tutorial disponível
- [ ] Tutorial funciona na mesa PvE Solo

## Referências
- `src/client/UI/TutorialUI.luau`
- `src/server/DataManager.luau`'
echo "Issue 8 OK"

gh issue create --repo nicolasbelisario/Truco \
  --title '[FEATURE] Partidas Privadas com Convite de Amigos' \
  --label 'enhancement,social,multiplayer' \
  --body '## Descrição
Não existe forma de convidar amigos para uma mesa específica. A API do Roblox permite convites sociais via SocialService.

## Comportamento Esperado
- Botão Convidar Amigo visível durante WAITING
- Integração com SocialService:PromptGameInvite do Roblox
- Mesa reserva assentos para convidados por 30 segundos
- Código de sala compartilhável via clipboard

## Critérios de Aceite
- [ ] SocialService:PromptGameInvite integrado
- [ ] Mesa pode ser marcada como privada via TableManager
- [ ] Reserva de assento por 30 segundos para convidado
- [ ] UI de convite exibida durante WAITING'
echo "Issue 9 OK"

gh issue create --repo nicolasbelisario/Truco \
  --title '[FEATURE] Melhorias de Áudio — SFX e Trilha Sonora' \
  --label 'enhancement,audio,ux' \
  --body '## Descrição
A regra RN-16 especifica SFX para eventos chave, mas SoundManager.luau é muito simples. Faltam efeitos sonoros para a maioria dos eventos do jogo.

## Comportamento Esperado
- SFX para: jogar carta, distribuir cartas, Truco, aceitar/correr, vencer queda, vencer partida, derrota
- Trilha sonora de lobby diferente da música de partida
- Volume configurável pelo jogador (slider na UI)
- Música aumenta de intensidade na Mão de Onze

## Critérios de Aceite
- [ ] SoundManager tem pelo menos 7 SFX registrados
- [ ] Volume de música e SFX configuráveis separadamente
- [ ] Configuração de volume salva localmente
- [ ] SFX de Truco sincronizado com a animação na UI
- [ ] Nenhuma música toca durante o tutorial

## Referências
- `src/client/UI/SoundManager.luau`'
echo "Issue 10 OK"

echo ""
echo "✅ Issues 7-10 criadas!"

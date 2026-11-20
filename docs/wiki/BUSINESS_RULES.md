# 📋 Regras de Negócio

> Regras invariantes do sistema. **Nenhuma implementação deve violar estas regras sem aprovação explícita.**
> IDs no formato `[RN-XX]` são referenciáveis de qualquer documento.

---

## Formato e Composição da Partida

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-01** | Uma partida sempre envolve exatamente **4 participantes** em **2 duplas** cruzadas (`{1, 3}` vs `{2, 4}`). | `GameRulesConfig.MAX_PLAYERS = 4`, `GameRulesConfig.TEAMS` |
| **RN-02** | Partidas podem ser **4 humanos** (PvP), ou **combinações com Bots IA** (`1+3`, `2+2`, `3+1`). | `TableManager.CONFIG_BOTS` |
| **RN-03** | O baralho padrão tem **40 cartas** (sem 8s, 9s e 10s). | `GameRulesConfig.CARTAS_NO_BARALHO`, `DeckManager.CriarBaralho()` |
| **RN-04** | Cada jogador recebe exatamente **3 cartas** por Mão. | `GameRulesConfig.CARTAS_POR_JOGADOR`, `RoundManager:DistribuirCartas()` |
| **RN-05** | Uma carta é **virada na mesa** (Vira) no início de cada Mão para definir as Manilhas. | `RoundManager.ViraAtual` |

---

## Força e Hierarquia das Cartas

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-06** | As **Manilhas** são as 4 cartas imediatamente superiores à Vira na ordem padrão (`3` gira para `4`). | `DeckManager.DefinirManilhas()` |
| **RN-07** | A força das Manilhas por naipe é **fixa**: Paus (Zap = 4) > Copas (3) > Espadas (2) > Ouros (Pica-fumo = 1). | `DeckManager.DefinirManilhas()`, `RuleManager.CalcularForcaCarta()` |
| **RN-08** | A ordem de força padrão crescente é: **4 < 5 < 6 < 7 < Q < J < K < A < 2 < 3**. | `CardSettings.Values`, `DeckManager.CriarBaralho()` |
| **RN-17** | Uma carta jogada **coberta (escondida)** tem força **zero** e sempre perde (não empata). | `RuleManager.CalcularForcaCarta()` |
| **RN-18** | Carta coberta **não pode ser jogada na 1ª queda** de uma Mão. | `RoundManager:JogarCarta()`, `HandUI.luau` |

---

## Sistema de Pontuação (Valor da Mão)

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-10** | O valor inicial de uma Mão é **1 ponto**. | `GameRulesConfig.ValoresMao.Base = 1` |
| **RN-11** | Os valores possíveis da Mão são: **1** (base), **3** (Truco), **6** (Seis), **9** (Nove), **12** (Doze). | `GameRulesConfig.ValoresMao`, `TrucoHandler.luau` |
| **RN-19** | A equipe que vencer **2 de 3 quedas** vence a Mão e recebe os pontos. | `RoundManager:AvaliarQueda()` |
| **RN-20** | **Regra de Canga (Empate)**: Empate só ocorre quando as maiores cartas pertencem a **duplas adversárias** (se parceiros da mesma dupla empatarem na maior carta, a queda pertence à dupla deles). Se a 1ª queda empatar, a 2ª decide; se empatar também, a 3ª decide; se a 1ª tiver vencedor e a 2ª ou 3ª empatar, vence quem levou a 1ª. Se todas as 3 empatarem, ninguém pontua (`DRAW`). | `RoundManager:AvaliarQueda()`, `RuleManager.ObterVencedorRodada()` |
| **RN-21** | A partida termina quando uma equipe atinge **12 pontos**. | `GameRulesConfig.PONTOS_VITORIA_PARTIDA = 12`, `Match:FinalizarMao()` |

---

## Mecânica de Truco e Bots

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-12** | Bots IA decidem jogada, corte, pedido de Truco, resposta a Truco e Mão de Onze conforme parâmetros configuráveis de dificuldade. | `Bot.luau`, `BotConfig.luau` |
| **RN-22** | O pedido de Truco só pode ser feito durante o estado `PLAYING`. | `TrucoHandler:ProcessarRequest()`, `UIManager.luau` |
| **RN-23** | Uma equipe **não pode pedir Truco** se já foi ela quem pediu na escala atual. | `TrucoHandler.Estado.EquipePediu` |
| **RN-24** | A equipe desafiada pode: **Aceitar** (mão vale o novo valor), **Aumentar** (escalar para 6/9/12) ou **Correr** (perde o valor anterior). | `TrucoHandler:ProcessarResponse()` |
| **RN-25** | Se a equipe **correr**, a equipe que pediu ganha o valor que a Mão valia *antes* do pedido. | `TrucoHandler:_Resolver()` |
| **RN-26** | O **timeout de resposta** ao Truco é de **15 segundos**. Após o timeout, a equipe automaticamente corre. | `GameRulesConfig.Tempos.LimiteRespostaTruco = 15` |
| **RN-27** | Em duplas com **2 humanos**, ambos devem votar na **mesma decisão** para ela ser executada. | `TrucoHandler:ProcessarResponse()` |

---

## Mão de Onze e Mão de Ferro

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-28** | Se **uma equipe** tem 11 pontos e a outra tem menos: é **Mão de Onze**. | `GameRulesConfig.Especiais`, `Match:VerificarProximaRodada()` |
| **RN-29** | Na Mão de Onze, a equipe com 11 vê as cartas do **parceiro** e decide: **Jogar** (mão vale 3) ou **Correr** (oponente ganha 1). | `RoundManager:IniciarMaoDeOnze()`, `DecidirMaoDeOnze()` |
| **RN-30** | Se **ambas as equipes** têm 11 pontos: é **Mão de Ferro**. Jogada às cegas, vale 3 pontos. | `RoundManager:IniciarMaoDeFerro()` |
| **RN-31** | Truco é **desativado** tanto na Mão de Onze quanto na Mão de Ferro. | `TrucoHandler:SetTrucoAtivo(false)` |

---

## Recompensas, Loja e Skins

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-13** | Ao final de cada partida, **todos** os jogadores humanos recebem Pontos de Recompensa. | `Match:FinalizarMao()` |
| **RN-14** | Vitória em **PvE** (contra bots): **+30 pts** (vencedores) / **+10 pts** (perdedores). | `EconomyConfig.Recompensas.PvE` |
| **RN-15a** | Vitória em **PvP** (contra humanos): **+50 pts** (vencedores) / **+20 pts** (perdedores). | `EconomyConfig.Recompensas.PvP` |
| **RN-15** | Pontos são usados **exclusivamente** para comprar Skins de cartas na loja. | `ShopManager.luau` |
| **RN-32** | A skin `"Padrao"` tem preço `0` e é desbloqueada por padrão para todos os jogadores. | `EconomyConfig.SkinPadraoId`, `DataManager.luau` |
| **RN-33** | Skins compradas com Pontos não podem ser reembolsadas. | `ShopManager.luau` |
| **RN-34** | Compras com Robux (pacotes de pontos e doações) são processadas via `MarketplaceService.ProcessReceipt`, registrando `RobuxGasto` e retornando `PurchaseGranted` apenas após crédito válido. | `RobuxManager.luau`, `EconomyConfig.ProdutosRobux` |

---

## Compliance, Segurança, Dados e Ranking

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-09** | Os termos **"aposta"**, **"gambling"**, **"bet"** e **"stake"** são **proibidos** em textos visíveis ao jogador, configs e código (variáveis/comentários). | Validado por `validate_configs.py` |
| **RN-35** | O estado canônico da partida deve ser mantido **exclusivamente no servidor**. | `Match.luau`, `RoundManager.luau`, `TrucoHandler.luau` |
| **RN-36** | Validação anti-cheat: o servidor verifica se é o turno do jogador e se a carta jogada pertence à sua mão em `MaosJogadores` antes de aceitar. | `RoundManager:JogarCarta()` |
| **RN-37** | O `DataManager` persiste no DataStore `TrucoData_v1` o perfil: `Pontos`, `Vitorias`, `Derrotas`, `PartidasJogadas`, `RobuxGasto`, `SkinsCompradas`, `SkinEquipada` e `TutorialVisto`. | `DataManager.luau` |
| **RN-38** | O `LeaderboardManager` sincroniza 3 `OrderedDataStore` globais (`Vitorias`, `Pontos`, `Robux`) via `OnStatChanged` e atualiza o quadro físico `Workspace.LeaderboardBoard`. | `LeaderboardManager.luau`, `LeaderboardUI.luau` |
| **RN-39** | Ações administrativas (`AdminActionEvent`) exigem validação de `UserId` fixo no servidor. | `AdminManager.luau` |

---

## Áudio e Visual

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-16** | O jogo deve ter **trilha sonora em loop** e **SFX** para eventos: distribuição de cartas, jogada (incluindo impacto de Manilha/Zap), Truco (pedido, aceite, fuga), resultado de queda/partida e tensão na Mão de Onze/Ferro. | `SoundManager.luau` (BGM + SFX + `PreloadAsync`), `AudioUI.luau` |
| **RN-17b** | As cartas são renderizadas em 2D (`HandUI`, `TableUI`) e 3D (`TableVisuals` com `SurfaceGui`) usando spritesheets de `CardSettings`. | `CardSettings.luau`, `TableVisuals.luau` |

---

## ⚠️ Divergências Conhecidas (Gaps entre Especificação e Código Atual)

> Documentado durante a auditoria SDD para correção priorizada:

| ID | Severidade | Status | Descrição do Gap | Arquivos Afetados |
|----|------------|--------|------------------|-------------------|
| **D-01** | 🔴 Crítica | ✅ Corrigido | Implementado handler `SHOW_ELEVEN_DECISION` / `HIDE_ELEVEN_DECISION`, modal `PainelMaoDeOnze` no cliente e validação de equipe/timeout no servidor. | `init.client.luau`, `UIManager.luau`, `RoundManager.luau` |
| **D-02** | 🟠 Alta | ✅ Corrigido | `RuleManager.ObterVencedorRodada` agora diferencia empate entre parceiros (`jogada.Team`) e retorna `"DRAW"` quando todos jogam cartas cobertas (`maiorForca <= 0`). | `RuleManager.luau`, `RoundManager.luau` |
| **D-03** | 🟠 Alta | ✅ Corrigido | Adicionado token `IDRodada` + flag `CorteFoiRealizado` em `RoundManager` (**Issue #7**) e `IDPartida` em `Match` para proteger `task.delay` e `task.wait`. | `RoundManager.luau`, `Match.luau` |
| **D-04** | 🟡 Média | ✅ Corrigido | Playlist `BackgroundMusic` centralizada em `SoundManager.luau` (**Issue #10**); `AlternarMute()` muta/restaura BGM e SFX imediatamente, com 11 SFX pré-carregados (`PreloadAsync`), sliders independentes em `AudioUI.luau` e trilha dinâmica na Mão de Onze/Ferro. | `src/client/init.client.luau`, `src/client/UI/SoundManager.luau`, `src/client/UI/AudioUI.luau` |
| **D-05** | 🟡 Média | ⏳ Aberto | `CameraManager.AplicarTensao(nomeAlvo)` busca apenas em `Players:FindFirstChild(nomeAlvo)`, não aplicando zoom quando um Bot pede Truco. | `src/client/UI/CameraManager.luau` |

# 📋 Regras de Negócio

> Regras invariantes do sistema. **Nenhuma implementação deve violar estas regras sem aprovação explícita.**
> IDs no formato `[RN-XX]` são referenciáveis de qualquer documento.

---

## Formato e Composição da Partida

| ID | Regra | Implementação |
|----|-------|--------------|
| **RN-01** | Uma partida sempre envolve exatamente **4 participantes** em **2 duplas**. | `GameConfig.MAX_PLAYERS = 4` |
| **RN-02** | Partidas podem ser **4 humanos**, ou **combinações com Bots IA** (1+3, 2+2, 3+1). | `TableManager.CONFIG_BOTS` |
| **RN-03** | O baralho padrão tem **40 cartas** (sem 8s, 9s e 10s). | `DeckManager.CriarBaralho()` |
| **RN-04** | Cada jogador recebe exatamente **3 cartas** por Mão. | `RoundManager:DistribuirCartas()` |
| **RN-05** | Uma carta é **virada na mesa** (Vira) no início de cada Mão para definir as Manilhas. | `RoundManager.ViraAtual` |

---

## Força e Hierarquia das Cartas

| ID | Regra |
|----|-------|
| **RN-06** | As **Manilhas** são as 4 cartas imediatamente superiores à Vira na ordem padrão: `4, 5, 6, 7, Q, J, K, A, 2, 3`. |
| **RN-07** | A força das Manilhas por naipe é **fixa**: Paus (Zap) > Copas > Espadas > Ouros (Pica-fumo). |
| **RN-08** | A ordem de força padrão crescente é: **4 < 5 < 6 < 7 < Q < J < K < A < 2 < 3**. |
| **RN-17** | Uma carta jogada **coberta (escondida)** tem força **zero** e sempre perde. |
| **RN-18** | Carta coberta **não pode ser jogada na 1ª queda** de uma Mão. |

---

## Sistema de Pontuação (Valor da Mão)

| ID | Regra |
|----|-------|
| **RN-10** | O valor inicial de uma Mão é **1 ponto**. |
| **RN-11** | Os valores possíveis da Mão são: **1** (base), **3** (Truco), **6** (Seis), **9** (Nove), **12** (Doze). |
| **RN-19** | A equipe que vencer **2 de 3 quedas** vence a Mão e recebe os pontos. |
| **RN-20** | Em caso de **empate na 1ª queda** (canga): a 2ª queda decide. Se empatar também, a 3ª decide. |
| **RN-21** | A partida termina quando uma equipe atinge **12 pontos**. |

---

## Mecânica de Truco (Desafio de Pontos)

| ID | Regra |
|----|-------|
| **RN-22** | O pedido de Truco só pode ser feito durante o estado `PLAYING`. |
| **RN-23** | Uma equipe **não pode pedir Truco** se já foi ela quem pediu na escala atual. |
| **RN-24** | A equipe desafiada pode: **Aceitar** (mão vale o novo valor), **Aumentar** (escalar mais) ou **Correr** (perde o valor anterior). |
| **RN-25** | Se a equipe **correr**, a equipe que pediu ganha o valor que a Mão valia *antes* do pedido. |
| **RN-26** | O **timeout de resposta** ao Truco é de **15 segundos**. Após o timeout, a equipe automaticamente corre. |
| **RN-27** | Em duplas com **2 humanos**, ambos devem votar na **mesma decisão** para ela ser executada. |

---

## Mão de Onze e Mão de Ferro

| ID | Regra |
|----|-------|
| **RN-28** | Se **uma equipe** tem 11 pontos e a outra tem menos: é Mão de Onze. |
| **RN-29** | Na Mão de Onze, a equipe com 11 vê as cartas do **parceiro** e decide: **Jogar** (mão vale 3) ou **Correr** (oponente ganha 1). |
| **RN-30** | Se **ambas as equipes** têm 11 pontos: é Mão de Ferro. Jogada às cegas, vale 3 pontos. **Truco desativado**. |
| **RN-31** | Truco é **desativado** tanto na Mão de Onze quanto na Mão de Ferro. |

---

## Recompensas e Progressão

| ID | Regra |
|----|-------|
| **RN-13** | Ao final de cada partida, **todos** os jogadores humanos recebem Pontos de Recompensa. |
| **RN-14** | Vitória em **PvE** (contra bots): **+30 pts** (vencedores) / **+10 pts** (perdedores). |
| **RN-15a** | Vitória em **PvP** (contra humanos): **+50 pts** (vencedores) / **+20 pts** (perdedores). |
| **RN-15** | Pontos são usados **exclusivamente** para comprar Skins de cartas na loja. |

---

## Loja e Skins

| ID | Regra |
|----|-------|
| **RN-32** | A skin `"Padrao"` é desbloqueada por padrão para todos os jogadores. |
| **RN-33** | Skins compradas com Pontos não podem ser reembolsadas. |
| **RN-34** | Skins pagas com Robux são processadas via `MarketplaceService`. |

---

## Compliance da Plataforma Roblox

| ID | Regra |
|----|-------|
| **RN-09** | Os termos **"aposta"**, **"gambling"**, **"bet"** e **"stake"** são **proibidos** em qualquer texto visível ao jogador ou no código (variáveis, comentários). |
| **RN-35** | O estado canônico da partida deve ser mantido **exclusivamente no servidor**. |
| **RN-36** | Validação anti-cheat: o servidor verifica se a carta jogada pertence à mão do jogador antes de aceitar. |

---

## Áudio

| ID | Regra |
|----|-------|
| **RN-16** | O jogo deve ter **trilha sonora em loop** e **SFX** para eventos: distribuição de cartas, jogada, Truco, resultado. |

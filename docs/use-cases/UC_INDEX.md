# 📋 Índice de Use Cases

> Use Cases documentam **o que o sistema deve fazer**, do ponto de vista dos atores.
> Cada UC mapeia para uma ou mais regras de negócio e módulos de código.

---

## Atores

| Ator | Descrição |
|------|-----------|
| **Jogador** | Usuário humano da plataforma Roblox |
| **Bot** | Agente de IA controlado pelo servidor |
| **Servidor** | Sistema lógico do jogo (autoridade canônica) |
| **Admin** | Jogador com permissão de administrador (`UserId` validado no servidor) |

---

## Use Cases Implementados

| ID | Nome | Ator | Status |
|----|------|------|--------|
| [UC-01](./UC-01_EntrarNaMesa.md) | Entrar na Mesa de Jogo | Jogador | ✅ Implementado |
| [UC-02](./UC-02_IniciarPartida.md) | Iniciar Partida | Servidor | ✅ Implementado |
| [UC-03](./UC-03_DistribuirCartas.md) | Distribuir Cartas | Servidor | ✅ Implementado |
| [UC-04](./UC-04_JogarCarta.md) | Jogar Carta | Jogador / Bot | ✅ Implementado |
| [UC-05](./UC-05_PedirTruco.md) | Pedir Truco | Jogador / Bot | ✅ Implementado |
| [UC-06](./UC-06_ResponderTruco.md) | Responder ao Truco | Jogador / Bot | ✅ Implementado |
| [UC-07](./UC-07_AvaliarQueda.md) | Avaliar Vencedor da Queda | Servidor | ✅ Implementado |
| [UC-08](./UC-08_FinalizarMao.md) | Finalizar Mão | Servidor | ✅ Implementado |
| [UC-09](./UC-09_MaoDeOnze.md) | Mão de Onze | Servidor / Jogador | ✅ Implementado |
| [UC-10](./UC-10_MaoDeFerro.md) | Mão de Ferro | Servidor | ✅ Implementado |
| [UC-11](./UC-11_ComprarSkin.md) | Comprar Skin / Pacotes de Pontos | Jogador | ✅ Implementado |
| [UC-12](./UC-12_EquiparSkin.md) | Equipar Skin | Jogador | ✅ Implementado |
| [UC-13](./UC-13_EmitirSinal.md) | Emitir Sinal / Emote | Jogador | ✅ Implementado |
| [UC-14](./UC-14_CortarBaralho.md) | Cortar Baralho | Jogador / Bot | ✅ Implementado |
| [UC-17](./UC-17_VisualizarRankingGlobal.md) | Visualizar Ranking Global | Jogador | ✅ Implementado |

## Use Cases Planejados (Backlog)

| ID | Nome | Ator | Issue |
|----|------|------|-------|
| UC-15 | Onboarding Rápido ("Jogar Agora"), Matchmaking PvP & Bot Drop-in | Jogador / Servidor | [#2](https://github.com/nicolasbelisario/Truco/issues/2) |
| UC-16 | Partidas Privadas com Convite de Amigos | Jogador | [#9](https://github.com/nicolasbelisario/Truco/issues/9) |
| UC-18 | Meta-Progressão: Conquistas, Missões Diárias & Win Streak | Servidor / Jogador | [#5](https://github.com/nicolasbelisario/Truco/issues/5) |
| UC-19 | Onboarding: Destaque de Manilhas & Tutorial 1ª Sessão | Jogador | [#8](https://github.com/nicolasbelisario/Truco/issues/8) |
| UC-20 | Modo Truco Mineiro / Variantes de Regras | Jogador / Servidor | [#6](https://github.com/nicolasbelisario/Truco/issues/6) |
| UC-21 | Sinais Clássicos de Truco, Chat Rápido & Animações | Jogador / Bot | [#4](https://github.com/nicolasbelisario/Truco/issues/4) |
| UC-22 | IA Tática dos Bots | Bot | [#1](https://github.com/nicolasbelisario/Truco/issues/1) |
| UC-23 | Imersão Tabletop 3D, Monte/Vira 3D & HUD Visual | Cliente | [#13](https://github.com/nicolasbelisario/Truco/issues/13) |
| UC-24 | Novos Cosméticos (Card Slam VFX, Títulos) & VIP Gamepass | Jogador / Servidor | [#15](https://github.com/nicolasbelisario/Truco/issues/15) |

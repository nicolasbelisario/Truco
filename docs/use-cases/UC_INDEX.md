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
| **Admin** | Jogador com permissão de administrador |

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
| [UC-11](./UC-11_ComprarSkin.md) | Comprar Skin com Pontos | Jogador | ✅ Implementado |
| [UC-12](./UC-12_EquiparSkin.md) | Equipar Skin | Jogador | ✅ Implementado |
| [UC-13](./UC-13_EmitirSinal.md) | Emitir Sinal / Emote | Jogador | ✅ Implementado |
| [UC-14](./UC-14_CortarBaralho.md) | Cortar Baralho | Jogador / Bot | ✅ Implementado |

## Use Cases Planejados (Backlog)

| ID | Nome | Ator | Issue |
|----|------|------|-------|
| UC-15 | Entrar em Fila de Matchmaking PvP | Jogador | [#2](https://github.com/nicolasbelisario/Truco/issues) |
| UC-16 | Convidar Amigo para Mesa | Jogador | [#9](https://github.com/nicolasbelisario/Truco/issues) |
| UC-17 | Visualizar Ranking Global | Jogador | [#3](https://github.com/nicolasbelisario/Truco/issues) |
| UC-18 | Desbloquear Conquista | Servidor | [#5](https://github.com/nicolasbelisario/Truco/issues) |
| UC-19 | Completar Tutorial | Jogador | [#8](https://github.com/nicolasbelisario/Truco/issues) |
| UC-20 | Selecionar Variante de Regras | Jogador | [#6](https://github.com/nicolasbelisario/Truco/issues) |

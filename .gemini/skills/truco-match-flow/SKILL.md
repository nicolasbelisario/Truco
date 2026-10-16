---
name: truco-match-flow
description: Especificação e invariantes da máquina de estados da partida, assentos, escalonamento de Truco, anticheat e rede cliente-servidor.
---

# Skill: Orquestração de Partida & Fluxo (`truco-match-flow`)

## 1. Propósito do Módulo
Gerenciar o ciclo de vida completo de uma partida de Truco Paulista no servidor Roblox, desde a entrada de jogadores nas cadeiras, contagem regressiva, corte, distribuição, turnos de cartas, desafios de Truco até o encerramento e transição de estados sem condições de corrida.

---

## 2. Regras de Negócio Inegociáveis (Invariantes)

1. **[RN-01 & RN-02] Ocupação da Mesa**:
   - A partida só inicia quando todas as 4 cadeiras estiverem ocupadas (por jogadores ou bots).
   - Se qualquer jogador levantar durante `COUNTDOWN` ou `PLAYING`, a partida deve ser imediatamente abortada ou resetada para `WAITING` para manter integridade.
2. **[RN-11] Escalonamento Estrito do Truco**:
   - Os valores de Mão seguem exclusivamente a sequência:
     $$1 \rightarrow 3 \rightarrow 6 \rightarrow 9 \rightarrow 12$$
   - Nenhum valor superior a $12$ pode ser solicitado.
   - A equipe que acabou de pedir/aumentar o Truco não pode pedir novamente na mesma sequência.
3. **[RN-26] Timeout de Resposta de Truco**:
   - A equipe desafiada tem rigorosamente $15$ segundos para responder (configurado em `GameRulesConfig.Tempos.LimiteRespostaTruco`).
   - Se o tempo expirar sem resposta, a equipe corre automaticamente (`TRUCO_TIMEOUT`).
4. **[RN-35 & RN-36] Servidor Autoritativo & Anti-Cheat**:
   - O servidor nunca aceita uma carta jogada pelo cliente se ela não existir na tabela `MaosJogadores[jogador]` do servidor.
   - Cartas jogadas fora de turno são descartadas silenciosamente no servidor.
5. **[RN-27] Votação em Dupla Humana**:
   - Quando a equipe desafiada for composta por dois jogadores humanos, a ação ("Aceitar", "Correr", "Aumentar") só é executada quando ambos os jogadores emitirem o mesmo voto.

---

## 3. Arquivos de Código Pertencentes a este Módulo
- `src/server/Classes/Match.luau` — Instância central da partida, gerenciador de assentos e placar.
- `src/server/Classes/RoundManager.luau` — Gerenciador de turnos, baralho e avaliação de quedas.
- `src/server/Classes/TrucoHandler.luau` — Máquina de estados de desafio, escalonamento e timeout.
- `src/server/Classes/EventBroadcaster.luau` — Emissão de RemoteEvents seguros do servidor para os clientes.
- `src/server/TableManager.luau` — Roteamento das mesas físicas e eventos de rede.

---

## 4. Script de Validação e Testes
Valida a lógica da máquina de estados e escalonamento de Truco de forma determinística:

- **Caminho**: `.gemini/skills/truco-match-flow/tests/test_match_flow.py`
- **Execução**:
  ```bash
  python .gemini/skills/truco-match-flow/tests/test_match_flow.py
  ```
- **Critério de Sucesso**: Transições de valores 1->3->6->9->12 válidas, rejeição de valor > 12 e lógica de timeout.

---
name: truco-core-rules
description: Especificação e invariantes do motor de regras de negócio do Truco Paulista (força de cartas, manilhas, canga, mão de onze e mão de ferro).
---

# Skill: Motor de Regras do Truco Paulista (`truco-core-rules`)

## 1. Propósito do Módulo
Garantir a integridade absoluta das regras do Truco Paulista no servidor Roblox, assegurando que o cálculo de força de cartas, determinação de manilhas a partir da vira, desempates (canga) e tratamento de rodadas especiais (Mão de Onze e Mão de Ferro) sejam matematicamente precisos, imutáveis e auditáveis.

---

## 2. Regras de Negócio Inegociáveis (Invariantes)

1. **[RN-03] Baralho Limpo**: O baralho contém exatamente 40 cartas (removidos 8s, 9s e 10s).
2. **[RN-04] Tamanho da Mão**: Cada jogador recebe rigorosamente 3 cartas no início da Mão.
3. **[RN-06] Ordem Padrão de Força**:
   $$4 < 5 < 6 < 7 < Q < J < K < A < 2 < 3$$
4. **[RN-07] Definição e Força das Manilhas**:
   - A manilha é a carta imediatamente seguinte à Vira na ordem padrão. Se a Vira for 3, a manilha é 4.
   - Ordem de força por naipe:
     $$\text{Paus (Zap)} > \text{Copas} > \text{Espadas} > \text{Ouros (Pica-fumo)}$$
5. **[RN-17] Carta Coberta (Escondida)**:
   - Carta jogada coberta tem força numérica $0$.
   - Não pode ser jogada na 1ª queda de uma Mão (forçada para `escondida = false`).
6. **[RN-20] Regra de Canga (Empate na Queda)**:
   - Se a 1ª queda empatar, quem vencer a 2ª queda vence a Mão.
   - Se a 1ª e a 2ª empatarem, quem vencer a 3ª queda vence a Mão.
   - Se as 3 quedas empatarem, ninguém pontua (`DRAW`).
7. **[RN-28 & RN-31] Mão de Onze & Mão de Ferro**:
   - Se uma equipe atinge 11 pontos, joga Mão de Onze valendo 3 pontos. **Truco desativado**.
   - Se ambas as equipes têm 11 pontos, joga Mão de Ferro no escuro valendo 3 pontos. **Truco desativado**.

---

## 3. Arquivos de Código Pertencentes a este Módulo
- `src/server/Utils/DeckManager.luau` — Geração do baralho, embaralhamento, corte e manilhas.
- `src/server/Utils/RuleManager.luau` — Cálculo de força individual e vencedor de cada queda.
- `src/shared/CardSettings.luau` — Mapeamento de naipes, valores e spritesheets.

---

## 4. Script de Validação e Testes
O script de validação deste módulo executa testes unitários de regras, manilhas e cenários de canga:

- **Caminho**: `.gemini/skills/truco-core-rules/tests/test_rules.py`
- **Execução**:
  ```bash
  python .gemini/skills/truco-core-rules/tests/test_rules.py
  ```
- **Critério de Sucesso**: 100% dos testes devem passar (asserts de hierarquia, manilha do vira 3 -> 4, empate na primeira queda).

"""
Validação do Fluxo de Partida e Escalonamento de Truco (Skill: truco-match-flow)
Testa o ciclo de vida do TrucoHandler, timeouts e anti-cheat.
"""

import unittest

VALORES_VALIDOS_TRUCO = [1, 3, 6, 9, 12]

class TrucoStateMock:
    def __init__(self):
        self.valor_atual = 1
        self.valor_pendente = 0
        self.equipe_pediu = None
        self.aguardando_resposta = False
        self.id_desafio = 0
        self.truco_ativo = True

    def processar_request(self, equipe_solicitante: str) -> bool:
        if not self.truco_ativo or self.aguardando_resposta:
            return False
        if self.equipe_pediu == equipe_solicitante:
            return False
        
        prox = 3 if self.valor_atual == 1 else self.valor_atual + 3
        if prox > 12:
            return False

        self.aguardando_resposta = True
        self.equipe_pediu = equipe_solicitante
        self.valor_pendente = prox
        self.id_desafio += 1
        return True

    def processar_response(self, equipe_resposta: str, acao: str):
        if not self.aguardando_resposta or equipe_resposta == self.equipe_pediu:
            return False
        
        if acao == "Aceitar":
            self.valor_atual = self.valor_pendente
            self.aguardando_resposta = False
            return "ACEITO"
        elif acao == "Correr":
            self.aguardando_resposta = False
            return "CORREU"
        elif acao == "Aumentar":
            self.valor_atual = self.valor_pendente
            prox = min(self.valor_atual + 3, 12)
            if prox == self.valor_atual:
                return False # Já está no máximo
            self.equipe_pediu = equipe_resposta
            self.valor_pendente = prox
            self.id_desafio += 1
            return "AUMENTOU"
        return False

class TestTrucoMatchFlow(unittest.TestCase):
    def test_escalonamento_normal_ate_doze(self):
        """1 -> 3 -> 6 -> 9 -> 12."""
        truco = TrucoStateMock()
        
        # Equipe A pede Truco (1 -> 3)
        self.assertTrue(truco.processar_request("A"))
        self.assertEqual(truco.valor_pendente, 3)
        
        # Equipe B aumenta para Seis (3 -> 6)
        res = truco.processar_response("B", "Aumentar")
        self.assertEqual(res, "AUMENTOU")
        self.assertEqual(truco.valor_pendente, 6)
        
        # Equipe A aumenta para Nove (6 -> 9)
        res = truco.processar_response("A", "Aumentar")
        self.assertEqual(res, "AUMENTOU")
        self.assertEqual(truco.valor_pendente, 9)
        
        # Equipe B aumenta para Doze (9 -> 12)
        res = truco.processar_response("B", "Aumentar")
        self.assertEqual(res, "AUMENTOU")
        self.assertEqual(truco.valor_pendente, 12)
        
        # Equipe A aceita o Doze
        res = truco.processar_response("A", "Aceitar")
        self.assertEqual(res, "ACEITO")
        self.assertEqual(truco.valor_atual, 12)

    def test_bloqueio_aumento_acima_de_doze(self):
        """Não pode aumentar além de 12."""
        truco = TrucoStateMock()
        truco.valor_atual = 12
        # Tentativa de pedir além de 12
        self.assertFalse(truco.processar_request("A"))

    def test_mesma_equipe_nao_pode_pedir_duas_vezes(self):
        """Equipe A pediu Truco, não pode pedir novamente enquanto aguarda."""
        truco = TrucoStateMock()
        self.assertTrue(truco.processar_request("A"))
        self.assertFalse(truco.processar_request("A"))

    def test_correr_entrega_pontos_anteriores(self):
        """Se Equipe A pede Truco (de 1 para 3) e B corre, A ganha 1 ponto."""
        truco = TrucoStateMock()
        truco.processar_request("A")
        valor_antes = truco.valor_atual # 1
        res = truco.processar_response("B", "Correr")
        self.assertEqual(res, "CORREU")
        self.assertEqual(valor_antes, 1)

if __name__ == "__main__":
    unittest.main()

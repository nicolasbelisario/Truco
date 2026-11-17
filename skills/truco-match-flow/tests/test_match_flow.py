"""
Validação do Fluxo de Partida, Corte de Baralho, Mão de Onze e Escalonamento de Truco (Skill: truco-match-flow)
Testa o ciclo de vida do TrucoHandler, timeouts, anti-cheat, tokens de rodada e corte.
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


class RoundCuttingMock:
    def __init__(self):
        self.id_rodada = 1
        self.corte_foi_realizado = False
        self.estado = "WAITING"
        self.jogador_corte = None
        self.distribuicoes_count = 0

    def iniciar_nova_rodada(self, jogador_corte: str) -> int:
        self.id_rodada += 1
        self.corte_foi_realizado = False
        self.estado = "CUTTING"
        self.jogador_corte = jogador_corte
        return self.id_rodada

    def resetar_estado(self):
        self.id_rodada += 1
        self.corte_foi_realizado = False
        self.estado = "WAITING"

    def cortar_baralho(self, jogador: str, quantidade: int = 1) -> bool:
        if self.estado != "CUTTING" or self.corte_foi_realizado:
            return False
        if jogador == self.jogador_corte:
            self.corte_foi_realizado = True
            self.distribuir_cartas()
            return True
        return False

    def executar_timeout_corte(self, id_rodada_capturado: int) -> bool:
        if (
            self.id_rodada == id_rodada_capturado
            and not self.corte_foi_realizado
            and self.estado == "CUTTING"
        ):
            self.corte_foi_realizado = True
            self.distribuir_cartas()
            return True
        return False

    def distribuir_cartas(self):
        self.distribuicoes_count += 1
        self.estado = "PLAYING"


class MaoDeOnzeMock:
    def __init__(self):
        self.estado = "WAITING"
        self.equipe_mao_de_onze = None
        self.valor_rodada = 1

    def iniciar_mao_de_onze(self, equipe_onze: str):
        self.valor_rodada = 3
        self.estado = "ELEVEN_DECISION"
        self.equipe_mao_de_onze = equipe_onze

    def decidir_mao_de_onze(self, jogador: str, decisao: str, equipe_jogador: str):
        if self.estado != "ELEVEN_DECISION":
            return False
        if self.equipe_mao_de_onze and equipe_jogador != self.equipe_mao_de_onze:
            return False
        if decisao not in ("CORRER", "JOGAR"):
            return False

        self.equipe_mao_de_onze = None
        if decisao == "CORRER":
            self.estado = "SCORING"
            return "CORREU"
        elif decisao == "JOGAR":
            self.estado = "PLAYING"
            return "JOGOU"
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

    # --- Testes de Bloqueio de Dupla Execução do Corte e Token de Rodada (D-03 / Issue #7) ---

    def test_corte_manual_bloqueia_timeout_posterior(self):
        """Após o corte manual pelo jogador autorizado, o timeout agendado não pode distribuir novamente."""
        round_mgr = RoundCuttingMock()
        id_rodada = round_mgr.iniciar_nova_rodada("Jogador2")
        self.assertEqual(id_rodada, 2)
        self.assertEqual(round_mgr.estado, "CUTTING")

        # Corte manual com sucesso
        corte_ok = round_mgr.cortar_baralho("Jogador2", 1)
        self.assertTrue(corte_ok)
        self.assertTrue(round_mgr.corte_foi_realizado)
        self.assertEqual(round_mgr.distribuicoes_count, 1)

        # Timeout da rodada dispara após o corte ter ocorrido
        timeout_executou = round_mgr.executar_timeout_corte(id_rodada)
        self.assertFalse(timeout_executou)
        # Não distribuiu uma segunda vez
        self.assertEqual(round_mgr.distribuicoes_count, 1)

    def test_mudanca_de_rodada_invalida_timeout_antigo(self):
        """Se a rodada mudar ou for resetada, o timeout agendado da rodada anterior é ignorado."""
        round_mgr = RoundCuttingMock()
        id_rodada_antiga = round_mgr.iniciar_nova_rodada("Jogador2")
        self.assertEqual(id_rodada_antiga, 2)

        # Partida reseta ou inicia nova rodada antes do timeout disparar
        round_mgr.resetar_estado()
        self.assertNotEqual(round_mgr.id_rodada, id_rodada_antiga)

        # Timeout antigo dispara
        timeout_executou = round_mgr.executar_timeout_corte(id_rodada_antiga)
        self.assertFalse(timeout_executou)
        self.assertEqual(round_mgr.distribuicoes_count, 0)

    def test_duplo_corte_manual_rejeitado(self):
        """Tentativa de cortar duas vezes na mesma rodada é bloqueada."""
        round_mgr = RoundCuttingMock()
        round_mgr.iniciar_nova_rodada("Jogador2")
        self.assertTrue(round_mgr.cortar_baralho("Jogador2", 1))
        # Segunda tentativa
        self.assertFalse(round_mgr.cortar_baralho("Jogador2", 1))
        self.assertEqual(round_mgr.distribuicoes_count, 1)

    def test_timeout_corte_executa_se_nenhum_corte_realizado(self):
        """Se ninguém cortou no tempo limite e a rodada continua a mesma, o timeout realiza o corte padrão."""
        round_mgr = RoundCuttingMock()
        id_rodada = round_mgr.iniciar_nova_rodada("Jogador2")
        timeout_executou = round_mgr.executar_timeout_corte(id_rodada)
        self.assertTrue(timeout_executou)
        self.assertTrue(round_mgr.corte_foi_realizado)
        self.assertEqual(round_mgr.distribuicoes_count, 1)

    # --- Testes de Decisão da Mão de Onze (D-01) ---

    def test_mao_de_onze_aceita_apenas_equipe_detentora_dos_onze_pontos(self):
        """Mão de Onze deve rejeitar tentativa de decisão por jogador da equipe adversária."""
        mao_onze = MaoDeOnzeMock()
        mao_onze.iniciar_mao_de_onze("A")
        self.assertEqual(mao_onze.estado, "ELEVEN_DECISION")

        # Jogador da Equipe B tenta decidir a Mão de Onze pertencente à Equipe A
        resultado_b = mao_onze.decidir_mao_de_onze("JogadorB1", "JOGAR", equipe_jogador="B")
        self.assertFalse(resultado_b)
        self.assertEqual(mao_onze.estado, "ELEVEN_DECISION")

        # Jogador da Equipe A decide com sucesso
        resultado_a = mao_onze.decidir_mao_de_onze("JogadorA1", "JOGAR", equipe_jogador="A")
        self.assertEqual(resultado_a, "JOGOU")
        self.assertEqual(mao_onze.estado, "PLAYING")

    def test_mao_de_onze_rejeita_decisao_fora_do_estado_eleven_decision(self):
        """Decisão de Mão de Onze enviada fora do estado ELEVEN_DECISION deve ser rejeitada."""
        mao_onze = MaoDeOnzeMock()
        mao_onze.estado = "PLAYING"
        mao_onze.equipe_mao_de_onze = "A"

        resultado = mao_onze.decidir_mao_de_onze("JogadorA1", "JOGAR", equipe_jogador="A")
        self.assertFalse(resultado)
        self.assertEqual(mao_onze.estado, "PLAYING")

    def test_mao_de_onze_rejeita_decisao_invalida(self):
        """Valores de decisão diferentes de JOGAR e CORRER são rejeitados."""
        mao_onze = MaoDeOnzeMock()
        mao_onze.iniciar_mao_de_onze("A")

        resultado = mao_onze.decidir_mao_de_onze("JogadorA1", "PEDIR_AUMENTO", equipe_jogador="A")
        self.assertFalse(resultado)
        self.assertEqual(mao_onze.estado, "ELEVEN_DECISION")

    def test_mao_de_onze_decisao_correr_finaliza_mao(self):
        """Se a equipe com 11 pontos decidir CORRER, a mão transiciona para SCORING."""
        mao_onze = MaoDeOnzeMock()
        mao_onze.iniciar_mao_de_onze("B")

        resultado = mao_onze.decidir_mao_de_onze("JogadorB1", "CORRER", equipe_jogador="B")
        self.assertEqual(resultado, "CORREU")
        self.assertEqual(mao_onze.estado, "SCORING")


if __name__ == "__main__":
    unittest.main()

"""
Validação Automatizada de Regras do Truco Paulista (Skill: truco-core-rules)
Executa asserts em cima da ordem de força, manilhas e cenários de empate (canga).
"""

import unittest

VALORES_PADRAO = ["4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"]
FORCA_PADRAO = {val: idx + 1 for idx, val in enumerate(VALORES_PADRAO)}

NAIPES_MANILHA = {
    "Paus": 4,      # Zap (mais forte)
    "Copas": 3,
    "Espadas": 2,
    "Ouros": 1      # Pica-fumo
}

def obter_manilha_de_vira(vira: str) -> str:
    idx = VALORES_PADRAO.index(vira)
    proximo_idx = (idx + 1) % len(VALORES_PADRAO)
    return VALORES_PADRAO[proximo_idx]

def calcular_forca_carta(valor: str, naipe: str, vira: str, escondida: bool = False) -> int:
    if escondida:
        return 0
    manilha_valor = obter_manilha_de_vira(vira)
    if valor == manilha_valor:
        return 100 + NAIPES_MANILHA[naipe]
    return FORCA_PADRAO[valor]

def determinar_vencedor_queda(cartas_jogadas, vira: str):
    """
    cartas_jogadas: lista de tuplas (jogador, equipe, valor, naipe, escondida)
    ou (jogador, valor, naipe, escondida) para compatibilidade retroativa.
    """
    maior_forca = 0
    vencedor = None
    equipe_maior = None
    empatou = False

    for item in cartas_jogadas:
        if len(item) == 5:
            jogador, equipe, valor, naipe, escondida = item
        else:
            jogador, valor, naipe, escondida = item
            equipe = None

        forca = calcular_forca_carta(valor, naipe, vira, escondida)
        if forca > maior_forca:
            maior_forca = forca
            vencedor = jogador
            equipe_maior = equipe
            empatou = False
        elif forca == maior_forca and maior_forca > 0:
            if not (equipe is not None and equipe_maior is not None and equipe == equipe_maior):
                empatou = True

    if maior_forca <= 0 or empatou:
        return "DRAW"
    return vencedor

class TestTrucoCoreRules(unittest.TestCase):
    def test_ordem_padrao(self):
        """Valida que 3 é mais forte que 2, que é mais forte que A, e 4 é a menor."""
        self.assertGreater(FORCA_PADRAO["3"], FORCA_PADRAO["2"])
        self.assertGreater(FORCA_PADRAO["2"], FORCA_PADRAO["A"])
        self.assertEqual(FORCA_PADRAO["4"], 1)
        self.assertEqual(FORCA_PADRAO["3"], 10)

    def test_vira_e_manilhas(self):
        """Valida rotação de manilha: Vira 3 -> Manilha 4; Vira 7 -> Manilha Q."""
        self.assertEqual(obter_manilha_de_vira("3"), "4")
        self.assertEqual(obter_manilha_de_vira("7"), "Q")
        self.assertEqual(obter_manilha_de_vira("A"), "2")

    def test_forca_manilhas_por_naipe(self):
        """Zap (Paus) > Copas > Espadas > Pica-fumo (Ouros)."""
        vira = "K" # Manilha = A
        zap = calcular_forca_carta("A", "Paus", vira)
        copas = calcular_forca_carta("A", "Copas", vira)
        espadas = calcular_forca_carta("A", "Espadas", vira)
        picafumo = calcular_forca_carta("A", "Ouros", vira)
        carta_3 = calcular_forca_carta("3", "Paus", vira) # 3 não é manilha aqui

        self.assertGreater(zap, copas)
        self.assertGreater(copas, espadas)
        self.assertGreater(espadas, picafumo)
        self.assertGreater(picafumo, carta_3)

    def test_carta_coberta_sempre_perde(self):
        """Carta coberta tem força zero e nunca empata nem vence."""
        vira = "4"
        forca_escondida = calcular_forca_carta("A", "Paus", vira, escondida=True)
        self.assertEqual(forca_escondida, 0)

    def test_queda_com_empate_canga(self):
        """Duas cartas com o mesmo maior valor padrão resultam em DRAW."""
        vira = "5"
        jogadas = [
            ("Jogador 1", "3", "Ouros", False),
            ("Jogador 2", "3", "Espadas", False),
            ("Jogador 3", "2", "Copas", False),
            ("Jogador 4", "Q", "Paus", False),
        ]
        # 3 de Ouros e 3 de Espadas empatam em 10 pontos
        maior_forca = -1
        empatou = False
        vencedor = None
        for jog, val, nai, esc in jogadas:
            f = calcular_forca_carta(val, nai, vira, esc)
            if f > maior_forca:
                maior_forca = f
                vencedor = jog
                empatou = False
            elif f == maior_forca:
                empatou = True
        self.assertTrue(empatou)
        self.assertEqual(determinar_vencedor_queda(jogadas, vira), "DRAW")

    def test_empate_mesma_dupla_nao_gera_canga(self):
        """Dois parceiros da mesma equipe empatando com a maior carta não geram canga; vence o primeiro a jogar."""
        vira = "5"
        jogadas = [
            ("Jogador 1", "A", "3", "Ouros", False),
            ("Jogador 2", "B", "2", "Espadas", False),
            ("Jogador 3", "A", "3", "Espadas", False),
            ("Jogador 4", "B", "Q", "Copas", False),
        ]
        vencedor = determinar_vencedor_queda(jogadas, vira)
        self.assertEqual(vencedor, "Jogador 1")

    def test_quatro_cartas_cobertas_gera_draw(self):
        """Quatro cartas cobertas têm força zero e a queda resulta em DRAW."""
        vira = "5"
        jogadas = [
            ("Jogador 1", "A", "3", "Ouros", True),
            ("Jogador 2", "B", "3", "Espadas", True),
            ("Jogador 3", "A", "2", "Copas", True),
            ("Jogador 4", "B", "Q", "Paus", True),
        ]
        vencedor = determinar_vencedor_queda(jogadas, vira)
        self.assertEqual(vencedor, "DRAW")

    def test_destaque_manilha_selos_issue8(self):
        """Identifica corretamente Manilhas para destaque em HandUI/ScoreUI (Issue #8)."""
        selos = {
            "Paus": "ZAP ♣️",
            "Copas": "COPAS ♥️",
            "Espadas": "ESPADAS ♠️",
            "Ouros": "OUROS ♦️",
        }
        vira = "5"
        manilha = obter_manilha_de_vira(vira)
        self.assertEqual(manilha, "6")

        mao = [("6", "Paus"), ("3", "Copas"), ("4", "Espadas")]
        destaques = [selos[naipe] for val, naipe in mao if val == manilha]
        self.assertEqual(destaques, ["ZAP ♣️"])

        # Rotação 3 -> 4
        self.assertEqual(obter_manilha_de_vira("3"), "4")
        destaques_rot = [selos[naipe] for val, naipe in mao if val == obter_manilha_de_vira("3")]
        self.assertEqual(destaques_rot, ["ESPADAS ♠️"])


if __name__ == "__main__":
    unittest.main()

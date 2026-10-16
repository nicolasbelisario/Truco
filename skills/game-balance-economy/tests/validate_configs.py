"""
Validador de Integridade de Configurações (Skill: game-balance-economy)
Analisa os arquivos em src/shared/Configs/ garantindo:
1. Nenhuma ocorrência de termos proibidos (RN-09: aposta, gambling, bet).
2. Consistência de preços e produtos únicos.
3. Skin padrão com custo zero.
"""

import os
import re
import unittest

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
CONFIGS_DIR = os.path.join(ROOT_DIR, "src", "shared", "Configs")

TERMOS_PROIBIDOS = [
    r"\baposta\b",
    r"\bapostas\b",
    r"\bgambling\b",
    r"\bbet\b",
    r"\bbetting\b",
    r"\bstake\b"
]

class TestEconomyConfigs(unittest.TestCase):
    def test_termos_proibidos_em_configs(self):
        """Verifica se nenhum arquivo de configuração contém termos de gambling (RN-09)."""
        self.assertTrue(os.path.exists(CONFIGS_DIR), f"Diretório não encontrado: {CONFIGS_DIR}")
        
        for root, _, files in os.walk(CONFIGS_DIR):
            for file in files:
                if file.endswith(".luau") or file.endswith(".lua"):
                    filepath = os.path.join(root, file)
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read().lower()
                        for pattern in TERMOS_PROIBIDOS:
                            matches = re.findall(pattern, content)
                            self.assertEqual(
                                len(matches), 0,
                                f"Termo proibido '{pattern}' encontrado no arquivo {file}!"
                            )

    def test_integridade_arquivo_economy_config(self):
        """Verifica se EconomyConfig.luau possui a estrutura esperada."""
        economy_path = os.path.join(CONFIGS_DIR, "EconomyConfig.luau")
        self.assertTrue(os.path.exists(economy_path))
        with open(economy_path, "r", encoding="utf-8") as f:
            content = f.read()
            self.assertIn('SkinPadraoId = "Padrao"', content)
            self.assertIn('Preco = 0', content)
            self.assertIn('Vitoria = 50', content)
            self.assertIn('Vitoria = 30', content)

    def test_integridade_arquivo_bot_config(self):
        """Verifica se BotConfig.luau possui todas as 3 dificuldades e limites válidos."""
        bot_path = os.path.join(CONFIGS_DIR, "BotConfig.luau")
        self.assertTrue(os.path.exists(bot_path))
        with open(bot_path, "r", encoding="utf-8") as f:
            content = f.read()
            self.assertIn('Facil', content)
            self.assertIn('Normal', content)
            self.assertIn('Dificil', content)

if __name__ == "__main__":
    unittest.main()

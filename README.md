
# Truco Paulista no Roblox

<p align="center">
  <img src="https://img.shields.io/badge/Roblox-Studio-blue?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox Studio" />
  <img src="https://img.shields.io/badge/Rojo-Integration-red?style=for-the-badge" alt="Rojo" />
  <img src="https://img.shields.io/badge/Luau-Scripting-00A2FF?style=for-the-badge" alt="Luau" />
</p>

Este é um repositório para o jogo de **Truco Paulista** desenvolvido na plataforma **Roblox**. O projeto traz a experiência do clássico jogo de cartas brasileiro de forma totalmente integrada e multijogador.

---

## Demonstração do Jogo

*Insira abaixo as capturas de tela ou GIFs demonstrando a interface, o lobby ou a mesa de jogo em funcionamento.*

| Lobby / Tela Principal | Mesa de Jogo |
| :---: | :---: |
| `![Lobby](https://github.com/user-attachments/assets/7607e48e-fcbe-44f5-9951-04d28da3be35)` | `![Mesa](https://github.com/user-attachments/assets/26914ab0-dc98-4350-bb6e-c88b803be50b)` |

| Sistema de Apostas (Truco!) | Visualização das Cartas |
| :---: | :---: |
| `![Grito de Truco](https://github.com/user-attachments/assets/43945dff-c42d-477d-9b77-f096fc7263cf)` | `![Cartas na Mão](https://github.com/user-attachments/assets/e7b85303-6c49-47ac-8582-718f5414a4d8)` |

---

## Sobre o Desenvolvimento

Este projeto representa um marco importante no meu aprendizado e adoção de práticas profissionais de engenharia de software dentro do ecossistema Roblox:

* **Integração Rojo + Roblox Studio:** Este é o meu **primeiro projeto** utilizando a ferramenta Rojo para gerenciar todo o ecossistema de código-fonte externamente (via VS Code) e versionamento de arquivos com Git, realizando a sincronização em tempo real com o Roblox Studio.
* **Estruturação com Suporte de IA:** A arquitetura inicial, divisão de responsabilidades entre Cliente/Servidor e a organização geral das pastas do projeto contaram com o auxílio de ferramentas de Inteligência Artificial para otimização e planejamento.
* **Design Visual 100% Autoral (Sem Uso de IA):** Ao contrário da estruturação do código, todos os elementos artísticos e visuais do jogo foram criados de forma puramente manual:
    * **Sprites das Cartas:** Todos os naipes, números e versos das cartas foram desenhados e estruturados manualmente no **Canva**, sem qualquer tipo de geração automatizada por IA.
    * **Skins e Interfaces:** Os componentes de interface de usuário (UI) e as skins presentes seguem o mesmo princípio de criação artística manual no Canva.

---

## Tecnologias Utilizadas

* [Roblox Studio](https://create.roblox.com/) - Ambiente base e motor do jogo.
* [Luau](https://luau-lang.org/) - Linguagem de programação derivada de Lua, otimizada para o Roblox.
* [Rojo](https://rojo.space/) - Sincronização e gerenciamento de arquivos externos.
* [Canva](https://www.canva.com/) - Criação de toda a identidade visual, sprites e interfaces gráficas.

---

## Regras do Truco Paulista (Resumo)

O Truco Paulista é jogado tradicionalmente com o baralho limpo (40 cartas, removendo os 8, 9 e 10). 
* **Ordem de força padrão (crescente):** 4, 5, 6, 7, Q, J, K, A, 2, 3.
* **As Manilhas:** São as quatro cartas mais fortes do jogo, determinadas pela carta que é virada na mesa ("Vira"). A manilha é sempre a carta imediatamente superior à vira.
* **Força das Manilhas (por naipe, do maior para o menor):** 1. ♣️ Paus (Zap)
    2. ♥️ Copas
    3. ♠️ Espadas
    4. ♦️ Ouros (Pica-fumo)

---

## Configuração do Ambiente Local

Se você deseja clonar o projeto e rodar o fluxo de desenvolvimento localmente:

1.  **Instale os pré-requisitos:**
    * [Rojo CLI](https://rojo.space/docs/v7/installation/) ou a extensão do VS Code.
    * Plugin do Rojo instalado no Roblox Studio.

2.  **Clone o repositório:**
    ```bash
    git clone https://github.com/nicolasbelisario/Truco.git
    cd Truco
    ```

3.  **Inicie o servidor do Rojo:**
    ```bash
    rojo serve
    ```

4.  **Conecte ao Roblox Studio:**
    * Abra um local vazio no Roblox Studio.
    * Abra o plugin do Rojo e clique em **Connect** para sincronizar automaticamente a estrutura definida no `default.project.json`.

---

## Autor

Desenvolvido com dedicação por [Nicolas Belisario](https://github.com/nicolasbelisario).

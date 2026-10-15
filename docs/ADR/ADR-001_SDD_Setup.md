# ADR-001 — Adoção de Spec Driven Development (SDD)

**Data**: 2026-10-15  
**Status**: ✅ Aceito  
**Decisores**: nicolasbelisario (maintainer)  

---

## Contexto

O projeto Truco Paulista estava em crescimento sem documentação formal de especificação. Com o aumento do uso de IA para desenvolvimento (GitHub Copilot, Antigravity), ficou evidente que a IA necessita de **contexto estruturado** para produzir código correto e aderente às regras do jogo.

Problemas identificados antes da migração:
- Regras de negócio estavam apenas no código ou na cabeça do desenvolvedor
- Sem glossário, termos como "Queda" e "Mão" podiam ser ambíguos para IAs e colaboradores
- Sem use cases, novas features eram desenvolvidas sem critérios claros de aceite
- Bugs como a condição de corrida no timeout de corte não tinham onde ser documentados formalmente

---

## Decisão

Adotar **Spec Driven Development (SDD)** como metodologia de desenvolvimento, estruturada nos seguintes artefatos:

```
docs/
├── wiki/
│   ├── README.md          # Índice e visão do produto
│   ├── GLOSSARY.md        # Linguagem ubíqua (termos canônicos)
│   ├── ARCHITECTURE.md    # Módulos, fluxos, protocolo de rede
│   └── BUSINESS_RULES.md  # Regras invariantes RN-XX
├── use-cases/
│   ├── UC_INDEX.md        # Índice de todos os use cases
│   └── UC-XX_*.md         # Documentação individual por use case
├── ADR/
│   └── ADR-XXX_*.md       # Architecture Decision Records
├── CHANGELOG.md           # Histórico de mudanças
└── scripts/
    └── create_issues.sh   # Scripts auxiliares
```

O arquivo `.gemini/GEMINI.md` serve como **contexto primário para IAs** e já continha a base das regras de negócio — foi mantido e passa a referenciar os documentos em `docs/`.

---

## Consequências

### Positivas
- IA (Antigravity, Copilot) tem contexto estruturado para gerar código correto
- Novos colaboradores entendem o domínio rapidamente pelo Glossário
- Issues no GitHub têm critérios de aceite claros ligados aos use cases
- Bugs são rastreáveis com referências de código exatas
- Architecture Decision Records preservam o "porquê" de decisões

### Negativas / Trade-offs
- Overhead inicial de manutenção da documentação
- Documentos podem ficar desatualizados se não houver disciplina
- **Mitigação**: Use Cases referenciam linhas de código específicas; mudanças no código devem atualizar a documentação

---

## Alternativas Consideradas

| Alternativa | Motivo da Rejeição |
|-------------|-------------------|
| Apenas comentários no código | Não acessível para IA sem leitura completa dos arquivos |
| Wiki do GitHub | Fora do repositório, não versionado junto ao código |
| Nenhuma documentação | Status quo insustentável com uso intenso de IA |

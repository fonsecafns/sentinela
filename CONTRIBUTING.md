# Contribuindo com o Sentinela

## Antes de tudo

O `SKILL.md` é a **fonte única de verdade**. `AGENTS.md`, `GEMINI.md`, `.cursor/rules/sentinela.mdc` e `.sentinela-shared/` são **gerados automaticamente** a partir dele. Nunca edite esses arquivos gerados diretamente, sua mudança seria sobrescrita na próxima geração.

## Fluxo de uma contribuição

1. Abra uma issue descrevendo o problema ou a melhoria antes de um PR grande, pra alinhar antes de codar.
2. Faça um fork e crie uma branch a partir de `main`.
3. Se a mudança for no comportamento da auditoria, edite **só** o `SKILL.md` (e `references/ferramentas-por-stack.md`, se for sobre ferramentas de alguma stack).
4. Rode `python scripts/build_adapters.py` pra regenerar os adaptadores. Confira no `git diff` que os arquivos gerados mudaram de forma consistente com a sua edição.
5. Se a mudança for no instalador, edite `install.sh` e `install.ps1` juntos, eles precisam continuar equivalentes entre si.
6. Commit seguindo [Conventional Commits](https://www.conventionalcommits.org/pt-br/) (`feat:`, `fix:`, `docs:` etc), mensagem curta e no imperativo.
7. Abra o PR descrevendo o que mudou e por quê.

## Testando localmente

Não há suíte de testes automatizada (é um arquivo de instruções, não código executável). Pra validar uma mudança no `SKILL.md`, instale a skill localmente a partir do seu fork e rode uma auditoria de verdade contra um projeto de teste, conferindo que o comportamento novo aparece como esperado no relatório.

## Licenciamento das contribuições

Este repositório tem licença dividida (veja a seção [Licença](README.md#licença) do README). Ao abrir um PR:

- Mudanças em `install.sh`, `install.ps1` ou `scripts/build_adapters.py` entram sob [MIT](LICENSE-MIT).
- Mudanças em `SKILL.md`, adaptadores gerados ou `references/` entram sob [BSL-1.1](LICENSE).

Só abra PR se estiver de acordo com esses termos para o seu conteúdo.

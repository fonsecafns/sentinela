# Política de Segurança

## Versões suportadas

O Sentinela não segue versionamento tradicional: `main` é sempre a versão suportada e recomendada. Não há versões antigas mantidas em paralelo.

## Reportando uma vulnerabilidade

Se você encontrar uma vulnerabilidade de segurança neste projeto (por exemplo nos instaladores `install.sh`/`install.ps1`, no `scripts/build_adapters.py`, ou uma instrução no `SKILL.md` que possa ser explorada para injeção de prompt ou execução indevida de comando), **não abra uma issue pública**.

Reporte de forma privada por [GitHub Security Advisories](https://github.com/fonsecafns/sentinela/security/advisories/new), que só é visível aos mantenedores até a correção sair.

Inclua, se possível:

- Passos para reproduzir o problema;
- Impacto esperado;
- Versão/commit afetado.

Você vai receber uma resposta inicial em até 5 dias úteis. Se confirmado, a correção é priorizada e um aviso é publicado depois que ela sai.

## Escopo

Este é um projeto de instruções para agentes de IA (skill), não um serviço com API ou banco de dados. O escopo de segurança relevante é: instaladores rodando comando arbitrário sem confirmação, e conteúdo do `SKILL.md`/adaptadores que possa ser sequestrado por injeção de prompt vindo de um projeto auditado.

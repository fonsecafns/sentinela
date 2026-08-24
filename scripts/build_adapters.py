#!/usr/bin/env python3
"""
Gera os adaptadores do Sentinela pra outras ferramentas de IA (Codex CLI,
Gemini CLI, Cursor) a partir do SKILL.md, que é a fonte única de verdade.

Rode este script sempre que o SKILL.md mudar:

    python3 scripts/build_adapters.py

Ele gera:
    AGENTS.md                     (Codex CLI e qualquer ferramenta compatível com AGENTS.md)
    GEMINI.md                     (Gemini CLI)
    .cursor/rules/sentinela.mdc   (Cursor)
    .sentinela-shared/ferramentas-por-stack.md  (cópia da referência usada pelos três acima)

Não edite os arquivos gerados diretamente, edite o SKILL.md e rode o script de novo.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_MD = ROOT / "SKILL.md"
REFERENCE_SRC = ROOT / "references" / "ferramentas-por-stack.md"
SHARED_REF_DIR = ROOT / ".sentinela-shared"
SHARED_REF_PATH = SHARED_REF_DIR / "ferramentas-por-stack.md"

REFERENCE_PATH_CLAUDE = "references/ferramentas-por-stack.md"
REFERENCE_PATH_SHARED = ".sentinela-shared/ferramentas-por-stack.md"

GUARDRAIL_NOTE = (
    "> Nota pra quem estiver adaptando ou revisando este arquivo: ao contrário do Claude, "
    "que só carrega uma skill quando o usuário pede algo relacionado, esta ferramenta pode "
    "manter este arquivo sempre carregado no contexto do projeto. Por isso, a regra abaixo "
    "vale antes de qualquer outra: **só execute a auditoria (ou qualquer parte dela) quando "
    "o usuário pedir isso explicitamente na conversa**, nunca por conta própria só porque "
    "este arquivo está presente no projeto.\n"
)


def strip_frontmatter(text):
    """Remove o bloco YAML entre --- no início do arquivo e retorna (frontmatter_dict, corpo)."""
    match = re.match(r"^---\n(.*?)\n---\n\n?(.*)$", text, re.DOTALL)
    if not match:
        raise ValueError("SKILL.md não tem o frontmatter YAML esperado")
    frontmatter_raw, body = match.groups()
    frontmatter = {}
    for line in frontmatter_raw.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            frontmatter[key.strip()] = value.strip()
    return frontmatter, body


def adapt_reference_path(body):
    return body.replace(REFERENCE_PATH_CLAUDE, REFERENCE_PATH_SHARED)


def build_agents_md(body, description):
    header = (
        "# Sentinela: Auditoria de Segurança\n\n"
        f"{GUARDRAIL_NOTE}\n"
        f"**O que isto faz:** {description}\n\n"
        "---\n\n"
    )
    # Remove o título duplicado do corpo original, já que o header acima já tem um.
    body_wo_title = re.sub(r"^# Sentinela: Auditoria de Segurança\n\n", "", body)
    return header + adapt_reference_path(body_wo_title)


def build_gemini_md(body, description):
    # Mesmo conteúdo do AGENTS.md, formato de arquivo idêntico (Gemini CLI também
    # usa um arquivo de contexto Markdown simples, carregado hierarquicamente).
    return build_agents_md(body, description)


def build_cursor_rule(body, description):
    frontmatter = (
        "---\n"
        f"description: {description}\n"
        "alwaysApply: false\n"
        "---\n\n"
    )
    header = (
        f"{GUARDRAIL_NOTE}\n"
        "---\n\n"
    )
    body_wo_title = re.sub(r"^# Sentinela: Auditoria de Segurança\n\n", "# Sentinela: Auditoria de Segurança\n\n", body)
    return frontmatter + header + adapt_reference_path(body_wo_title)


def main():
    raw = SKILL_MD.read_text(encoding="utf-8")
    frontmatter, body = strip_frontmatter(raw)
    description = frontmatter.get("description", "").strip('"')

    (ROOT / "AGENTS.md").write_text(build_agents_md(body, description), encoding="utf-8")
    (ROOT / "GEMINI.md").write_text(build_gemini_md(body, description), encoding="utf-8")

    cursor_dir = ROOT / ".cursor" / "rules"
    cursor_dir.mkdir(parents=True, exist_ok=True)
    (cursor_dir / "sentinela.mdc").write_text(build_cursor_rule(body, description), encoding="utf-8")

    SHARED_REF_DIR.mkdir(parents=True, exist_ok=True)
    SHARED_REF_PATH.write_text(REFERENCE_SRC.read_text(encoding="utf-8"), encoding="utf-8")

    print("Gerados: AGENTS.md, GEMINI.md, .cursor/rules/sentinela.mdc, .sentinela-shared/ferramentas-por-stack.md")


if __name__ == "__main__":
    main()

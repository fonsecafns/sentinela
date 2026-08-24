#!/usr/bin/env bash
# Instalador do Sentinela (auditoria de segurança) para Claude Code, Codex CLI,
# Gemini CLI e Cursor.
#
# Uso rápido (instala tudo, global, pra usar em qualquer projeto seu):
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash
#
# Escolhendo só uma ferramenta:
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash -s -- --claude
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash -s -- --codex
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash -s -- --gemini
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash -s -- --cursor
#
# Instalando só neste projeto (em vez de globalmente pra todos os seus projetos):
#   curl -fsSL https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.sh | bash -s -- --project
#
# Ver todas as opções: passe --help

set -euo pipefail

REPO_URL="https://github.com/fonsecafns/sentinela.git"
REPO_TARBALL="https://codeload.github.com/fonsecafns/sentinela/tar.gz/refs/heads/main"
BRANCH="main"

INSTALL_CLAUDE=0
INSTALL_CODEX=0
INSTALL_GEMINI=0
INSTALL_CURSOR=0
SCOPE="global" # global | project
ANY_FLAG=0

print_help() {
  cat <<'EOF'
Instalador do Sentinela

Ferramentas (pode combinar mais de uma; sem nenhuma, instala em todas):
  --claude    Instala como Claude Code skill
  --codex     Instala como AGENTS.md (Codex CLI e compatíveis)
  --gemini    Instala como GEMINI.md (Gemini CLI)
  --cursor    Instala como regra do Cursor (sempre neste projeto, Cursor não
              tem instalação global por arquivo)
  --all       Instala em todas as ferramentas (padrão se nenhuma flag for dada)

Escopo:
  --global    Instala pra todos os seus projetos (padrão pra Claude/Codex/Gemini)
  --project   Instala só no projeto atual (pasta onde você rodou o comando)

  -h, --help  Mostra esta ajuda
EOF
}

for arg in "$@"; do
  case "$arg" in
    --claude) INSTALL_CLAUDE=1; ANY_FLAG=1 ;;
    --codex) INSTALL_CODEX=1; ANY_FLAG=1 ;;
    --gemini) INSTALL_GEMINI=1; ANY_FLAG=1 ;;
    --cursor) INSTALL_CURSOR=1; ANY_FLAG=1 ;;
    --all) INSTALL_CLAUDE=1; INSTALL_CODEX=1; INSTALL_GEMINI=1; INSTALL_CURSOR=1; ANY_FLAG=1 ;;
    --global) SCOPE="global" ;;
    --project) SCOPE="project" ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Opção desconhecida: $arg (use --help pra ver as opções)"; exit 1 ;;
  esac
done

if [ "$ANY_FLAG" -eq 0 ]; then
  INSTALL_CLAUDE=1
  INSTALL_CODEX=1
  INSTALL_GEMINI=1
  INSTALL_CURSOR=1
fi

echo "Sentinela: baixando o repositório..."

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

if command -v git >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$WORK_DIR/sentinela" >/dev/null 2>&1
elif command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
  curl -fsSL "$REPO_TARBALL" -o "$WORK_DIR/sentinela.tar.gz"
  tar -xzf "$WORK_DIR/sentinela.tar.gz" -C "$WORK_DIR"
  mv "$WORK_DIR"/sentinela-* "$WORK_DIR/sentinela"
else
  echo "Preciso de 'git', ou de 'curl' + 'tar', pra baixar o repositório. Instale um dos dois e tente de novo."
  exit 1
fi

SRC="$WORK_DIR/sentinela"

append_block() {
  # append_block <arquivo> <conteúdo>
  local file="$1"
  local content="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "<!-- sentinela:start -->" "$file" 2>/dev/null; then
    echo "Já existe uma seção do Sentinela em $file, deixei como estava. Edite manualmente se quiser atualizar."
  else
    {
      echo ""
      echo "<!-- sentinela:start -->"
      echo "$content"
      echo "<!-- sentinela:end -->"
    } >> "$file"
    echo "Adicionado em $file"
  fi
}

install_claude() {
  local target
  if [ "$SCOPE" = "global" ]; then
    target="$HOME/.claude/skills/sentinela"
  else
    target="./.claude/skills/sentinela"
  fi
  mkdir -p "$target"
  cp "$SRC/SKILL.md" "$target/SKILL.md"
  cp -r "$SRC/references" "$target/references"
  echo "Claude Code: instalado em $target"
}

install_codex() {
  local shared_dir target_file
  if [ "$SCOPE" = "global" ]; then
    target_file="$HOME/.codex/AGENTS.md"
    shared_dir="$HOME/.codex/.sentinela-shared"
  else
    target_file="./AGENTS.md"
    shared_dir="./.sentinela-shared"
  fi
  mkdir -p "$shared_dir"
  cp "$SRC/.sentinela-shared/ferramentas-por-stack.md" "$shared_dir/ferramentas-por-stack.md"
  append_block "$target_file" "$(cat "$SRC/AGENTS.md")"
  echo "Codex CLI: instalado em $target_file (referências em $shared_dir)"
}

install_gemini() {
  local shared_dir target_file
  if [ "$SCOPE" = "global" ]; then
    target_file="$HOME/.gemini/GEMINI.md"
    shared_dir="$HOME/.gemini/.sentinela-shared"
  else
    target_file="./GEMINI.md"
    shared_dir="./.sentinela-shared"
  fi
  mkdir -p "$shared_dir"
  cp "$SRC/.sentinela-shared/ferramentas-por-stack.md" "$shared_dir/ferramentas-por-stack.md"
  append_block "$target_file" "$(cat "$SRC/GEMINI.md")"
  echo "Gemini CLI: instalado em $target_file (referências em $shared_dir)"
}

install_cursor() {
  # O Cursor não tem um mecanismo de regra global por arquivo (regras globais
  # são configuradas na interface do Cursor), então isso é sempre por projeto.
  local target="./.cursor/rules/sentinela.mdc"
  local shared_dir="./.sentinela-shared"
  mkdir -p "$(dirname "$target")" "$shared_dir"
  cp "$SRC/.cursor/rules/sentinela.mdc" "$target"
  cp "$SRC/.sentinela-shared/ferramentas-por-stack.md" "$shared_dir/ferramentas-por-stack.md"
  echo "Cursor: instalado em $target (regra 'agent requested', só entra quando fizer sentido pro pedido)"
}

[ "$INSTALL_CLAUDE" -eq 1 ] && install_claude
[ "$INSTALL_CODEX" -eq 1 ] && install_codex
[ "$INSTALL_GEMINI" -eq 1 ] && install_gemini
[ "$INSTALL_CURSOR" -eq 1 ] && install_cursor

echo ""
echo "Pronto. Peça 'roda o sentinela nesse projeto' (ou equivalente) na ferramenta instalada pra testar."

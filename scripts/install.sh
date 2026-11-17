#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SOURCE="$ROOT/factory"
CODEX_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CONFIG_DIR="$HOME/.config/expo-project-factory"
BIN_DIR="$HOME/.local/bin"
COMMAND_SOURCE="$ROOT/bin/expo-factory"
COMMAND_LINK="$BIN_DIR/expo-factory"
DEFAULTS_FILE="$CONFIG_DIR/defaults.md"

is_linked() {
  [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]
}

# Check every destination before changing anything, so a conflict leaves no partial install.
check_free() {
  local target="$1"
  local link="$2"

  if is_linked "$target" "$link"; then
    return
  fi

  if [ -e "$link" ] || [ -L "$link" ]; then
    echo "Refusing to overwrite existing path: $link"
    echo "Back it up or remove it manually, then rerun this installer."
    echo "Nothing was installed."
    exit 1
  fi
}

link_skill() {
  local target="$1"
  local link="$2"

  if is_linked "$target" "$link"; then
    echo "Already linked: $link"
    return
  fi

  ln -s "$target" "$link"
  echo "Installed: $link -> $target"
}

check_free "$SKILL_SOURCE" "$CODEX_SKILLS/expo-project-factory"
check_free "$SKILL_SOURCE" "$CLAUDE_SKILLS/expo-project-factory"
check_free "$COMMAND_SOURCE" "$COMMAND_LINK"

mkdir -p "$CODEX_SKILLS" "$CLAUDE_SKILLS" "$BIN_DIR"

link_skill "$SKILL_SOURCE" "$CODEX_SKILLS/expo-project-factory"
link_skill "$SKILL_SOURCE" "$CLAUDE_SKILLS/expo-project-factory"
link_skill "$COMMAND_SOURCE" "$COMMAND_LINK"

# Personal defaults are copied, not linked, so your edits stay out of this repo.
if [ -e "$DEFAULTS_FILE" ] || [ -L "$DEFAULTS_FILE" ]; then
  echo "Keeping existing defaults: $DEFAULTS_FILE"
else
  echo
  echo "Which backend do you usually build on? (sets your defaults; you can change it later)"
  echo "  1) Node.js with NestJS + PostgreSQL"
  echo "  2) Node.js with Express"
  echo "  3) Supabase"
  echo "  4) Firebase"
  echo "  5) No backend (data stays on the device)"
  echo "  6) Decide later - the agent proposes one on your first project"
  CHOICE=""
  read -r -p "Choose 1-6 [6]: " CHOICE || true

  BACKEND="not decided"
  DATABASE="not decided"
  AUTH="not decided"
  case "$CHOICE" in
    1) BACKEND="NestJS REST API"; DATABASE="PostgreSQL"; AUTH="JWT issued by the API" ;;
    2) BACKEND="Node.js REST API (Express)"; AUTH="JWT issued by the API" ;;
    3) BACKEND="Supabase"; DATABASE="Supabase Postgres"; AUTH="Supabase Auth" ;;
    4) BACKEND="Firebase"; DATABASE="Cloud Firestore"; AUTH="Firebase Authentication" ;;
    5) BACKEND="none (data stays on the device)"; DATABASE="on-device SQLite (expo-sqlite)"; AUTH="none" ;;
    ""|6) ;;
    *) echo "Unrecognised choice '$CHOICE'; leaving the backend undecided." ;;
  esac

  mkdir -p "$CONFIG_DIR"
  sed \
    -e "s|^- Backend / API: .*|- Backend / API: $BACKEND|" \
    -e "s|^- Database: .*|- Database: $DATABASE|" \
    -e "s|^- Authentication: .*|- Authentication: $AUTH|" \
    "$ROOT/templates/defaults.md" > "$DEFAULTS_FILE"
  echo "Created defaults: $DEFAULTS_FILE"
fi

echo
echo "Factory skill linked for Codex and Claude Code."
echo "Next:"
echo "  1. Install the official Expo plugin in each agent and restart the sessions."
case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "  2. Start a project from any folder with: expo-factory new"
    ;;
  *)
    echo "  2. Add $BIN_DIR to your PATH so the expo-factory command is found."
    echo "     For zsh:  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "     For bash: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    echo "     Then open a new terminal and run: expo-factory new"
    echo "     Until then this works: $COMMAND_LINK new"
    ;;
esac
echo
echo "You do not need to edit the defaults file. After you approve your first plan,"
echo "the agent offers to save that stack for future projects:"
echo "  $DEFAULTS_FILE"

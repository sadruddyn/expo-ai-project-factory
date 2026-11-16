#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SOURCE="$ROOT/factory"
CODEX_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"
CONFIG_DIR="$HOME/.config/expo-project-factory"
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

mkdir -p "$CODEX_SKILLS" "$CLAUDE_SKILLS"

link_skill "$SKILL_SOURCE" "$CODEX_SKILLS/expo-project-factory"
link_skill "$SKILL_SOURCE" "$CLAUDE_SKILLS/expo-project-factory"

# Personal defaults are copied, not linked, so your edits stay out of this repo.
if [ -e "$DEFAULTS_FILE" ] || [ -L "$DEFAULTS_FILE" ]; then
  echo "Keeping existing defaults: $DEFAULTS_FILE"
else
  echo
  echo "Which backend do you usually build on? (sets your defaults; you can change it later)"
  echo "  1) NestJS + PostgreSQL"
  echo "  2) Supabase"
  echo "  3) Firebase"
  echo "  4) No backend (data stays on the device)"
  echo "  5) Decide later - the agent proposes one on your first project"
  CHOICE=""
  read -r -p "Choose 1-5 [5]: " CHOICE || true

  BACKEND="not decided"
  DATABASE="not decided"
  AUTH="not decided"
  case "$CHOICE" in
    1) BACKEND="NestJS REST API"; DATABASE="PostgreSQL"; AUTH="JWT issued by the API" ;;
    2) BACKEND="Supabase"; DATABASE="Supabase Postgres"; AUTH="Supabase Auth" ;;
    3) BACKEND="Firebase"; DATABASE="Cloud Firestore"; AUTH="Firebase Authentication" ;;
    4) BACKEND="none (data stays on the device)"; DATABASE="on-device SQLite (expo-sqlite)"; AUTH="none" ;;
    ""|5) ;;
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
echo "  2. Start a project with ./scripts/new-project.sh"
echo
echo "You do not need to edit the defaults file. After you approve your first plan,"
echo "the agent offers to save that stack for future projects:"
echo "  $DEFAULTS_FILE"

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
  mkdir -p "$CONFIG_DIR"
  cp "$ROOT/templates/defaults.md" "$DEFAULTS_FILE"
  echo "Created defaults: $DEFAULTS_FILE"
fi

echo
echo "Factory skill linked for Codex and Claude Code."
echo "Next:"
echo "  1. Edit $DEFAULTS_FILE once with your usual stack."
echo "  2. Install the official Expo plugin in each agent and restart the sessions."
echo "  3. Start a project with ./scripts/new-project.sh"

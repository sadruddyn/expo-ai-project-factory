#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_SOURCE="$ROOT/factory"
CODEX_SKILLS="$HOME/.agents/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

mkdir -p "$CODEX_SKILLS" "$CLAUDE_SKILLS"

link_skill() {
  local target="$1"
  local link="$2"

  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    echo "Already linked: $link"
    return
  fi

  if [ -e "$link" ] || [ -L "$link" ]; then
    echo "Refusing to overwrite existing path: $link"
    echo "Back it up or remove it manually, then rerun this installer."
    exit 1
  fi

  ln -s "$target" "$link"
  echo "Installed: $link -> $target"
}

link_skill "$SKILL_SOURCE" "$CODEX_SKILLS/expo-project-factory"
link_skill "$SKILL_SOURCE" "$CLAUDE_SKILLS/expo-project-factory"

echo
echo "Factory skill linked for Codex and Claude Code."
echo "Next: install the official Expo plugin in each agent and restart the sessions."

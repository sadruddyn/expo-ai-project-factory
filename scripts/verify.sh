#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_LINK="$HOME/.agents/skills/expo-project-factory"
CLAUDE_LINK="$HOME/.claude/skills/expo-project-factory"
FAILED=0

check() {
  local label="$1"
  local path="$2"
  if [ -e "$path/SKILL.md" ]; then
    echo "PASS  $label: $path"
  else
    echo "FAIL  $label: missing SKILL.md at $path"
    FAILED=1
  fi
}

check "Codex factory skill" "$CODEX_LINK"
check "Claude Code factory skill" "$CLAUDE_LINK"

for path in "$CODEX_LINK" "$CLAUDE_LINK"; do
  if [ -e "$path/SKILL.md" ]; then
    grep -q '^name: expo-project-factory$' "$path/SKILL.md" \
      && echo "PASS  Skill metadata: $path" \
      || { echo "FAIL  Invalid skill metadata: $path"; FAILED=1; }
  fi
done

if [ -L "$CODEX_LINK" ]; then
  [ "$(cd "$(dirname "$CODEX_LINK")" && cd "$(readlink "$CODEX_LINK")" && pwd)" = "$ROOT/factory" ] \
    && echo "PASS  Codex symlink target" \
    || { echo "FAIL  Codex symlink target"; FAILED=1; }
fi

if [ -L "$CLAUDE_LINK" ]; then
  [ "$(cd "$(dirname "$CLAUDE_LINK")" && cd "$(readlink "$CLAUDE_LINK")" && pwd)" = "$ROOT/factory" ] \
    && echo "PASS  Claude symlink target" \
    || { echo "FAIL  Claude symlink target"; FAILED=1; }
fi

COMMAND_LINK="$HOME/.local/bin/expo-factory"
if [ -x "$COMMAND_LINK" ]; then
  echo "PASS  expo-factory command: $COMMAND_LINK"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "INFO  $HOME/.local/bin is not on your PATH; run the command by its full path or add that folder to PATH." ;;
  esac
else
  echo "INFO  No expo-factory command at $COMMAND_LINK. Run scripts/install.sh to create it."
fi

DEFAULTS_FILE="$HOME/.config/expo-project-factory/defaults.md"
if [ -f "$DEFAULTS_FILE" ]; then
  echo "PASS  Personal defaults: $DEFAULTS_FILE"
else
  echo "INFO  No personal defaults at $DEFAULTS_FILE; the skill will use its built-in defaults. Run scripts/install.sh to create the file."
fi

echo
if command -v codex >/dev/null 2>&1; then
  echo "INFO  Codex CLI found. Confirm Expo plugin in /plugins."
else
  echo "INFO  Codex CLI not found; skip CLI check."
fi

if command -v claude >/dev/null 2>&1; then
  echo "INFO  Claude Code CLI found. Confirm Expo plugin with /plugin."
else
  echo "INFO  Claude Code CLI not found; skip CLI check."
fi

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi

echo "PASS  Factory skill filesystem verification complete."

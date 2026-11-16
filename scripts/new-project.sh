#!/usr/bin/env bash
set -euo pipefail

# Project intake for Expo AI Project Factory.
# Asks for a project name and a brief; everything else comes from your
# personal defaults file or is inferred by the factory skill.
#
# Usage: ./scripts/new-project.sh [optional-parent-directory]

PARENT="${1:-$HOME/Development}"
PARENT="${PARENT/#\~/$HOME}"
DEFAULTS_FILE="$HOME/.config/expo-project-factory/defaults.md"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

echo
echo "======================================"
echo "       Expo AI Project Factory"
echo "          New Project Setup"
echo "======================================"
echo

# Remove control characters (for example a stray ESC keypress); keeps tabs,
# newlines and all UTF-8 text.
clean() {
  LC_ALL=C tr -d '\000-\010\013-\037\177'
}

PROJECT_NAME=""
read -r -p "Project name: " PROJECT_NAME || true
PROJECT_NAME="$(printf '%s' "$PROJECT_NAME" | clean)"
if [ -z "$PROJECT_NAME" ]; then
  echo "Project name is required."
  exit 1
fi

SLUG="$(slugify "$PROJECT_NAME")"
if [ -z "$SLUG" ]; then
  echo "Could not create a folder name from the project name."
  echo "Use at least one letter or digit (a-z, 0-9)."
  exit 1
fi

echo
echo "Describe the project in your own words, then press ENTER to submit."
echo "(Pasting several lines at once is fine.)"
echo
BRIEF=""
read -r -p "> " BRIEF || true

# ENTER submits. When a multi-line description is pasted into a terminal, the
# remaining lines arrive immediately after the first, so collect whatever is
# already waiting instead of letting it spill into the confirmation prompt.
if [ -t 0 ]; then
  if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then PASTE_WAIT=0.2; else PASTE_WAIT=1; fi
  while IFS= read -r -t "$PASTE_WAIT" line; do
    BRIEF+=$'\n'"$line"
  done
fi

# Command substitution also trims trailing blank lines.
BRIEF="$(printf '%s' "$BRIEF" | clean)"
while [ "${BRIEF#$'\n'}" != "$BRIEF" ]; do
  BRIEF="${BRIEF#$'\n'}"
done

if [ -z "$BRIEF" ]; then
  echo "Project brief is required."
  exit 1
fi

DEST="$PARENT/$SLUG"

if [ -e "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
  echo
  echo "Refusing to write into a non-empty directory: $DEST"
  echo "Choose another project name or pass a different parent directory."
  exit 1
fi

echo
echo "--------------- Project Summary ---------------"
echo "Name:     $PROJECT_NAME"
echo "Folder:   $DEST"
if [ -f "$DEFAULTS_FILE" ]; then
  echo "Defaults: $DEFAULTS_FILE"
else
  echo "Defaults: none found (run ./scripts/install.sh to create them)"
fi
echo
echo "Brief:"
printf '%s\n' "$BRIEF"
echo "------------------------------------------------"
echo

CONFIRM=""
read -r -p "Create this project workspace? (y/N): " CONFIRM || true
case "$CONFIRM" in
  y|Y|yes|YES) ;;
  *) echo "Cancelled. No project files were created."; exit 0 ;;
esac

mkdir -p "$DEST"

cat > "$DEST/PROJECT_BRIEF.md" <<EOF
# Project Brief: $PROJECT_NAME

## Product description

$BRIEF

## Everything else

Platforms, backend, database, authentication, native features and constraints
are intentionally not listed here. Take them from the description above, then
from the personal defaults file at \`~/.config/expo-project-factory/defaults.md\`,
then from the factory skill's built-in defaults. List every assumption in the
plan so it can be corrected before implementation.
EOF

START_PROMPT='Use the `expo-project-factory` skill. Read `PROJECT_BRIEF.md` and prepare the plan. Do not create or modify files, install dependencies, or run destructive commands. Wait for my explicit approval before implementation.'

cat > "$DEST/FACTORY_START_HERE.md" <<EOF
# Start here

Open this folder in Claude Code or Codex, then send this message:

$START_PROMPT

After you have read the plan, reply:

Approved. Implement Phase 1 only.
EOF

echo
echo "Project workspace created successfully:"
echo "  $DEST"

# Offer to open the agent with the first message already sent. Only in a real
# terminal, so piped and scripted runs never launch anything.
if [ -t 0 ] && [ -t 1 ]; then
  HAS_CLAUDE=0
  HAS_CODEX=0
  command -v claude >/dev/null 2>&1 && HAS_CLAUDE=1
  command -v codex >/dev/null 2>&1 && HAS_CODEX=1
  AGENT=""
  ANSWER=""
  echo
  if [ "$HAS_CLAUDE" -eq 1 ] && [ "$HAS_CODEX" -eq 1 ]; then
    read -r -p "Open the project now? 1) Claude Code  2) Codex  ENTER) not now: " ANSWER || true
    case "$ANSWER" in
      1) AGENT="claude" ;;
      2) AGENT="codex" ;;
    esac
  elif [ "$HAS_CLAUDE" -eq 1 ]; then
    read -r -p "Open the project in Claude Code now? (Y/n): " ANSWER || ANSWER="n"
    case "$ANSWER" in ""|y|Y|yes|YES) AGENT="claude" ;; esac
  elif [ "$HAS_CODEX" -eq 1 ]; then
    read -r -p "Open the project in Codex now? (Y/n): " ANSWER || ANSWER="n"
    case "$ANSWER" in ""|y|Y|yes|YES) AGENT="codex" ;; esac
  fi

  if [ -n "$AGENT" ]; then
    echo "Opening $AGENT in $DEST and asking it for the plan..."
    cd "$DEST"
    exec "$AGENT" "$START_PROMPT"
  fi
fi

echo
echo "Next steps:"
echo "  1. Open the project in your agent:"
echo "       cd \"$DEST\" && claude      (or: codex)"
echo "  2. Send this message:"
echo
echo "       Follow FACTORY_START_HERE.md"
echo
echo "  3. Read the plan and its assumptions, then reply:"
echo
echo "       Approved. Implement Phase 1 only."

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

PROJECT_NAME=""
read -r -p "Project name: " PROJECT_NAME || true
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
echo "Describe the project in your own words."
echo "You can enter multiple lines. Press ENTER on an empty line when finished:"
echo
BRIEF=""
while IFS= read -r line; do
  [ -z "$line" ] && break
  if [ -n "$BRIEF" ]; then
    BRIEF+=$'\n'
  fi
  BRIEF+="$line"
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

cat > "$DEST/FACTORY_START_HERE.md" <<'EOF'
# Start here

Open this folder in Codex or Claude Code, then send:

Use the `expo-project-factory` skill. Read `PROJECT_BRIEF.md` and prepare the plan.
Do not create or modify files, install dependencies, or run destructive commands.
Wait for my explicit approval before implementation.
EOF

echo
echo "Project workspace created successfully:"
echo "  $DEST"
echo
echo "Next steps:"
echo "  1. Open this folder in Codex or Claude Code."
echo "  2. Send the prompt in FACTORY_START_HERE.md."
echo "  3. Review the plan and its assumptions, then approve Phase 1."

#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <project-directory> <project-name>"
  exit 2
fi

DEST="$1"
NAME="$2"

if [ -e "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
  echo "Refusing to use a non-empty directory: $DEST"
  exit 1
fi

mkdir -p "$DEST"
cp "$(dirname "$0")/../templates/project-brief.md" "$DEST/PROJECT_BRIEF.md"

cat > "$DEST/FACTORY_START_HERE.md" <<EOF
# $NAME

Open this folder in Codex or Claude Code.

Start with:

Use the expo-project-factory skill. Read PROJECT_BRIEF.md.
Inspect this repository. Do not modify files yet.
Prepare the skill selection, architecture, dependency and phased implementation plan.
Wait for my explicit approval.
EOF

echo "Created project workspace: $DEST"
echo "Fill in $DEST/PROJECT_BRIEF.md, then open this folder in your coding agent."

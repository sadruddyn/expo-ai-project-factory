#!/usr/bin/env bash
set -euo pipefail

# Interactive project intake for Expo AI Project Factory.
# Usage: ./scripts/new-project.sh [optional-parent-directory]

PARENT="${1:-$HOME/Development}"
mkdir -p "$PARENT"

ask() {
  local prompt="$1"
  local default="${2:-}"
  local answer
  if [ -n "$default" ]; then
    read -r -p "$prompt [$default]: " answer
    printf '%s' "${answer:-$default}"
  else
    read -r -p "$prompt: " answer
    printf '%s' "$answer"
  fi
}

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

PROJECT_NAME="$(ask "Project name")"
if [ -z "$PROJECT_NAME" ]; then
  echo "Project name is required."
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

echo
PLATFORMS="$(ask "Target platforms (iOS / Android / Web)" "iOS + Android")"
PROJECT_KIND="$(ask "Project type (brand-new / existing app / migration)" "brand-new")"
BACKEND="$(ask "Backend (Node.js / NestJS / Firebase / Supabase / none / other)" "Not decided")"
DATABASE="$(ask "Database (PostgreSQL / MySQL / MongoDB / Firebase / none / other)" "Not decided")"
AUTH="$(ask "Authentication (email / phone OTP / social / none / not decided)" "Not decided")"
NATIVE_FEATURES="$(ask "Native features (location, Siri, camera, notifications, etc.)" "None specified")"
DESIGN="$(ask "Design references (Figma URL, app examples, or none)" "None provided")"
CONSTRAINTS="$(ask "Constraints (budget, paid SDKs, deadlines, offline support)" "Avoid unnecessary paid SDKs and dependencies")"

SLUG="$(slugify "$PROJECT_NAME")"
if [ -z "$SLUG" ]; then
  echo "Could not create a folder name from project name."
  exit 1
fi

DEFAULT_DEST="$PARENT/$SLUG"
DEST="$(ask "Project folder" "$DEFAULT_DEST")"
DEST="${DEST/#\~/$HOME}"

echo
echo "--------------- Project Summary ---------------"
echo "Name:              $PROJECT_NAME"
echo "Folder:            $DEST"
echo "Platforms:         $PLATFORMS"
echo "Project type:      $PROJECT_KIND"
echo "Backend:           $BACKEND"
echo "Database:          $DATABASE"
echo "Authentication:    $AUTH"
echo "Native features:   $NATIVE_FEATURES"
echo "Design references: $DESIGN"
echo "Constraints:       $CONSTRAINTS"
echo
echo "Brief:"
printf '%s\n' "$BRIEF"
echo "------------------------------------------------"
echo

read -r -p "Create this project workspace? (y/N): " CONFIRM
case "$CONFIRM" in
  y|Y|yes|YES) ;;
  *) echo "Cancelled. No project files were created."; exit 0 ;;
esac

if [ -e "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
  echo "Refusing to write into a non-empty directory: $DEST"
  echo "Choose another folder or an empty directory."
  exit 1
fi

mkdir -p "$DEST"

cat > "$DEST/PROJECT_BRIEF.md" <<EOF
# Project Brief: $PROJECT_NAME

- **Project name:** $PROJECT_NAME
- **Project type:** $PROJECT_KIND
- **Target platforms:** $PLATFORMS
- **Backend:** $BACKEND
- **Database:** $DATABASE
- **Authentication:** $AUTH
- **Native features:** $NATIVE_FEATURES
- **Design references:** $DESIGN
- **Constraints:** $CONSTRAINTS

## Product description

$BRIEF
EOF

cat > "$DEST/FACTORY_START_HERE.md" <<'EOF'
# Start here

Open this folder in Codex or Claude Code.

Then send:

Use the `expo-project-factory` skill. Read `PROJECT_BRIEF.md`.
Inspect this repository and the available Expo skills.
Do not create or modify files, install dependencies, or run destructive commands.
Prepare:
1. Project classification and understanding
2. Relevant skills selected, with reasons; identify missing skills
3. Existing repository findings (if any)
4. Architecture and proposed folder structure
5. Navigation and screen/module breakdown
6. State management, API and storage strategy
7. Dependencies with compatibility checks and reasons
8. Native configuration, permissions and rebuild implications
9. Security, accessibility and performance considerations
10. Phased implementation plan and verification commands

Wait for my explicit approval before implementation.
EOF

echo
echo "Project workspace created successfully:"
echo "  $DEST"
echo
echo "Next steps:"
echo "  1. Open this folder in Codex or Claude Code."
echo "  2. Ask it to use the expo-project-factory skill and read PROJECT_BRIEF.md."
echo "  3. Review the plan and explicitly approve before implementation."

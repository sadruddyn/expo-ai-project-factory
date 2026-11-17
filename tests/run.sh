#!/usr/bin/env bash
# Tests for install.sh, verify.sh and new-project.sh with piped input.
# Everything runs in throwaway HOME directories; the real HOME is never touched.
#
# Usage: tests/run.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$ROOT"

PASSED=0
FAILED=0

ok() {
  PASSED=$((PASSED + 1))
  echo "PASS  $1"
}

fail() {
  FAILED=$((FAILED + 1))
  echo "FAIL  $1"
}

# expect_exit <label> <expected-exit-code> <actual-exit-code>
expect_exit() {
  if [ "$2" -eq "$3" ]; then ok "$1"; else fail "$1 (expected exit $2, got $3)"; fi
}

# expect_line <label> <file> <exact line>
expect_line() {
  if grep -qxF -- "$3" "$2" 2>/dev/null; then ok "$1"; else fail "$1 (line not found: $3)"; fi
}

new_home() {
  local dir="$WORK/$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s' "$dir"
}

echo "== syntax"
for script in scripts/*.sh tests/*.sh; do
  bash -n "$script"
  expect_exit "bash -n $script" 0 $?
done

echo "== install and verify"
H="$(new_home fresh)"
HOME="$H" ./scripts/verify.sh >/dev/null 2>&1
expect_exit "verify fails before install" 1 $?

printf '\n' | HOME="$H" ./scripts/install.sh >/dev/null 2>&1
expect_exit "install succeeds" 0 $?
D="$H/.config/expo-project-factory/defaults.md"
expect_line "ENTER leaves backend undecided" "$D" "- Backend / API: not decided"

HOME="$H" ./scripts/verify.sh >/dev/null 2>&1
expect_exit "verify passes after install" 0 $?

for link in "$H/.claude/skills/expo-project-factory" "$H/.agents/skills/expo-project-factory"; do
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$ROOT/factory" ]; then
    ok "skill link points at factory/: ${link#"$H"/}"
  else
    fail "skill link points at factory/: ${link#"$H"/}"
  fi
done

echo "- my own note" >> "$D"
printf '1\n' | HOME="$H" ./scripts/install.sh >/dev/null 2>&1
expect_exit "reinstall succeeds" 0 $?
expect_line "reinstall keeps the user's edits" "$D" "- my own note"
expect_line "reinstall does not apply a new backend answer" "$D" "- Backend / API: not decided"

echo "== installer backend choices"
check_choice() {
  local label="$1" input="$2" backend="$3" database="$4" auth="$5" home file
  home="$(new_home "choice_$label")"
  file="$home/.config/expo-project-factory/defaults.md"
  if [ "$input" = "NONE" ]; then
    HOME="$home" ./scripts/install.sh </dev/null >/dev/null 2>&1
  else
    printf '%s\n' "$input" | HOME="$home" ./scripts/install.sh >/dev/null 2>&1
  fi
  expect_exit "choice $label: install exits 0" 0 $?
  expect_line "choice $label: backend" "$file" "- Backend / API: $backend"
  expect_line "choice $label: database" "$file" "- Database: $database"
  expect_line "choice $label: authentication" "$file" "- Authentication: $auth"
  if diff \
    <(grep -vE '^- (Backend / API|Database|Authentication):' templates/defaults.md) \
    <(grep -vE '^- (Backend / API|Database|Authentication):' "$file") >/dev/null; then
    ok "choice $label: other lines match the template"
  else
    fail "choice $label: other lines match the template"
  fi
}
check_choice 1 1 "NestJS REST API" "PostgreSQL" "JWT issued by the API"
check_choice 2 2 "Supabase" "Supabase Postgres" "Supabase Auth"
check_choice 3 3 "Firebase" "Cloud Firestore" "Firebase Authentication"
check_choice 4 4 "none (data stays on the device)" "on-device SQLite (expo-sqlite)" "none"
check_choice 5 5 "not decided" "not decided" "not decided"
check_choice unrecognised abc "not decided" "not decided" "not decided"
check_choice no-input NONE "not decided" "not decided" "not decided"

echo "== installer refuses to overwrite"
H="$(new_home conflict)"
mkdir -p "$H/.claude/skills/expo-project-factory"
printf '1\n' | HOME="$H" ./scripts/install.sh >/dev/null 2>&1
expect_exit "conflict exits 1" 1 $?
if [ ! -e "$H/.agents/skills/expo-project-factory" ] && [ ! -e "$H/.config" ]; then
  ok "conflict leaves nothing behind"
else
  fail "conflict leaves nothing behind"
fi

echo "== new-project with piped input"
H="$(new_home project)"
OUT="$WORK/project.out"
printf 'Grocery Shop!\nLists with $HOME and `backticks`.\ny\n' | HOME="$H" ./scripts/new-project.sh >"$OUT" 2>&1
expect_exit "creates a workspace" 0 $?
P="$H/Development/grocery-shop"
expect_line "brief is written literally" "$P/PROJECT_BRIEF.md" 'Lists with $HOME and `backticks`.'
expect_line "title uses the project name" "$P/PROJECT_BRIEF.md" "# Project Brief: Grocery Shop!"
if grep -q 'expo-project-factory' "$P/FACTORY_START_HERE.md" 2>/dev/null; then
  ok "start file names the skill"
else
  fail "start file names the skill"
fi
if grep -qE 'Open the project.* now\?' "$OUT"; then
  fail "piped run does not offer to open an agent"
else
  ok "piped run does not offer to open an agent"
fi
if grep -q 'Follow FACTORY_START_HERE.md' "$OUT"; then
  ok "piped run prints the next steps"
else
  fail "piped run prints the next steps"
fi

printf 'Grocery Shop\nAgain.\ny\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "refuses a non-empty folder" 1 $?

printf 'Cancel App\nBrief.\nn\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "answering n exits 0" 0 $?
[ ! -e "$H/Development/cancel-app" ] && ok "answering n creates nothing" || fail "answering n creates nothing"

printf 'Eof App\nBrief.\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "missing confirmation exits 0" 0 $?
[ ! -e "$H/Development/eof-app" ] && ok "missing confirmation creates nothing" || fail "missing confirmation creates nothing"

printf '\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "empty name exits 1" 1 $?

printf 'App\n\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "empty brief exits 1" 1 $?

printf '!!!\n' | HOME="$H" ./scripts/new-project.sh >/dev/null 2>&1
expect_exit "name without letters or digits exits 1" 1 $?

printf 'Other App\nBrief.\nyes\n' | HOME="$H" ./scripts/new-project.sh "$H/Clients" >/dev/null 2>&1
expect_exit "custom parent directory" 0 $?
[ -f "$H/Clients/other-app/PROJECT_BRIEF.md" ] && ok "custom parent holds the workspace" || fail "custom parent holds the workspace"

echo
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

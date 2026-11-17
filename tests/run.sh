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
for script in scripts/*.sh tests/*.sh bin/expo-factory bootstrap.sh; do
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

echo "== expo-factory command"
H="$(new_home command)"
printf '\n' | HOME="$H" ./scripts/install.sh >/dev/null 2>&1
CMD="$H/.local/bin/expo-factory"
if [ -L "$CMD" ] && [ "$(readlink "$CMD")" = "$ROOT/bin/expo-factory" ]; then
  ok "install links the expo-factory command"
else
  fail "install links the expo-factory command"
fi

(cd "$WORK" && HOME="$H" "$CMD" help >/dev/null 2>&1)
expect_exit "help exits 0 when run through the link from another folder" 0 $?

(cd "$WORK" && HOME="$H" "$CMD" verify >/dev/null 2>&1)
expect_exit "verify through the command exits 0" 0 $?

HOME="$H" "$CMD" nonsense >/dev/null 2>&1
expect_exit "unknown command exits 2" 2 $?

printf 'First App\nBrief.\ny\n' | (cd "$WORK" && HOME="$H" "$CMD" new >/dev/null 2>&1)
expect_exit "new without a saved folder (piped) exits 0" 0 $?
[ -f "$H/Development/first-app/PROJECT_BRIEF.md" ] && ok "piped new uses ~/Development" || fail "piped new uses ~/Development"
[ ! -e "$H/.config/expo-project-factory/projects-dir" ] && ok "piped new does not save a folder" || fail "piped new does not save a folder"

HOME="$H" "$CMD" projects-dir "$H/Work Apps" >/dev/null 2>&1
expect_exit "projects-dir saves a folder" 0 $?
if [ "$(HOME="$H" "$CMD" projects-dir)" = "$H/Work Apps" ]; then
  ok "projects-dir shows the saved folder"
else
  fail "projects-dir shows the saved folder"
fi
printf 'Second App\nBrief.\ny\n' | HOME="$H" "$CMD" new >/dev/null 2>&1
[ -f "$H/Work Apps/second-app/PROJECT_BRIEF.md" ] && ok "new uses the saved folder (with a space in it)" || fail "new uses the saved folder (with a space in it)"

printf 'Third App\nBrief.\ny\n' | HOME="$H" "$CMD" new "$H/Elsewhere" >/dev/null 2>&1
[ -f "$H/Elsewhere/third-app/PROJECT_BRIEF.md" ] && ok "new <folder> overrides the saved folder" || fail "new <folder> overrides the saved folder"

HOME="$H" "$CMD" projects-dir '~/Apps' >/dev/null 2>&1
if [ "$(HOME="$H" "$CMD" projects-dir)" = "$H/Apps" ]; then
  ok "projects-dir expands a leading ~"
else
  fail "projects-dir expands a leading ~"
fi

H="$(new_home command_conflict)"
mkdir -p "$H/.local/bin"
echo "something else" > "$H/.local/bin/expo-factory"
printf '\n' | HOME="$H" ./scripts/install.sh >/dev/null 2>&1
expect_exit "existing expo-factory file: install exits 1" 1 $?
if [ ! -e "$H/.claude" ] && [ ! -e "$H/.agents" ] && [ "$(cat "$H/.local/bin/expo-factory")" = "something else" ]; then
  ok "existing expo-factory file is left alone and nothing is installed"
else
  fail "existing expo-factory file is left alone and nothing is installed"
fi

echo "== bootstrap (one-line installer)"
# A committed copy of the working tree stands in for the GitHub repository.
SRC="$WORK/source-repo"
mkdir -p "$SRC"
(cd "$ROOT" && tar --exclude=.git -cf - .) | (cd "$SRC" && tar -xf -)
git -C "$SRC" init --quiet
git -C "$SRC" add -A
git -C "$SRC" -c user.name=test -c user.email=test@example.invalid commit --quiet -m "snapshot"

H="$(new_home bootstrap)"
HOME="$H" EXPO_FACTORY_REPO="$SRC" bash "$ROOT/bootstrap.sh" </dev/null >"$WORK/bootstrap.out" 2>&1
expect_exit "bootstrap installs" 0 $?
B="$H/.expo-project-factory"
[ -f "$B/factory/SKILL.md" ] && ok "bootstrap downloads the factory" || fail "bootstrap downloads the factory"
if [ "$(readlink "$H/.claude/skills/expo-project-factory" 2>/dev/null)" = "$B/factory" ]; then
  ok "bootstrap links the skill to the downloaded copy"
else
  fail "bootstrap links the skill to the downloaded copy"
fi
if [ "$(readlink "$H/.local/bin/expo-factory" 2>/dev/null)" = "$B/bin/expo-factory" ]; then
  ok "bootstrap links the command to the downloaded copy"
else
  fail "bootstrap links the command to the downloaded copy"
fi
HOME="$H" "$H/.local/bin/expo-factory" verify >/dev/null 2>&1
expect_exit "verify passes after bootstrap" 0 $?

echo "- kept" >> "$H/.config/expo-project-factory/defaults.md"
HOME="$H" EXPO_FACTORY_REPO="$SRC" bash "$ROOT/bootstrap.sh" </dev/null >/dev/null 2>&1
expect_exit "bootstrap again (update) exits 0" 0 $?
expect_line "bootstrap again keeps the defaults file" "$H/.config/expo-project-factory/defaults.md" "- kept"

echo "change" > "$SRC/NEWFILE"
git -C "$SRC" add -A
git -C "$SRC" -c user.name=test -c user.email=test@example.invalid commit --quiet -m "update"
HOME="$H" "$H/.local/bin/expo-factory" update >/dev/null 2>&1
expect_exit "expo-factory update exits 0" 0 $?
[ -f "$B/NEWFILE" ] && ok "update pulls the new version" || fail "update pulls the new version"

cat "$ROOT/bootstrap.sh" | HOME="$(new_home bootstrap_piped)" EXPO_FACTORY_REPO="$SRC" bash >/dev/null 2>&1
expect_exit "bootstrap piped into bash exits 0" 0 $?

H="$(new_home bootstrap_occupied)"
mkdir -p "$H/.expo-project-factory"
echo "mine" > "$H/.expo-project-factory/notes.txt"
HOME="$H" EXPO_FACTORY_REPO="$SRC" bash "$ROOT/bootstrap.sh" </dev/null >/dev/null 2>&1
expect_exit "bootstrap refuses a folder with other files" 1 $?
if [ "$(cat "$H/.expo-project-factory/notes.txt")" = "mine" ] && [ ! -e "$H/.claude" ]; then
  ok "refused bootstrap changes nothing"
else
  fail "refused bootstrap changes nothing"
fi

echo
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]

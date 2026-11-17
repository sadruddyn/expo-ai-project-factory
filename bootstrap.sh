#!/usr/bin/env bash
# One-line installer for Expo AI Project Factory:
#
#   curl -fsSL https://raw.githubusercontent.com/sadruddyn/expo-ai-project-factory/main/bootstrap.sh | bash
#
# It clones (or updates) the factory in ~/.expo-project-factory and runs its
# installer. Nothing else on the machine is touched; see scripts/install.sh for
# the three paths that script creates.
set -euo pipefail

# Everything is inside main, called on the last line, so a download that is cut
# off part-way runs nothing.
main() {
  local repo="${EXPO_FACTORY_REPO:-https://github.com/sadruddyn/expo-ai-project-factory.git}"
  local dir="${EXPO_FACTORY_HOME:-$HOME/.expo-project-factory}"

  if ! command -v git >/dev/null 2>&1; then
    echo "Git is required. Install Git, then run this again."
    exit 1
  fi

  if [ -d "$dir/.git" ]; then
    echo "Updating the factory in $dir"
    git -C "$dir" pull --ff-only --quiet
  elif [ -e "$dir" ] && [ -n "$(find "$dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    echo "Refusing to install into a folder that already has other files: $dir"
    echo "Move it away, or choose another folder with EXPO_FACTORY_HOME=/some/path."
    exit 1
  else
    echo "Downloading the factory to $dir"
    git clone --quiet "$repo" "$dir"
  fi

  # When this script is piped into bash, standard input is the script itself,
  # so the installer's question has to read from the terminal directly.
  if [ -t 0 ]; then
    "$dir/scripts/install.sh"
  elif (: </dev/tty) 2>/dev/null; then
    "$dir/scripts/install.sh" </dev/tty
  else
    "$dir/scripts/install.sh" </dev/null
  fi
}

main "$@"

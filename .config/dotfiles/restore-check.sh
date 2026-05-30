#!/usr/bin/env bash
set -euo pipefail

real_home="${REAL_HOME:-$HOME}"
source_git_dir="${DOTFILES_SOURCE_GIT_DIR:-$real_home/.dotfiles}"
bootstrap="$real_home/.config/dotfiles/bootstrap.sh"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if [[ ! -d "$source_git_dir" || ! -f "$source_git_dir/HEAD" ]]; then
  printf 'source dotfiles git dir was not found: %s\n' "$source_git_dir" >&2
  exit 1
fi

if [[ ! -x "$bootstrap" ]]; then
  printf 'bootstrap script was not found or executable: %s\n' "$bootstrap" >&2
  exit 1
fi

mkdir -p "$tmp_dir/home"

HOME="$tmp_dir/home" \
DOTFILES_REPO_URL="$source_git_dir" \
bash "$bootstrap"

test -f "$tmp_dir/home/.zshrc"
test -f "$tmp_dir/home/.config/dotfiles/ignore"
test -f "$tmp_dir/home/.config/dotfiles/packages/native.txt"
test -f "$tmp_dir/home/.config/zsh/aliases.zsh"

git --git-dir="$tmp_dir/home/.dotfiles" --work-tree="$tmp_dir/home" status --short --branch

printf 'Restore check passed in %s\n' "$tmp_dir/home"

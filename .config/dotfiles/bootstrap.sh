#!/usr/bin/env bash
set -euo pipefail

repo_url="${DOTFILES_REPO_URL:-git@github.com:dylanm5017/cachy-dotfiles.git}"
git_dir="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
work_tree="${DOTFILES_WORK_TREE:-$HOME}"
ignore_file="$HOME/.config/dotfiles/ignore"
state_dir="$HOME/.local/state/dotfiles"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

dot() {
  git --git-dir="$git_dir" --work-tree="$work_tree" "$@"
}

checkout_with_backup() {
  local output backup_dir conflict

  if output="$(dot checkout 2>&1)"; then
    return 0
  fi

  backup_dir="$state_dir/checkout-conflicts-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"

  printf '%s\n' "$output" \
    | awk '/^[[:space:]]+[.[:alnum:]_\/-]+/ {print $1}' \
    | while IFS= read -r conflict; do
        [[ -z "$conflict" || ! -e "$work_tree/$conflict" ]] && continue
        mkdir -p "$backup_dir/$(dirname "$conflict")"
        mv -- "$work_tree/$conflict" "$backup_dir/$conflict"
      done

  printf 'Backed up checkout conflicts to %s\n' "$backup_dir" >&2
  dot checkout
}

require git

if [[ ! -d "$git_dir" || ! -f "$git_dir/HEAD" ]]; then
  git clone --bare "$repo_url" "$git_dir"
fi

dot config --local status.showUntrackedFiles all
dot config --local core.excludesfile "$ignore_file"

checkout_with_backup

printf 'Dotfiles ready. Try: dot status --short\n'

#!/usr/bin/env bash
set -euo pipefail

git_dir="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
work_tree="${DOTFILES_WORK_TREE:-$HOME}"
package_dir="$HOME/.config/dotfiles/packages"
native_manifest="$package_dir/native.txt"
foreign_manifest="$package_dir/foreign.txt"

usage() {
  cat <<'EOF'
Usage:
  audit.sh
  audit.sh --candidates

Default mode reports tracked dotfiles status, ignore checks, and package drift.
Candidate mode lists untracked config file paths that may be worth reviewing,
without reading their contents.
EOF
}

dot() {
  git --git-dir="$git_dir" --work-tree="$work_tree" "$@"
}

section() {
  printf '\n%s\n' "$1"
  printf '%*s\n' "${#1}" '' | tr ' ' '-'
}

count_lines() {
  wc -l 2>/dev/null | tr -d ' '
}

comm_section() {
  local title left right

  title="$1"
  left="$2"
  right="$3"

  section "$title"
  if [[ -f "$left" && -f "$right" ]]; then
    comm -23 "$left" "$right" | sed -n '1,80p'
  else
    printf 'missing manifest or package query result\n'
  fi
}

is_tracked() {
  local rel_path

  rel_path="$1"
  dot ls-files --error-unmatch "$rel_path" >/dev/null 2>&1
}

candidate_config_files() {
  local path rel_path

  find "$HOME/.config" -maxdepth 2 -type f \
    -not -path "$HOME/.config/gh/*" \
    -not -path "$HOME/.config/kdeconnect/*" \
    -not -path "$HOME/.config/Bitwarden/*" \
    -not -path "$HOME/.config/Code/*" \
    -not -path "$HOME/.config/Code - OSS/*" \
    -not -path "$HOME/.config/chromium/*" \
    -not -path "$HOME/.config/discord/*" \
    -not -path "$HOME/.config/Epic/*" \
    -not -path "$HOME/.config/Slack/*" \
    -not -path "$HOME/.config/StardewValley/*" \
    -not -path "$HOME/.config/teams-for-linux/*" \
    -not -path "$HOME/.config/Necesse/*" \
    -not -path "$HOME/.config/spotify/*" \
    -not -path "$HOME/.config/libaccounts-glib/*" \
    -not -path "$HOME/.config/session/*" \
    -not -path "$HOME/.config/akonadi/*" \
    -not -path "$HOME/.config/dconf/*" \
    -not -path "$HOME/.config/pulse/*" \
    -not -iname '*secret*' \
    -not -iname '*token*' \
    -not -iname '*credential*' \
    -not -iname '*auth*' \
    -not -iname '*.key' \
    -not -iname '*.pem' \
    -not -iname '*.crt' \
    -not -iname '*.cert' \
    -not -iname '*.db' \
    -not -iname '*.db-wal' \
    -not -iname '*.db-shm' \
    -not -iname '*.log' \
    -not -iname '*log.txt' \
    -print 2>/dev/null \
    | sort \
    | while IFS= read -r path; do
        rel_path="${path#$HOME/}"
        is_tracked "$rel_path" && continue
        printf '%s\n' "$rel_path"
      done
}

case "${1:-}" in
  --candidates)
    section 'Untracked config candidates'
    candidate_config_files | sed -n '1,200p'
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  '')
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

section 'Dotfiles status'
dot status --short --branch

section 'Tracked files'
printf 'Tracked count: %s\n' "$(dot ls-files | count_lines)"
dot ls-files | sed -n '1,120p'

section 'Ignored noise checks'
dot check-ignore -v \
  "$HOME/.dotfiles" \
  "$HOME/.cache" \
  "$HOME/.config/Code" \
  "$HOME/.config/Slack" \
  "$HOME/.ssh" \
  2>/dev/null || true

section 'Package manifests'
printf 'Native manifest:  %s\n' "$native_manifest"
printf 'Foreign manifest: %s\n' "$foreign_manifest"

if command -v pacman >/dev/null 2>&1; then
  native_now="$(mktemp)"
  foreign_now="$(mktemp)"
  native_manifest_sorted="$(mktemp)"
  foreign_manifest_sorted="$(mktemp)"
  trap 'rm -f "$native_now" "$foreign_now" "$native_manifest_sorted" "$foreign_manifest_sorted"' EXIT

  pacman -Qqen | sort > "$native_now"
  pacman -Qqem | sort > "$foreign_now"

  printf 'Native installed:  %s\n' "$(count_lines < "$native_now")"
  printf 'Foreign installed: %s\n' "$(count_lines < "$foreign_now")"

  [[ -f "$native_manifest" ]] && sort "$native_manifest" > "$native_manifest_sorted"
  [[ -f "$foreign_manifest" ]] && sort "$foreign_manifest" > "$foreign_manifest_sorted"

  comm_section 'Native installed but missing from manifest' "$native_now" "$native_manifest_sorted"
  comm_section 'Native manifest but not installed' "$native_manifest_sorted" "$native_now"
  comm_section 'Foreign installed but missing from manifest' "$foreign_now" "$foreign_manifest_sorted"
  comm_section 'Foreign manifest but not installed' "$foreign_manifest_sorted" "$foreign_now"
else
  printf 'pacman was not found\n'
fi

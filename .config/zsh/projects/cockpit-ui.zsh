_cockpit_truncate() {
  _fzf_truncate "$@"
}

_cockpit_pad() {
  _fzf_pad "$@"
}

_cockpit_ansi() {
  _fzf_ansi "$@"
}

_cockpit_state_label() {
  local kind state branch state_label

  kind="$1"
  state="$2"

  case "$kind:$state" in
    remote:unmounted)
      print -r -- 'offline'
      ;;
    remote:mounted*)
      print -r -- 'mounted'
      ;;
    local:git:*|remote:*git:*)
      branch="${state#*git:}"
      state_label="${branch##* }"
      case "$state_label" in
        clean|dirty) print -r -- "$state_label" ;;
        *) print -r -- 'git' ;;
      esac
      ;;
    *)
      print -r -- 'folder'
      ;;
  esac
}

_cockpit_branch_label() {
  local state branch state_label

  state="$1"

  if [[ "$state" != *git:* ]]; then
    print -r -- '-'
    return
  fi

  branch="${state#*git:}"
  state_label="${branch##* }"

  case "$state_label" in
    clean|dirty)
      branch="${branch% $state_label}"
      ;;
  esac

  print -r -- "$branch"
}

_cockpit_kind_label() {
  case "$1" in
    remote) print -r -- 'REM' ;;
    *) print -r -- 'LOC' ;;
  esac
}

_cockpit_state_color() {
  case "$1" in
    dirty) print -r -- '33' ;;
    clean) print -r -- '32' ;;
    mounted) print -r -- '36' ;;
    offline) print -r -- '2;31' ;;
    *) print -r -- '2' ;;
  esac
}

_cockpit_display_row() {
  local kind name state context project_path description
  local kind_label state_label branch_label context_label meta_label display
  local kind_field name_field state_field branch_field context_field meta_field

  kind="$1"
  name="$2"
  state="$3"
  context="$4"
  project_path="$5"
  description="$6"

  kind_label="$(_cockpit_kind_label "$kind")"
  state_label="$(_cockpit_state_label "$kind" "$state")"
  branch_label="$(_cockpit_branch_label "$state")"
  context_label="$context"
  meta_label="$description"

  if [[ "$kind" == 'remote' ]]; then
    context_label="${context%%:*}"
    [[ -z "$meta_label" || "$meta_label" == '-' ]] && meta_label="${project_path/#$HOME/~}"
  else
    meta_label="${meta_label//, / }"
  fi

  kind_field="$(_cockpit_ansi "$([[ "$kind" == 'remote' ]] && print -r -- '35' || print -r -- '36')" "$(_cockpit_pad "$kind_label" 3)")"
  name_field="$(_cockpit_ansi '1' "$(_cockpit_pad "$name" 28)")"
  state_field="$(_cockpit_ansi "$(_cockpit_state_color "$state_label")" "$(_cockpit_pad "$state_label" 8)")"
  branch_field="$(_cockpit_ansi '2' "$(_cockpit_pad "$branch_label" 26)")"
  context_field="$(_cockpit_ansi '2' "$(_cockpit_pad "$context_label" 16)")"
  meta_field="$(_cockpit_ansi '2' "$(_cockpit_truncate "$meta_label" 32)")"

  display="$kind_field  $name_field  $state_field  $branch_field  $context_field  $meta_field"

  print -r -- "$display"$'\t'"$kind"$'\t'"$name"$'\t'"$state"$'\t'"$context"$'\t'"$project_path"$'\t'"$description"
}

_cockpit_display_rows() {
  local kind_filter kind name state context project_path description

  kind_filter="$1"

  while IFS=$'\t' read -r kind name state context project_path description; do
    _cockpit_display_row "$kind" "$name" "$state" "$context" "$project_path" "$description"
  done < <(_cockpit_candidates "$kind_filter")
}

_cockpit_preview_command() {
  cat <<'EOF'
kind={2}
name={3}
state={4}
context={5}
dir={6}
description={7}
short_dir="$dir"

case "$short_dir" in
  "$HOME"/*) short_dir="~/${short_dir#$HOME/}" ;;
esac

printf "%s\n" "$name"
printf "  %s  %s\n" "$kind" "$state"

case "$kind" in
  remote)
    printf "\nRemote\n  %s\n" "$context"
    printf "  mount: %s\n" "$short_dir"
    printf "  note:  %s\n" "$description"
    ;;
  *)
    printf "\nLocation\n  %s\n" "$short_dir"
    printf "  group: %s\n" "$context"
    printf "  tags:  %s\n" "$description"
    ;;
esac

if [ ! -d "$dir" ]; then
  printf "\nUnavailable\n  path does not exist or the remote project is not mounted\n"
  exit 0
fi

if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
  [ -z "$branch" ] && branch="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
  changed_total="$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

  printf "\nGit\n"
  printf "  branch:  %s\n" "$branch"
  printf "  changes: %s\n" "$changed_total"

  if [ "$changed_total" != "0" ]; then
    printf "\nChanges\n"
    git -C "$dir" status --short 2>/dev/null | sed -n '1,14p'
    if [ "$changed_total" -gt 14 ] 2>/dev/null; then
      printf "  ... %s more\n" "$((changed_total - 14))"
    fi
  fi

  printf "\nRecent\n"
  git -C "$dir" log -4 --oneline --decorate --color=always 2>/dev/null
fi

if [ -f "$dir/package.json" ] && command -v jq >/dev/null 2>&1; then
  scripts="$(jq -r '.scripts // {} | to_entries[] | "  " + .key + ": " + .value' "$dir/package.json" 2>/dev/null)"
  if [ -n "$scripts" ]; then
    printf "\nScripts\n"
    printf "%s\n" "$scripts" | sed -n '1,8p'
  fi
fi

readme=
for candidate in README.md README.markdown README.txt README; do
  if [ -f "$dir/$candidate" ]; then
    readme="$dir/$candidate"
    break
  fi
done

if [ -n "$readme" ]; then
  printf "\nREADME\n"
  if command -v bat >/dev/null 2>&1; then
    bat --color=always --style=plain --line-range=:36 "$readme" 2>/dev/null
  else
    sed -n '1,36p' "$readme" 2>/dev/null
  fi
fi

printf "\nFiles\n"
if command -v eza >/dev/null 2>&1; then
  eza -la --icons --git "$dir" 2>/dev/null | sed -n '1,36p'
else
  ls -la "$dir" 2>/dev/null | sed -n '1,36p'
fi
EOF
}

_cockpit_action_for_key() {
  case "$1" in
    ctrl-e) print -r -- 'code' ;;
    ctrl-n) print -r -- 'nvim' ;;
    ctrl-t) print -r -- 'terminal' ;;
    ctrl-o) print -r -- 'open' ;;
    ctrl-s) print -r -- 'status' ;;
    ctrl-r) print -r -- 'run-script' ;;
    ctrl-d) print -r -- 'dev' ;;
    ctrl-g) print -r -- 'github' ;;
    ctrl-y) print -r -- 'notes' ;;
    ctrl-f) print -r -- 'yazi' ;;
    ctrl-x) print -r -- 'mount' ;;
    ctrl-u) print -r -- 'unmount' ;;
    *) print -r -- 'cd' ;;
  esac
}

_cockpit_select() {
  local query kind_filter rows output key row action preview

  query="${1:-}"
  kind_filter="$2"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_cockpit_display_rows "$kind_filter")"
  if [[ -z "$rows" ]]; then
    print -u2 'no projects found under ~/Projects, ~/work, or projects/remote-projects.tsv'
    return 1
  fi

  preview="$(_cockpit_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='cockpit> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-t,ctrl-o,ctrl-s,ctrl-r,ctrl-d,ctrl-g,ctrl-y,ctrl-f,ctrl-x,ctrl-u \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH / REMOTE             GROUP             TAGS\nenter cd | ^e code | ^n nvim | ^t term | ^o files | ^f yazi | ^r script | ^d dev | ^g github | ^y notes | ^x mount | ^u unmount | ^s status' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  row="${row#*$'\t'}"
  action="$(_cockpit_action_for_key "$key")"
  print -r -- "$action"$'\t'"$row"
}

_cockpit_matches() {
  local query kind_filter row kind name row_l
  local -a exact partial

  query="${(L)1}"
  kind_filter="$2"

  while IFS=$'\t' read -r row; do
    kind="${row%%$'\t'*}"
    [[ -n "$kind_filter" && "$kind" != "$kind_filter" ]] && continue

    name="${row#*$'\t'}"
    name="${name%%$'\t'*}"
    row_l="${(L)row}"

    if [[ "${(L)name}" == "$query" ]]; then
      exact+=("$row")
    elif [[ "$row_l" == *"$query"* ]]; then
      partial+=("$row")
    fi
  done < <(_cockpit_candidates "$kind_filter")

  if (( ${#exact[@]} )); then
    printf '%s\n' "${exact[@]}"
  else
    printf '%s\n' "${partial[@]}"
  fi
}

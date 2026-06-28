_rproj_action_for_key() {
  case "$1" in
    ctrl-e) print -r -- 'cd' ;;
    ctrl-n) print -r -- 'nvim' ;;
    ctrl-s) print -r -- 'status' ;;
    ctrl-u) print -r -- 'unmount' ;;
    *) print -r -- 'code' ;;
  esac
}

_rproj_select() {
  local query rows output key row action kind name state remote local_path description preview

  query="${1:-}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_cockpit_display_rows remote)" || return

  if [[ -z "$rows" ]]; then
    print -u2 'no remote projects found'
    return 1
  fi

  preview="$(_cockpit_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='remote project> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-s,ctrl-u \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH / REMOTE          HOST              NOTE\nenter code | ^e cd | ^n nvim | ^s status | ^u unmount' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  row="${row#*$'\t'}"
  IFS=$'\t' read -r kind name state remote local_path description <<< "$row"

  action="$(_rproj_action_for_key "$key")"

  print -r -- "$action"$'\t'"$name"
}
_rproj_mounted_display_rows() {
  local name host remote_path local_path description remote

  while IFS=$'\t' read -r name host remote_path local_path description; do
    remote="$(_rproj_remote "$host" "$remote_path")"
    _cockpit_display_row remote "$name" mounted "$remote" "$local_path" "$description"
  done < <(_rproj_mounted_rows)
}

_rproj_select_mounted() {
  local rows output row kind name state remote local_path description preview

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_rproj_mounted_display_rows)"

  if [[ -z "$rows" ]]; then
    print -r -- 'no remote projects are mounted'
    return 1
  fi

  preview="$(_cockpit_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='unmount remote project> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH / REMOTE          HOST              NOTE\nenter unmount selected project' \
          --preview="$preview" \
          --preview-window='right,60%,border-left'
  )" || return

  row="${output#*$'\n'}"
  [[ "$row" == "$output" ]] && row="$output"
  [[ -z "$row" ]] && return 0

  row="${row#*$'\t'}"
  IFS=$'\t' read -r kind name state remote local_path description <<< "$row"

  print -r -- "$name"
}

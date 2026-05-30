_rproj_config_file() {
  print -r -- "${RPROJ_CONFIG:-$HOME/.config/zsh/remote-projects.tsv}"
}

_rproj_expand_path() {
  local path

  path="$1"

  case "$path" in
    '~') print -r -- "$HOME" ;;
    '~/'*) print -r -- "$HOME/${path#\~/}" ;;
    *) print -r -- "$path" ;;
  esac
}

_rproj_rows() {
  local config line name host remote_path local_path description

  config="$(_rproj_config_file)"

  if [[ ! -f "$config" ]]; then
    print -u2 "remote project config was not found: $config"
    return 1
  fi

  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    IFS=$'\t' read -r name host remote_path local_path description <<< "$line"

    if [[ -z "$name" || -z "$host" || -z "$remote_path" || -z "$local_path" ]]; then
      print -u2 "skipping invalid remote project row: $line"
      continue
    fi

    local_path="$(_rproj_expand_path "$local_path")"
    print -r -- "$name"$'\t'"$host"$'\t'"$remote_path"$'\t'"$local_path"$'\t'"$description"
  done < "$config"
}

_rproj_is_mounted() {
  local local_path

  local_path="$1"

  command -v findmnt >/dev/null 2>&1 \
    && findmnt -rn --mountpoint "$local_path" >/dev/null 2>&1
}

_rproj_mount_state() {
  local local_path

  local_path="$1"

  if _rproj_is_mounted "$local_path"; then
    print -r -- 'mounted'
  else
    print -r -- 'unmounted'
  fi
}

_rproj_remote() {
  local host remote_path

  host="$1"
  remote_path="$2"

  print -r -- "$host:$remote_path"
}

_rproj_candidates() {
  local row name host remote_path local_path description state remote

  while IFS=$'\t' read -r name host remote_path local_path description; do
    state="$(_rproj_mount_state "$local_path")"
    remote="$(_rproj_remote "$host" "$remote_path")"
    print -r -- "$name"$'\t'"$state"$'\t'"$remote"$'\t'"$local_path"$'\t'"$description"
  done < <(_rproj_rows)
}

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

_rproj_matches() {
  local query row name row_l
  local -a exact partial

  query="${(L)1}"

  while IFS= read -r row; do
    name="${row%%$'\t'*}"
    row_l="${(L)row}"

    if [[ "${(L)name}" == "$query" ]]; then
      exact+=("$row")
    elif [[ "$row_l" == *"$query"* ]]; then
      partial+=("$row")
    fi
  done < <(_rproj_rows)

  if (( ${#exact[@]} )); then
    printf '%s\n' "${exact[@]}"
  else
    printf '%s\n' "${partial[@]}"
  fi
}

_rproj_require() {
  local command_name

  command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    print -u2 "$command_name is not installed or not on PATH"
    return 1
  fi
}

_rproj_prompt() {
  local prompt default value

  prompt="$1"
  default="$2"

  if [[ -n "$default" ]]; then
    printf '%s [%s]> ' "$prompt" "$default" >&2
  else
    printf '%s> ' "$prompt" >&2
  fi

  read -r value
  [[ -z "$value" ]] && value="$default"
  print -r -- "$value"
}

_rproj_validate_field() {
  local label value

  label="$1"
  value="$2"

  if [[ "$value" == *$'\t'* || "$value" == *$'\n'* ]]; then
    print -u2 "$label cannot contain tabs or newlines"
    return 1
  fi
}

_rproj_mount() {
  local name host remote_path local_path description

  IFS=$'\t' read -r name host remote_path local_path description <<< "$1"

  _rproj_require sshfs || return

  if _rproj_is_mounted "$local_path"; then
    return 0
  fi

  if [[ -e "$local_path" && ! -d "$local_path" ]]; then
    print -u2 "remote project mount path is not a directory: $local_path"
    return 1
  fi

  mkdir -p -- "$local_path" || return
  sshfs "$(_rproj_remote "$host" "$remote_path")" "$local_path"
}

_rproj_status() {
  local name host remote_path local_path description state remote

  IFS=$'\t' read -r name host remote_path local_path description <<< "$1"

  state="$(_rproj_mount_state "$local_path")"
  remote="$(_rproj_remote "$host" "$remote_path")"

  print -r -- "Name:        $name"
  print -r -- "Description: $description"
  print -r -- "Remote:      $remote"
  print -r -- "Local:       $local_path"
  print -r -- "State:       $state"

  if [[ "$state" == 'mounted' ]]; then
    print -r -- ''
    findmnt --mountpoint "$local_path"
  fi
}

_rproj_status_all() {
  local only_mounted row name host remote_path local_path description state remote shown

  only_mounted="$1"
  shown=0

  if [[ "$only_mounted" != 'mounted-only' ]]; then
    printf '%-18s %-10s %-32s %s\n' 'NAME' 'STATE' 'LOCAL' 'REMOTE'
  fi

  while IFS=$'\t' read -r name host remote_path local_path description; do
    state="$(_rproj_mount_state "$local_path")"

    if [[ "$only_mounted" == 'mounted-only' && "$state" != 'mounted' ]]; then
      continue
    fi

    remote="$(_rproj_remote "$host" "$remote_path")"
    printf '%-18s %-10s %-32s %s\n' "$name" "$state" "$local_path" "$remote"
    shown=1
  done < <(_rproj_rows)

  if (( ! shown )) && [[ "$only_mounted" == 'mounted-only' ]]; then
    print -r -- 'no remote projects are mounted'
  fi
}

rproj-status() {
  case "$1" in
    --mounted|-m)
      _rproj_status_all mounted-only
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  rproj-status
  rproj-status --mounted

Shows registered remote projects and whether they are currently mounted.
EOF
      ;;
    '')
      _rproj_status_all all
      ;;
    *)
      print -u2 "unknown rproj-status option: $1"
      return 1
      ;;
  esac
}

alias rps='rproj-status'

_rproj_busy_processes() {
  local local_path

  local_path="$1"

  print -u2 ''
  print -u2 "Processes using $local_path:"

  if command -v lsof >/dev/null 2>&1; then
    lsof +D "$local_path" 2>/dev/null
    return
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser -vm "$local_path"
    return
  fi

  print -u2 'lsof and fuser are not installed or not on PATH'
}

_rproj_unmount() {
  local mode name host remote_path local_path description

  mode="$1"
  IFS=$'\t' read -r name host remote_path local_path description <<< "$2"

  _rproj_require fusermount3 || return

  if ! _rproj_is_mounted "$local_path"; then
    print -r -- "$name is not mounted: $local_path"
    return 0
  fi

  case "$mode" in
    force)
      fusermount3 -uz "$local_path"
      ;;
    normal)
      fusermount3 -u "$local_path" || {
        _rproj_busy_processes "$local_path"
        return 1
      }
      ;;
    *)
      print -u2 "unknown unmount mode: $mode"
      return 1
      ;;
  esac
}

_rproj_mounted_rows() {
  local name host remote_path local_path description

  while IFS=$'\t' read -r name host remote_path local_path description; do
    _rproj_is_mounted "$local_path" || continue
    print -r -- "$name"$'\t'"$host"$'\t'"$remote_path"$'\t'"$local_path"$'\t'"$description"
  done < <(_rproj_rows)
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

rproj-unmount() {
  local mode query selection row mounted_rows
  local -a matches mounted

  mode='normal'

  case "$1" in
    --force|-f)
      mode='force'
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage:
  rproj-unmount [project]
  rproj-unmount --force [project]

Without a project name, unmounts the only mounted project or opens a picker
when multiple remote projects are mounted.
EOF
      return
      ;;
  esac

  query="$*"

  if [[ -z "$query" ]]; then
    mounted_rows="$(_rproj_mounted_rows)"
    if [[ -n "$mounted_rows" ]]; then
      mounted=("${(@f)mounted_rows}")
    else
      mounted=()
    fi

    case "${#mounted[@]}" in
      0)
        print -r -- 'no remote projects are mounted'
        return 0
        ;;
      1)
        row="${mounted[1]}"
        ;;
      *)
        selection="$(_rproj_select_mounted)" || return
        [[ -z "$selection" ]] && return 0
        matches=("${(@f)$(_rproj_matches "$selection")}")
        row="${matches[1]}"
        ;;
    esac
  else
    matches=("${(@f)$(_rproj_matches "$query")}")

    if (( ${#matches[@]} == 0 )); then
      print -u2 "remote project was not found: $query"
      return 1
    fi

    if (( ${#matches[@]} > 1 )); then
      selection="$(_rproj_select_mounted)" || return
      [[ -z "$selection" ]] && return 0
      matches=("${(@f)$(_rproj_matches "$selection")}")
    fi

    row="${matches[1]}"
  fi

  _rproj_unmount "$mode" "$row"
}

alias rpu='rproj-unmount'

_rproj_open() {
  local action row name host remote_path local_path description

  action="$1"
  row="$2"
  IFS=$'\t' read -r name host remote_path local_path description <<< "$row"

  case "$action" in
    status)
      _rproj_status "$row"
      ;;
    unmount)
      _rproj_unmount normal "$row"
      ;;
    force-unmount)
      _rproj_unmount force "$row"
      ;;
    cd)
      _rproj_mount "$row" || return
      cd -- "$local_path"
      ;;
    nvim)
      _rproj_mount "$row" || return
      cd -- "$local_path" || return
      if command -v nvim >/dev/null 2>&1; then
        nvim .
      else
        print -u2 'nvim is not installed or not on PATH'
      fi
      ;;
    code|*)
      _rproj_mount "$row" || return
      cd -- "$local_path" || return
      if command -v code >/dev/null 2>&1; then
        code .
      else
        print -u2 'code is not installed or not on PATH'
      fi
      ;;
  esac
}

_rproj_add_help() {
  cat <<'EOF'
Usage:
  rproj-add [name] [host] [remote_path] [local_path] [description...]

Any missing fields are prompted for. The default host is homeserver and the
default local path is ~/remote/<name>.
EOF
}

rproj-add() {
  local config name host remote_path local_path description existing

  if [[ "$1" == '-h' || "$1" == '--help' ]]; then
    _rproj_add_help
    return
  fi

  config="$(_rproj_config_file)"

  name="$1"
  host="$2"
  remote_path="$3"
  local_path="$4"
  shift $(( $# < 4 ? $# : 4 ))
  description="$*"

  [[ -z "$name" ]] && name="$(_rproj_prompt 'project name' '')"
  if [[ -z "$name" ]]; then
    print -u2 'project name is required'
    return 1
  fi

  if [[ "$name" == *[[:space:]]* || "$name" == *:* || "$name" == */* ]]; then
    print -u2 'project name cannot contain whitespace, :, or /'
    return 1
  fi

  if [[ -f "$config" ]] && existing="$(_rproj_matches "$name")" && [[ -n "$existing" ]]; then
    print -u2 "remote project already exists: $name"
    return 1
  fi

  [[ -z "$host" ]] && host="$(_rproj_prompt 'ssh host' 'homeserver')"
  [[ -z "$remote_path" ]] && remote_path="$(_rproj_prompt 'remote path' "/home/dylana/apps/$name")"
  [[ -z "$local_path" ]] && local_path="$(_rproj_prompt 'local mount path' "~/remote/$name")"
  [[ -z "$description" ]] && description="$(_rproj_prompt 'description' "$name on $host")"

  if [[ -z "$host" || -z "$remote_path" || -z "$local_path" ]]; then
    print -u2 'host, remote path, and local mount path are required'
    return 1
  fi

  _rproj_validate_field 'project name' "$name" || return
  _rproj_validate_field 'ssh host' "$host" || return
  _rproj_validate_field 'remote path' "$remote_path" || return
  _rproj_validate_field 'local mount path' "$local_path" || return
  _rproj_validate_field 'description' "$description" || return

  mkdir -p -- "${config:h}" || return

  if [[ ! -f "$config" ]]; then
    print -r -- '# name	host	remote_path	local_path	description' > "$config" || return
  fi

  print -r -- "$name"$'\t'"$host"$'\t'"$remote_path"$'\t'"$local_path"$'\t'"$description" >> "$config" || return
  print -r -- "added remote project: $name"
}

alias rpa='rproj-add'

_rproj_help() {
  cat <<'EOF'
Usage:
  rproj [project]
  rproj --cd [project]
  rproj --nvim [project]
  rproj --status [project]
  rproj --unmount [project]
  rproj --force-unmount [project]
  rproj --add [name] [host] [remote_path] [local_path] [description...]
  rproj-status [--mounted]
  rproj-unmount [project]

Without a project name, rproj opens an fzf picker.
EOF
}

rproj() {
  local action requested_action query selection row project_name selected_action
  local -a matches

  action='code'

  case "$1" in
    --cd)
      action='cd'
      shift
      ;;
    --nvim)
      action='nvim'
      shift
      ;;
    --status)
      action='status'
      shift
      ;;
    --unmount)
      action='unmount'
      shift
      ;;
    --force-unmount)
      action='force-unmount'
      shift
      ;;
    --add)
      shift
      rproj-add "$@"
      return
      ;;
    -h|--help)
      _rproj_help
      return
      ;;
  esac

  requested_action="$action"
  query="$*"

  if [[ "$action" == 'status' && -z "$query" ]]; then
    rproj-status
    return
  fi

  if [[ "$action" == 'status' && "$query" == '--mounted' ]]; then
    rproj-status --mounted
    return
  fi

  if [[ "$action" == 'unmount' && -z "$query" ]]; then
    rproj-unmount
    return
  fi

  if [[ "$action" == 'force-unmount' && -z "$query" ]]; then
    rproj-unmount --force
    return
  fi

  if [[ -z "$query" ]]; then
    selection="$(_rproj_select)" || return
    [[ -z "$selection" ]] && return 0

    selected_action="${selection%%$'\t'*}"
    [[ "$requested_action" == 'code' ]] && action="$selected_action"
    project_name="${selection#*$'\t'}"
    matches=("${(@f)$(_rproj_matches "$project_name")}")
  else
    matches=("${(@f)$(_rproj_matches "$query")}")
  fi

  if (( ${#matches[@]} == 0 )); then
    print -u2 "remote project was not found: ${query:-$project_name}"
    return 1
  fi

  if (( ${#matches[@]} > 1 )); then
    selection="$(_rproj_select "$query")" || return
    [[ -z "$selection" ]] && return 0

    selected_action="${selection%%$'\t'*}"
    [[ "$requested_action" == 'code' ]] && action="$selected_action"
    project_name="${selection#*$'\t'}"
    matches=("${(@f)$(_rproj_matches "$project_name")}")
  fi

  row="${matches[1]}"
  _rproj_open "$action" "$row"
}

alias rp='rproj'
_rproj_project_completion_items() {
  local name host remote_path local_path description label

  while IFS=$'\t' read -r name host remote_path local_path description; do
    label="$description"
    [[ -z "$label" ]] && label="$host:$remote_path"
    print -r -- "$name:$label"
  done < <(_rproj_rows 2>/dev/null)
}

_rproj_mounted_completion_items() {
  local name host remote_path local_path description label

  while IFS=$'\t' read -r name host remote_path local_path description; do
    label="$description"
    [[ -z "$label" ]] && label="$host:$remote_path"
    print -r -- "$name:$label"
  done < <(_rproj_mounted_rows 2>/dev/null)
}

_rproj_complete_projects() {
  local -a projects

  projects=("${(@f)$(_rproj_project_completion_items)}")
  _describe -t remote-projects 'remote project' projects
}

_rproj_complete_mounted_projects() {
  local -a projects

  projects=("${(@f)$(_rproj_mounted_completion_items)}")
  _describe -t mounted-remote-projects 'mounted remote project' projects
}

_rproj_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '--cd[cd into project]:remote project:_rproj_complete_projects' \
    '--nvim[open project in nvim]:remote project:_rproj_complete_projects' \
    '--status[show project status]:remote project:_rproj_complete_projects' \
    '--unmount[unmount project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--force-unmount[lazy force-unmount project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--add[add a remote project]' \
    '*:remote project:_rproj_complete_projects'
}

_rproj_add_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '1:project name:' \
    '2:ssh host:_hosts' \
    '3:remote path:' \
    '4:local mount path:_files -/' \
    '*:description:'
}

_rproj_status_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-m --mounted)'{-m,--mounted}'[show only mounted projects]'
}

_rproj_unmount_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-f --force)'{-f,--force}'[lazy force-unmount project]' \
    '*:mounted remote project:_rproj_complete_mounted_projects'
}
if (( $+functions[compdef] )); then
  compdef _rproj_completion rproj rp
  compdef _rproj_add_completion rproj-add rpa
  compdef _rproj_status_completion rproj-status rps
  compdef _rproj_unmount_completion rproj-unmount rpu
fi

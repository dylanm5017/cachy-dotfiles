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

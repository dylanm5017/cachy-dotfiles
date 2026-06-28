_rproj_config_file() {
  print -r -- "${RPROJ_CONFIG:-$HOME/.config/zsh/projects/remote-projects.tsv}"
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

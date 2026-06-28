_cockpit_project_state() {
  local dir branch dirty

  dir="$1"

  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
    [[ -z "$branch" ]] && branch="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)"
    [[ -z "$branch" ]] && branch='git'

    if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then
      dirty='dirty'
    else
      dirty='clean'
    fi

    print -r -- "git:$branch $dirty"
    return
  fi

  print -r -- 'dir'
}

_cockpit_project_tags() {
  local dir tags
  local -a detected

  dir="$1"
  detected=()

  [[ -f "$dir/package.json" ]] && detected+=('node')
  [[ -f "$dir/pnpm-lock.yaml" ]] && detected+=('pnpm')
  [[ -f "$dir/yarn.lock" ]] && detected+=('yarn')
  [[ -f "$dir/bun.lock" || -f "$dir/bun.lockb" ]] && detected+=('bun')
  [[ -f "$dir/vite.config.ts" || -f "$dir/vite.config.js" || -f "$dir/vite.config.mjs" ]] && detected+=('vite')
  [[ -f "$dir/Cargo.toml" ]] && detected+=('rust')
  [[ -f "$dir/pyproject.toml" ]] && detected+=('python')
  [[ -f "$dir/go.mod" ]] && detected+=('go')
  [[ -f "$dir/docker-compose.yml" || -f "$dir/compose.yml" ]] && detected+=('compose')
  [[ -f "$dir/flake.nix" ]] && detected+=('nix')

  if (( ${#detected[@]} )); then
    tags="${(j:, :)detected}"
    print -r -- "$tags"
  else
    print -r -- '-'
  fi
}

_cockpit_local_rows() {
  local name context kind project_path state tags

  while IFS=$'\t' read -r name context kind project_path; do
    [[ -z "$project_path" ]] && continue

    state="$(_cockpit_project_state "$project_path")"
    tags="$(_cockpit_project_tags "$project_path")"

    print -r -- 'local'$'\t'"$name"$'\t'"$state"$'\t'"$context"$'\t'"$project_path"$'\t'"$tags"
  done < <(_project_candidates)
}

_cockpit_remote_rows() {
  local name host remote_path local_path description state project_state remote

  while IFS=$'\t' read -r name host remote_path local_path description; do
    [[ -z "$local_path" ]] && continue

    state="$(_rproj_mount_state "$local_path")"
    if [[ "$state" == 'mounted' && -d "$local_path" ]]; then
      project_state="$(_cockpit_project_state "$local_path")"
      [[ "$project_state" != 'dir' ]] && state="$state $project_state"
    fi

    remote="$(_rproj_remote "$host" "$remote_path")"
    [[ -z "$description" ]] && description='-'

    print -r -- 'remote'$'\t'"$name"$'\t'"$state"$'\t'"$remote"$'\t'"$local_path"$'\t'"$description"
  done < <(_rproj_rows 2>/dev/null)
}

_cockpit_candidates() {
  local kind_filter

  kind_filter="$1"

  {
    case "$kind_filter" in
      local)
        _cockpit_local_rows
        ;;
      remote)
        _cockpit_remote_rows
        ;;
      *)
        _cockpit_local_rows
        _cockpit_remote_rows
        ;;
    esac
  } | sort -f -t $'\t' -k2,2 -k1,1
}

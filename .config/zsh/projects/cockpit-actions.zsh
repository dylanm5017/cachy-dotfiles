_cockpit_package_runner() {
  local dir

  dir="$1"

  if [[ -f "$dir/pnpm-lock.yaml" ]] && command -v pnpm >/dev/null 2>&1; then
    print -r -- 'pnpm'
    return
  fi

  if [[ -f "$dir/yarn.lock" ]] && command -v yarn >/dev/null 2>&1; then
    print -r -- 'yarn'
    return
  fi

  if [[ ( -f "$dir/bun.lock" || -f "$dir/bun.lockb" ) ]] && command -v bun >/dev/null 2>&1; then
    print -r -- 'bun'
    return
  fi

  if command -v npm >/dev/null 2>&1; then
    print -r -- 'npm'
    return
  fi

  return 1
}

_cockpit_run_script() {
  local dir scripts rows selected script runner command display

  dir="$1"

  if [[ ! -f "$dir/package.json" ]]; then
    print -u2 "package.json was not found in $dir"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    print -u2 'jq is not installed or not on PATH'
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  scripts="$(jq -r '.scripts // {} | to_entries[] | [.key, .value] | @tsv' "$dir/package.json" 2>/dev/null)"
  if [[ -z "$scripts" ]]; then
    print -u2 "package.json has no scripts: $dir"
    return 1
  fi

  rows="$(
    print -r -- "$scripts" \
      | while IFS=$'\t' read -r script command; do
          display="$(_fzf_ansi '1' "$(_fzf_pad "$script" 24)")  $(_fzf_ansi '2' "$(_fzf_truncate "$command" 72)")"
          print -r -- "$display"$'\t'"$script"$'\t'"$command"
        done
  )"

  selected="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='script> ' \
          --height=50% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2,3 \
          --header=$'SCRIPT                    COMMAND\nenter run selected script' \
          --preview='printf "Script\n  %s\n\nCommand\n  %s\n" {2} {3}' \
          --preview-window='right,50%,border-left'
  )" || return

  [[ -z "$selected" ]] && return 0

  script="$(print -r -- "$selected" | awk -F '\t' '{print $2}')"
  runner="$(_cockpit_package_runner "$dir")" || {
    print -u2 'no package runner found'
    return 1
  }

  cd -- "$dir" || return

  case "$runner" in
    pnpm) pnpm run "$script" ;;
    yarn) yarn "$script" ;;
    bun) bun run "$script" ;;
    npm|*) npm run "$script" ;;
  esac
}

_cockpit_run_package_script() {
  local dir script runner

  dir="$1"
  script="$2"

  if [[ ! -f "$dir/package.json" ]]; then
    print -u2 "package.json was not found in $dir"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    print -u2 'jq is not installed or not on PATH'
    return 1
  fi

  if ! jq -e --arg script "$script" '.scripts[$script] // empty' "$dir/package.json" >/dev/null 2>&1; then
    print -u2 "package.json has no $script script: $dir"
    return 1
  fi

  runner="$(_cockpit_package_runner "$dir")" || {
    print -u2 'no package runner found'
    return 1
  }

  cd -- "$dir" || return

  case "$runner" in
    pnpm) pnpm run "$script" ;;
    yarn) yarn "$script" ;;
    bun) bun run "$script" ;;
    npm|*) npm run "$script" ;;
  esac
}

_cockpit_status() {
  local row kind name state context dir description

  row="$1"
  IFS=$'\t' read -r kind name state context dir description <<< "$row"

  print -r -- "Name:        $name"
  print -r -- "Kind:        $kind"
  print -r -- "State:       $state"
  print -r -- "Context:     $context"
  print -r -- "Path:        $dir"
  print -r -- "Description: $description"

  if [[ -d "$dir" ]] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -r -- ''
    git -C "$dir" status --short --branch
  fi
}

_cockpit_open_github() {
  local dir remote url

  dir="$1"

  if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "not a git repository: $dir"
    return 1
  fi

  if command -v gh >/dev/null 2>&1; then
    (
      cd -- "$dir" || exit 1
      gh repo view --web
    )
    return
  fi

  remote="$(git -C "$dir" remote get-url origin 2>/dev/null)" || {
    print -u2 "origin remote was not found: $dir"
    return 1
  }

  case "$remote" in
    git@github.com:*)
      url="https://github.com/${remote#git@github.com:}"
      ;;
    https://github.com/*)
      url="$remote"
      ;;
    *)
      print -u2 "origin remote is not a GitHub URL: $remote"
      return 1
      ;;
  esac

  url="${url%.git}"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &!
  else
    print -r -- "$url"
  fi
}

_cockpit_open_notes() {
  local row note_file

  row="$1"
  note_file="$(_cockpit_note_file "$row")"
  mkdir -p -- "${note_file:h}" || return
  [[ -f "$note_file" ]] || print -r -- "# ${note_file:t:r}" > "$note_file"

  "${EDITOR:-nvim}" "$note_file"
}

_cockpit_open_yazi() {
  local dir

  dir="$1"

  if ! command -v yazi >/dev/null 2>&1; then
    print -u2 'yazi is not installed or not on PATH'
    return 1
  fi

  if (( $+functions[y] )); then
    y "$dir"
  else
    command yazi "$dir"
  fi
}

_cockpit_open_remote() {
  local action name row local_path

  action="$1"
  name="$2"
  local_path="$3"

  row="$(_rproj_matches "$name" | sed -n '1p')"
  if [[ -z "$row" ]]; then
    print -u2 "remote project was not found: $name"
    return 1
  fi

  case "$action" in
    terminal)
      _rproj_mount "$row" || return
      if command -v alacritty >/dev/null 2>&1; then
        alacritty --working-directory "$local_path" >/dev/null 2>&1 &!
      else
        print -u2 'alacritty is not installed or not on PATH'
      fi
      ;;
    open)
      _rproj_mount "$row" || return
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$local_path" >/dev/null 2>&1 &!
      else
        print -u2 'xdg-open is not installed or not on PATH'
      fi
      ;;
    run-script)
      _rproj_mount "$row" || return
      _cockpit_run_script "$local_path"
      ;;
    dev)
      _rproj_mount "$row" || return
      _cockpit_run_package_script "$local_path" dev
      ;;
    test)
      _rproj_mount "$row" || return
      _cockpit_run_package_script "$local_path" test
      ;;
    github)
      _rproj_mount "$row" || return
      _cockpit_open_github "$local_path"
      ;;
    notes)
      _cockpit_open_notes remote$'\t'"$name"$'\t'"mounted"$'\t'"$local_path"$'\t'"$local_path"$'\t''remote project notes'
      ;;
    yazi)
      _rproj_mount "$row" || return
      _cockpit_open_yazi "$local_path"
      ;;
    mount)
      _rproj_mount "$row"
      ;;
    status)
      _rproj_status "$row"
      ;;
    unmount)
      _rproj_unmount normal "$row"
      ;;
    *)
      _rproj_open "$action" "$row"
      ;;
  esac
}

_cockpit_open() {
  local action row kind name state context project_path description

  action="$1"
  row="$2"
  IFS=$'\t' read -r kind name state context project_path description <<< "$row"

  case "$action" in
    status) ;;
    *) _cockpit_record_recent "$row" ;;
  esac

  case "$kind" in
    remote)
      _cockpit_open_remote "$action" "$name" "$project_path"
      ;;
    local)
      case "$action" in
        status)
          _cockpit_status "$row"
          ;;
        run-script)
          _cockpit_run_script "$project_path"
          ;;
        dev)
          _cockpit_run_package_script "$project_path" dev
          ;;
        test)
          _cockpit_run_package_script "$project_path" test
          ;;
        github)
          _cockpit_open_github "$project_path"
          ;;
        notes)
          _cockpit_open_notes "$row"
          ;;
        yazi)
          _cockpit_open_yazi "$project_path"
          ;;
        mount|unmount)
          print -u2 "$action is only available for remote projects"
          return 1
          ;;
        *)
          _project_open "$action" "$project_path"
          ;;
      esac
      ;;
    *)
      print -u2 "unknown cockpit project kind: $kind"
      return 1
      ;;
  esac
}

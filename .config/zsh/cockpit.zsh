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
    ctrl-e) print -r -- 'cd' ;;
    ctrl-n) print -r -- 'nvim' ;;
    ctrl-t) print -r -- 'terminal' ;;
    ctrl-o) print -r -- 'open' ;;
    ctrl-s) print -r -- 'status' ;;
    ctrl-r) print -r -- 'run-script' ;;
    ctrl-x) print -r -- 'mount' ;;
    ctrl-u) print -r -- 'unmount' ;;
    *) print -r -- 'code' ;;
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
    print -u2 'no projects found under ~/Projects, ~/work, or remote-projects.tsv'
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
          --expect=ctrl-e,ctrl-n,ctrl-t,ctrl-o,ctrl-s,ctrl-r,ctrl-x,ctrl-u \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH / REMOTE             GROUP             TAGS\nenter code | ^e cd | ^n nvim | ^t term | ^o files | ^r script | ^x mount | ^u unmount | ^s status' \
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

_cockpit_help() {
  cat <<'EOF'
Usage:
  cockpit [project]
  cockpit --cd [project]
  cockpit --nvim [project]
  cockpit --terminal [project]
  cockpit --open [project]
  cockpit --status [project]
  cockpit --run-script [project]
  cockpit --mount [remote-project]
  cockpit --unmount [remote-project]
  cockpit --new [project-name]

Without a project name, cockpit opens a unified local and remote project picker.
EOF
}

_cockpit_kind_filter_for_action() {
  case "$1" in
    mount|unmount) print -r -- 'remote' ;;
  esac
}

cockpit() {
  local action requested_action query selection selected_action row kind_filter
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
    --terminal)
      action='terminal'
      shift
      ;;
    --open)
      action='open'
      shift
      ;;
    --status)
      action='status'
      shift
      ;;
    --run-script)
      action='run-script'
      shift
      ;;
    --mount)
      action='mount'
      shift
      ;;
    --unmount)
      action='unmount'
      shift
      ;;
    --new)
      shift
      newproj "$@"
      return
      ;;
    -h|--help)
      _cockpit_help
      return
      ;;
  esac

  requested_action="$action"
  query="$*"
  kind_filter="$(_cockpit_kind_filter_for_action "$action")"

  if [[ -z "$query" ]]; then
    selection="$(_cockpit_select '' "$kind_filter")" || return
    [[ -z "$selection" ]] && return 0

    selected_action="${selection%%$'\t'*}"
    [[ "$requested_action" == 'code' ]] && action="$selected_action"
    row="${selection#*$'\t'}"
    _cockpit_open "$action" "$row"
    return
  fi

  matches=("${(@f)$(_cockpit_matches "$query" "$kind_filter")}")

  if (( ${#matches[@]} == 0 )); then
    print -u2 "project was not found: $query"
    return 1
  fi

  if (( ${#matches[@]} == 1 )); then
    _cockpit_open "$action" "${matches[1]}"
    return
  fi

  selection="$(_cockpit_select "$query" "$kind_filter")" || return
  [[ -z "$selection" ]] && return 0

  selected_action="${selection%%$'\t'*}"
  [[ "$requested_action" == 'code' ]] && action="$selected_action"
  row="${selection#*$'\t'}"
  _cockpit_open "$action" "$row"
}

alias pc='cockpit'
alias workon='cockpit'
_cockpit_completion_items() {
  local row kind name state context project_path description label

  while IFS=$'\t' read -r kind name state context project_path description; do
    label="$kind $state $context"
    print -r -- "$name:$label"
  done < <(_cockpit_candidates 2>/dev/null)
}

_cockpit_complete_projects() {
  local -a projects

  projects=("${(@f)$(_cockpit_completion_items)}")
  _describe -t cockpit-projects 'project' projects
}

_cockpit_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '--cd[cd into project]:project:_cockpit_complete_projects' \
    '--nvim[open project in nvim]:project:_cockpit_complete_projects' \
    '--terminal[open project in a terminal]:project:_cockpit_complete_projects' \
    '--open[open project in file manager]:project:_cockpit_complete_projects' \
    '--status[show project status]:project:_cockpit_complete_projects' \
    '--run-script[pick and run a package.json script]:project:_cockpit_complete_projects' \
    '--mount[mount remote project]:remote project:_rproj_complete_projects' \
    '--unmount[unmount remote project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--new[create a new local project]' \
    '*:project:_cockpit_complete_projects'
}

if (( $+functions[compdef] )); then
  compdef _cockpit_completion cockpit pc workon
fi

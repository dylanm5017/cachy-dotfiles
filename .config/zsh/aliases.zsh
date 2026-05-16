alias ls='eza --icons'
alias ll='eza -lah --icons --git'

alias gs='git status'
alias gc='git commit'
alias gp='git pull'
alias gbr='git branch -r'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git switch'

gbs() {
  local selected local_branch

  selected=$(
    git for-each-ref --format='%(refname:short)' refs/heads refs/remotes \
      | command grep -v '^[^/]*/HEAD$' \
      | sort -u \
      | fzf --prompt='branch> ' --preview='git log --oneline --decorate --color=always -20 {}'
  )

  [[ -z "$selected" ]] && return 0

  if git show-ref --verify --quiet "refs/remotes/$selected"; then
    local_branch="${selected#*/}"
    git show-ref --verify --quiet "refs/heads/$local_branch" \
      && git switch "$local_branch" \
      || git switch --track "$selected"
  else
    git switch "$selected"
  fi
}

alias grep='rg'
alias cat='bat'
alias h='tldr'
alias helpme='tldr'

alias ni='fnm install && fnm use'
alias nv='fnm use'
alias nd='fnm default'

alias nvmrc='fnm use || fnm install'
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dot-add='dot add -p'

noutdated() {
  if ! command -v npm >/dev/null 2>&1; then
    print -u2 'npm not found'
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    npm outdated "$@"
    return $?
  fi

  local json rows selected package

  json="$(npm outdated --json "$@" 2>/dev/null)"

  if [[ -z "$json" || "$json" == "{}" ]]; then
    print 'npm packages are up to date'
    return 0
  fi

  rows="$(
    print -r -- "$json" \
      | jq -r 'to_entries | sort_by(.key)[] | [
          .key,
          (.value.current // "-"),
          (.value.wanted // "-"),
          (.value.latest // "-"),
          (.value.dependent // "-"),
          (.value.location // "-")
        ] | @tsv'
  )" || {
    npm outdated "$@"
    return $?
  }

  selected="$(
    print -r -- "$rows" \
      | fzf \
          --prompt='npm outdated> ' \
          --header=$'PACKAGE\tCURRENT\tWANTED\tLATEST\tDEPENDENT' \
          --delimiter=$'\t' \
          --with-nth='1,2,3,4,5' \
          --preview=$'printf "Package: %s\nCurrent: %s\nWanted: %s\nLatest: %s\nDependent: %s\nLocation: %s\n" {1} {2} {3} {4} {5} {6}'
  )" || return

  [[ -z "$selected" ]] && return 0

  package="$(print -r -- "$selected" | awk -F '\t' '{print $1}')"
  print -r -- "npm install ${package}@latest"
}

alias no='noutdated'
alias nout='noutdated'

alias ubuntu='ssh dylana@192.168.1.17'
alias ub='ssh dylana@192.168.1.17'

alias pkglist='pacman -Qqe > ~/.dotfiles/pkglist.txt'

ftext() {
  local query selected

  if (( $# )); then
    query="$*"
  else
    printf 'search> '
    read -r query
  fi

  [[ -z "$query" ]] && return 0

  selected=$(
    rga --files-with-matches -- "$query" 2>/dev/null \
      | fzf --prompt='text> ' --preview='bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null'
  )

  [[ -z "$selected" ]] && return 0
  print -r -- "$selected"
}

ff() {
  local selected

  selected=$(
    rg --files \
      | fzf --prompt='file> ' --preview='bat --color=always --style=numbers --line-range=:200 {}'
  )

  [[ -n "$selected" ]] && print -r -- "$selected"
}

fe() {
  local selected

  selected="$(ff)" || return
  [[ -z "$selected" ]] && return 0

  "${EDITOR:-nvim}" "$selected"
}

projects() {
  cd -- "$HOME/Projects"
}

_project_roots() {
  [[ -d "$HOME/Projects" ]] && print -r -- "$HOME/Projects"
  [[ -d "$HOME/work" ]] && print -r -- "$HOME/work"
}

_project_context() {
  local project_path rel group

  project_path="$1"

  if [[ "$project_path" == "$HOME/Projects" || "$project_path" == "$HOME/Projects/"* ]]; then
    print -r -- 'Projects'
    return
  fi

  if [[ "$project_path" == "$HOME/work" || "$project_path" == "$HOME/work/"* ]]; then
    rel="${project_path#$HOME/work/}"
    group="${rel%%/*}"

    if [[ "$rel" == "$group" ]]; then
      print -r -- 'work'
    else
      print -r -- "work/$group"
    fi

    return
  fi

  print -r -- 'project'
}

_project_git_dirs() {
  local root git_dir

  root="$1"

  if command -v fd >/dev/null 2>&1; then
    fd -H -t d -d 5 \
      --exclude node_modules \
      --exclude dist \
      --exclude build \
      --exclude target \
      --exclude .cache \
      --exclude .nx \
      --exclude coverage \
      --exclude test-results \
      '^\.git$' "$root" 2>/dev/null \
      | while IFS= read -r git_dir; do
          print -r -- "${git_dir:h}"
        done
  else
    find "$root" -maxdepth 5 \
      \( -type d \( \
        -name node_modules -o \
        -name dist -o \
        -name build -o \
        -name target -o \
        -name .cache -o \
        -name .nx -o \
        -name coverage -o \
        -name test-results \
      \) -prune \) -o \
      \( -type d -name .git -print \) 2>/dev/null \
      | while IFS= read -r git_dir; do
          print -r -- "${git_dir:h}"
        done
  fi
}

_project_candidates() {
  local root project_path name context kind
  local -A seen
  local -a rows

  if [[ -d "$HOME/Projects" ]]; then
    for project_path in "$HOME/Projects"/*(N/); do
      [[ -n "${seen[$project_path]}" ]] && continue
      seen[$project_path]=1

      name="${project_path:t}"
      context="$(_project_context "$project_path")"
      kind='dir'
      [[ -d "$project_path/.git" ]] && kind='git'

      rows+=("$name"$'\t'"$context"$'\t'"$kind"$'\t'"$project_path")
    done
  fi

  while IFS= read -r root; do
    while IFS= read -r project_path; do
      [[ -z "$project_path" || -n "${seen[$project_path]}" ]] && continue
      seen[$project_path]=1

      name="${project_path:t}"
      context="$(_project_context "$project_path")"
      kind='git'

      rows+=("$name"$'\t'"$context"$'\t'"$kind"$'\t'"$project_path")
    done < <(_project_git_dirs "$root")
  done < <(_project_roots)

  (( ${#rows[@]} )) && printf '%s\n' "${rows[@]}" | sort -f
}

_project_preview_command() {
  cat <<'EOF'
dir={4}

printf "Path\n  %s\n" "$dir"

if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf "\nGit\n"
  git -C "$dir" status --short --branch 2>/dev/null
  git -C "$dir" log -1 --oneline --decorate --color=always 2>/dev/null
fi

if [ -f "$dir/package.json" ] && command -v jq >/dev/null 2>&1; then
  scripts="$(jq -r '.scripts // {} | to_entries[] | "  " + .key + ": " + .value' "$dir/package.json" 2>/dev/null)"
  if [ -n "$scripts" ]; then
    printf "\nScripts\n%s\n" "$scripts"
  fi
fi

printf "\nFiles\n"
if command -v eza >/dev/null 2>&1; then
  eza -la --icons --git "$dir" 2>/dev/null | sed -n '1,80p'
else
  ls -la "$dir" 2>/dev/null | sed -n '1,80p'
fi
EOF
}

_project_action_for_key() {
  case "$1" in
    ctrl-e) print -r -- 'cd' ;;
    ctrl-n) print -r -- 'nvim' ;;
    ctrl-t) print -r -- 'terminal' ;;
    ctrl-o) print -r -- 'open' ;;
    *) print -r -- 'code' ;;
  esac
}

_project_select() {
  local query rows output key row action project_path preview

  query="${1:-}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_project_candidates)"
  if [[ -z "$rows" ]]; then
    print -u2 'no projects found under ~/Projects or ~/work'
    return 1
  fi

  preview="$(_project_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --prompt='project> ' \
          --height=70% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-t,ctrl-o \
          --delimiter=$'\t' \
          --with-nth=1,2,3 \
          --header='enter: code | ctrl-e: cd | ctrl-n: nvim | ctrl-t: terminal | ctrl-o: files' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  action="$(_project_action_for_key "$key")"
  project_path="${row##*$'\t'}"

  print -r -- "$action"$'\t'"$project_path"
}

_project_matches() {
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
  done < <(_project_candidates)

  if (( ${#exact[@]} )); then
    printf '%s\n' "${exact[@]}"
  else
    printf '%s\n' "${partial[@]}"
  fi
}

_project_remember() {
  local project_path

  project_path="$1"

  command -v zoxide >/dev/null 2>&1 && zoxide add "$project_path" >/dev/null 2>&1
}

_project_open() {
  local action project_path

  action="$1"
  project_path="$2"

  if [[ ! -d "$project_path" ]]; then
    print -u2 "project directory does not exist: $project_path"
    return 1
  fi

  _project_remember "$project_path"

  case "$action" in
    cd)
      cd -- "$project_path"
      ;;
    nvim)
      cd -- "$project_path" || return
      if command -v nvim >/dev/null 2>&1; then
        nvim .
      else
        print -u2 'nvim is not installed or not on PATH'
      fi
      ;;
    terminal)
      if command -v alacritty >/dev/null 2>&1; then
        alacritty --working-directory "$project_path" >/dev/null 2>&1 &!
      else
        print -u2 'alacritty is not installed or not on PATH'
      fi
      ;;
    open)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$project_path" >/dev/null 2>&1 &!
      else
        print -u2 'xdg-open is not installed or not on PATH'
      fi
      ;;
    code|*)
      cd -- "$project_path" || return
      if command -v code >/dev/null 2>&1; then
        code .
      else
        print -u2 'code is not installed or not on PATH'
      fi
      ;;
  esac
}

proj() {
  local query selection action project_path
  local -a matches

  query="$*"

  if [[ -z "$query" ]]; then
    selection="$(_project_select)" || return
    [[ -z "$selection" ]] && return 0

    action="${selection%%$'\t'*}"
    project_path="${selection#*$'\t'}"
    _project_open "$action" "$project_path"
    return
  fi

  matches=("${(@f)$(_project_matches "$query")}")

  if (( ${#matches[@]} == 0 )); then
    print -u2 "project was not found: $query"
    return 1
  fi

  if (( ${#matches[@]} == 1 )); then
    project_path="${matches[1]##*$'\t'}"
    _project_open code "$project_path"
    return
  fi

  selection="$(_project_select "$query")" || return
  [[ -z "$selection" ]] && return 0

  action="${selection%%$'\t'*}"
  project_path="${selection#*$'\t'}"
  _project_open "$action" "$project_path"
}

alias p='proj'

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

_rproj_preview_command() {
  cat <<'EOF'
name={1}
state={2}
remote={3}
dir={4}
description={5}

printf "Project\n  %s\n" "$name"
printf "\nDescription\n  %s\n" "$description"
printf "\nRemote\n  %s\n" "$remote"
printf "\nLocal\n  %s\n" "$dir"
printf "\nState\n  %s\n" "$state"

if command -v findmnt >/dev/null 2>&1; then
  mount_details="$(findmnt -rn --mountpoint "$dir" --output SOURCE,FSTYPE,OPTIONS 2>/dev/null)"
  if [ -n "$mount_details" ]; then
    printf "\nMount\n%s\n" "$mount_details"
  fi
fi

if [ -d "$dir" ]; then
  printf "\nFiles\n"
  if command -v eza >/dev/null 2>&1; then
    eza -la --icons --git "$dir" 2>/dev/null | sed -n '1,80p'
  else
    ls -la "$dir" 2>/dev/null | sed -n '1,80p'
  fi
fi
EOF
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
  local query rows output key row action name preview

  query="${1:-}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_rproj_candidates)" || return

  if [[ -z "$rows" ]]; then
    print -u2 'no remote projects found'
    return 1
  fi

  preview="$(_rproj_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --prompt='remote project> ' \
          --height=70% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-s,ctrl-u \
          --delimiter=$'\t' \
          --with-nth=1,2,3,5 \
          --header='enter: code | ctrl-e: cd | ctrl-n: nvim | ctrl-s: status | ctrl-u: unmount' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  action="$(_rproj_action_for_key "$key")"
  name="${row%%$'\t'*}"

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

_rproj_select_mounted() {
  local rows output row name host remote_path local_path description preview

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(
    while IFS=$'\t' read -r name host remote_path local_path description; do
      print -r -- "$name"$'\t'"mounted"$'\t'"$(_rproj_remote "$host" "$remote_path")"$'\t'"$local_path"$'\t'"$description"
    done < <(_rproj_mounted_rows)
  )"

  if [[ -z "$rows" ]]; then
    print -r -- 'no remote projects are mounted'
    return 1
  fi

  preview="$(_rproj_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --prompt='unmount remote project> ' \
          --height=70% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1,3,4,5 \
          --header='enter: unmount selected project' \
          --preview="$preview" \
          --preview-window='right,60%,border-left'
  )" || return

  row="${output#*$'\n'}"
  [[ "$row" == "$output" ]] && row="$output"
  [[ -z "$row" ]] && return 0

  print -r -- "${row%%$'\t'*}"
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

_newproj_pick() {
  local prompt selected

  prompt="$1"
  shift

  if command -v fzf >/dev/null 2>&1; then
    selected="$(printf '%s\n' "$@" | fzf --prompt="$prompt")" || return 1
    [[ -z "$selected" ]] && return 1

    print -r -- "$selected"
    return 0
  fi

  PS3="$prompt "
  select selected in "$@"; do
    if [[ -n "$selected" ]]; then
      print -r -- "$selected"
      return 0
    fi

    print -u2 'invalid selection'
  done

  return 1
}

_newproj_finish() {
  local project_dir

  project_dir="$1"

  if command -v git >/dev/null 2>&1; then
    git -C "$project_dir" init -q
  else
    print -u2 'git not found; skipping git init'
  fi

  cd -- "$project_dir" || return
  if command -v code >/dev/null 2>&1; then
    code .
  else
    print -u2 'code is not installed or not on PATH'
  fi
}

newproj() {
  local project_name projects_dir project_dir template node_version version
  local compatible_versions installed_versions

  projects_dir="$HOME/Projects"

  if (( $# )); then
    project_name="$*"
  else
    printf 'project name> '
    read -r project_name
  fi

  if [[ -z "$project_name" ]]; then
    print -u2 'project name is required'
    return 1
  fi

  if [[ "$project_name" == */* ]]; then
    print -u2 'project name cannot contain /'
    return 1
  fi

  project_dir="$projects_dir/$project_name"

  if [[ -e "$project_dir" ]]; then
    print -u2 "project already exists: $project_dir"
    return 1
  fi

  template="$(_newproj_pick 'project type> ' 'Vite React TypeScript' 'Blank')" || return

  mkdir -p -- "$projects_dir" || return

  case "$template" in
    'Vite React TypeScript')
      if ! command -v fnm >/dev/null 2>&1; then
        print -u2 'fnm not found'
        return 1
      fi

      if ! command -v npm >/dev/null 2>&1; then
        print -u2 'npm not found'
        return 1
      fi

      compatible_versions=(v20.20.2 v22.22.2 v24.14.1)
      installed_versions=()

      for version in "${compatible_versions[@]}"; do
        if fnm list | command grep -F -q "$version"; then
          installed_versions+=("$version")
        fi
      done

      if (( ${#installed_versions[@]} == 0 )); then
        print -u2 'no compatible fnm Node versions found; install v20.19+, v22.12+, or v24+'
        return 1
      fi

      node_version="$(_newproj_pick 'node version> ' "${installed_versions[@]}")" || return
      fnm use "$node_version" || return

      (
        cd -- "$projects_dir" || exit 1
        npm create vite@latest "$project_name" -- --template react-ts --no-interactive
      ) || return

      if [[ ! -d "$project_dir" ]]; then
        print -u2 "project was not created: $project_dir"
        return 1
      fi

      print -r -- "$node_version" > "$project_dir/.nvmrc"
      ;;
    Blank)
      mkdir -- "$project_dir" || return
      ;;
    *)
      print -u2 "unknown project type: $template"
      return 1
      ;;
  esac

  _newproj_finish "$project_dir"
}

alias np='newproj'

mkcd() {
  [[ -z "$1" ]] && return 1

  mkdir -p -- "$1" && cd -- "$1"
}

tmpcd() {
  local dir

  dir="$(mktemp -d)" || return
  cd -- "$dir"
}

dps() {
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

alias di='docker images'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

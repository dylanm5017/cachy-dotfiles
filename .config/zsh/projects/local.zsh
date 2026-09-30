# projects — cd to ~/Projects
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

_project_action_for_key() {
  case "$1" in
    ctrl-e) print -r -- 'code' ;;
    ctrl-n) print -r -- 'nvim' ;;
    ctrl-t) print -r -- 'terminal' ;;
    ctrl-o) print -r -- 'open' ;;
    *) print -r -- 'cd' ;;
  esac
}

_project_select() {
  local query rows output key row action kind name state context project_path tags preview

  query="${1:-}"

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  rows="$(_cockpit_display_rows local)"
  if [[ -z "$rows" ]]; then
    print -u2 'no projects found under ~/Projects or ~/work'
    return 1
  fi

  preview="$(_cockpit_preview_command)"
  output="$(
    print -r -- "$rows" \
      | fzf \
          --ansi \
          --prompt='project> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --expect=ctrl-e,ctrl-n,ctrl-t,ctrl-o \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,3,5,6,7 \
          --header=$'TYPE  PROJECT                       STATE     BRANCH                    GROUP             TAGS\nenter cd | ^e code | ^n nvim | ^t term | ^o files' \
          --preview="$preview" \
          --preview-window='right,60%,border-left' \
          --query="$query"
  )" || return

  key="${output%%$'\n'*}"
  row="${output#*$'\n'}"

  [[ -z "$row" || "$row" == "$output" ]] && return 0

  row="${row#*$'\t'}"
  IFS=$'\t' read -r kind name state context project_path tags <<< "$row"

  action="$(_project_action_for_key "$key")"

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

# proj — fuzzy-pick a local project and open it
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
    _project_open cd "$project_path"
    return
  fi

  selection="$(_project_select "$query")" || return
  [[ -z "$selection" ]] && return 0

  action="${selection%%$'\t'*}"
  project_path="${selection#*$'\t'}"
  _project_open "$action" "$project_path"
}

alias p='proj'

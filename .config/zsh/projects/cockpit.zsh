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
  cockpit --dev [project]
  cockpit --test [project]
  cockpit --github [project]
  cockpit --notes [project]
  cockpit --yazi [project]
  cockpit --recent [project]
  cockpit --doctor
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
  local action first query selection selected_action row kind_filter
  local -a matches

  action='cd'
  local first="$1"

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
    --dev)
      action='dev'
      shift
      ;;
    --test)
      action='test'
      shift
      ;;
    --github)
      action='github'
      shift
      ;;
    --notes)
      action='notes'
      shift
      ;;
    --yazi)
      action='yazi'
      shift
      ;;
    --recent)
      action='recent'
      shift
      ;;
    --doctor)
      _cockpit_doctor
      return
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

  query="$*"
  kind_filter="$(_cockpit_kind_filter_for_action "$action")"

  if [[ "$action" == 'recent' ]]; then
    if [[ -z "$query" ]]; then
      selection="$(_cockpit_select_recent)" || return
      [[ -z "$selection" ]] && return 0

      selected_action="${selection%%$'\t'*}"
      row="${selection#*$'\t'}"
      _cockpit_open "$selected_action" "$row"
      return
    fi

    matches=("${(@f)$(_cockpit_recent_matches "$query")}")

    if (( ${#matches[@]} == 0 )); then
      print -u2 "recent project was not found: $query"
      return 1
    fi

    if (( ${#matches[@]} == 1 )); then
      _cockpit_open cd "${matches[1]}"
      return
    fi

    selection="$(_cockpit_select_recent "$query")" || return
    [[ -z "$selection" ]] && return 0

    selected_action="${selection%%$'\t'*}"
    row="${selection#*$'\t'}"
    _cockpit_open "$selected_action" "$row"
    return
  fi

  if [[ -z "$query" ]]; then
    selection="$(_cockpit_select '' "$kind_filter")" || return
    [[ -z "$selection" ]] && return 0

    selected_action="${selection%%$'\t'*}"
    [[ "$first" != -* ]] && action="$selected_action"
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
  [[ "$first" != -* ]] && action="$selected_action"
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
    '--dev[run package.json dev script]:project:_cockpit_complete_projects' \
    '--test[run package.json test script]:project:_cockpit_complete_projects' \
    '--github[open project repository on GitHub]:project:_cockpit_complete_projects' \
    '--notes[open project notes]:project:_cockpit_complete_projects' \
    '--yazi[open project in Yazi]:project:_cockpit_complete_projects' \
    '--recent[open recent cockpit projects]:project:_cockpit_complete_projects' \
    '--doctor[check cockpit tools and paths]' \
    '--mount[mount remote project]:remote project:_rproj_complete_projects' \
    '--unmount[unmount remote project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--new[create a new local project]' \
    '*:project:_cockpit_complete_projects'
}

if (( $+functions[compdef] )); then
  compdef _cockpit_completion cockpit pc workon
fi

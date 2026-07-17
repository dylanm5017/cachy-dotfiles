_newproj_pick() {
  local prompt selected option

  prompt="$1"
  shift

  if command -v fzf >/dev/null 2>&1; then
    selected="$(
      printf '%s\n' "$@" \
        | while IFS= read -r option; do
            print -r -- "$(_fzf_ansi '1' "$option")"$'\t'"$option"
          done \
        | fzf \
            --ansi \
            --prompt="$prompt" \
            --height=40% \
            --layout=reverse \
            --border \
            --delimiter=$'\t' \
            --with-nth=1 \
            --nth=1,2 \
            --header='enter select | esc cancel'
    )" || return 1
    [[ -z "$selected" ]] && return 1

    selected="${selected#*$'\t'}"
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
  print -r -- "created $project_dir (run 'code .' to open in the editor)"
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

      compatible_versions=(v24.14.1 v22.22.2 v20.20.2)
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

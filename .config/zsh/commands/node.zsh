alias ni='fnm install && fnm use'
alias nv='fnm use'
alias nd='fnm default'
alias nvmrc='fnm use || fnm install'

noutdated() {
  if ! command -v npm >/dev/null 2>&1; then
    print -u2 'npm not found'
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    npm outdated "$@"
    return $?
  fi

  local json rows selected package current wanted latest dependent location display

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
      | while IFS=$'\t' read -r package current wanted latest dependent location; do
          display="$(_fzf_ansi '1' "$(_fzf_pad "$package" 30)")  $(_fzf_ansi '2' "$(_fzf_pad "$current" 12)")  $(_fzf_pad "$wanted" 12)  $(_fzf_ansi '32' "$(_fzf_pad "$latest" 12)")  $(_fzf_ansi '2' "$(_fzf_truncate "$dependent" 24)")"
          print -r -- "$display"$'\t'"$package"$'\t'"$current"$'\t'"$wanted"$'\t'"$latest"$'\t'"$dependent"$'\t'"$location"
        done \
      | fzf \
          --ansi \
          --prompt='npm outdated> ' \
          --height=70% \
          --layout=reverse \
          --border \
          --header=$'PACKAGE                         CURRENT       WANTED        LATEST        DEPENDENT\nenter prints install command' \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2,6,7 \
          --preview=$'printf "Package\n  %s\n\nVersions\n  current: %s\n  wanted:  %s\n  latest:  %s\n\nDependent\n  %s\n\nLocation\n  %s\n" {2} {3} {4} {5} {6} {7}' \
          --preview-window='right,50%,border-left'
  )" || return

  [[ -z "$selected" ]] && return 0

  package="$(print -r -- "$selected" | awk -F '\t' '{print $2}')"
  print -r -- "npm install ${package}@latest"
}

alias no='noutdated'
alias nout='noutdated'

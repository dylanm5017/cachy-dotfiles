if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi

[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh 2>/dev/null
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh 2>/dev/null

_fzf_truncate() {
  local value width

  value="$1"
  width="$2"

  if (( ${#value} <= width )); then
    print -r -- "$value"
    return
  fi

  if (( width <= 3 )); then
    print -r -- "${value[1,$width]}"
  else
    print -r -- "${value[1,$(( width - 3 ))]}..."
  fi
}

_fzf_pad() {
  local value width

  value="$(_fzf_truncate "$1" "$2")"
  width="$2"

  printf "%-${width}s" "$value"
}

_fzf_ansi() {
  local code value

  code="$1"
  value="$2"

  print -rn -- $'\033['"$code"$'m'"$value"$'\033[0m'
}

_fzf_file_kind() {
  local item ext

  item="$1"
  ext="${item:e}"

  case "$ext" in
    ts|tsx) print -r -- 'TS' ;;
    js|jsx|mjs|cjs) print -r -- 'JS' ;;
    json) print -r -- 'JSON' ;;
    md|markdown) print -r -- 'MD' ;;
    zsh|sh|bash) print -r -- 'SH' ;;
    yml|yaml|toml) print -r -- 'CFG' ;;
    css|scss|sass) print -r -- 'CSS' ;;
    html) print -r -- 'HTML' ;;
    py) print -r -- 'PY' ;;
    rs) print -r -- 'RS' ;;
    go) print -r -- 'GO' ;;
    *) print -r -- 'FILE' ;;
  esac
}

_fzf_file_rows() {
  local item kind name dir display

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue

    kind="$(_fzf_file_kind "$item")"
    name="${item:t}"
    dir="${item:h}"
    [[ "$dir" == "$item" ]] && dir='.'

    display="$(_fzf_ansi '36' "$(_fzf_pad "$kind" 5)")  $(_fzf_ansi '1' "$(_fzf_pad "$name" 34)")  $(_fzf_ansi '2' "$(_fzf_truncate "$dir" 56)")"
    print -r -- "$display"$'\t'"$item"
  done
}

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
      | _fzf_file_rows \
      | fzf \
          --ansi \
          --prompt='text> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2 \
          --header=$'TYPE   FILE                              DIRECTORY\nenter prints path' \
          --preview='bat --color=always --style=numbers --line-range=:200 {2} 2>/dev/null' \
          --preview-window='right,60%,border-left'
  )

  [[ -z "$selected" ]] && return 0
  selected="${selected#*$'\t'}"
  print -r -- "$selected"
}

ff() {
  local selected

  selected=$(
    rg --files \
      | _fzf_file_rows \
      | fzf \
          --ansi \
          --prompt='file> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2 \
          --header=$'TYPE   FILE                              DIRECTORY\nenter prints path' \
          --preview='bat --color=always --style=numbers --line-range=:200 {2}' \
          --preview-window='right,60%,border-left'
  )

  selected="${selected#*$'\t'}"
  [[ -n "$selected" ]] && print -r -- "$selected"
}

fe() {
  local selected

  selected="$(ff)" || return
  [[ -z "$selected" ]] && return 0

  "${EDITOR:-nvim}" "$selected"
}

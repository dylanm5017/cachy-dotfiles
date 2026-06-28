if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"

  if command -v usage >/dev/null 2>&1; then
    source <(mise completion zsh)
  fi
fi

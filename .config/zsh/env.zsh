export PATH="$HOME/.local/share/fnm:$PATH"

if command -v fnm >/dev/null 2>&1; then
  # Pick up repo version files even when working in nested directories.
  if fnm_env="$(fnm env --shell zsh --use-on-cd --version-file-strategy recursive 2>/dev/null)"; then
    eval "$fnm_env"
  fi
  unset fnm_env
fi

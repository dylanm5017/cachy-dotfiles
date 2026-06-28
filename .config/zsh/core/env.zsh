export GOPATH="$HOME/.local/share/go"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export PATH="$HOME/scripts:$HOME/.local/bin:$HOME/.local/share/fnm:$GOPATH/bin:$PATH"
export STARSHIP_CONFIG="$HOME/.config/shell/starship.toml"

if command -v fnm >/dev/null 2>&1; then
  # Pick up repo version files even when working in nested directories.
  if fnm_env="$(fnm env --shell zsh --use-on-cd --version-file-strategy recursive 2>/dev/null)"; then
    eval "$fnm_env"
  fi
  unset fnm_env
fi

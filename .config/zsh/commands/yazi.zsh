if command -v yazi >/dev/null 2>&1; then
  y() {
    local cwd_file cwd

    cwd_file="$(mktemp -t yazi-cwd.XXXXXX)" || return
    command yazi --cwd-file="$cwd_file" "$@"

    if cwd="$(command cat -- "$cwd_file" 2>/dev/null)" \
      && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi

    command rm -f -- "$cwd_file"
  }

  yc() {
    y "$HOME/.config"
  }

  yp() {
    y "$HOME/Projects"
  }

  yd() {
    y "$HOME/Downloads"
  }
fi

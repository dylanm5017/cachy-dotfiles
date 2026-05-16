if [[ -z "${FZF_DEFAULT_OPTS:-}" ]]; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
fi

[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh 2>/dev/null
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh 2>/dev/null

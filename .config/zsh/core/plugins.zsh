# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# history
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi

# completion UI
_dyl_fzf_tab_home="${${(%):-%N}:A:h:h}/vendor/fzf-tab"
if [[ -f "$_dyl_fzf_tab_home/fzf-tab.plugin.zsh" ]]; then
  zstyle ':completion:*' menu no
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:*' fzf-flags --height=80% --layout=reverse --border
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [[ -d "$realpath" ]]; then eza -la --icons --git --color=always "$realpath" 2>/dev/null || ls -la "$realpath" 2>/dev/null; elif [[ -f "$realpath" ]]; then bat --color=always --style=numbers --line-range=:120 "$realpath" 2>/dev/null || sed -n "1,120p" "$realpath" 2>/dev/null; else print -r -- "$word"; fi'
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff --color=always -- "$word" 2>/dev/null || git diff --cached --color=always -- "$word" 2>/dev/null || print -r -- "$word"'
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview 'ps -p "$word" -o pid,ppid,stat,etime,command 2>/dev/null'
  source "$_dyl_fzf_tab_home/fzf-tab.plugin.zsh"
fi
unset _dyl_fzf_tab_home

# zsh plugins that wrap widgets should load after fzf-tab.
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
fi

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

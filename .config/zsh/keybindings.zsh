# Enable modern key handling
bindkey -e

bindkey '^ ' autosuggest-accept

# Search history by the current command-line substring.
if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  [[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" history-substring-search-up
  [[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" history-substring-search-down
fi

# Fix common keys
bindkey '^[[3~' delete-char       # Delete
bindkey '^[[H' beginning-of-line  # Home
bindkey '^[[F' end-of-line        # End
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

autoload -U zkbd

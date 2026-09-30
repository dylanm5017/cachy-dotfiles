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

# Treat / and = as word separators so ctrl+w deletes one path segment
# instead of the whole path, and splits --flag=value.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Word motion
bindkey '^[[1;5D' backward-word        # ctrl+left
bindkey '^[[1;5C' forward-word         # ctrl+right
bindkey '^[[1;3D' backward-word        # alt+left
bindkey '^[[1;3C' forward-word         # alt+right

# Word deletion
bindkey '^H' backward-kill-word        # ctrl+backspace
bindkey '^[^?' backward-kill-word      # alt+backspace
bindkey '^[[3;5~' kill-word            # ctrl+delete

# Cycle backwards through completion candidates.
bindkey '^[[Z' reverse-menu-complete   # shift+tab

# Open the current command line in $EDITOR; the buffer is replaced on save.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line       # ctrl+x ctrl+e

bindkey '^ ' autosuggest-accept
# Enable modern key handling
bindkey -e

# Fix common keys
bindkey '^[[3~' delete-char       # Delete
bindkey '^[[H' beginning-of-line  # Home
bindkey '^[[F' end-of-line        # End
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

autoload -U zkbd
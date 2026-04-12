autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' max-errors 2 numeric

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''

setopt NO_CASE_GLOB
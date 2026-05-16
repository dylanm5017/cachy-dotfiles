autoload -Uz compinit

setopt EXTENDED_GLOB

[ -s "$HOME/.bun/_bun" ] && fpath=("$HOME/.bun" $fpath)

zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ ! -e "$zcompdump" || -n "$zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
unset zcompdump

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' max-errors 2 numeric

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''

setopt NO_CASE_GLOB

compdef dot=git

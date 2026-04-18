alias ls='eza --icons'
alias ll='eza -lah --icons --git'

alias gs='git status'
alias gc='git commit'
alias gp='git push'

alias grep='rg'
alias cat='bat'

alias ni='fnm install && fnm use'
alias nv='fnm use'
alias nd='fnm default'

alias nvmrc='fnm use || fnm install'
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dot-add='dot add -p'

alias pkglist='pacman -Qqe > ~/.dotfiles/pkglist.txt'
alias ff='rg --files | fzf'
alias proj='cd $(fd . ~/ -t d -d 3 | fzf)'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
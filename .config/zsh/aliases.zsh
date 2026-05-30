alias ls='eza --icons'
alias ll='eza -lah --icons --git'

alias grep='rg'
alias cat='bat'
alias h='tldr'
alias helpme='tldr'

alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias dot-add='dot add -p'

alias ubuntu='ssh dylana@192.168.1.17'
alias ub='ssh dylana@192.168.1.17'

pkglist() {
  local package_dir

  package_dir="$HOME/.config/dotfiles/packages"
  mkdir -p -- "$package_dir" || return

  pacman -Qqen | sort > "$package_dir/native.txt" || return
  pacman -Qqem | sort > "$package_dir/foreign.txt" || return

  print -r -- "updated $package_dir/native.txt"
  print -r -- "updated $package_dir/foreign.txt"
}

mkcd() {
  [[ -z "$1" ]] && return 1

  mkdir -p -- "$1" && cd -- "$1"
}

tmpcd() {
  local dir

  dir="$(mktemp -d)" || return
  cd -- "$dir"
}

dps() {
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

alias di='docker images'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

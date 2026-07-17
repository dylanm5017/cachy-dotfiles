alias ls='eza --icons'
alias ll='eza -lah --icons --git'

alias grep='rg'
alias cat='bat'
alias h='tldr'

conf() {
  local entries selection dir

  entries=(
    "hypr"$'\t'"$HOME/.config/hypr"
    "zsh"$'\t'"$HOME/.config/zsh"
    "quickshell"$'\t'"$HOME/.config/quickshell"
    "nvim"$'\t'"$HOME/.config/nvim"
    "alacritty"$'\t'"$HOME/.config/alacritty"
    "kitty"$'\t'"$HOME/.config/kitty"
    "waybar"$'\t'"$HOME/.config/waybar"
    "mako"$'\t'"$HOME/.config/mako"
    "smoky-plum"$'\t'"$HOME/.config/smoky-plum"
    "btop"$'\t'"$HOME/.config/btop"
    "rofi"$'\t'"$HOME/.config/rofi"
    "yazi"$'\t'"$HOME/.config/yazi"
    "git"$'\t'"$HOME/.config/git"
    "dotfiles"$'\t'"$HOME/.config/dotfiles"
  )

  selection="$(printf '%s\n' "${entries[@]}" \
    | fzf \
        --prompt='config> ' \
        --height=40% \
        --layout=reverse \
        --border \
        --delimiter=$'\t' \
        --with-nth=1 \
        --query="${1:-}"
  )" || return

  [[ -z "$selection" ]] && return 0

  dir="${selection##*$'\t'}"
  cd -- "$dir"
}

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

clearff() {
  clear
  fastfetch
}

alias clear='clearff'
alias di='docker images'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

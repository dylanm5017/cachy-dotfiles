# Aliases that swap or change a standard command are skipped inside Claude Code
# (which sets CLAUDECODE=1): its shell loads this file, and `rm -i` / `mv -i`
# hang waiting for a y/n no one can type, while rg and bat take different flags
# and output than the grep and cat that commands are written for.
if [[ -z $CLAUDECODE ]]; then
  alias ls='eza --icons'
  alias grep='rg'
  alias cat='bat'
  alias rm='rm -i'
  alias cp='cp -i'
  alias mv='mv -i'
fi

alias ll='eza -lah --icons --git'
alias h='tldr'

# conf — jump to a config directory under ~/.config
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

# pkglist — snapshot explicit and AUR package lists into the dotfiles repo
pkglist() {
  local package_dir

  package_dir="$HOME/.config/dotfiles/packages"
  mkdir -p -- "$package_dir" || return

  pacman -Qqen | sort > "$package_dir/native.txt" || return
  pacman -Qqem | sort > "$package_dir/foreign.txt" || return

  print -r -- "updated $package_dir/native.txt"
  print -r -- "updated $package_dir/foreign.txt"
}

# mkcd — create a directory and cd into it
mkcd() {
  [[ -z "$1" ]] && return 1

  mkdir -p -- "$1" && cd -- "$1"
}

# tmpcd — create a scratch directory and cd into it
tmpcd() {
  local dir

  dir="$(mktemp -d)" || return
  cd -- "$dir"
}

# dps — list running docker containers as a compact table
dps() {
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

command -v lazydocker >/dev/null 2>&1 && alias lzd='lazydocker'

# clearff — clear the screen and redraw the fastfetch banner
clearff() {
  clear
  fastfetch
}

alias clear='clearff'
alias di='docker images'

# Directory stack. AUTO_PUSHD is on in core/options.zsh, so every cd already
# records where you were — these make that stack visible and reachable.
# Plain `..` needs no alias: AUTO_CD handles it.
alias d='dirs -v'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# dp — jump back to a directory visited earlier in this shell session.
# zoxide covers frecency across sessions; this covers where you have actually been.
dp() {
  local rows selected index dir display

  if ! command -v fzf >/dev/null 2>&1; then
    dirs -v
    return
  fi

  rows="$(dirs -lv)"

  if [[ -z "$rows" ]]; then
    print 'directory stack is empty'
    return 0
  fi

  selected="$(
    print -r -- "$rows" \
      | while IFS=$'\t' read -r index dir; do
          [[ -z "$dir" ]] && continue
          display="$(_fzf_ansi '36' "$(_fzf_pad "$index" 4)")  $(_fzf_ansi '1' "$(_fzf_truncate "$dir" 72)")"
          print -r -- "$display"$'\t'"$dir"
        done \
      | fzf \
          --ansi \
          --prompt='dir> ' \
          --height=40% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2 \
          --header=$'#     DIRECTORY\nenter cd' \
          --preview='eza -la --icons --git --color=always {2} 2>/dev/null || ls -la {2} 2>/dev/null' \
          --preview-window='right,55%,border-left' \
          --query="${1:-}"
  )" || return

  [[ -z "$selected" ]] && return 0

  dir="${selected#*$'\t'}"
  cd -- "$dir"
}

# Package management shortcuts (Arch / pacman / paru).
# Install, update, and search prefer paru (AUR-aware) and fall back to pacman.

# pi — install packages, preferring paru over pacman
pi() {
  if command -v paru >/dev/null 2>&1; then
    paru -S "$@"
  else
    sudo pacman -S "$@"
  fi
}

# pup — upgrade all packages, preferring paru over pacman
pup() {
  if command -v paru >/dev/null 2>&1; then
    paru -Syu "$@"
  else
    sudo pacman -Syu "$@"
  fi
}

# pss — search packages, preferring paru over pacman
pss() {
  if command -v paru >/dev/null 2>&1; then
    paru -Ss "$@"
  else
    pacman -Ss "$@"
  fi
}

alias prm='sudo pacman -Rns'
alias pin='pacman -Si'
alias pql='pacman -Q'

# porphans — list orphaned packages and offer to remove them
porphans() {
  local orphans

  orphans="$(pacman -Qtdq 2>/dev/null)"

  if [[ -z "$orphans" ]]; then
    print 'no orphan packages'
    return 0
  fi

  print -r -- "$orphans"
  print
  print -rn -- 'remove the packages above? [y/N] '
  local reply
  read -r reply
  [[ "$reply" == [yY] ]] || return 0

  print -r -- "$orphans" | sudo pacman -Rns -
}

# pf — fuzzy-pick packages to install (Tab to multi-select).
pf() {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  local lister installer
  if command -v paru >/dev/null 2>&1; then
    lister='paru -Slq'
    installer='paru -S'
  else
    lister='pacman -Slq'
    installer='sudo pacman -S'
  fi

  eval "$lister" 2>/dev/null \
    | fzf --multi --preview='pacman -Si {1} 2>/dev/null || paru -Si {1} 2>/dev/null' \
          --preview-window='right,60%,border-left' \
    | xargs -ro ${=installer}
}

# pfr — fuzzy-pick installed packages to remove (Tab to multi-select).
pfr() {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'fzf is not installed or not on PATH'
    return 1
  fi

  pacman -Qq 2>/dev/null \
    | fzf --multi --preview='pacman -Qi {1}' \
          --preview-window='right,60%,border-left' \
    | xargs -ro sudo pacman -Rns
}

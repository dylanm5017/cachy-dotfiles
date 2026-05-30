_audit_bytes() {
  local audit_path

  audit_path="$1"

  if [[ -e "$audit_path" ]]; then
    du -sh "$audit_path" 2>/dev/null | awk '{print $1}'
  else
    print -r -- '-'
  fi
}

_audit_count() {
  local count

  count="$(cat 2>/dev/null | wc -l | tr -d ' ')"
  print -r -- "$count"
}

_audit_section() {
  print -r -- ''
  print -r -- "$1"
  print -r -- "${(l:${#1}::-:)}"
}

pacman-cache-plan() {
  _audit_section 'Pacman cache policy'
  print -r -- "Current cache: $(_audit_bytes /var/cache/pacman/pkg)"
  print -r -- ''
  print -r -- 'Recommended manual review:'
  print -r -- '  paccache -dk3'
  print -r -- ''
  print -r -- 'Recommended manual prune after review:'
  print -r -- '  sudo paccache -rk3'
  print -r -- ''
  print -r -- 'This helper does not delete anything.'
}

system-audit() {
  local orphans foreign errors docker_status boot_size root_size home_size pacman_cache downloads_size trash_size steam_size

  orphans="$(pacman -Qdtq 2>/dev/null | _audit_count)"
  foreign="$(pacman -Qqm 2>/dev/null | _audit_count)"
  errors="$(journalctl -p 3 -b --no-pager 2>/dev/null | sed '/^-- No entries --$/d' | _audit_count)"
  pacman_cache="$(_audit_bytes /var/cache/pacman/pkg)"
  downloads_size="$(_audit_bytes "$HOME/Downloads")"
  trash_size="$(_audit_bytes "$HOME/.local/share/Trash")"
  steam_size="$(_audit_bytes "$HOME/.local/share/Steam")"
  root_size="$(df -h / 2>/dev/null | awk 'NR==2 {print $5 " used, " $4 " free"}')"
  home_size="$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $5 " used, " $4 " free"}')"
  boot_size="$(df -h /boot 2>/dev/null | awk 'NR==2 {print $5 " used, " $4 " free"}')"

  if docker info >/dev/null 2>&1; then
    docker_status='available'
  elif command -v docker >/dev/null 2>&1; then
    docker_status='installed, daemon unavailable'
  else
    docker_status='not installed'
  fi

  _audit_section 'System'
  print -r -- "OS:       $(. /etc/os-release 2>/dev/null && print -r -- "${PRETTY_NAME:-unknown}")"
  print -r -- "Kernel:   $(uname -r)"
  print -r -- "Session:  ${XDG_CURRENT_DESKTOP:-unknown} / ${XDG_SESSION_TYPE:-unknown}"

  _audit_section 'Health'
  print -r -- "Failed system units:"
  systemctl --failed --no-pager 2>/dev/null | sed -n '1,12p'
  print -r -- ''
  print -r -- "Failed user units:"
  systemctl --user --failed --no-pager 2>/dev/null | sed -n '1,12p'
  print -r -- ''
  print -r -- "High-priority journal entries this boot: $errors"
  journalctl -p 3 -b --no-pager -n 12 2>/dev/null | sed -n '1,18p'

  _audit_section 'Packages'
  print -r -- "Explicit packages: $(pacman -Qqe 2>/dev/null | _audit_count)"
  print -r -- "Foreign packages:  $foreign"
  print -r -- "Orphans:           $orphans"
  print -r -- ''
  print -r -- 'Foreign packages:'
  pacman -Qqm 2>/dev/null | sed -n '1,24p'
  print -r -- ''
  print -r -- 'Orphans to review, not auto-remove:'
  pacman -Qdtq 2>/dev/null | sed -n '1,24p'

  _audit_section 'Storage'
  print -r -- "Root:         ${root_size:-unknown}"
  print -r -- "Home:         ${home_size:-unknown}"
  print -r -- "Boot:         ${boot_size:-unknown}"
  print -r -- "Pacman cache: $pacman_cache"
  print -r -- "Downloads:    $downloads_size"
  print -r -- "Trash:        $trash_size"
  print -r -- "Steam:        $steam_size"

  _audit_section 'Dev services'
  print -r -- "Docker: $docker_status"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true

  _audit_section 'Suggested next commands'
  print -r -- 'pacman-cache-plan'
  print -r -- 'journalctl -p 3 -b --no-pager'
  print -r -- 'systemctl status nftables.service bluetooth.service --no-pager'
  print -r -- 'paru -Syu'
}

_dev_package_manager() {
  local dir

  dir="${1:-$PWD}"

  if [[ -f "$dir/pnpm-lock.yaml" ]]; then
    print -r -- 'pnpm'
  elif [[ -f "$dir/yarn.lock" ]]; then
    print -r -- 'yarn'
  elif [[ -f "$dir/bun.lock" || -f "$dir/bun.lockb" ]]; then
    print -r -- 'bun'
  elif [[ -f "$dir/package-lock.json" || -f "$dir/package.json" ]]; then
    print -r -- 'npm'
  else
    print -r -- '-'
  fi
}

devhealth() {
  local docker_status package_manager git_state

  package_manager="$(_dev_package_manager "$PWD")"

  if docker info >/dev/null 2>&1; then
    docker_status='available'
  elif command -v docker >/dev/null 2>&1; then
    docker_status='installed, daemon unavailable'
  else
    docker_status='not installed'
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_state="$(git status --short --branch 2>/dev/null | sed -n '1,12p')"
  else
    git_state='not in a git repository'
  fi

  _audit_section 'Runtime'
  print -r -- "Node:       $(node --version 2>/dev/null || print -r -- '-')"
  print -r -- "npm:        $(npm --version 2>/dev/null || print -r -- '-')"
  print -r -- "Bun:        $(bun --version 2>/dev/null || print -r -- '-')"
  print -r -- "fnm default: $(fnm default 2>/dev/null || print -r -- '-')"
  print -r -- ''
  print -r -- 'Installed fnm versions:'
  fnm list 2>/dev/null | sed -n '1,12p'

  _audit_section 'Project'
  print -r -- "Directory:       $PWD"
  print -r -- "Package manager: $package_manager"
  print -r -- ''
  print -r -- "$git_state"
  if [[ -f package.json ]] && command -v jq >/dev/null 2>&1; then
    print -r -- ''
    print -r -- 'Scripts:'
    jq -r '.scripts // {} | to_entries[] | "  " + .key + ": " + .value' package.json 2>/dev/null | sed -n '1,16p'
  fi

  _audit_section 'Tooling'
  for command_name in git rg fd fzf bat eza zoxide jq rga nvim code docker paru; do
    printf '%-8s %s\n' "$command_name" "$(command -v "$command_name" 2>/dev/null || print -r -- '-')"
  done
  print -r -- "Docker:  $docker_status"

  _audit_section 'Common caches'
  print -r -- "npm:        $(_audit_bytes "$HOME/.npm")"
  print -r -- "Playwright: $(_audit_bytes "$HOME/.cache/ms-playwright")"
  print -r -- "Cypress:    $(_audit_bytes "$HOME/.cache/Cypress")"
  print -r -- "paru:       $(_audit_bytes "$HOME/.cache/paru")"
  print -r -- "node-gyp:   $(_audit_bytes "$HOME/.cache/node-gyp")"
}

_theme_read_ini() {
  local file key

  file="$1"
  key="$2"

  [[ -f "$file" ]] || {
    print -r -- '-'
    return
  }

  awk -F= -v key="$key" '$1 == key {print $2; found=1} END {if (!found) print "-"}' "$file"
}

theme-audit() {
  local kdeglobals gtk3 gtk4 kvantum alacritty

  kdeglobals="$HOME/.config/kdeglobals"
  gtk3="$HOME/.config/gtk-3.0/settings.ini"
  gtk4="$HOME/.config/gtk-4.0/settings.ini"
  kvantum="$HOME/.config/Kvantum/kvantum.kvconfig"
  alacritty="$HOME/.config/alacritty/alacritty.toml"

  _audit_section 'KDE'
  print -r -- "Look and feel: $(_theme_read_ini "$kdeglobals" LookAndFeelPackage)"
  print -r -- "Widget style:  $(_theme_read_ini "$kdeglobals" widgetStyle)"
  print -r -- "Icon theme:    $(_theme_read_ini "$kdeglobals" Theme | sed -n '1p')"
  print -r -- "Font:          $(_theme_read_ini "$kdeglobals" font)"
  print -r -- "Fixed font:    $(_theme_read_ini "$kdeglobals" fixed)"

  _audit_section 'Kvantum'
  print -r -- "Theme: $(_theme_read_ini "$kvantum" theme)"
  print -r -- 'Available Catppuccin Kvantum themes:'
  find /usr/share/Kvantum "$HOME/.config/Kvantum" -maxdepth 2 -type f -name '*.kvconfig' 2>/dev/null \
    | sed 's#^.*/##; s#\.kvconfig$##' \
    | sort -u \
    | rg -i 'catppuccin|mocha|frappe|macchiato' || true

  _audit_section 'GTK'
  print -r -- "GTK3 theme:  $(_theme_read_ini "$gtk3" gtk-theme-name)"
  print -r -- "GTK4 theme:  $(_theme_read_ini "$gtk4" gtk-theme-name)"
  print -r -- "GTK3 icons:  $(_theme_read_ini "$gtk3" gtk-icon-theme-name)"
  print -r -- "GTK4 icons:  $(_theme_read_ini "$gtk4" gtk-icon-theme-name)"
  print -r -- "GTK3 cursor: $(_theme_read_ini "$gtk3" gtk-cursor-theme-name)"
  print -r -- "GTK4 cursor: $(_theme_read_ini "$gtk4" gtk-cursor-theme-name)"
  print -r -- ''
  print -r -- 'Installed GTK Catppuccin themes:'
  find /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes" -maxdepth 2 -type d 2>/dev/null \
    | sed 's#^.*/##' \
    | sort -u \
    | rg -i 'catppuccin|mocha' || print -r -- '  none found'

  _audit_section 'Terminal'
  if [[ -f "$alacritty" ]]; then
    rg -n '^(opacity|import|family|size)\b' "$alacritty" 2>/dev/null | sed -n '1,24p'
  else
    print -r -- 'Alacritty config not found'
  fi

  _audit_section 'Recommended alignment'
  print -r -- 'Keep: Catppuccin Mocha, Papirus-Dark, Iosevka Nerd Font.'
  print -r -- 'Use theme-audit after installing a Catppuccin GTK theme before changing GTK from Breeze.'
}

alias sysa='system-audit'
alias dha='devhealth'
alias tha='theme-audit'
alias pcp='pacman-cache-plan'

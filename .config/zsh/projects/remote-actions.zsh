_rproj_mount() {
  local name host remote_path local_path description

  IFS=$'\t' read -r name host remote_path local_path description <<< "$1"

  _rproj_require sshfs || return

  if _rproj_is_mounted "$local_path"; then
    return 0
  fi

  if [[ -e "$local_path" && ! -d "$local_path" ]]; then
    print -u2 "remote project mount path is not a directory: $local_path"
    return 1
  fi

  mkdir -p -- "$local_path" || return
  sshfs "$(_rproj_remote "$host" "$remote_path")" "$local_path"
}

_rproj_status() {
  local name host remote_path local_path description state remote

  IFS=$'\t' read -r name host remote_path local_path description <<< "$1"

  state="$(_rproj_mount_state "$local_path")"
  remote="$(_rproj_remote "$host" "$remote_path")"

  print -r -- "Name:        $name"
  print -r -- "Description: $description"
  print -r -- "Remote:      $remote"
  print -r -- "Local:       $local_path"
  print -r -- "State:       $state"

  if [[ "$state" == 'mounted' ]]; then
    print -r -- ''
    findmnt --mountpoint "$local_path"
  fi
}

_rproj_status_all() {
  local only_mounted row name host remote_path local_path description state remote shown

  only_mounted="$1"
  shown=0

  if [[ "$only_mounted" != 'mounted-only' ]]; then
    printf '%-18s %-10s %-32s %s\n' 'NAME' 'STATE' 'LOCAL' 'REMOTE'
  fi

  while IFS=$'\t' read -r name host remote_path local_path description; do
    state="$(_rproj_mount_state "$local_path")"

    if [[ "$only_mounted" == 'mounted-only' && "$state" != 'mounted' ]]; then
      continue
    fi

    remote="$(_rproj_remote "$host" "$remote_path")"
    printf '%-18s %-10s %-32s %s\n' "$name" "$state" "$local_path" "$remote"
    shown=1
  done < <(_rproj_rows)

  if (( ! shown )) && [[ "$only_mounted" == 'mounted-only' ]]; then
    print -r -- 'no remote projects are mounted'
  fi
}
_rproj_busy_processes() {
  local local_path

  local_path="$1"

  print -u2 ''
  print -u2 "Processes using $local_path:"

  if command -v lsof >/dev/null 2>&1; then
    lsof +D "$local_path" 2>/dev/null
    return
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser -vm "$local_path"
    return
  fi

  print -u2 'lsof and fuser are not installed or not on PATH'
}

_rproj_unmount() {
  local mode name host remote_path local_path description

  mode="$1"
  IFS=$'\t' read -r name host remote_path local_path description <<< "$2"

  _rproj_require fusermount3 || return

  if ! _rproj_is_mounted "$local_path"; then
    print -r -- "$name is not mounted: $local_path"
    return 0
  fi

  case "$mode" in
    force)
      fusermount3 -uz "$local_path"
      ;;
    normal)
      fusermount3 -u "$local_path" || {
        _rproj_busy_processes "$local_path"
        return 1
      }
      ;;
    *)
      print -u2 "unknown unmount mode: $mode"
      return 1
      ;;
  esac
}

_rproj_mounted_rows() {
  local name host remote_path local_path description

  while IFS=$'\t' read -r name host remote_path local_path description; do
    _rproj_is_mounted "$local_path" || continue
    print -r -- "$name"$'\t'"$host"$'\t'"$remote_path"$'\t'"$local_path"$'\t'"$description"
  done < <(_rproj_rows)
}
_rproj_open() {
  local action row name host remote_path local_path description

  action="$1"
  row="$2"
  IFS=$'\t' read -r name host remote_path local_path description <<< "$row"

  case "$action" in
    status)
      _rproj_status "$row"
      ;;
    unmount)
      _rproj_unmount normal "$row"
      ;;
    force-unmount)
      _rproj_unmount force "$row"
      ;;
    cd)
      _rproj_mount "$row" || return
      cd -- "$local_path"
      ;;
    nvim)
      _rproj_mount "$row" || return
      cd -- "$local_path" || return
      if command -v nvim >/dev/null 2>&1; then
        nvim .
      else
        print -u2 'nvim is not installed or not on PATH'
      fi
      ;;
    code|*)
      _rproj_mount "$row" || return
      cd -- "$local_path" || return
      if command -v code >/dev/null 2>&1; then
        code .
      else
        print -u2 'code is not installed or not on PATH'
      fi
      ;;
  esac
}

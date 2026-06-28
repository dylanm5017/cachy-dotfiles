_cockpit_doctor_tool() {
  local label command_name required tool_status tool_path

  label="$1"
  command_name="$2"
  required="$3"

  if tool_path="$(whence -p "$command_name" 2>/dev/null)" && [[ -n "$tool_path" ]]; then
    tool_status='ok'
  elif tool_path="$(command -v "$command_name" 2>/dev/null)" && [[ -n "$tool_path" ]]; then
    tool_status='ok'
  elif [[ "$required" == 'required' ]]; then
    tool_status='missing'
    tool_path='required'
  else
    tool_status='optional'
    tool_path='not installed'
  fi

  printf '%-18s %-10s %s\n' "$label" "$tool_status" "$tool_path"
}

_cockpit_doctor() {
  local root config recent_file notes_dir row name host remote_path local_path description count

  print -r -- 'Cockpit doctor'
  print -r -- '--------------'

  print -r -- ''
  print -r -- 'Tools'
  _cockpit_doctor_tool 'fzf' fzf required
  _cockpit_doctor_tool 'git' git required
  _cockpit_doctor_tool 'jq' jq required
  _cockpit_doctor_tool 'code' code optional
  _cockpit_doctor_tool 'nvim' nvim optional
  _cockpit_doctor_tool 'alacritty' alacritty optional
  _cockpit_doctor_tool 'xdg-open' xdg-open optional
  _cockpit_doctor_tool 'gh' gh optional
  _cockpit_doctor_tool 'yazi' yazi optional
  _cockpit_doctor_tool 'sshfs' sshfs optional
  _cockpit_doctor_tool 'fusermount3' fusermount3 optional
  _cockpit_doctor_tool 'atuin' atuin optional
  _cockpit_doctor_tool 'mise' mise optional

  print -r -- ''
  print -r -- 'Project roots'
  for root in "$HOME/Projects" "$HOME/work"; do
    if [[ -d "$root" ]]; then
      print -r -- "ok        $root"
    else
      print -r -- "missing   $root"
    fi
  done

  print -r -- ''
  print -r -- 'Remote projects'
  config="$(_rproj_config_file)"
  if [[ -f "$config" ]]; then
    count=0
    while IFS=$'\t' read -r name host remote_path local_path description; do
      [[ -z "$name" ]] && continue
      (( count++ ))
    done < <(_rproj_rows 2>/dev/null)
    print -r -- "ok        $config"
    print -r -- "entries   $count"
  else
    print -r -- "missing   $config"
  fi

  print -r -- ''
  print -r -- 'State paths'
  recent_file="$(_cockpit_recent_file)"
  notes_dir="$(_cockpit_notes_dir)"
  print -r -- "recent    $recent_file"
  print -r -- "notes     $notes_dir"
}

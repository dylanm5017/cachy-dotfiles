_rproj_project_completion_items() {
  local name host remote_path local_path description label

  while IFS=$'\t' read -r name host remote_path local_path description; do
    label="$description"
    [[ -z "$label" ]] && label="$host:$remote_path"
    print -r -- "$name:$label"
  done < <(_rproj_rows 2>/dev/null)
}

_rproj_mounted_completion_items() {
  local name host remote_path local_path description label

  while IFS=$'\t' read -r name host remote_path local_path description; do
    label="$description"
    [[ -z "$label" ]] && label="$host:$remote_path"
    print -r -- "$name:$label"
  done < <(_rproj_mounted_rows 2>/dev/null)
}

_rproj_complete_projects() {
  local -a projects

  projects=("${(@f)$(_rproj_project_completion_items)}")
  _describe -t remote-projects 'remote project' projects
}

_rproj_complete_mounted_projects() {
  local -a projects

  projects=("${(@f)$(_rproj_mounted_completion_items)}")
  _describe -t mounted-remote-projects 'mounted remote project' projects
}

_rproj_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '--cd[cd into project]:remote project:_rproj_complete_projects' \
    '--nvim[open project in nvim]:remote project:_rproj_complete_projects' \
    '--status[show project status]:remote project:_rproj_complete_projects' \
    '--unmount[unmount project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--force-unmount[lazy force-unmount project]:mounted remote project:_rproj_complete_mounted_projects' \
    '--add[add a remote project]' \
    '*:remote project:_rproj_complete_projects'
}

_rproj_add_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '1:project name:' \
    '2:ssh host:_hosts' \
    '3:remote path:' \
    '4:local mount path:_files -/' \
    '*:description:'
}

_rproj_status_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-m --mounted)'{-m,--mounted}'[show only mounted projects]'
}

_rproj_unmount_completion() {
  _arguments -s \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-f --force)'{-f,--force}'[lazy force-unmount project]' \
    '*:mounted remote project:_rproj_complete_mounted_projects'
}
if (( $+functions[compdef] )); then
  compdef _rproj_completion rproj rp
  compdef _rproj_add_completion rproj-add rpa
  compdef _rproj_status_completion rproj-status rps
  compdef _rproj_unmount_completion rproj-unmount rpu
fi

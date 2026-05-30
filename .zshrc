typeset -a _dyl_zsh_modules=(
  history
  options
  completion
  env
  plugins
  fzf
  fzf-tools
  aliases
  git
  node
  projects
  remote-projects
  newproj
  cockpit
  audits
  keybindings
  exports
)

for _dyl_zsh_module in "${_dyl_zsh_modules[@]}"; do
  _dyl_zsh_file="$HOME/.config/zsh/${_dyl_zsh_module}.zsh"
  [[ -r "$_dyl_zsh_file" ]] && source "$_dyl_zsh_file"
done

unset _dyl_zsh_file _dyl_zsh_module _dyl_zsh_modules

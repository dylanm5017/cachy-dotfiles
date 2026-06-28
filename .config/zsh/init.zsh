_dyl_zsh_dir="${${(%):-%N}:A:h}"

typeset -a _dyl_zsh_modules=(
  core/history.zsh
  core/options.zsh
  core/completion.zsh
  core/env.zsh
  core/mise.zsh
  core/plugins.zsh
  lib/fzf.zsh
  commands/aliases.zsh
  commands/yazi.zsh
  commands/git.zsh
  commands/node.zsh
  projects/local.zsh
  projects/remote-data.zsh
  projects/cockpit-model.zsh
  projects/cockpit-ui.zsh
  projects/cockpit-state.zsh
  projects/remote-ui.zsh
  projects/remote-actions.zsh
  projects/remote-commands.zsh
  projects/remote-completions.zsh
  projects/new.zsh
  projects/cockpit-actions.zsh
  projects/cockpit-doctor.zsh
  projects/cockpit.zsh
  commands/audits.zsh
  core/keybindings.zsh
)

for _dyl_zsh_module in "${_dyl_zsh_modules[@]}"; do
  _dyl_zsh_file="$_dyl_zsh_dir/$_dyl_zsh_module"
  [[ -r "$_dyl_zsh_file" ]] && source "$_dyl_zsh_file"
done

# Local, untracked secrets (credentials, tokens). Kept out of the dotfiles repo.
_dyl_zsh_secrets="$_dyl_zsh_dir/secrets.zsh"
[[ -r "$_dyl_zsh_secrets" ]] && source "$_dyl_zsh_secrets"

unset _dyl_zsh_file _dyl_zsh_module _dyl_zsh_modules _dyl_zsh_dir _dyl_zsh_secrets

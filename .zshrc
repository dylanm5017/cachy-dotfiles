_dyl_zsh_init="$HOME/.config/zsh/init.zsh"
[[ -r "$_dyl_zsh_init" ]] && source "$_dyl_zsh_init"
unset _dyl_zsh_init

# BEGIN Smoky Plum managed fzf
smoky_plum_fzf="${XDG_CONFIG_HOME:-$HOME/.config}/smoky-plum/fzf/current.sh"
[ -r "$smoky_plum_fzf" ] && . "$smoky_plum_fzf"
unset smoky_plum_fzf
# END Smoky Plum managed fzf

# Secrets/credentials live in ~/.config/zsh/secrets.zsh (gitignored), sourced by init.zsh.
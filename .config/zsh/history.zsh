HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history   # make sure this is set

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

setopt SHARE_HISTORY      # share across sessions
setopt INC_APPEND_HISTORY # write commands immediately
setopt APPEND_HISTORY     # append instead of overwrite
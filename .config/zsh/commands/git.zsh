alias gs='git status'
alias gc='git commit'
alias gp='git pull'
alias gbr='git branch -r'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git switch'

_git_branch_rows() {
  local branch sha age scope color current display

  git for-each-ref --format='%(refname:short)%09%(objectname:short)%09%(committerdate:relative)' refs/heads refs/remotes \
    | command grep -v '^[^/]*/HEAD' \
    | sort -f \
    | while IFS=$'\t' read -r branch sha age; do
        [[ -z "$branch" ]] && continue

        scope='LOC'
        color='36'
        if git show-ref --verify --quiet "refs/remotes/$branch"; then
          scope='REM'
          color='35'
        fi

        current=' '
        [[ "$branch" == "$(git branch --show-current 2>/dev/null)" ]] && current='*'

        display="$(_fzf_ansi "$color" "$(_fzf_pad "$scope" 3)")  $current $(_fzf_ansi '1' "$(_fzf_pad "$branch" 42)")  $(_fzf_ansi '2' "$(_fzf_pad "$sha" 8)")  $(_fzf_ansi '2' "$(_fzf_truncate "$age" 18)")"
        print -r -- "$display"$'\t'"$branch"
      done
}

gbs() {
  local selected local_branch

  selected=$(
    _git_branch_rows \
      | fzf \
          --ansi \
          --prompt='branch> ' \
          --height=80% \
          --layout=reverse \
          --border \
          --delimiter=$'\t' \
          --with-nth=1 \
          --nth=1,2 \
          --header=$'TYPE  BRANCH                                      SHA       UPDATED\nenter switch | local branches switch directly | remote branches track when needed' \
          --preview='git log --oneline --decorate --color=always -20 {2}' \
          --preview-window='right,60%,border-left'
  )

  [[ -z "$selected" ]] && return 0
  selected="${selected#*$'\t'}"

  if git show-ref --verify --quiet "refs/remotes/$selected"; then
    local_branch="${selected#*/}"
    git show-ref --verify --quiet "refs/heads/$local_branch" \
      && git switch "$local_branch" \
      || git switch --track "$selected"
  else
    git switch "$selected"
  fi
}

#!/bin/bash

git clone --bare <your-repo-url> $HOME/.dotfiles

alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

dot checkout
dot config --local status.showUntrackedFiles no
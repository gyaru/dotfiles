#!/bin/zsh
# .zshrc

#  envs/exports
source $HOME/.zshenv

# load danua
source $XDG_DATA_HOME/danua/init.zsh

# prompt
source $SCRIPTS/prompt.zsh

# load syntax highlighting plugin
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# script functions
source $SCRIPTS/update-git		# lazy dotfiles updates
source $SCRIPTS/ssh-aliases		# ssh aliases/functions
source $SCRIPTS/randomfunctions # lazy functions

# dircolors
eval `dircolors ~/.dircolors`
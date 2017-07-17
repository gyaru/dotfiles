#!/bin/zsh
# .zshrc

# keybindings
source $XDG_CONFIG_HOME/zsh/key-bindings.zsh

# disable C-s C-q
stty start undef
stty stop undef

# colours
autoload -Uz colors && colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"
eval `dircolors ~/.dircolors`

# prompt
setopt prompt_subst			# prompt substitution options
source $XDG_CONFIG_HOME/zsh/git.zsh	# git functions for prompt
source $XDG_CONFIG_HOME/zsh/prompt.zsh	# actual prompt

# beep
unsetopt beep				# no beep pls

# changing directories
setopt auto_cd				# perform cd if the command issued can't be executed and is a name of a directory
setopt cdable_vars			# try to expand the expression if the argument isn't a directory
setopt auto_pushd			# make cd push the old directory onto the directory stack
setopt pushd_ignore_dups		# don't push multiple copies of the same onto the directory stack

# set history file
if [ -z "$HISTFILE" ]; then
    HISTFILE=$HOME/.zsh_history
fi

# set history settings
HISTSIZE=10000				# set the
SAVEHIST=10000				# history size
setopt extended_history			# timestamp infront of every command
setopt hist_expire_dups_first		# kill dupes first
setopt hist_ignore_dups			# ignore dupes
setopt hist_ignore_space		# don't add commands that starts with space
setopt hist_verify			# don't execute ! commands
setopt inc_append_history		# append to the history incrementally
setopt append_history			# append history to the history file
setopt share_history			# share command history data

# completion
source $XDG_CONFIG_HOME/zsh/completion.zsh	# fixing completion "bugs"
setopt always_to_end				# move cursor to the end of the world when completed
setopt auto_menu				# use menu completion when double tap tab
setopt complete_in_word				# do not set the cursor to the end when completion is started
autoload compinit && compinit			# load and start

# load syntax highlighting plugin
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# load tty colour scheme
if [ "$TERM" = "linux" ]; then
  /bin/echo -e "
  \e]P02b303b
  \e]P1bf616a
  \e]P2a3be8c
  \e]P3ebcb8b
  \e]P48fa1b3
  \e]P5b48ead
  \e]P696b5b4
  \e]P7c0c5ce
  \e]P865737e
  \e]P9bf616a
  \e]PAa3be8c
  \e]PBebcb8b
  \e]PC8fa1b3
  \e]PDb48ead
  \e]PE96b5b4
  \e]PFeff1f5
  "
  # get rid of artifacts
  clear
fi

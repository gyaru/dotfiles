#!/bin/zsh
# .zprofile

# panel fifo
export PANEL_FIFO="/tmp/panel-fifo"

# source .zshrc
[[ -f ~/.zshrc ]] && . ~/.zshrc
if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec startx
fi

PATH="$PATH:$(ruby -e 'puts Gem.user_dir')/bin"

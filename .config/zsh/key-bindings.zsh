#!/bin/zsh
# make sure the terminal is in application mode
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

bindkey -e 				# Use emacs key bindings
bindkey '\ew' kill-region 		# [Esc-w] - Kill from the cursor to the mark
bindkey '^[[1;5C' forward-word		# [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word		# [Ctrl-LeftArrow] - move backward one word
bindkey '^?' backward-delete-char	# [Backspace] - delete backward
bindkey '^r' history-incremental-search-backward      # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.
if [[ "${terminfo[kpp]}" != "" ]]; then
  bindkey "${terminfo[kpp]}" up-line-or-history       # [PageUp] - Up a line of history
fi
if [[ "${terminfo[knp]}" != "" ]]; then
  bindkey "${terminfo[knp]}" down-line-or-history     # [PageDown] - Down a line of history
fi

# start typing + [Up-Arrow] - fuzzy find history forward
if [[ "${terminfo[kcuu1]}" != "" ]]; then
  autoload -U up-line-or-beginning-search
  zle -N up-line-or-beginning-search
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
  autoload -U down-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

if [[ "${terminfo[khome]}" != "" ]]; then	# [Home] - Go to beginning of line
  bindkey "${terminfo[khome]}" beginning-of-line
fi
if [[ "${terminfo[kend]}" != "" ]]; then	# [End] - Go to end of line
  bindkey "${terminfo[kend]}" end-of-line
fi

bindkey ' ' magic-space # [Space] - do history expansion

if [[ "${terminfo[kcbt]}" != "" ]]; then	# [Shift-Tab] - move through the completion menu backwards
  bindkey "${terminfo[kcbt]}" reverse-menu-complete 
fi

if [[ "${terminfo[kdch1]}" != "" ]]; then	# [Delete] - delete forward
  bindkey "${terminfo[kdch1]}" delete-char
else
  bindkey "^[[3~" delete-char
  bindkey "^[3;5~" delete-char
  bindkey "\e[3~" delete-char
fi

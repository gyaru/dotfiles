#!/bin/zsh
zmodload -i zsh/complist

# case-insensitive (all),partial-word and then substring completion
if [ "x$CASE_SENSITIVE" = "xtrue" ]; then
  zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unset CASE_SENSITIVE
else
  if [ "x$HYPHEN_INSENSITIVE" = "xtrue" ]; then
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
    unset HYPHEN_INSENSITIVE
  else
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  fi
fi

zstyle ':completion:*' list-colors ''
bindkey -M menuselect '^o' accept-and-infer-next-history

zstyle ':completion:*:*:*:*:*' menu select

# completion for kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.cache/zsh

# don't complete shitty users
zstyle ':completion:*:*:*:users' ignored-patterns \
        avahi bin colord nvidia-persistenced ntp rtkit polkitd uuidd \
        systemd-bus-proxy systemd-coredump systemd-journal-gateway systemd-journal-remote \
        systemd-journal-upload systemd-network systemd-resolve systemd-timesync '_*'        # thanks systemd

# ... unless we really want to.
zstyle '*' single-ignored show

# completion waiting
expand-or-complete-with-dots() {
  echo -n "\e[31m...\e[0m"
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots
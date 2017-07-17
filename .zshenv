#!/bin/zsh
# .zshenv
 
# XDG defaults
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DOWNLOAD_DIR=/mnt/iowa/downloads

# defaults
export BROWSER=firefox-beta

# standard path
export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin"

# perl
export PATH="$PATH:/usr/bin/vendor_perl:/usr/bin/core_perl"

# golang
export GOPATH="$HOME/gocode"
export PATH="$PATH:$GOPATH/bin"

# ruby
export PATH="$PATH:$HOME/.gem/ruby/2.2.0/bin"
export PATH="$PATH:$HOME/.gem/ruby/2.4.0/bin"

# no wineshit
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# gtk - disable atk-bridge
export NO_AT_BRIDGE=1

# steam "if using a distribution that doesn't have proper compatible tray support"
export STEAM_FRAME_FORCE_CLOSE=0

# qt
export QT_STYLE_OVERRIDE=GTK+

# aliases
alias mkdir='mkdir -pv'
alias ls='ls --color=auto -hF --group-directories-first'
alias vim='nvim'
alias ping='ping -c 5'
alias du='du -h'
alias df='df -h'
alias pdflatex='pdflatex -synctex=1 -interaction=nonstopmode'
alias neofetch='neofetch --line_wrap off --ascii --shell_version on --cpu_shorthand tiny --block_width 3 --disk_display info --memory_display info --ascii_logo_size small'
alias irc='mosh atago-eru.me --server="LANG=en_US.UTF-8 mosh-server" -- bin/irc'

# functions
qrcode() {
    echo $@ | curl -F-=\<- qrenco.de
}

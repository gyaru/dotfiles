# .zshenv
 
# XDG defaults
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_BIN_HOME=$HOME/.local/bin
export XDG_LIB_HOME=$HOME/.local/lib
export XDG_CACHE_HOME=$HOME/.cache

# standard path
#export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/vendor_perl:/usr/bin/core_perl:$HOME/.gem/ruby/2.2.0/bin"
export PATH="$HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/bin"

# perl
export PATH="$PATH:/usr/bin/vendor_perl:/usr/bin/core_perl"

# ruby
export PATH="$PATH:$HOME/.gem/ruby/2.2.0/bin"

# scripts
export SCRIPTS=$HOME/scripts

# wine
export WINEDIR=/mnt/amatsukaze/wine
export WINEPREFIX=$WINEDIR/.wine
export WINEARCH=win32
export WINEDLLOVERRIDES='winemenubuilder.exe=d' # prevents wine from populating with menu entries/desktop links

# gtk - disable atk-bridge
export NO_AT_BRIDGE=1

# go
export GOPATH="$HOME/gocode"
export PATH="$PATH:$GOPATH/bin"

# aliases
alias mkdir='mkdir -pv'
alias ls='ls --color=auto -hF --group-directories-first'
alias ping='ping -c 5'
alias du='du -h'
alias df='df -h'

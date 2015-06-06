# .zshrc

# source .zshenv
source $HOME/.zshenv 

# load antigen
source $XDG_DATA_HOME/antigen/antigen.zsh
antigen use oh-my-zsh
antigen apply

# antigen start cache
function dots-start-capture () {
    dots__capture__file=$1
    echo "Starting -antigen-load capture into $dots__capture__file"

    # remove prior cache file
    [ -f "$dots__capture__file" ] && rm -f $dots__capture__file
    
    # save current -antigen-load and shim in a version
    # that logs calls to the catpure file
    eval "function -dots-original$(functions -- -antigen-load)"
    function -antigen-load () {
        echo -antigen-load "$@" >>! $dots__capture__file
        -dots-original-antigen-load "$@"
    }
}

# antigen stop cache
function dots-stop-capture () {
    echo "Captured -antigen-load calls into $dots__capture__file"
    unset dots__capture__file
    eval "function $(functions -- -dots-original-antigen-load | sed 's/-dots-original//')"
}

if [ -f "$XDG_CACHE_HOME/zdotcache" ] ; then
    source "$XDG_CACHE_HOME/zdotcache"
else
    dots-start-capture "$XDG_CACHE_HOME/zdotcache"

    # antigen
    # plugins
	antigen bundle zsh-users/zsh-syntax-highlighting
    # oh-my-zsh plugins
	antigen bundle robbyrussell/oh-my-zsh plugins/systemd
	antigen bundle robbyrussell/oh-my-zsh plugins/git
	antigen bundle robbyrussell/oh-my-zsh plugins/cp
	antigen bundle robbyrussell/oh-my-zsh plugins/rsync

	# personal stuff
	# theme
	antigen theme Eryla/zshstuff themes/myucel
	# plugins
	antigen bundle Eryla/zshstuff plugins/completion-waiting-dots

	antigen apply
   dots-stop-capture
fi

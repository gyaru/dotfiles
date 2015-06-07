# .zshrc

#  envs/exports
source $HOME/.zshenv

# load antigen
source $XDG_DATA_HOME/antigen/antigen.zsh
antigen use oh-my-zsh
antigen apply

# antigen plugins
antigen-plugins () {
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
}

# script functions
source $SCRIPTS/update-git		# lazy dotfiles updates
source $SCRIPTS/ssh-aliases		# ssh aliases/functions
source $SCRIPTS/antigen-cache	# antigen caching

# dircolors
eval `dircolors ~/.dircolors`

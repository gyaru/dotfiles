# .zshrc

#  envs/exports
source $HOME/.zshenv

# load zgen
source $XDG_DATA_HOME/zgen/zgen.zsh

# load plugins

if ! zgen saved; then
	echo "generating a new zgen save"

	# oh-my-zsh base
	zgen oh-my-zsh
	# plugins
	zgen oh-my-zsh plugins/systemd
	zgen oh-my-zsh plugins/git
	zgen oh-my-zsh plugins/cp
	zgen oh-my-zsh plugins/rsync
	zgen load zsh-users/zsh-syntax-highlighting
	zgen load Eryla/zshstuff plugins/completion-waiting-dots
	# theme
	zgen load Eryla/zshstuff themes/myucel
	# lets roll
	zgen save
fi

# script functions
source $SCRIPTS/update-git		# lazy dotfiles updates
source $SCRIPTS/ssh-aliases		# ssh aliases/functions

# dircolors
eval `dircolors ~/.dircolors`

#!/bin/sh

cd "${0%/*}" || exit

DC="$HOME"/.config
GC="${0%/*}/.config"

# home
cp -v "$HOME"/.xinitrc 										.xinitrc
cp -v "$HOME"/.xserverrc 										.xserverrc

# .zsh
cp -v "$HOME"/.zprofile 										.zprofile
cp -v "$HOME"/.zshenv 										.zshenv
cp -v "$HOME"/.zshrc 											.zshrc
cp -v "$HOME"/.config/zsh/completion.zsh 							.config/zsh/completion.zsh
cp -v "$HOME"/.config/zsh/git.zsh 									.config/zsh/git.zsh
cp -v "$HOME"/.config/zsh/key-bindings.zsh 							.config/zsh/key-bindings.zsh
cp -v "$HOME"/.config/zsh/prompt.zsh 								.config/zsh/prompt.zsh

# bspwm
cp -v "$HOME"/.config/bspwm/bspwmrc									.config/bspwm/bspwmrc

# compton
cp -v "$HOME"/.config/compton/config								.config/compton/config

# fontconfig
cp -v "$HOME"/.config/fontconfig/conf.d/20-dpi.conf					.config/fontconfig/conf.d/20-dpi.conf
cp -v "$HOME"/.config/fontconfig/conf.d/51-noto-color-emoji.conf	.config/fontconfig/conf.d/51-noto-color-emoji.conf
cp -v "$HOME"/.config/fontconfig/conf.d/68-color-emoji.conf			.config/fontconfig/conf.d/68-color-emoji.conf

# gtk 2
cp -v "$HOME"/.gtkrc-2.0										.gtkrc-2.0

# gtk 3
cp -v "$HOME"/.config/gtk-3.0/gtk.css								.config/gtk-3.0/gtk.css
cp -v "$HOME"/.config/gtk-3.0/settings.ini							.config/gtk-3.0/settings.ini

# lemonbar / panel script
cp -v "$HOME"/.config/lemonbar/config								.config/lemonbar/config
cp -v "$HOME"/.config/lemonbar/panel								.config/lemonbar/panel
cp -v "$HOME"/.config/lemonbar/panel_bar							.config/lemonbar/panel_bar
cp -v "$HOME"/.config/lemonbar/plugins/bluetooth					.config/lemonbar/plugins/bluetooth
cp -v "$HOME"/.config/lemonbar/plugins/mpd							.config/lemonbar/plugins/mpd
cp -v "$HOME"/.config/lemonbar/plugins/toggle_output				.config/lemonbar/plugins/toggle_output
cp -v "$HOME"/.config/lemonbar/plugins/volume						.config/lemonbar/plugins/volume

# mpd
cp -v "$HOME"/.config/mpd/mpd.conf									.config/mpd/mpd.conf

# mpv
cp -v "$HOME"/.config/mpv/config									.config/mpv/config
cp -v "$HOME"/.config/mpv/input.conf								.config/mpv/input.conf

# ncmpcpp
cp -v "$HOME"/.config/ncmpcpp/config								.config/ncmpcpp/config

# nvim
cp -v "$HOME"/.config/nvim/init.vim									.config/nvim/init.vim
cp -v "$HOME"/.config/nvim/keybindings.vim							.config/nvim/keybindings.vim
cp -v "$HOME"/.config/nvim/plugins.vim								.config/nvim/plugins.vim

# pacaur
cp -v "$HOME"/.config/pacaur/config									.config/pacaur/config

# sxhkd
cp -v "$HOME"/.config/sxhkd/sxhkdrc									.config/sxhkd/sxhkdrc

# systemd
cp -v "$HOME"/.config/systemd/user/mpd.socket						.config/systemd/user/mpd.socket

# termite
cp -v "$HOME"/.config/termite/config								.config/termite/config
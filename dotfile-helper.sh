#!/bin/sh

cd "${0%/*}"

DC="~/.config"
GC="${0%/*}/.config"

# home
cp -v ~/.xinitrc 										.xinitrc
cp -v ~/.xserverrc 										.xserverrc

# .zsh
cp -v ~/.zprofile 										.zprofile
cp -v ~/.zshenv 										.zshenv
cp -v ~/.zshrc 											.zshrc
cp -v ~/.config/zsh/completion.zsh 							.config/zsh/completion.zsh
cp -v ~/.config/zsh/git.zsh 									.config/zsh/git.zsh
cp -v ~/.config/zsh/key-bindings.zsh 							.config/zsh/key-bindings.zsh
cp -v ~/.config/zsh/prompt.zsh 								.config/zsh/prompt.zsh

# bspwm
cp -v ~/.config/bspwm/bspwmrc									.config/bspwm/bspwmrc

# compton
cp -v ~/.config/compton/config								.config/compton/config

# fontconfig
cp -v ~/.config/fontconfig/conf.d/20-dpi.conf					.config/fontconfig/conf.d/20-dpi.conf
cp -v ~/.config/fontconfig/conf.d/51-noto-color-emoji.conf	.config/fontconfig/conf.d/51-noto-color-emoji.conf
cp -v ~/.config/fontconfig/conf.d/68-color-emoji.conf			.config/fontconfig/conf.d/68-color-emoji.conf
cp -v ~/.config/fontconfig/conf.d/69-aliasing.conf			.config/fontconfig/conf.d/69-aliasing.conf

# gtk 2
cp -v ~/.gtkrc-2.0										.gtkrc-2.0

# gtk 3
cp -v ~/.config/gtk-3.0/gtk.css								.config/gtk-3.0/gtk.css
cp -v ~/.config/gtk-3.0/settings.ini							.config/gtk-3.0/settings.ini

# lemonbar / panel script
cp -v ~/.config/lemonbar/config								.config/lemonbar/config
cp -v ~/.config/lemonbar/panel								.config/lemonbar/panel
cp -v ~/.config/lemonbar/panel_bar							.config/lemonbar/panel_bar
cp -v ~/.config/lemonbar/plugins/bluetooth					.config/lemonbar/plugins/bluetooth
cp -v ~/.config/lemonbar/plugins/mpd							.config/lemonbar/plugins/mpd
cp -v ~/.config/lemonbar/plugins/toggle_output				.config/lemonbar/plugins/toggle_output
cp -v ~/.config/lemonbar/plugins/volume						.config/lemonbar/plugins/volume

# mpd
cp -v ~/.config/mpd/mpd.conf									.config/mpd/mpd.conf

# mpv
cp -v ~/.config/mpv/config									.config/mpv/config
cp -v ~/.config/mpv/input.conf								.config/mpv/input.conf

# ncmpcpp
cp -v ~/.config/ncmpcpp/config								.config/ncmpcpp/config

# nvim
cp -v ~/.config/nvim/init.vim									.config/nvim/init.vim
cp -v ~/.config/nvim/keybindings.vim							.config/nvim/keybindings.vim

# pacaur
cp -v ~/.config/pacaur/config									.config/pacaur/config

# sxhkd
cp -v ~/.config/sxhkd/sxhkdrc									.config/sxhkd/sxhkdrc

# systemd
cp -v ~/.config/systemd/user/mpd.socket						.config/systemd/user/mpd.socket

# termite
cp -v ~/.config/termite/config								.config/termite/config
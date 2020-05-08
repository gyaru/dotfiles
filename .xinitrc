#!/bin/bash
# .xinitrc

# compositor
picom --config ~/.config/picom/config -b &

# cursor
xsetroot -cursor_name left_ptr &

# wallpaper
nitrogen --restore &

# icc profile
xcalib -d :0 ~/.local/share/u3415w.icc &

# xrdb
[[ -f ~/.Xresources ]] && xrdb -merge -I "$HOME" ~/.Xresources

# start sxhkd with bash as shell
SXHKD_SHELL=/bin/bash sxhkd -r /tmp/sxhkd.log &

# clipboard manager
autocutsel -selection PRIMARY -fork &

# lazy screensaver
~/bin/prevent-screensaver &

# window manager
exec bspwm

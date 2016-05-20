# .xinitrc

#  envs/exports
source $HOME/.zshenv

# compositor
compton --config ~/.config/compton/config -b &

# .Xresources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# keyboard - layout
setxkbmap us & 

# keyboard - typematic delay (200ms) and rate (30Hz)
xset r rate 160 20

# enable numlock
xdotool key Num_Lock

# mouse - steelseries rival
rivalctl --cpi1 400 &
xset m 0 0 & # no acc
xsetroot -cursor_name left_ptr &

# hide cursor on inactivity
unclutter -noevents -idle 2 -jitter 1 -root >/dev/null 2>&1 &

# X hotkey demon
# sxhkd &

# wallpaper
nitrogen --restore &

# window manager
exec bspwm

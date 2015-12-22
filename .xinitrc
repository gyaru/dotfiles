# .xinitrc

# compositor
compton -b

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
xsetroot -cursor_name left_ptr &

# hide cursor on inactivity
unclutter -noevents -idle 2 -jitter 1 -root >/dev/null 2>&1 &

# X hotkey demon
sxhkd &

# wallpaper
nitrogen --restore &

# window manager
exec bspwm

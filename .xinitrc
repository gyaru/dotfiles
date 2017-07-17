# .xinitrc

# compositor
compton --config ~/.config/compton/config -b &

# cursor
xsetroot -cursor_name left_ptr &

# wallpaper
nitrogen --restore &

# nvidia regression metamodes bug
nvidia-settings --assign CurrentMetaMode="DFP-4: 3440x1440_60 +0+0 {  ForceCompositionPipeline = On }" &

# icc profile
xcalib -d :0 ~/.local/share/dell_u3415w.icc &

# crossfeed b2b
pacmd load-module module-ladspa-sink sink_name=bs2b master=alsa_output.pci-0000_00_1b.0.analog-stereo plugin=bs2b label=bs2b control=700,6.0 &

# start sxhkd with bash as shell
SXHKD_SHELL=/bin/bash sxhkd -r /tmp/sxhkd.log &

# clipboard manager
autocutsel -selection PRIMARY -fork &

# window manager
exec bspwm

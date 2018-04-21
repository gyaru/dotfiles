#!/bin/sh

cd "${0%/*}" || exit

DC="$HOME"/.config
GC="${0%/*}/.config"

# home
cp -v "$HOME"/.xinitrc                                                          .xinitrc
cp -v "$HOME"/.xserverrc                                                        .xserverrc
cp -v "$HOME"/.Xresources                                                       .Xresources

# .zsh
cp -v "$HOME"/.zprofile                                                         .zprofile
cp -v "$HOME"/.zshenv                                                           .zshenv
cp -v "$HOME"/.zshrc                                                            .zshrc
cp -v "$DC"/zsh/completion.zsh                                                  "$GC"/zsh/completion.zsh
cp -v "$DC"/zsh/git.zsh                                                         "$GC"/zsh/git.zsh
cp -v "$DC"/zsh/key-bindings.zsh                                                "$GC"/zsh/key-bindings.zsh
cp -v "$DC"/zsh/prompt.zsh                                                      "$GC"/zsh/prompt.zsh

# bspwm
cp -v "$DC"/bspwm/bspwmrc                                                       "$GC"/bspwm/bspwmrc

# compton
cp -v "$DC"/compton/config                                                      "$GC"/compton/config

# firefox
cp -v ~/.mozilla/firefox/l31x8z8z.gyaru/user.js                                 "$GC"/firefox/user.js

# fontconfig
cp -v "$DC"/fontconfig/conf.d/10-aliasing.conf                                  "$GC"/fontconfig/conf.d/10-aliasing.conf
cp -v "$DC"/fontconfig/conf.d/10-hinting-slight.conf                            "$GC"/fontconfig/conf.d/10-hinting-slight.conf
cp -v "$DC"/fontconfig/conf.d/20-dpi.conf                                       "$GC"/fontconfig/conf.d/20-dpi.conf
cp -v "$DC"/fontconfig/conf.d/30-win32-aliases.conf                             "$GC"/fontconfig/conf.d/30-win32-aliases.conf
cp -v "$DC"/fontconfig/conf.d/51-noto-color-emoji.conf                          "$GC"/fontconfig/conf.d/51-noto-color-emoji.conf
cp -v "$DC"/fontconfig/conf.d/68-color-emoji.conf                               "$GC"/fontconfig/conf.d/68-color-emoji.conf

# gtk 2
cp -v "$HOME"/.gtkrc-2.0                                                        .gtkrc-2.0

# gtk 3
cp -v "$DC"/gtk-3.0/gtk.css                                                     "$GC"/gtk-3.0/gtk.css
cp -v "$DC"/gtk-3.0/settings.ini                                                "$GC"/gtk-3.0/settings.ini

# lemonbar / panel script
cp -v "$DC"/lemonbar/config                                                     "$GC"/lemonbar/config
cp -v "$DC"/lemonbar/panel                                                      "$GC"/lemonbar/panel
cp -v "$DC"/lemonbar/panel_bar                                                  "$GC"/lemonbar/panel_bar
cp -v "$DC"/lemonbar/plugins/bluetooth                                          "$GC"/lemonbar/plugins/bluetooth
cp -v "$DC"/lemonbar/plugins/mpd                                                "$GC"/lemonbar/plugins/mpd
cp -v "$DC"/lemonbar/plugins/toggle_output                                      "$GC"/lemonbar/plugins/toggle_output
cp -v "$DC"/lemonbar/plugins/volume                                             "$GC"/lemonbar/plugins/volume

# mpd
cp -v "$DC"/mpd/mpd.conf                                                        "$GC"/mpd/mpd.conf

# mpv
cp -v "$DC"/mpv/config                                                          "$GC"/mpv/config
cp -v "$DC"/mpv/input.conf                                                      "$GC"/mpv/input.conf

# ncmpcpp
cp -v "$DC"/ncmpcpp/config                                                      "$GC"/ncmpcpp/config

# nvim
cp -v "$DC"/nvim/init.vim                                                       "$GC"/nvim/init.vim
cp -v "$DC"/nvim/keybindings.vim                                                "$GC"/nvim/keybindings.vim
cp -v "$DC"/nvim/plugins.vim                                                    "$GC"/nvim/plugins.vim

# trizen
cp -v "$DC"/trizen/trizen.conf                                                  "$GC"/trizen/trizen.conf

# sxhkd
cp -v "$DC"/sxhkd/sxhkdrc                                                       "$GC"/sxhkd/sxhkdrc

# systemd
cp -v "$DC"/systemd/user/mpd.socket                                             "$GC"/systemd/user/mpd.socket

# termite
cp -v "$DC"/termite/config                                                      "$GC"/termite/config

# ranger
cp -v "$DC"/ranger/rc.conf                                                      "$GC"/ranger/rc.conf
cp -v "$DC"/ranger/rifle.conf                                                   "$GC"/ranger/rifle.conf

# visual studio code
cp -v "$DC"/Code/User/settings.json                                             "$GC"/Code/User/settings.json
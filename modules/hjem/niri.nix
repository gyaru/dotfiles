{
  flake,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe getExe';
  pickColor = getExe flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-pick-color;
in {
  packages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    cliphist
    wl-clip-persist
  ];
  rum.desktops.niri = {
    enable = true;

    spawn-at-startup = [
      ["${getExe pkgs.wl-clip-persist}" "--clipboard" "both"]
      ["${getExe' pkgs.wl-clipboard "wl-paste"}" "--type" "text" "--watch" "${getExe pkgs.cliphist}" "store"]
      ["${getExe' pkgs.wl-clipboard "wl-paste"}" "--type" "image" "--watch" "${getExe pkgs.cliphist}" "store"]
    ];

    config =
      /*
      kdl
      */
      ''
        input {
          keyboard {
            xkb {
              layout "us,se"
            }
            numlock
          }

          touchpad {
            tap
            natural-scroll
          }

          mouse {
            accel-profile "flat"
          }
        }

        layout {
          gaps 16
          center-focused-column "never"

          preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
          }

          default-column-width { proportion 0.5; }

          focus-ring {
            width 4
            active-color "#7fc8ff"
            inactive-color "#505050"
          }

          border {
            off
          }
        }

        animations {
          off
        }

        xwayland-satellite {
          path "${getExe pkgs.xwayland-satellite}"
        }

        output "LG Electronics 34GN850 004NTGY1J495" {
          position x=0 y=0
          focus-at-startup
        }

        output "HDMI-A-1" {
          position x=-200 y=1440
        }

        binds {
          Mod+Shift+Slash { show-hotkey-overlay; }

          Mod+Return { spawn "${getExe pkgs.kitty}"; }
          Mod+Space { spawn "${getExe pkgs.fuzzel}"; }
          Mod+O { spawn "${getExe pkgs.firefox-bin}"; }
          Mod+C { spawn "${pickColor}"; }

          Mod+Shift+W { close-window; }
          Mod+Shift+M { spawn "${getExe pkgs.wlogout}"; }
          Mod+F11 { screenshot-screen; }
          Mod+F { toggle-window-floating; }

          Mod+P { toggle-column-tabbed-display; }
          Mod+S { toggle-column-tabbed-display; }

          Mod+Left  { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+Up    { focus-window-up; }
          Mod+Down  { focus-window-down; }

          Mod+Shift+Left  { consume-or-expel-window-left; }
          Mod+Shift+Right { consume-or-expel-window-right; }
          Mod+Shift+Up    { move-window-up; }
          Mod+Shift+Down  { move-window-down; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }

          Mod+Shift+1 { move-window-to-workspace 1; }
          Mod+Shift+2 { move-window-to-workspace 2; }
          Mod+Shift+3 { move-window-to-workspace 3; }
          Mod+Shift+4 { move-window-to-workspace 4; }
          Mod+Shift+5 { move-window-to-workspace 5; }
          Mod+Shift+6 { move-window-to-workspace 6; }

          Mod+Shift+S { screenshot; }
          XF86Calculator { switch-layout "next"; }

          XF86AudioRaiseVolume allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-volume" "--limit" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
          XF86AudioNext allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "next" "--ignore-player" "chromium"; }
          XF86AudioPrev allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "previous" "--ignore-player" "chromium"; }
          XF86AudioPlay allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "play-pause" "--ignore-player" "chromium"; }

          Print { screenshot; }
          Ctrl+Print { screenshot-screen; }
          Alt+Print { screenshot-window; }

          Mod+Shift+E { quit; }
        }

        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
        prefer-no-csd
      '';
  };
}

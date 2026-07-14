{
  flake,
  inputs,
  pkgs,
  ...
}: {
  hjem = {
    clobberByDefault = true;
    specialArgs = {inherit flake;};
    extraModules = [
      inputs.hjem-rum.hjemModules.default
      flake.hjemModules.git
      flake.hjemModules.hyprland
      flake.hjemModules.kitty
    ];

    users.lis = {
      enable = true;
      user = "lis";
      directory = "/home/lis";

      packages = with pkgs; [
        inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.default
        alejandra
        btop
        claude-code
        direnv
        eza
        firefox-bin
        flatpak
        fzf
        ghostty
        grim
        hyprpicker
        hyprprop
        imv
        kooha
        mpv
        nil
        nix-direnv
        obs-studio
        playerctl
        rose-pine-cursor
        runelite
        slurp
        socat
        spotify
        starship
        strace
        swaybg
        tealdeer
        telegram-desktop
        vesktop
        vscode
        waybar
        wl-clipboard
        wlogout
        xclip
        xdg-utils
        xprop
      ];

      environment.sessionVariables = {
        BROWSER = "firefox";
        MOZ_USE_XINPUT2 = "1";
        RUSTUP_HOME = "/home/lis/.local/share/rustup";
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "BreezeX-RosePineDawn-Linux";
        XDG_CACHE_HOME = "/home/lis/.cache";
        XDG_CONFIG_HOME = "/home/lis/.config";
        XDG_DATA_HOME = "/home/lis/.local/share";
        XDG_STATE_HOME = "/home/lis/.local/state";
      };

      rum.programs.zsh = {
        enable = true;
        plugins.zsh-autosuggestions.source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        initConfig =
          /*
          bash
          */
          ''
            eval "$(${pkgs.starship}/bin/starship init zsh)"
            eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
          '';
        loginConfig =
          /*
          bash
          */
          ''
            if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
              exec dbus-run-session Hyprland
            fi
          '';
      };
    };
  };
}

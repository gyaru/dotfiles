{
  flake,
  inputs,
  pkgs,
  ...
}: {
  hjem = {
    clobberByDefault = true;
    specialArgs = {inherit flake inputs;};
    extraModules = [
      inputs.hjem-rum.hjemModules.default
      flake.hjemModules.git
      flake.hjemModules.kitty
      flake.hjemModules.niri
      flake.hjemModules.noctalia
    ];

    users.lis = {
      enable = true;
      user = "lis";
      directory = "/home/lis";

      packages = with pkgs; [
        _1password-gui
        alejandra
        btop
        codex
        direnv
        eza
        firefox-bin
        flatpak
        fuzzel
        fzf
        gpu-screen-recorder
        grim
        imv
        kooha
        mpv
        nil
        nix-direnv
        obs-studio
        opencode
        playerctl
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
        wlogout
        xclip
        xdg-utils
        xprop
      ];

      environment.sessionVariables = {
        BROWSER = "firefox";
        MOZ_USE_XINPUT2 = "1";
        RUSTUP_HOME = "/home/lis/.local/share/rustup";
        XCURSOR_SIZE = "18";
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
          "\n"
          +
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
              exec dbus-run-session niri
            fi
          '';
      };
    };
  };
}

{lib, ...}: let
  inherit (lib.lists) singleton;
  inherit (lib.meta) getExe;
  inherit (lib.options) mkOption;
  inherit (lib.strings) escapeShellArg;
  inherit (lib.types) package str;
in {
  flake.modules.hjem."battle.net" = {
    config,
    pkgs,
    ...
  }: let
    gamePackages = {
      name,
      desktopName,
      executable,
    }: let
      gameLauncher = pkgs.callPackage ({
        writeShellApplication,
        umu-launcher,
      }:
        writeShellApplication {
          inherit name;
          text =
            /*
            bash
            */
            ''
              export WINEPREFIX=${escapeShellArg config.programs.battle-net.prefix}
              export PROTONPATH=${escapeShellArg "${config.programs.battle-net.protonPackage}"}
              export GAMEID=umu-default
              export STORE=none
              export PROTON_VERB=run
              export STEAM_COMPAT_LIBRARY_PATHS=${escapeShellArg config.programs.battle-net.wowDirectory}"''${STEAM_COMPAT_LIBRARY_PATHS:+:$STEAM_COMPAT_LIBRARY_PATHS}"

              executable=${escapeShellArg "${config.programs.battle-net.wowDirectory}/${executable}"}
              if [[ ! -f "$executable" ]]; then
                printf 'Game executable not found: %s\n' "$executable" >&2
                exit 1
              fi
              cd -- "''${executable%/*}"
              exec ${getExe umu-launcher} "$executable" "$@"
            '';
        }) {};
    in [
      gameLauncher
      (pkgs.makeDesktopItem {
        inherit name desktopName;
        exec = getExe gameLauncher;
        icon = "applications-games";
        categories = singleton "Game";
      })
    ];

    launcher = pkgs.callPackage ({
      writeShellApplication,
      curl,
      coreutils,
      umu-launcher,
    }:
      writeShellApplication {
        name = "battle-net";
        runtimeInputs = [curl coreutils];
        text =
          /*
          bash
          */
          ''
            export WINEPREFIX=${escapeShellArg config.programs.battle-net.prefix}
            export PROTONPATH=${escapeShellArg "${config.programs.battle-net.protonPackage}"}
            export GAMEID=umu-default
            export STORE=none

            executable="$WINEPREFIX/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
            installer_source=""

            if [[ "''${1:-}" == "--help" ]]; then
              printf '%s\n' 'Usage: battle-net [--install [INSTALLER.exe]] [Battle.net arguments...]'
              exit 0
            fi

            if [[ "''${1:-}" == "--install" ]]; then
              shift
              if [[ $# -gt 0 ]]; then
                installer_source=$(realpath --canonicalize-existing -- "$1")
                shift
              fi
              executable=""
            fi

            if [[ ! -f "$executable" ]]; then
              mkdir --parents -- ${escapeShellArg config.xdg.cache.directory}
              installer_dir=$(mktemp --directory --tmpdir=${escapeShellArg config.xdg.cache.directory} battle-net.XXXXXXXX)
              trap 'rm --recursive --force -- "$installer_dir"' EXIT
              if [[ -n "$installer_source" ]]; then
                cp -- "$installer_source" "$installer_dir/Battle.net-Setup.exe"
              else
                curl --fail --location --show-error \
                  --output "$installer_dir/Battle.net-Setup.exe" \
                  'https://www.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe'
              fi
              ${getExe umu-launcher} "$installer_dir/Battle.net-Setup.exe" "$@"
            else
              exec ${getExe umu-launcher} "$executable" "$@"
            fi
          '';
      }) {};
  in {
    options.programs.battle-net = {
      wowDirectory = mkOption {
        type = str;
        default = "/mnt/suzu/Program Files (x86)/World of Warcraft";
        description = "Existing World of Warcraft installation directory.";
      };

      prefix = mkOption {
        type = str;
        default = "${config.xdg.data.directory}/games/battle.net";
        description = "Dedicated Wine prefix for Battle.net and its games.";
      };

      protonPackage = mkOption {
        type = package;
        default = pkgs.proton-ge-bin.steamcompattool;
        description = "Proton runner used only by the Battle.net launcher.";
      };
    };

    config.packages =
      [
        launcher
        (pkgs.makeDesktopItem {
          name = "battle-net";
          desktopName = "Battle.net";
          comment = "Battle.net with a dedicated GE-Proton prefix";
          exec = getExe launcher;
          icon = "applications-games";
          categories = singleton "Game";
        })
      ]
      ++ gamePackages {
        name = "world-of-warcraft-forever";
        desktopName = "World of Warcraft Forever";
        executable = "_classic_beta_/WowB.exe";
      }
      ++ gamePackages {
        name = "world-of-warcraft";
        desktopName = "World of Warcraft";
        executable = "_retail_/Wow.exe";
      };
  };
}

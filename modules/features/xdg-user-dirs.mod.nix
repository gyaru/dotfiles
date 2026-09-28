_: {
  flake.modules.hjem.xdg-user-dirs = {
    config,
    lib,
    ...
  }: let
    inherit (lib.attrsets) mapAttrsToList;
    inherit (lib.options) mkOption;
    inherit (lib.strings) concatStringsSep;
    inherit (lib.types) attrsOf str;
  in {
    options.xdg.userDirectories = mkOption {
      type = attrsOf str;
      default = {
        DESKTOP = "${config.directory}/desktop";
        DOCUMENTS = "${config.directory}/documents";
        DOWNLOAD = "${config.directory}/downloads";
        MUSIC = "${config.directory}/music";
        PICTURES = "${config.directory}/pictures";
        PUBLICSHARE = "${config.directory}/public";
        TEMPLATES = "${config.directory}/templates";
        VIDEOS = "${config.directory}/videos";
      };
      description = "XDG user directory paths.";
    };

    config.xdg.config.files = {
      "user-dirs.dirs".text =
        concatStringsSep "\n"
        <| mapAttrsToList
        (name: path: ''XDG_${name}_DIR="${path}"'')
        config.xdg.userDirectories;

      "user-dirs.conf".text = "enabled=False\n";

      "user-tmpfiles.d/xdg-user-dirs.conf".text =
        concatStringsSep "\n"
        <| mapAttrsToList
        (_: path: ''d "${path}" 0700 - - -'')
        config.xdg.userDirectories;
    };
  };
}

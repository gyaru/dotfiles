_: {
  flake.modules.nixos.fonts = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.lists) singleton;
    inherit (lib.modules) mkDefault;
  in {
    fonts = {
      packages = with pkgs; [
        balsamiqsans
        lucide-icons
        maple-mono.NF
        mplus-fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
      ];
      fontconfig = {
        enable = mkDefault true;
        defaultFonts = {
          monospace = singleton "M PLUS 1 Code";
          emoji = singleton "Noto Color Emoji";
        };
        antialias = true;
        hinting = {
          enable = true;
          style = "full";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
      };
    };
  };
}

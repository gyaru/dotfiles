_: {
  flake.modules.nixos.file-manager = {pkgs, ...}: {
    environment.systemPackages = with pkgs.kdePackages; [dolphin];
  };
}

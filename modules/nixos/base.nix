{pkgs, ...}: {
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
    "kernel.printk" = "3 3 3 3";
  };
  environment.systemPackages = with pkgs; [
    alejandra
    atool
    curl
    fd
    file
    jq
    man-pages
    man-pages-posix
    nano
    nix-output-monitor
    p7zip
    ripgrep
    unzip
    wget
  ];
}

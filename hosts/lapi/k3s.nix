{
  pkgs,
  config,
  ...
}: let
  containerdConfigTmpl = pkgs.writeText "k3s-containerd-config.toml.tmpl" ''
    version = 3
    root = "/var/lib/rancher/k3s/agent/containerd"
    state = "/run/k3s/containerd"

    [grpc]
      address = "/run/k3s/containerd/containerd.sock"

    [plugins.'io.containerd.internal.v1.opt']
      path = "/var/lib/rancher/k3s/agent/containerd"

    [plugins.'io.containerd.grpc.v1.cri']
      stream_server_address = "127.0.0.1"
      stream_server_port = "10010"

    [plugins.'io.containerd.cri.v1.runtime']
      enable_selinux = false
      enable_unprivileged_ports = true
      enable_unprivileged_icmp = true
      device_ownership_from_security_context = false
      enable_cdi = true
      cdi_spec_dirs = ["/var/run/cdi", "/etc/cdi"]

    [plugins.'io.containerd.cri.v1.images']
      snapshotter = "overlayfs"
      disable_snapshot_annotations = true
      use_local_image_pull = true

    [plugins.'io.containerd.cri.v1.images'.pinned_images]
      sandbox = "rancher/mirrored-pause:3.6"

    [plugins.'io.containerd.cri.v1.runtime'.cni]
      bin_dirs = ["/var/lib/rancher/k3s/data/cni"]
      conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d"

    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"

    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
      SystemdCgroup = true

    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runhcs-wcow-process]
      runtime_type = "io.containerd.runhcs.v1"

    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.nvidia]
      runtime_type = "io.containerd.runc.v2"

    [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.nvidia.options]
      BinaryName = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime.cdi"

    [plugins.'io.containerd.cri.v1.images'.registry]
      config_path = "/var/lib/rancher/k3s/agent/etc/containerd/certs.d"
  '';
in {
  networking.firewall = {
    trustedInterfaces = ["cni0" "flannel.1"];
    allowedTCPPorts = [51413]; # torrent
    allowedUDPPorts = [51413]; # torrent
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 80 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 6443 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 8096 -s 192.168.1.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --dport 8080 -s 192.168.1.0/24 -j nixos-fw-accept
    '';
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-token.path;
    extraFlags = toString [
      "--tls-san=127.0.0.1"
      "--tls-san=${config.networking.hostName}"
      "--disable=traefik"
      "--disable=servicelb"
      "--write-kubeconfig-mode=600"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      k3s
      kubectl
      runc
      nvidia-container-toolkit.tools
    ];

    etc."nvidia-container-toolkit/config.toml".text = ''
      disable-require = false
      supported-driver-capabilities = "compat32,compute,display,graphics,ngx,utility,video"

      [nvidia-container-cli]
      environment = []
      ldconfig = "@${pkgs.glibc}/sbin/ldconfig"
      load-kmods = true

      [nvidia-container-runtime]
      log-level = "info"
      mode = "cdi"
      runtimes = ["${pkgs.runc}/bin/runc"]

      [nvidia-container-runtime.modes.cdi]
      annotation-prefixes = ["cdi.k8s.io/"]
      default-kind = "nvidia.com/gpu"
      spec-dirs = ["/etc/cdi", "/var/run/cdi"]

      [nvidia-container-runtime.modes.csv]
      mount-spec-path = "/etc/nvidia-container-runtime/host-files-for-container.d"

      [nvidia-container-runtime.modes.legacy]
      cuda-compat-mode = "ldconfig"

      [nvidia-container-runtime-hook]
      path = "${pkgs.nvidia-container-toolkit.tools}/bin/nvidia-container-runtime-hook"
      skip-mode-detection = false

      [nvidia-ctk]
      path = "${pkgs.nvidia-container-toolkit}/bin/nvidia-ctk"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/rancher/k3s/agent/etc/containerd 0755 root root -"
    "L+ /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl - - - - ${containerdConfigTmpl}"
  ];

  # home-assistant
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", MODE="0666", GROUP="dialout"
  '';
}

_: {
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "lapi";
        "netbios name" = "lapi";
        security = "user";
        "map to guest" = "never";
        "guest account" = "nobody";
        "hosts allow" = "192.168.1.0/24 100.64.0.0/10 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
      };
      media = {
        path = "/mlem/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "lis";
        "write list" = "lis";
      };
      mlem = {
        path = "/mlem";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "lis";
        "write list" = "lis";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}

# Passwordless project access for devices allowed through the tailnet ACLs.
{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = false;
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        interfaces = "lo";
        "bind interfaces only" = "yes";
        "smb ports" = "445";
        "map to guest" = "Bad User";
        "guest account" = "keyclicker";
        "load printers" = "no";
        "disable spoolss" = "yes";
      };

      projects = {
        path = "${config.users.users.keyclicker.home}/projects";
        "read only" = "no";
        "guest ok" = "yes";
        "guest only" = "yes";
      };
    };
  };

  # Samba stays on loopback; own only the tailnet TCP 445 listener.
  systemd.services.projects-smb-tailnet = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" ];
    after = [
      "tailscaled.service"
      "samba-smbd.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --tcp=445 tcp://127.0.0.1:445";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --tcp=445 off";
      TimeoutStartSec = 30;
      Restart = "on-failure";
      RestartSec = 15;
    };
  };
}

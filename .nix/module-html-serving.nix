# Shared HTML directory, available privately through Tailscale Serve.
{ config, pkgs, ... }:

let
  public = "${config.users.users.keyclicker.home}/public";
  python = pkgs.python3.withPackages (packages: [ packages.jinja2 ]);
in
{
  systemd.tmpfiles.rules = [ "d ${public} 0755 keyclicker users -" ];

  systemd.services.html-serving = {
    description = "HTML directory server";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "keyclicker";
      Group = "users";
      ExecStart = "${python}/bin/python ${../.scripts/html-serving}/server.py --directory ${public}";
      Restart = "on-failure";
      RestartSec = 3;
      NoNewPrivileges = true;
    };
  };

  # Configure just this port, leaving other tailnet services alone.
  systemd.services.html-serving-tailnet = {
    description = "Expose the HTML directory over Tailscale";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "tailscaled.service"
      "html-serving.service"
    ];
    after = [
      "tailscaled.service"
      "html-serving.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=8444 http://127.0.0.1:8765";
      TimeoutStartSec = 30;
      Restart = "on-failure";
      RestartSec = 15;
    };
  };
}

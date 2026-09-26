# Shared HTML directory, available privately through Tailscale Serve.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  projects = "${config.users.users.keyclicker.home}/projects";
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
      ExecStart = lib.escapeShellArgs [
        "${python}/bin/python"
        "${../.scripts/html-serving}/server.py"
        "--directory"
        public
        "--allow-root"
        projects
      ];
      Restart = "on-failure";
      RestartSec = 3;
      NoNewPrivileges = true;
    };
  };

  # Own this Serve port; leave unrelated routes alone.
  systemd.services.html-serving-tailnet = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" ];
    after = [
      "tailscaled.service"
      "html-serving.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --yes --https=8444 http://127.0.0.1:8765";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=8444 off";
      TimeoutStartSec = 30;
      Restart = "on-failure";
      RestartSec = 15;
    };
  };
}

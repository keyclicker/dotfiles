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
  imports = [ ./option-tailnet.nix ];

  local.tailnet.https."8444" = "http://127.0.0.1:8765";

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
}

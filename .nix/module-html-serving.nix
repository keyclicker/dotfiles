# Shared HTML directory on loopback; module-gateway.nix serves it at
# /public/ on the tailnet.
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
        "${../packages/html-serving}/server.py"
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

# Tailnet front door of the agents box: Tailscale terminates HTTPS on
# 443, nginx routes by path, and the ~/public directory server sits
# behind it at /public/. Routes and the services index live in
# packages/gateway, the directory server in packages/html-serving.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.users.users.keyclicker.home;
  public = "${home}/public";
  python = pkgs.python3.withPackages (packages: [ packages.jinja2 ]);

  routes = pkgs.replaceVars ../packages/gateway/nginx.conf {
    site = ../packages/gateway;
  };
in
{
  imports = [ ./option-tailnet.nix ];

  local.tailnet.https."443" = "http://127.0.0.1:8080";

  services.nginx = {
    enable = true;
    appendHttpConfig = "include ${routes};";
  };

  # ---- ~/public directory server --------------------------------------------

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
        "${home}/projects"
      ];
      Restart = "on-failure";
      RestartSec = 3;
      NoNewPrivileges = true;
    };
  };
}

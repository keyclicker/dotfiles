# Tailnet front door of the agents box: Tailscale terminates HTTPS on
# 443, nginx routes by path. The routes and the services index live in
# packages/gateway.
{ pkgs, ... }:

let
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
}

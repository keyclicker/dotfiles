# One tailnet front door for the agents box: Tailscale terminates HTTPS
# for the node name and svc:t3, nginx routes by Host and path. The
# routes and the services index live in packages/gateway.
{ pkgs, ... }:

let
  gateway = "http://127.0.0.1:8080";
  routes = pkgs.replaceVars ../packages/gateway/nginx.conf {
    site = ../packages/gateway;
  };
in
{
  imports = [ ./option-tailnet.nix ];

  local.tailnet.https."443" = gateway;
  local.tailnet.services.t3 = gateway;

  services.nginx = {
    enable = true;
    appendHttpConfig = "include ${routes};";
  };
}

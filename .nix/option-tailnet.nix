# Own declared Serve ports without replacing unrelated manual routes.
{ config, lib, ... }:

let
  cfg = config.local.tailnet;
  serve = "${config.services.tailscale.package}/bin/tailscale serve";

  # Tailscaled owns the listener; the unit configures and removes its port.
  units =
    protocol: routes:
    lib.mapAttrs' (
      port: target:
      lib.nameValuePair "tailnet-${protocol}-${port}" {
        wantedBy = [ "multi-user.target" ];
        wants = [ "tailscaled.service" ];
        after = [ "tailscaled.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${serve} --bg --yes --${protocol}=${port} ${lib.escapeShellArg target}";
          ExecStop = "${serve} --${protocol}=${port} off";
          TimeoutStartSec = 30;
          Restart = "on-failure";
          RestartSec = 15;
        };
      }
    ) routes;
in
{
  options.local.tailnet = {
    https = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Tailnet HTTPS ports mapped to local HTTP backends.";
    };
    tcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Tailnet TCP ports mapped to local TCP backends.";
    };
  };

  config.systemd.services = units "https" cfg.https // units "tcp" cfg.tcp;
}

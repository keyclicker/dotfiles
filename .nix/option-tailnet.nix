# Own declared Serve ports without replacing unrelated manual routes.
{ config, lib, ... }:

let
  cfg = config.local.tailnet;
  serve = "${config.services.tailscale.package}/bin/tailscale serve";

  # Tailscaled owns the listener; the unit configures and removes it.
  unit = name: start: stop: {
    ${name} = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "tailscaled.service" ];
      after = [ "tailscaled.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = start;
        ExecStop = stop;
        TimeoutStartSec = 30;
        Restart = "on-failure";
        RestartSec = 15;
      };
    };
  };

  # Ports on the node's own name
  ports =
    protocol: routes:
    lib.concatMapAttrs (
      port: target:
      unit "tailnet-${protocol}-${port}"
        "${serve} --bg --yes --${protocol}=${port} ${lib.escapeShellArg target}"
        "${serve} --${protocol}=${port} off"
    ) routes;

  # HTTPS 443 on svc:<name>, a name of its own
  services = lib.concatMapAttrs (
    name: target:
    unit "tailnet-svc-${name}"
      "${serve} --yes --service=svc:${name} --https=443 ${lib.escapeShellArg target}"
      "${serve} clear svc:${name}"
  ) cfg.services;
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
    services = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Tailscale Services (`svc:<name>`, reachable as
        `<name>.<tailnet>.ts.net`) mapped to local HTTP backends. Each
        must be defined in the admin console and this host approved.
      '';
    };
  };

  config.systemd.services = ports "https" cfg.https // ports "tcp" cfg.tcp // services;
}

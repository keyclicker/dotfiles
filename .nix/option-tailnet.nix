# Share local backends through Tailscale without replacing unrelated routes.
{
  config,
  lib,
  ...
}:

let
  cfg = config.local.tailnet;

  # Each route owns one persistent Serve listener and its cleanup.
  serveUnits =
    protocol: routes:
    lib.mapAttrs' (
      port: target:
      lib.nameValuePair "tailnet-${protocol}-${port}" {
        description = "Tailscale ${protocol} listener on ${port}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "tailscaled.service" ];
        after = [
          "tailscaled.service"
          "tailscaled-autoconnect.service"
          "tailscaled-set.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.escapeShellArgs [
            "${config.services.tailscale.package}/bin/tailscale"
            "serve"
            "--bg"
            "--yes"
            "--${protocol}=${port}"
            target
          ];
          ExecStop = lib.escapeShellArgs [
            "${config.services.tailscale.package}/bin/tailscale"
            "serve"
            "--${protocol}=${port}"
            "off"
          ];
          TimeoutStartSec = 30;
          Restart = "on-failure";
          RestartSec = 15;
        };
      }
    ) routes;

  # Attribute names become CLI ports, so reject invalid names at evaluation.
  portMap = lib.types.addCheck (lib.types.attrsOf lib.types.str) (
    routes:
    lib.all (port: builtins.match "[1-9][0-9]{0,4}" port != null && lib.toInt port <= 65535) (
      builtins.attrNames routes
    )
  );
in
{
  options.local.tailnet = {
    https = lib.mkOption {
      type = portMap;
      default = { };
      example = {
        "8444" = "http://127.0.0.1:8765";
      };
      description = "Tailnet HTTPS ports mapped to local HTTP backends.";
    };
    tcp = lib.mkOption {
      type = portMap;
      default = { };
      example = {
        "445" = "tcp://127.0.0.1:445";
      };
      description = "Tailnet TCP ports mapped to local TCP backends.";
    };
  };

  config = lib.mkIf (cfg.https != { } || cfg.tcp != { }) {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "local.tailnet requires services.tailscale.enable";
      }
      {
        assertion = lib.intersectLists (builtins.attrNames cfg.https) (builtins.attrNames cfg.tcp) == [ ];
        message = "local.tailnet HTTPS and TCP listeners must use different ports";
      }
    ];
    systemd.services = serveUnits "https" cfg.https // serveUnits "tcp" cfg.tcp;
  };
}

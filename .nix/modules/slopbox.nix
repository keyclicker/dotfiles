# T3 Code: CLI wrapper + web server.
{ pkgs, ... }:

{
  # The web UI stays LAN-only.
  local.lan.allowedTCPPorts = [ 3773 ];

  systemd.services.t3 = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      HOME = "/home/keyclicker";
      T3CODE_HOME = "/var/lib/t3";
    };
    path = [
      pkgs.bash
      pkgs.nodejs
    ];
    serviceConfig = {
      Type = "simple";
      User = "keyclicker";
      Group = "users";
      WorkingDirectory = "/home/keyclicker";
      StateDirectory = "t3";
      StateDirectoryMode = "0700";
      ExecStart = "${pkgs.writeShellScript "t3-server" ''
        exec ${pkgs.nodejs}/bin/npx --yes t3@latest \
          --mode web \
          --host 0.0.0.0 \
          --port 3773 \
          --no-browser \
          --base-dir /var/lib/t3
      ''}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "t3" ''
      exec ${nodejs}/bin/npx --yes t3@latest "$@"
    '')
  ];
}

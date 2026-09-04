# T3 Code: CLI wrapper + web server.
{ pkgs, ... }:

{
  # The web UI stays LAN-only.
  local.lan.allowedTCPPorts = [ 3773 ];

  # Runs as keyclicker so the agents it spawns see the user's ~/.claude,
  # ~/.codex and dotfiles. t3 resolves the environment for those from
  # the user's login shell (`zsh -ilc`) itself, so the service PATH
  # below is only what t3's own startup needs.
  systemd.services.t3 = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.bash
      pkgs.gcc
      pkgs.gnumake
      pkgs.nodejs
      pkgs.python3
    ];
    serviceConfig = {
      Type = "simple";
      User = "keyclicker";
      Group = "users";
      WorkingDirectory = "/home/keyclicker";
      StateDirectory = "t3";
      StateDirectoryMode = "0700";
      # --base-dir is StateDirectory: t3's own state stays out of $HOME.
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

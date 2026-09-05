# T3 Code web server. The `t3` binary is the npm global that
# home-agents.nix keeps installed in the user's ~/.local/bin, so the
# service waits for home-manager's activation on a first boot and
# picks up whatever version the last rebuild left.
{ pkgs, ... }:

let
  t3 = "/home/keyclicker/.local/bin/t3";
in
{
  imports = [ ./option-lan.nix ];

  # The web UI stays LAN-only.
  local.lan.allowedTCPPorts = [ 3773 ];

  # Runs as keyclicker so the agents it spawns see the user's ~/.claude,
  # ~/.codex and dotfiles. t3 resolves the environment for those from
  # the user's login shell (`zsh -ilc`) itself, so the service PATH
  # below is only what t3's own startup needs.
  systemd.services.t3 = {
    description = "T3 Code server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "home-manager-keyclicker.service"
    ];
    wants = [ "network-online.target" ];
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
      # --base-dir is StateDirectory: t3's own state stays out of $HOME.
      ExecStart = "${pkgs.writeShellScript "t3-server" ''
        exec ${t3} \
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
}

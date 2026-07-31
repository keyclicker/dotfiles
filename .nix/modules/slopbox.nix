# AI coding agents: claude, codex, t3 (CLI wrappers + t3 web server).
{ pkgs, ... }:

{
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
      pkgs.nodejs_24
    ];
    serviceConfig = {
      Type = "simple";
      User = "keyclicker";
      Group = "users";
      WorkingDirectory = "/home/keyclicker";
      StateDirectory = "t3";
      StateDirectoryMode = "0700";
      ExecStart = "${pkgs.writeShellScript "t3-server" ''
        exec ${pkgs.nodejs_24}/bin/npx --yes t3@latest \
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
      exec ${nodejs_24}/bin/npx --yes t3@latest "$@"
    '')

    (writeShellScriptBin "codex" ''
      exec ${nodejs_24}/bin/npx --yes @openai/codex@latest "$@"
    '')

    (writeShellScriptBin "claude" ''
      exec ${nodejs_24}/bin/npx --yes @anthropic-ai/claude-code@latest "$@"
    '')
  ];
}

# Headless browser stack for agents. Shared by hosts/agents.nix and
# hosts/jail.nix, which both run agents without a display and without
# a usable kernel sandbox (LXC guest, Docker container).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium
    playwright-test

    # agent-browser drives its own Chromium; point it at the one from
    # nixpkgs and drop the sandbox the container already provides.
    (writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.lib.getExe chromium}"
      export AGENT_BROWSER_ARGS="--no-sandbox"
      exec ${pkgs.lib.getExe agent-browser} "$@"
    '')
  ];
}

# Headless browser stack for agents. Shared by host-agents.nix and
# host-jail.nix, which both run agents without a display and without
# a usable kernel sandbox (LXC guest, Docker container).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium
    playwright-test

    # agent-browser wants its own Chromium; point it at the nixpkgs
    # one instead. --no-sandbox because the container is the sandbox
    # here, and Chromium's own cannot start without kernel namespaces.
    (writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.lib.getExe chromium}"
      export AGENT_BROWSER_ARGS="--no-sandbox"
      exec ${pkgs.lib.getExe agent-browser} "$@"
    '')
  ];
}

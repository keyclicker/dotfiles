# Headless browser stack for the agents VM, with Chromium's sandbox enabled.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium
    playwright-test

    # Use nixpkgs Chromium and leave its sandbox enabled.
    (writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.lib.getExe chromium}"
      exec ${pkgs.lib.getExe agent-browser} "$@"
    '')
  ];
}

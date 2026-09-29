# Keep configuration, caches and persistent data out of the home root.
# Agent homes stay at their defaults: running sessions hold those paths.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  paths = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/mod";
    GOBIN = "${config.home.homeDirectory}/.local/bin";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    DOOMDIR = "${config.xdg.configHome}/doom";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
  };
in
{
  xdg.enable = true;
  home.sessionVariables = paths;
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux paths;

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.dataHome}/cargo/bin"
  ];
}

# Raspberry Pi running Ubuntu.
#
# Bootstrap on the pi:
#   $ sh <(curl -L https://nixos.org/nix/install) --daemon
#   $ nix run home-manager -- switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
# Afterwards:
#   $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
{ pkgs, ... }:

{
  imports = [ ../home/standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";

  # Full user environment: dev toolchains + AI agent CLIs on top of
  # standalone's common set (same import-as-function pattern).
  home.packages =
    (import ../modules/dev.nix { inherit pkgs; }).environment.systemPackages
    ++ (import ../modules/agents.nix { inherit pkgs; }).environment.systemPackages;
}

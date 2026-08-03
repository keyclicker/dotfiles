# Raspberry Pi running Ubuntu.
#
# Bootstrap on the pi:
#   $ sh <(curl -L https://nixos.org/nix/install) --daemon
#   $ nix run home-manager -- switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
# Afterwards:
#   $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
{ ... }:

{
  imports = [ ../home/standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";
}

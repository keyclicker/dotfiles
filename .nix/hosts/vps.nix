# Ubuntu VPS: standalone home-manager user environment. Same set as
# raspberry minus the AI agent CLIs.
#
# Bootstrap:
#   $ sh <(curl -L https://nixos.org/nix/install) --daemon
#   $ nix run home-manager -- switch -b hm-bak --flake ~/.dotfiles/.nix#keyclicker@vps
# Afterwards:
#   $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@vps
{ ... }:

{
  imports = [ ../home/standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";

  # Standalone's common set is the whole environment; no agents.nix.
}

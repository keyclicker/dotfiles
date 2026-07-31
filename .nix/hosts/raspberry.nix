# Raspberry Pi running Ubuntu: system stays apt, nix provides the
# user environment via standalone home-manager.
#
# Bootstrap on the pi:
#   $ sh <(curl -L https://nixos.org/nix/install) --daemon
#   $ nix run home-manager -- switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
# Afterwards:
#   $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
{ pkgs, ... }:

{
  imports = [ ../home/common.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";

  # Reuse the shared CLI tools. modules/common.nix must stay a plain
  # { pkgs, ... } function for this import to keep working; the moment
  # it needs config/lib, extract the list into shared data instead.
  home.packages =
    (import ../modules/common.nix { inherit pkgs; })
      .environment.systemPackages;

  # User-level equivalent of the gc settings in modules/common.nix
  # (whose nix.* options are system-scoped and don't apply here).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.home-manager.enable = true;

  # home.stateVersion comes from home/common.nix.
}

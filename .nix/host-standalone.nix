# Foreign Linux (Ubuntu pi, Ubuntu VPS, ...): one leaf for all of
# them, instantiated per architecture in flake.nix as
# keyclicker@standalone-<system>. No identity: the distro owns the
# hostname, the system and its management; this is only the user's
# shell environment.
#
# Bootstrap (installs nix, picks the architecture, first switch):
#   $ ~/.dotfiles/install.sh standalone zsh
# Afterwards:
#   $ dots rebuild
{ ... }:

{
  imports = [ ./home-standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";
}

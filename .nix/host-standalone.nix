# Foreign Linux (Ubuntu pi, Ubuntu VPS, ...): one leaf for all of
# them, instantiated per architecture in flake.nix as
# keyclicker@standalone-<system>. No identity: the distro owns the
# hostname, the system and its management; this is only the user's
# shell environment.
#
# Bootstrap (installs nix, picks the architecture, first switch):
#   $ curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- standalone
# Afterwards:
#   $ dots rebuild
{ ... }:

{
  imports = [ ./home-standalone.nix ];

  home.username = "keyclicker";
  home.homeDirectory = "/home/keyclicker";
}

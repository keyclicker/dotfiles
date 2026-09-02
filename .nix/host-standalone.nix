# Foreign Linux (Ubuntu pi, Ubuntu VPS, ...). One leaf for all of
# them; flake.nix instantiates it per architecture as
# keyclicker@standalone-<system>. No identity: the distro owns the
# hostname and the system. This is only the user's shell environment.
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

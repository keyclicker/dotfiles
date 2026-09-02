# Shared by servers (NixOS only): what a headless box adds on top of
# profile-user.nix — docker, and nix-ld for the foreign binaries
# tools download.
{ ... }:

{
  programs.nix-ld.enable = true;
  virtualisation.docker.enable = true;

  users.users.keyclicker.extraGroups = [ "docker" ];
}

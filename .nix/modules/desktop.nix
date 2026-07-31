# Shared by desktops (darwin + NixOS).
{ pkgs, ... }:

{
  environment.systemPackages = (import ../packages.nix { inherit pkgs; }).desktop;
}

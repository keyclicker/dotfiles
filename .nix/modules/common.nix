# Shared by every machine (darwin + NixOS).
{ pkgs, ... }:

{
  nix = {
    # Necessary for using flakes on this system.
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Remove unreachable store paths and generations older than 30 days.
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    # Deduplicate identical files in the Nix store weekly.
    optimise.automatic = true;
  };

  environment.systemPackages = (import ../packages.nix { inherit pkgs; }).common;
}

# Foreign (non-NixOS) Linux hosts: the system stays with the distro
# (apt, systemd), nix provides the user environment via standalone
# home-manager. Emulates at user level what module-common.nix does
# at system level on NixOS/nix-darwin.
{ pkgs, ... }:

{
  imports = [ ./home-common.nix ];

  # System packages become user packages. The imported modules must
  # stay plain { pkgs, ... } functions for this to keep working; the
  # moment one needs config/lib, extract its list into shared data.
  # Extras (dev toolchains, agent CLIs) are added by the host leaf.
  home.packages =
    (import ./module-common.nix { inherit pkgs; }).environment.systemPackages
    ++ [
      # Terminfo for terminals the distro's ncurses doesn't know yet;
      # picked up via TERMINFO_DIRS exported in .zshenv.
      pkgs.ghostty.terminfo
    ];

  # User-level equivalent of the gc settings in module-common.nix
  # (whose nix.* options are system-scoped and don't apply here).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Standalone home-manager manages itself.
  programs.home-manager.enable = true;
}

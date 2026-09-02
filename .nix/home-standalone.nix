# Foreign (non-NixOS) Linux hosts: the system stays with the distro
# (apt, systemd, nix daemon, gc), nix provides only the user
# environment via standalone home-manager: the dotfile links plus the
# same shell tools every NixOS/darwin machine has.
{ pkgs, ... }:

{
  imports = [ ./home-common.nix ];

  # System packages become user packages. The imported modules must
  # stay plain { pkgs, ... } functions for this to keep working; the
  # moment one needs config/lib, extract its list into shared data.
  # Extras (agent CLIs, browser) are added by the jail leaf.
  home.packages =
    (import ./module-common.nix { inherit pkgs; }).environment.systemPackages
    ++ [
      # Terminfo for terminals the distro's ncurses doesn't know yet;
      # picked up via TERMINFO_DIRS exported in .zshenv.
      pkgs.ghostty.terminfo
    ];

  # Standalone home-manager manages itself.
  programs.home-manager.enable = true;
}

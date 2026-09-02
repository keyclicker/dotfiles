# Foreign (non-NixOS) Linux hosts. The distro owns the system: apt,
# systemd, the nix daemon. Standalone home-manager owns only the user
# environment: the dotfile links and the same shell tools every
# NixOS/darwin machine has.
{ pkgs, ... }:

{
  imports = [ ./home-common.nix ];

  # System packages become user packages. This only works while the
  # imported module stays a plain { pkgs, ... } function. The moment
  # it needs config or lib, move its package list into shared data.
  # The jail leaf adds its extras (agent CLIs, browser) the same way.
  home.packages =
    (import ./module-common.nix { inherit pkgs; }).environment.systemPackages
    ++ [
      # Terminfo for terminals the distro's ncurses does not know yet.
      # .zshenv exports TERMINFO_DIRS to pick it up.
      pkgs.ghostty.terminfo
    ];

  # User-level copy of the nix settings in module-common.nix. Its
  # nix.* options are system-scoped and do not apply here.
  nix = {
    # Only used to render and check ~/.config/nix/nix.conf. Not
    # installed: the daemon's nix stays on PATH.
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Nothing on the distro side collects the nix store. This timer
    # is the only gc these hosts get.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Standalone home-manager manages itself.
  programs.home-manager.enable = true;
}

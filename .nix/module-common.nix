# Every machine somebody works in (mac, agents, desktops, foreign
# Linux, jail), on top of module-core.nix: the interactive tool set
# the dotfiles wire up. Generic guests skip it; nothing here is needed
# to administer a box, and yazi + ffmpeg alone weigh over a gigabyte.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GitHub
    gh

    # Shell tools
    bat
    stow
    p7zip
    carapace
    delta

    # User tools
    tokei
    vifm
    yazi
    btop

    # Media
    ffmpeg

    # Encryption
    gnupg
  ];
}

# GUI apps from nixpkgs: the ones that must see the host as it is —
# PATH, nix tools, dotfiles, an unsandboxed $HOME. Terminal, editors,
# media, system tools. The mac gets the same set as homebrew casks;
# the self-updating consumer apps come from flathub instead
# (module-flatpak.nix), where a sandbox costs nothing.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Terminal
    ghostty

    # Browser: the same chromium the agents drive, for a profile that
    # is not brave's.
    chromium

    # Editors and dev
    vscode
    emacs-pgtk # .doom.d
    imhex

    # Media
    mpv
    qbittorrent
    obs-studio
    blender

    # System
    pavucontrol
    nautilus
  ];

  # Nautilus: removable media, trash, network shares.
  services.gvfs.enable = true;
  services.udisks2.enable = true;
}

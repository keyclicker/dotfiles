# GUI apps on the NixOS desktop, the mac's casks
# (module-apps-darwin.nix) from two sources. nixpkgs for the ones
# that must see the host as it is — PATH, nix tools, dotfiles, an
# unsandboxed $HOME: terminal, editors, media, system tools. flathub
# for the self-updating consumer apps (browser, chat, music, notes),
# where a sandbox costs nothing and tracking upstream between
# rebuilds matters: declared with nix-flatpak (its module is imported
# next to the output in flake.nix, this file only sets the options),
# installed at activation, refreshed weekly on their own, so discord's
# "update or else" never bites.
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

  services.flatpak = {
    enable = true;

    packages = [
      "com.brave.Browser"
      "com.discordapp.Discord"
      "com.spotify.Client"
      "md.obsidian.Obsidian"
      "org.telegram.desktop"
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}

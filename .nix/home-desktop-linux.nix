# The NixOS desktop's look, the part that is not a dotfile: GTK apps
# (nautilus, and the flatpaks through the settings portal) follow
# dconf and settings.ini, which home-manager writes; sway, waybar,
# fuzzel, mako and ghostty carry their own TokyoNight colors in the
# dotfiles home-dotfiles.nix links. Pairs with
# module-desktop-linux.nix.
{ pkgs, ... }:

{
  # ~/Pictures for screenshots and the rest of the standard set.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };
}

# Desktop-only dotfile links: GUI tools and window management. Mac
# and the NixOS desktop; the Linux branch also carries the GTK look,
# which lives in dconf and settings.ini rather than in a dotfile.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
lib.mkMerge [
  {
    home.file = {
      ".doom.d".source = link ".doom.d";
      ".config/ghostty".source = link ".config/ghostty";
      ".config/mpv/input.conf".source = link ".config/mpv/input.conf";
      ".config/mpv/mpv.conf".source = link ".config/mpv/mpv.conf";
      ".config/qalculate".source = link ".config/qalculate";
      # mac-only tools, but the links are inert elsewhere
      ".config/karabiner".source = link ".config/karabiner";
      ".config/linearmouse".source = link ".config/linearmouse";
      ".config/skhd".source = link ".config/skhd";
      ".config/yabai".source = link ".config/yabai";
    };
  }

  (lib.mkIf isDarwin {
    home.file."Library/Preferences/DOSBox 0.74-3-3 Preferences".source =
      link "Library/Preferences/DOSBox 0.74-3-3 Preferences";
  })

  (lib.mkIf isLinux {
    # The sway session (module-sway.nix installs what these call).
    home.file = {
      ".config/sway".source = link ".config/sway";
      ".config/waybar".source = link ".config/waybar";
      ".config/wofi".source = link ".config/wofi";
      ".config/mako".source = link ".config/mako";
      ".config/pavucontrol.ini".source = link ".config/pavucontrol.ini";
    };

    # ~/Pictures for screenshots and the rest of the standard set.
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    # GTK apps (nautilus, and the flatpaks through the settings
    # portal) follow these; sway, waybar, wofi, mako and ghostty
    # carry their own TokyoNight colors.
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
  })
]

# Desktop-only dotfile links: GUI tools and window management.
# Mac today; the future NixOS desktop reuses the isLinux branch.
{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  home.file =
    {
      ".doom.d".source = link ".doom.d";
      ".config/ghostty".source = link ".config/ghostty";
      ".config/mpv".source = link ".config/mpv";
      ".config/qalculate".source = link ".config/qalculate";
      # mac-only tools, but the links are inert elsewhere
      ".config/karabiner".source = link ".config/karabiner";
      ".config/linearmouse".source = link ".config/linearmouse";
      ".config/skhd".source = link ".config/skhd";
      ".config/yabai".source = link ".config/yabai";
    }
    // (
      if isDarwin then
        {
          "Library/Preferences/DOSBox 0.74-3-3 Preferences".source =
            link "Library/Preferences/DOSBox 0.74-3-3 Preferences";
        }
      else
        { }
    )
    // (
      if isLinux then
        {
          ".config/keyd".source = link ".config/keyd";
          ".config/sway".source = link ".config/sway";
          ".config/waybar".source = link ".config/waybar";
          ".config/wofi".source = link ".config/wofi";
          ".config/pavucontrol.ini".source = link ".config/pavucontrol.ini";
        }
      else
        { }
    );
}

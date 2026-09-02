# Consumer apps from flathub, self-updating like the homebrew casks
# on the mac: browser, chat, music, notes. Declared with nix-flatpak
# (its module is imported next to the output in flake.nix, this file
# only sets the options): installed at activation, refreshed weekly
# on their own, so discord's "update or else" never bites between
# rebuilds. Apps that must see the host's PATH and dotfiles stay in
# nixpkgs (module-apps.nix).
{ ... }:

{
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

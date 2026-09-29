# Keep personal folders together, away from the dotfiles in $HOME.
{ config, ... }:

let
  files = "${config.home.homeDirectory}/Files";
in
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "${files}/Desktop";
    documents = "${files}/Documents";
    download = "${files}/Downloads";
    music = "${files}/Music";
    pictures = "${files}/Pictures";
    publicShare = "${files}/Public";
    templates = "${files}/Templates";
    videos = "${files}/Videos";
  };
}

# Shared by desktops (mac + the NixOS desktop leaves).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Chess engines
    stockfish
    #gnuchess
    #lc0

    # Calculator
    libqalculate

    # Media downloader
    yt-dlp
  ];
}

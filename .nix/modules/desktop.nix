# Shared by desktops (mac + future NixOS desktop).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Chess engines
    stockfish
    #gnuchess
    #lc0

    # AI
    ollama

    # Calculator
    libqalculate

    # Media downloader
    yt-dlp
  ];
}

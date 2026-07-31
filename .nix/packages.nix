{ pkgs }:

{
  # Cross-platform CLI tools the dotfiles depend on. Installed everywhere.
  common = with pkgs; [
    # Basics
    coreutils
    cmake
    openssh
    git
    gh

    # Shell tools
    fd
    wget
    bat
    fzf
    ripgrep
    tealdeer # Better-maintained replacement for tldr client
    stow
    p7zip
    watch
    tree
    carapace
    delta

    # User tools
    tokei
    mc
    vifm
    htop
    btop

    # Development
    pnpm
    uv
    luarocks

    # Workspace
    tmux
    neovim

    # Encryption
    gnupg

    # Dependencies
    tree-sitter
  ];

  # Shared by desktops (mac + future NixOS desktop).
  desktop = with pkgs; [
    ffmpeg
    nodejs
    postgresql
    postgresql.pg_config
    go
    rustup

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

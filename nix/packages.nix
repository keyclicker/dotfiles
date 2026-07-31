{ pkgs, ... }:

{
  homebrew = {
    enable = true;
    casks = [
      "blender"
      "brave-browser"
      "chatgpt"
      "claude"
      "discord"
      "ghostty"
      "github"
      "imhex"
      "karabiner-elements"
      "obs"
      "obsidian"
      "postico"
      "puremac"
      "qbittorrent"
      "spotify"
      "tailscale-app"
      "visual-studio-code"
      "xld"
      "mactex-no-gui"
      "raspberry-pi-imager"
      "t3-code"
    ];
  };

  # Packages installed in the system profile.
  environment.systemPackages = with pkgs; [
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
    # neofetch
    ffmpeg
    tokei
    mc
    vifm
    htop
    btop

    # Development
    go
    rustup
    nodejs
    pnpm
    uv
    luarocks
    postgresql
    postgresql.pg_config

    # Containers
    docker
    docker-compose
    docker-buildx
    colima
    lazydocker

    # Workspace
    skhd
    tmux
    neovim

    # Encryption
    gnupg
    pinentry_mac

    # Dependencies
    tree-sitter

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

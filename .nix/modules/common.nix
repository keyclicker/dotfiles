# Shared by every machine (darwin + NixOS): nix settings + the
# cross-platform CLI tools the dotfiles depend on.
{ pkgs, ... }:

{
  nix = {
    # Necessary for using flakes on this system.
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Remove unreachable store paths and generations older than 30 days.
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    # Deduplicate identical files in the Nix store weekly.
    optimise.automatic = true;
  };

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
    tokei
    mc
    vifm
    htop
    btop

    # Development
    nodejs
    pnpm
    uv
    luarocks
    go
    rustup
    postgresql
    postgresql.pg_config

    # Media
    ffmpeg

    # Containers (docker itself is per-host: daemon on NixOS, colima on mac)
    docker-compose
    lazydocker

    # Workspace
    tmux
    neovim

    # Encryption
    gnupg

    # Dependencies
    tree-sitter
  ];
}

# Shared by every machine (darwin + NixOS): nix settings + the
# cross-platform CLI tools the dotfiles depend on.
{ pkgs, ... }:

{
  time.timeZone = "America/Vancouver";

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
    openssh
    git
    gh

    # Shell (NixOS hosts also set programs.zsh.enable in server.nix;
    # foreign hosts get the binary from here)
    zsh

    # Userland the dotfiles and their scripts assume. Real hosts also
    # get most of these from the distro; the Docker jail has nothing
    # underneath, so they are declared here rather than per-host.
    curl
    diffutils
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    gzip
    jq
    less
    which
    xz

    # Shell tools
    fd
    rsync
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
    tree-sitter # nvim
  ];
}

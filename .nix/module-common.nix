# Shared by every machine (darwin + NixOS): nix settings, the
# cross-platform CLI tools the dotfiles depend on, and the dev
# toolchains. Every machine wants both, so they live in one file.
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

    # Deduplicate identical files in the Nix store on a timer.
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    # Basics
    coreutils
    openssh
    git
    gh

    # Shell. NixOS hosts also set programs.zsh.enable in
    # profile-server.nix; foreign hosts get the binary from here.
    zsh

    # Userland the dotfiles assume. NixOS already has these in its
    # required set, so listing them again costs nothing there.
    # nix-darwin ships none of them, Ubuntu picks mawk over gawk, and
    # the jail has no distro at all. Declaring them here makes all
    # four behave the same.
    curl
    diffutils
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    gzip
    iperf3
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
    yazi
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

    # Build
    cmake
    gnumake
    pkg-config
    binutils

    # Languages
    python3
    nodejs
    pnpm
    uv
    luarocks
    go
    rustup
    postgresql
    postgresql.pg_config

    # C compilers, for nvim-treesitter grammar builds and the like.
    # Both wrappers provide cc and c++. hiPrio makes gcc win that
    # collision; clang stays available under its own name.
    (pkgs.lib.hiPrio gcc)
    clang
  ];
}

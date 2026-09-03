# Every machine (darwin + NixOS + foreign Linux): nix settings and the
# CLI floor a box is administered with over ssh. Generic guests (vm,
# container) stop here so their store stays small; every other
# machine stacks module-common.nix and module-dev.nix on top.
{ pkgs, ... }:

{
  time.timeZone = "America/Vancouver";

  # vscode, discord, spotify, ... on the desktop; the mac already
  # takes them as casks.
  nixpkgs.config.allowUnfree = true;

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

    # Shell (NixOS hosts also set programs.zsh.enable in profile-server.nix;
    # foreign hosts get the binary from here)
    zsh

    # Userland the dotfiles assume. NixOS lists the same store paths in
    # its required set, so the overlap there is free; nix-darwin ships
    # none of it, Ubuntu defaults to mawk over gawk, and the jail has
    # no platform at all. Declaring it here is what makes the four
    # behave the same.
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
    fzf
    ripgrep
    watch
    tree
    htop
    tealdeer # Better-maintained replacement for tldr client

    # Containers (docker itself is per-host: daemon on NixOS, colima on
    # mac). Generic guests run compose stacks and are watched with
    # lazydocker over ssh, so both belong to the floor.
    docker-compose
    lazydocker

    # Workspace
    tmux
    neovim
    mc
  ];
}

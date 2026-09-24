# Interactive tools and dev toolchains for every machine somebody works in
# (mac, agents, desktops, foreign Linux), on top of module-core.nix.
# Generic guests skip this layer to keep their stores small.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # GitHub
    gh

    # Shell tools
    bat
    stow
    p7zip
    carapace
    delta

    # User tools
    tokei
    vifm
    yazi
    btop

    # Media
    ffmpeg

    # Encryption
    gnupg

    # Dependencies
    tree-sitter # nvim
    unzip # nvim: mason unpacks zip-shipped tools (clangd, stylua) with it

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

    # C compilers (nvim-treesitter grammar builds and the like). Both
    # wrappers provide cc/c++; hiPrio makes gcc win that collision,
    # clang stays available under its own name.
    (pkgs.lib.hiPrio gcc)
    clang
  ];
}

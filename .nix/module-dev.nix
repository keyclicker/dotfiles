# Dev toolchains: build tools, languages, C compilers. Stacked
# wherever module-common.nix is, on its own so the toolchain list
# reads separately from the shell tools and can be left off a host
# that only needs a shell.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
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

    # C compilers (nvim-treesitter grammar builds and the like). Both
    # wrappers provide cc/c++; hiPrio makes gcc win that collision,
    # clang stays available under its own name.
    (pkgs.lib.hiPrio gcc)
    clang
  ];
}

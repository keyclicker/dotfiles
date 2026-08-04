# Development toolchains, split from common so lean hosts can skip
# them. Every full machine stacks common + dev.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Build
    cmake

    # Languages
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

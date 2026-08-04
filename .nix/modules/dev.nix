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
  ];
}

{
  description = "agent-jail user tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.buildEnv {
            name = "agent-jail-user-tools";
            paths = with pkgs; [
              neovim
              postgresql
              nginx
              python312
              eslint
              prettier
              tsx
              python312Packages.pytest
              ruff
            ];
          };
        });
    };
}

{
  description = "keyclicker's machines";

  inputs = {
    # Linux hosts follow nixos-unstable; mac keeps nixpkgs-unstable
    # (same pin the original standalone darwin flake used).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
    }:
    {
      # $ sudo darwin-rebuild switch --flake ~/.nix#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          ./modules/common.nix
          ./modules/desktop.nix
          ./hosts/mac.nix
          { system.configurationRevision = self.rev or self.dirtyRev or null; }
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.nix#agents
      nixosConfigurations."agents" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./modules/common.nix
          ./modules/server.nix
          ./modules/slopbox.nix
          ./hosts/agents.nix
        ];
      };
    };
}

{
  description = "keyclicker's machines";

  inputs = {
    # Linux hosts follow nixos-unstable; mac keeps nixpkgs-unstable
    # (same pin the original standalone darwin flake used).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
    }:
    let
      # The jail image is built for whatever the Docker host runs, so
      # the leaf is instantiated once per architecture and the
      # launcher asks for the name matching its own.
      jailConfigurations = nixpkgs.lib.listToAttrs (
        map
          (system: {
            name = "keyclicker@jail-${system}";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${system};
              modules = [ ./host-jail.nix ];
            };
          })
          [
            "aarch64-linux"
            "x86_64-linux"
          ]
      );
    in
    {
      # Wiring only: one output per machine, each pointing at its
      # host-*.nix leaf, which is where the module stack is composed.
      # Home-manager stays here because it needs the flake input.

      # $ sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          ./host-mac.nix
          home-manager.darwinModules.home-manager
          {
            # Required by the home-manager darwin module.
            users.users.keyclicker.home = "/Users/keyclicker";
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [
                ./home-common.nix
                ./home-desktop.nix
              ];
            };
          }
          { system.configurationRevision = self.rev or self.dirtyRev or null; }
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents
      nixosConfigurations."agents" = nixpkgs.lib.nixosSystem {
        modules = [
          ./host-agents.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [ ./home-common.nix ];
            };
          }
        ];
      };

      # Generic guests: one configuration, spawned as many times as
      # needed, no pet identity (see the leaves).

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
      nixosConfigurations."vm" = nixpkgs.lib.nixosSystem {
        modules = [ ./host-vm.nix ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        modules = [ ./host-container.nix ];
      };

      homeConfigurations = {
        # Ubuntu pi: apt system, nix user environment.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
        "keyclicker@raspberry" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [ ./host-raspberry.nix ];
        };

        # Ubuntu VPS: apt system, nix user environment, no agent CLIs.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@vps
        "keyclicker@vps" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./host-vps.nix ];
        };
      }
      # Docker jail: activated inside the container by
      # .scripts/agent-jail, one entry per supported architecture.
      // jailConfigurations;
    };
}

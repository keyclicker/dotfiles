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
              modules = [ ./hosts/jail.nix ];
            };
          })
          [
            "aarch64-linux"
            "x86_64-linux"
          ]
      );
    in
    {
      # $ sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          ./modules/common.nix
          ./modules/desktop.nix
          ./modules/agents.nix
          ./modules/ollama-darwin.nix
          ./hosts/mac.nix
          home-manager.darwinModules.home-manager
          {
            # Required by the home-manager darwin module.
            users.users.keyclicker.home = "/Users/keyclicker";
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [
                ./home/common.nix
                ./home/desktop.nix
              ];
            };
          }
          { system.configurationRevision = self.rev or self.dirtyRev or null; }
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents
      nixosConfigurations."agents" = nixpkgs.lib.nixosSystem {
        # Arch comes from nixpkgs.hostPlatform in hosts/agents-hardware.nix.
        modules = [
          ./modules/common.nix
          ./modules/server.nix
          ./modules/agents.nix
          ./modules/browser.nix
          ./modules/slopbox.nix
          ./modules/iperf.nix
          ./modules/vm.nix
          ./option-lan.nix
          ./hosts/agents.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [ ./home/common.nix ];
            };
          }
        ];
      };

      # Generic guests: one configuration, spawned as many times as
      # needed, no pet identity (hostname comes from the spawner or
      # hostnamectl, see modules/vm.nix / platform-container.nix).
      # Prebuilt images come later (#32); until then install the
      # manual way and switch like any other configuration. No
      # home-manager: a fresh guest has no ~/.dotfiles checkout for
      # the symlinks to point at.

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
      nixosConfigurations."vm" = nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/common.nix
          ./modules/server.nix
          ./modules/vm.nix
          ./option-lan.nix
          ./host-vm.nix
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        modules = [
          ./modules/common.nix
          ./modules/server.nix
          ./platform-container.nix
          ./option-lan.nix
          ./host-container.nix
        ];
      };

      homeConfigurations = {
        # Ubuntu pi: apt system, nix user environment.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
        "keyclicker@raspberry" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [ ./hosts/raspberry.nix ];
        };

        # Ubuntu VPS: apt system, nix user environment, no agent CLIs.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@vps
        "keyclicker@vps" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./hosts/vps.nix ];
        };
      }
      # Docker jail: activated inside the container by
      # .scripts/agent-jail, one entry per supported architecture.
      // jailConfigurations;
    };
}

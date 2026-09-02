{
  description = "keyclicker's machines";

  inputs = {
    # Linux hosts follow nixos-unstable. The mac stays on
    # nixpkgs-unstable, the pin its old standalone flake used.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      disko,
    }:
    let
      # home-manager needs pkgs for one fixed system, and these leaves
      # serve any machine. So each leaf gets one output per
      # architecture, keyclicker@<name>-<system>. The caller (dots,
      # agent-jail) picks the one matching its own.
      homePerSystem =
        name: leaf:
        nixpkgs.lib.listToAttrs (
          map
            (system: {
              name = "keyclicker@${name}-${system}";
              value = home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.${system};
                modules = [ leaf ];
              };
            })
            [
              "aarch64-linux"
              "x86_64-linux"
            ]
        );
    in
    {
      # Wiring only. Each output points at its host-*.nix leaf, and the
      # leaf composes the module stack. Home-manager and disko are
      # wired here because they need the flake inputs. The leaves only
      # set their options.

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
          disko.nixosModules.disko
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
        modules = [
          ./host-vm.nix
          disko.nixosModules.disko
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        modules = [ ./host-container.nix ];
      };

      homeConfigurations =
        # Foreign Linux (Ubuntu pi, VPS, ...): distro system, nix user
        # environment. `dots rebuild` resolves the architecture.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@standalone-x86_64-linux
        homePerSystem "standalone" ./host-standalone.nix
        # Docker jail: activated inside the container by .scripts/agent-jail.
        // homePerSystem "jail" ./host-jail.nix;
    };
}

{
  description = "keyclicker's machines";

  inputs = {
    # Linux hosts follow nixos-unstable; mac keeps nixpkgs-unstable
    # (same pin the original standalone darwin flake used).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # The agent CLIs ship near-daily, the rest of a machine does not,
    # so they get a pin of their own: `nix flake update nixpkgs-agents`
    # refreshes them alone. nixpkgs-unstable because this single input
    # serves darwin and linux hosts alike.
    nixpkgs-agents.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      nixpkgs-agents,
      nix-darwin,
      home-manager,
    }:
    let
      # The agents pin, instantiated rather than taken from
      # `legacyPackages`: nixpkgs marks claude-code unfree, and the
      # permission has to be given to the package set the CLIs come
      # from — a host-side allowUnfree would not reach in here. Named
      # one by one, so nothing else unfree slips in with it.
      agentPkgsFor =
        system:
        import nixpkgs-agents {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        };

      # modules/agents.nix names claude-code, codex and opencode like
      # any other package; this is what makes them resolve through the
      # agents pin on every host instead of the host's own nixpkgs.
      agentOverlay = final: prev: {
        inherit (agentPkgsFor prev.stdenv.hostPlatform.system)
          claude-code
          codex
          opencode
          ;
      };

      # Standalone home-manager leaves are handed a package set
      # directly, and `legacyPackages` carries no overlays.
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ agentOverlay ];
        };

      # The jail image is built for whatever the Docker host runs, so
      # the leaf is instantiated once per architecture and the
      # launcher asks for the name matching its own.
      jailConfigurations = nixpkgs.lib.listToAttrs (
        map
          (system: {
            name = "keyclicker@jail-${system}";
            value = home-manager.lib.homeManagerConfiguration {
              pkgs = pkgsFor system;
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
          ./modules/dev.nix
          ./modules/desktop.nix
          ./modules/agents.nix
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
          {
            nixpkgs.overlays = [ agentOverlay ];
            system.configurationRevision = self.rev or self.dirtyRev or null;
          }
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents
      nixosConfigurations."agents" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./modules/common.nix
          ./modules/dev.nix
          ./modules/server.nix
          ./modules/agents.nix
          ./modules/browser.nix
          ./modules/slopbox.nix
          ./hosts/agents.nix
          home-manager.nixosModules.home-manager
          { nixpkgs.overlays = [ agentOverlay ]; }
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

      homeConfigurations = {
        # Ubuntu pi: apt system, nix user environment.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
        "keyclicker@raspberry" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "aarch64-linux";
          modules = [ ./hosts/raspberry.nix ];
        };

        # Ubuntu VPS: apt system, nix user environment, no agent CLIs
        # — hence the only leaf without the agents overlay.
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

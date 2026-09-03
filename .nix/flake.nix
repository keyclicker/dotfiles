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
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Declarative flathub apps for the desktop (module-apps-linux.nix).
    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      disko,
      nix-flatpak,
    }:
    let
      # Standalone home-manager outputs carry no machine identity, but
      # home-manager needs pkgs for a fixed system, so each leaf is
      # instantiated once per architecture as keyclicker@<name>-<system>
      # and the caller (dots, agent-jail) picks the one matching its own.
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

      # The desktop leaf with its flake-input plumbing, built twice:
      # for Proxmox as is, for UTM on the mac with platform-utm.nix
      # on top.
      desktopModules = [
        ./host-desktop.nix
        disko.nixosModules.disko
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
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
      ];

      # NixOS outputs share one constructor so every leaf gets the
      # platform as a special arg: module-ollama-desktop.nix has to
      # pick launchd or services.ollama before config exists, and
      # asking pkgs there is infinite recursion.
      nixos =
        modules:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            isDarwin = false;
          };
          inherit modules;
        };
    in
    {
      # Wiring only: one output per machine, each pointing at its
      # host-*.nix leaf, which is where the module stack is composed.
      # Home-manager, disko and nix-flatpak stay here because they
      # need the flake input; the leaves only set their options.

      # $ sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          isDarwin = true;
        };
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
      nixosConfigurations."agents" = nixos [
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

      # Desktop VM (#35): generic like vm, but with home-manager, since
      # the sway session is made of dotfiles.

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#desktop-vm
      nixosConfigurations."desktop-vm" = nixos desktopModules;

      # $ dots set desktop-utm; dots rebuild
      nixosConfigurations."desktop-utm" = nixos (desktopModules ++ [ ./platform-utm.nix ]);

      # Generic guests: one configuration, spawned as many times as
      # needed, no pet identity (see the leaves).

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
      nixosConfigurations."vm" = nixos [
        ./host-vm.nix
        disko.nixosModules.disko
      ];

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
      nixosConfigurations."container" = nixos [ ./host-container.nix ];

      homeConfigurations =
        # Foreign Linux (Ubuntu pi, VPS, ...): distro system, nix user
        # environment. `dots rebuild` resolves the architecture.
        # $ home-manager switch --flake ~/.dotfiles/.nix#keyclicker@standalone-x86_64-linux
        homePerSystem "standalone" ./host-standalone.nix
        # Docker jail: activated inside the container by .scripts/agent-jail.
        // homePerSystem "jail" ./host-jail.nix;
    };
}

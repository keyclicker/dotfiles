{
  description = "keyclicker's machines";

  inputs = {
    # One nixpkgs for every host, mac included: nixos-unstable is
    # cut from the same commits as nixpkgs-unstable, only gated on
    # the NixOS tests instead of the darwin jobs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # PR 1277 until it merges: master's image builder still hands a
    # module tree to vmTools as the kernel, which nixpkgs now rejects.
    disko.url = "github:nix-community/disko/pull/1277/head";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Declarative flathub apps for the desktop (module-apps-linux.nix).
    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      disko,
      nix-flatpak,
      ...
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

      # Flake-input plumbing shared by the desktop leaves (Proxmox and
      # UTM): disko, nix-flatpak and home-manager with the desktop
      # home layers.
      desktopModules = [
        disko.nixosModules.disko
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            users.keyclicker.imports = [
              ./home-dotfiles.nix
              ./home-desktop-linux.nix
            ];
          };
        }
      ];
    in
    {
      # Wiring only: one output per machine, each pointing at its
      # host-*.nix leaf, which is where the module stack is composed.
      # Home-manager, disko and nix-flatpak stay here because they
      # need the flake input; the leaves only set their options.

      # $ sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          os = "darwin";
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
              users.keyclicker.imports = [ ./home-dotfiles.nix ];
            };
          }
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
              users.keyclicker.imports = [ ./home-dotfiles.nix ];
            };
          }
        ];
      };

      # Desktop VM (#35): generic like vm, but with home-manager, since
      # the sway session is made of dotfiles.

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#desktop-vm
      nixosConfigurations."desktop-vm" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          os = "linux";
        };
        modules = [ ./host-desktop-vm.nix ] ++ desktopModules;
      };

      # $ dots set desktop-utm; dots rebuild
      nixosConfigurations."desktop-utm" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          os = "linux";
        };
        modules = [ ./host-desktop-utm.nix ] ++ desktopModules;
      };

      # Generic guests: one configuration, spawned as many times as
      # needed, no pet identity (see the leaves).

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
      nixosConfigurations."vm" = nixpkgs.lib.nixosSystem {
        modules = [
          ./host-vm.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [ ./home-dotfiles.nix ];
            };
          }
        ];
      };

      # $ sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        modules = [
          ./host-container.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              users.keyclicker.imports = [ ./home-dotfiles.nix ];
            };
          }
        ];
      };

      # Prebuilt guest images (#32): the files a hypervisor imports
      # instead of running the installer. x86_64 like the guests;
      # `dots image <target> [host:dir]` builds and ships one, the
      # import flow is in README.md.
      packages.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          vm = self.nixosConfigurations.vm.config;
          container = self.nixosConfigurations.container.config;
        in
        {
          # main.qcow2 + swap.qcow2: disko formats blank images as
          # hardware-vm.nix says and installs the vm closure into them,
          # in a build VM, so the result boots like an `iso vm` install.
          vm-image = vm.system.build.diskoImages;

          # rootfs.tar.xz (lxc-container.nix, already in the container's
          # stack) + the incus metadata tarball next to it; Proxmox CTs
          # take the rootfs alone.
          container-image = pkgs.linkFarm "container-image" {
            "rootfs.tar.xz" = "${container.system.build.tarball}/${container.image.filePath}";
            "metadata.tar.xz" = "${container.system.build.metadata}/${container.image.filePath}";
          };
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

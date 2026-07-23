{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration = { ... }: {
        system = {
          primaryUser = "keyclicker";
        };

        nix = {
          # Necessary for using flakes on this system.
          settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Remove unreachable store paths and generations older than 30 days.
          gc = {
            automatic = true;
            options = "--delete-older-than 30d";
          };

          # Deduplicate identical files in the Nix store weekly.
          optimise.automatic = true;
        };

        # Move windows by holding Control+Command and dragging anywhere.
        system.defaults.NSGlobalDomain.NSWindowShouldDragOnGesture = true;

        # Keep Touch ID available inside long-running tmux sessions.
        security.pam.services.sudo_local = {
          touchIdAuth = true;
          reattach = true;
        };

        # Enable alternative shell support in nix-darwin.
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 6;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          ./packages.nix
        ];
      };
    };
}

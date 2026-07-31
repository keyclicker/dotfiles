{ pkgs, ... }:

{
  system = {
    primaryUser = "keyclicker";
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

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    enable = true;
    casks = [
      "blender"
      "brave-browser"
      "chatgpt"
      "claude"
      "discord"
      "ghostty"
      "imhex"
      "karabiner-elements"
      "obs"
      "obsidian"
      "postico"
      "puremac"
      "qbittorrent"
      "spotify"
      "visual-studio-code"
      "xld"
    ];
  };

  # Mac-only packages; cross-platform ones come from modules/{common,desktop}.
  environment.systemPackages = with pkgs; [
    # Containers
    docker
    docker-compose
    docker-buildx
    colima
    lazydocker

    # Workspace
    skhd

    # Encryption
    pinentry_mac
  ];
}

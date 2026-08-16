{ pkgs, ... }:

{
  system = {
    primaryUser = "keyclicker";
  };

  # Pin the name — macOS silently renames to "MacBookPro" after name
  # conflicts on the network, OS updates, or iCloud sync.
  networking = {
    hostName = "mac";
    localHostName = "mac";
    computerName = "mac";
  };

  system.defaults.NSGlobalDomain = {
    # Move windows by holding Control+Command and dragging anywhere.
    NSWindowShouldDragOnGesture = true;
    # No alternative characters on hold.
    ApplePressAndHoldEnabled = false;
  };

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
      "github"
      "google-chrome"
      "imhex"
      "karabiner-elements"
      "obs"
      "obsidian"
      "postico"
      "puremac"
      "qbittorrent"
      "spotify"
      "tailscale-app"
      "visual-studio-code"
      "xld"
      "mactex-no-gui"
      "raspberry-pi-imager"
      "t3-code"
      "handy"
      "cmux"
    ];
  };

  # Mac-only packages; cross-platform ones come from modules/{common,desktop}.
  environment.systemPackages = with pkgs; [
    # Containers
    docker
    docker-buildx
    colima

    # Workspace
    skhd

    # Encryption
    pinentry_mac
  ];
}

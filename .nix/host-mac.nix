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
      "brave-browser"
      "google-chrome"

      "handy"
      "mos"
      "linearmouse"
      "logi-options+"
      "monitorcontrol"
      "karabiner-elements"

      "ghostty"
      "github"
      "visual-studio-code"
      "imhex"

      "chatgpt"
      "claude"
      "t3-code"

      "postico"
      "postman"

      "wifiman"
      "tailscale-app"
      "raspberry-pi-imager"
      "utm"

      "qbittorrent"
      "spotify"

      "obs"
      "xld"
      "grandperspective"
      "blender"
      "adobe-creative-cloud"

      "obsidian"
      "discord"
      "puremac"
      "mactex-no-gui"

      # To test:
      "cmux"
    ];
  };

  # Mac-only packages; cross-platform ones come from module-common / profile-desktop.
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

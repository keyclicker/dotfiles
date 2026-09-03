# The MacBook: nix-darwin system layer; the apps are homebrew casks
# (module-apps-darwin.nix).
{ ... }:

{
  imports = [
    ./module-common.nix
    ./profile-desktop.nix
    ./module-agents.nix
    ./module-ollama-desktop.nix
    ./module-apps-darwin.nix
  ];

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
}

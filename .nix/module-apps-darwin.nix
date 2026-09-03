# GUI apps on the mac, as homebrew casks (self-updating, signed,
# what the apps' own installers would put in /Applications), plus
# the mac-only packages from nixpkgs. module-apps-linux.nix is the
# same set for the NixOS desktop.
{ pkgs, ... }:

{
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

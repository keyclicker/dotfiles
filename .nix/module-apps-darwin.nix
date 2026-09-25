# GUI apps on the mac, as homebrew casks (self-updating, signed,
# what the apps' own installers would put in /Applications), plus
# selected packages from nixpkgs. module-apps-linux.nix is the
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

      "chatgpt"
      "claude"
      "t3-code"
      "muse"

      "postico"
      "postman"

      "wifiman"
      "tailscale-app"
      "raspberry-pi-imager"
      "utm"

      "spotify"

      "obs"
      "grandperspective"
      "blender"
      "adobe-creative-cloud"

      "obsidian"
      "discord"
      "telegram"
      "puremac"
      "mactex-no-gui"

      # To test:
      "cmux"
    ];
  };

  # Packages managed by Nix on macOS.
  environment.systemPackages = with pkgs; [
    # Desktop apps
    imhex
    qbittorrent
    xld

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

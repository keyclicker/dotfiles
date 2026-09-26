# The agents VM console: XFCE/X11 for Cua, viewed through Proxmox SPICE.
{ pkgs, ... }:

let
  cuaDriver = pkgs.callPackage ./package-cua-driver.nix { };
in
{
  services.xserver = {
    enable = true;
    videoDrivers = [
      "modesetting"
      "qxl"
    ];
    displayManager.lightdm.enable = true;
    desktopManager.xfce = {
      enable = true;
      # The server account has no password to unlock a screensaver.
      enableScreensaver = false;
    };
  };

  # Console access is already gated by Proxmox, like the serial autologin.
  services.displayManager = {
    defaultSession = "xfce";
    autoLogin = {
      enable = true;
      user = "keyclicker";
    };
  };

  services.spice-vdagentd.enable = true;
  services.gnome.at-spi2-core.enable = true;
  environment.systemPackages = [ cuaDriver ];

  # Inherit the display and session bus imported by the X11 session wrapper.
  systemd.user.services.cua-driver = {
    description = "Cua desktop automation";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${cuaDriver}/bin/cua-driver serve";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}

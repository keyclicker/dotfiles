# Persistent XFCE/X11 desktop for Cua, shared through Tailnet-only noVNC
# (module-gateway.nix serves it at /desktop/).
{
  lib,
  pkgs,
  ...
}:

let
  cuaDriver = import ./package-cua-driver.nix { inherit pkgs; };
  vncPort = "5901";
  webPort = "6080";
in
{
  services.xserver = {
    enable = true;
    videoDrivers = [ "dummy" ];

    # A real Xorg server hot-plugs Cua's virtual input devices; Xvnc cannot.
    # Keep the 4:3 frame independent of the viewer's browser dimensions.
    resolutions = [
      {
        x = 1280;
        y = 960;
      }
    ];
    virtualScreen = {
      x = 1280;
      y = 960;
    };
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
    monitorSection = ''
      HorizSync 30-100
      VertRefresh 50-100
    '';
    deviceSection = ''
      VideoRam 16384
    '';

    displayManager.lightdm = {
      enable = true;
      greeter.enable = false;
      extraConfig = ''
        logind-check-graphical = false
        minimum-display-number = 1
      '';
    };

    desktopManager.xfce = {
      enable = true;
      # The server account has no password to unlock a screensaver.
      enableScreensaver = false;
    };
  };

  services.displayManager = {
    defaultSession = "xfce";
    autoLogin = {
      enable = true;
      user = "keyclicker";
    };
  };

  # Use NixOS's restricted uinput group, not a world-writable device.
  hardware.uinput.enable = true;
  users.users.keyclicker.extraGroups = [ "uinput" ];
  users.users.keyclicker.linger = true;

  fonts.packages = [ pkgs.noto-fonts ];
  services.gnome.at-spi2-core.enable = true;

  environment.systemPackages = [ cuaDriver ];

  # XFCE runs application autostarts after its window manager is ready.
  # Starting at graphical-session.target races the compositor: Cua chooses
  # its overlay visual once at startup, leaving the cursor invisible.
  environment.etc."xdg/autostart/cua-desktop.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Cua desktop services
    Exec=${pkgs.systemd}/bin/systemctl --user start cua-driver.service desktop-vnc.service
    OnlyShowIn=XFCE;
    Terminal=false
    StartupNotify=false
  '';

  systemd.user.services.cua-driver = {
    description = "Cua desktop automation";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    # Preserve the graphical session's PATH for apps launched through Cua.
    environment.PATH = lib.mkForce null;

    serviceConfig = {
      ExecStart = "${cuaDriver}/bin/cua-driver serve";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Export the existing Xorg desktop; viewer disconnects leave it running.
  # DISPLAY and XAUTHORITY come from the NixOS X11 session wrapper.
  systemd.user.services.desktop-vnc = {
    description = "Share the XFCE desktop over loopback VNC";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = toString [
        "${pkgs.tigervnc}/bin/x0vncserver"
        "-rfbport ${vncPort} -localhost -SecurityTypes None -AlwaysShared"
        "-AcceptSetDesktopSize=0"
      ];
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.services.novnc = {
    description = "Browser access to the XFCE desktop";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = toString [
        "${pkgs.python3Packages.websockify}/bin/websockify"
        "--web ${pkgs.novnc}/share/webapps/novnc"
        "127.0.0.1:${webPort} 127.0.0.1:${vncPort}"
      ];
      DynamicUser = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}

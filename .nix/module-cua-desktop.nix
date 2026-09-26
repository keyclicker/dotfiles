# Persistent XFCE/X11 desktop for Cua, shared through Tailnet-only noVNC.
{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./option-tailnet.nix ];

  local.tailnet.https."8445" = "http://127.0.0.1:6080";

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = false;
    desktopManager.xfce = {
      enable = true;
      # The server account has no password to unlock a screensaver.
      enableScreensaver = false;
    };
  };

  services.gnome.at-spi2-core.enable = true;
  environment.systemPackages = [ pkgs.tigervnc ];
  # Cua's official prebuilt installer uses the standard Linux loader.
  programs.nix-ld.libraries = with pkgs; [
    libX11
    libXi
    libxkbcommon
  ];
  users.users.keyclicker.linger = true;

  # xinit owns both processes: restarting the service restarts the session.
  systemd.user.services.vnc-desktop = {
    description = "XFCE desktop on TigerVNC";
    wantedBy = [ "default.target" ];
    environment = {
      XAUTHORITY = "%t/vnc-desktop/Xauthority";
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "XFCE";
    };
    preStart = ''
      umask 077
      ${pkgs.xauth}/bin/xauth -f "$XAUTHORITY" add :1 . \
        "$(${pkgs.util-linux}/bin/mcookie)"
    '';
    serviceConfig = {
      RuntimeDirectory = "vnc-desktop";
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.xinit}/bin/xinit"
        config.services.displayManager.sessionData.wrapper
        "${pkgs.xfce4-session}/bin/startxfce4"
        "-- ${pkgs.tigervnc}/bin/Xvnc :1"
        "-auth %t/vnc-desktop/Xauthority"
        "-geometry 1440x900 -depth 24 -s 0 -nolisten tcp"
        "-localhost -SecurityTypes None -AlwaysShared"
      ];
      Restart = "always";
      RestartSec = 3;
    };
  };

  # Inherit the display and session bus imported by the X11 session wrapper.
  systemd.user.services.cua-driver = {
    description = "Cua desktop automation";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "%h/.local/bin/cua-driver serve";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Serve the browser client and bridge WebSockets to the local VNC server.
  systemd.services.novnc = {
    description = "Browser access to the XFCE desktop";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.python3Packages.websockify}/bin/websockify"
        "--web ${pkgs.novnc}/share/webapps/novnc"
        "127.0.0.1:6080 127.0.0.1:5901"
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

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}

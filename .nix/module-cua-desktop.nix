# Persistent XFCE/X11 desktop for Cua, shared through Tailnet-only noVNC
# (module-gateway.nix serves it at /desktop/).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  display = ":1";
  vncPort = "5901";
  webPort = "6080";
  xauthority = "%t/vnc-desktop/Xauthority";

  # 4:3 and fixed: agents click in screenshot pixels, so the frame must not
  # follow whoever's browser window is open. noVNC scales it instead.
  geometry = "1280x960";
in
{
  services.xserver = {
    enable = true;
    # vnc-desktop below starts the session; no login screen.
    displayManager.lightdm.enable = false;
    desktopManager.xfce = {
      enable = true;
      # The server account has no password to unlock a screensaver.
      enableScreensaver = false;
    };
  };

  # Default fonts come with X; noto covers the rest of the web.
  fonts.packages = [ pkgs.noto-fonts ];

  # Start the desktop at boot, not at the first login.
  users.users.keyclicker.linger = true;

  # xinit owns both processes: restarting the service restarts the session.
  systemd.user.services.vnc-desktop = {
    description = "XFCE desktop on TigerVNC";
    wantedBy = [ "default.target" ];
    environment = {
      XAUTHORITY = xauthority;
      XDG_SESSION_TYPE = "x11";
      XDG_CURRENT_DESKTOP = "XFCE";
    };
    preStart = ''
      umask 077
      ${pkgs.xauth}/bin/xauth add ${display} . \
        "$(${pkgs.util-linux}/bin/mcookie)"
    '';
    serviceConfig = {
      RuntimeDirectory = "vnc-desktop";
      ExecStart = toString [
        "${pkgs.xinit}/bin/xinit"
        config.services.displayManager.sessionData.wrapper
        "${pkgs.xfce4-session}/bin/startxfce4"
        "-- ${pkgs.tigervnc}/bin/Xvnc ${display}"
        "-auth ${xauthority} -nolisten tcp"
        "-rfbport ${vncPort} -localhost -SecurityTypes None -AlwaysShared"
        "-geometry ${geometry} -AcceptSetDesktopSize=0 -depth 24 -s 0"
      ];
      Restart = "always";
      RestartSec = 3;
    };
  };

  # Cua reads windows through the accessibility bus.
  services.gnome.at-spi2-core.enable = true;

  # Cua's official prebuilt installer uses the standard Linux loader.
  programs.nix-ld.libraries = with pkgs; [
    libX11
    libXi
    libxkbcommon
  ];

  # Inherit the display and session bus imported by the X11 session wrapper.
  systemd.user.services.cua-driver = {
    description = "Cua desktop automation";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    # Drop the unit's minimal PATH: apps launched through Cua need the
    # session's PATH, imported by the X11 session wrapper.
    environment.PATH = lib.mkForce null;

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

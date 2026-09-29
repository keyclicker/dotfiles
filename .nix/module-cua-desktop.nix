# Persistent XFCE/X11 desktop for Cua, shared through Tailnet-only noVNC
# (module-gateway.nix serves it at /desktop/).
{
  lib,
  pkgs,
  ...
}:

let
  vncPort = "5901";
  webPort = "6080";
in
{
  services.xserver = {
    enable = true;

    # Real Xorg on the virtio GPU: glamor and GLX render through virgl on
    # the Proxmox host. A real server also hot-plugs Cua's virtual input
    # devices; Xvnc cannot.
    videoDrivers = [ "modesetting" ];

    # 4:3 and fixed: agents click in screenshot pixels, so the frame must
    # not follow the EDID's preferred mode. noVNC scales it instead.
    # Nobody sits at this screen, so never blank what VNC and Cua look at;
    # with DPMS, xfce4-power-manager turns the output off after 15 min.
    monitorSection = ''
      Option "PreferredMode" "1280x960"
      Option "DPMS" "false"
    '';
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';

    displayManager.lightdm = {
      enable = true;
      greeter.enable = false;
      # `:1`, the display the agents' docs (.agents/AGENTS.md) point at.
      extraConfig = ''
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

  # Mesa's virgl driver for the virtio GPU.
  hardware.graphics.enable = true;

  # Audio without hardware: apps play into a virtual speaker, agents
  # play into a virtual mic that apps record from. Sound cards the VM may
  # have stay unused, so nothing depends on the hypervisor's audio device.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;

    extraConfig.pipewire."10-agents-audio" = {
      # Record what apps play: `pw-record -P '{ stream.capture.sink = true }'
      # --target agents-speaker`.
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "agents-speaker";
            "node.description" = "Agents speaker";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
      ];

      # `pw-play --target agents-mic` comes out of the "Agents mic" source.
      # A loopback, since wireplumber never routes playback into a source.
      "context.modules" = [
        {
          name = "libpipewire-module-loopback";
          args = {
            "audio.position" = "FL,FR";
            "capture.props" = {
              "node.name" = "agents-mic";
              "node.description" = "Agents mic input";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "agents-mic-source";
              "node.description" = "Agents mic";
              "media.class" = "Audio/Source";
            };
          };
        }
      ];
    };

    wireplumber.extraConfig."10-no-sound-cards" = {
      "wireplumber.profiles".main."monitor.alsa" = "disabled";
    };
  };

  # Realtime scheduling for pipewire.
  security.rtkit.enable = true;

  # Use NixOS's restricted uinput group, not a world-writable device.
  hardware.uinput.enable = true;
  users.users.keyclicker.extraGroups = [ "uinput" ];

  fonts.packages = [ pkgs.noto-fonts ];
  services.gnome.at-spi2-core.enable = true;

  # Cua Driver is installed by hand from upstream's prebuilt release
  # (README: Agents desktop): nixpkgs has no package, and building Cua's
  # own flake recompiles Rust on every nixpkgs bump. Switch to
  # `pkgs.cua-driver` once nixpkgs has it and drop these libraries.
  programs.nix-ld.libraries = with pkgs; [
    libX11
    libXi
    libxkbcommon
  ];

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
      ExecStart = "%h/.local/bin/cua-driver serve";
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

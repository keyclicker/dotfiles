# Agent desktops: XFCE on Xvnc, driven by Cua, watched through Tailnet-only
# noVNC (module-gateway.nix serves it at /desktop/).
#
# Each desktop is a slot N: display `:N`, VNC on 5900+N (Xvnc's default),
# its own session bus (so Cua's accessibility view stays inside it) and
# noVNC token `N`. Agent slots also get a `cua-driver@N` daemon on its own
# socket and their own Chromium profile. Slot 1 is the user's, slot 2 the
# agents'.
{
  lib,
  pkgs,
  ...
}:

let
  desktops = [
    1
    2
  ];
  agentDesktops = [ 2 ];

  # Chromium hands a new window to the running instance of its profile,
  # which may sit on another desktop: one profile per agent slot keeps
  # agents' browsers on their own screen. Set for the session; Cua gets
  # it with the rest of the session's environment (startCua).
  agentChromeProfile = "%h/.local/state/agent-desktop/%i";

  webPort = "6080";

  # noVNC connects with `?token=N`; websockify maps it to the slot's VNC.
  tokens = pkgs.writeText "agent-desktop-tokens" (
    lib.concatMapStrings (n: "${toString n}: 127.0.0.1:${toString (5900 + n)}\n") desktops
  );

  # The X client xinit runs: XFCE on a session bus of its own. NixOS's
  # session config lists every package's D-Bus services (at-spi).
  session = pkgs.writeShellScript "agent-desktop-session" ''
    exec ${pkgs.dbus}/bin/dbus-run-session \
      --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon \
      --config-file=/etc/dbus-1/session.conf \
      -- ${sessionOnBus}
  '';

  # The desktop's accessibility bus runs on dbus-broker, which activates
  # the at-spi registry through the systemd user manager, outside this
  # session, and fails. Start the registry here, before any app registers.
  sessionOnBus = pkgs.writeShellScript "agent-desktop-session-bus" ''
    ${pkgs.at-spi2-core}/libexec/at-spi2-registryd &
    exec ${pkgs.xfce4-session}/bin/startxfce4
  '';

  # Run from XFCE autostart, i.e. after its window manager and compositor
  # are up: Cua picks its overlay visual once at startup, and started any
  # earlier its cursor stays invisible. Hands the session's environment to
  # `cua-driver@N`, which cannot inherit it through systemd.
  startCua = pkgs.writeShellScript "agent-desktop-cua" ''
    # No Cua, so no agent input, on the user's desktops.
    case " ${toString agentDesktops} " in
      *" $SLOT "*) ;;
      *) exit 0 ;;
    esac

    printf '%s\n' \
      "DISPLAY=$DISPLAY" \
      "XAUTHORITY=$XAUTHORITY" \
      "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS" \
      "PATH=$PATH" \
      "CHROME_CONFIG_HOME=$CHROME_CONFIG_HOME" \
      > "$XDG_RUNTIME_DIR/agent-desktop/$SLOT.env"
    exec ${pkgs.systemd}/bin/systemctl --user start "cua-driver@$SLOT.service"
  '';
in
{
  # XFCE and the X11 bits it needs; no display manager, no local X server.
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = false;
    desktopManager.xfce = {
      enable = true;
      # The server account has no password to unlock a screensaver.
      enableScreensaver = false;
    };
  };

  # Start the desktops at boot, not at the first login.
  users.users.keyclicker.linger = true;

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

  environment.etc."xdg/autostart/agent-desktop-cua.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Cua for this desktop
    Exec=${startCua}
    OnlyShowIn=XFCE;
    Terminal=false
    StartupNotify=false
  '';

  # ---- Slot templates ------------------------------------------------------

  systemd.user.services = {
    # xinit owns Xvnc and the session: restarting the unit restarts both.
    # 1280x960 and fixed: agents click in screenshot pixels, so the frame must
    # not follow whoever's browser is open; noVNC scales it instead.
    "agent-desktop@" = {
      description = "Agent desktop :%i";
      environment = {
        XAUTHORITY = "%t/agent-desktop/%i.xauth";
        XDG_SESSION_TYPE = "x11";
        XDG_CURRENT_DESKTOP = "XFCE";

        # The user manager's login PATH (and XDG_DATA_DIRS) reach the apps.
        PATH = lib.mkForce null;
      };
      preStart = ''
        umask 077
        mkdir -p "$XDG_RUNTIME_DIR/agent-desktop"
        rm -f "$XAUTHORITY"
        ${pkgs.xauth}/bin/xauth -f "$XAUTHORITY" add ":$SLOT" . \
          "$(${pkgs.util-linux}/bin/mcookie)"
      '';
      # The session's env for Cua (startCua) dies with the session.
      postStop = ''
        rm -f "$XDG_RUNTIME_DIR/agent-desktop/$SLOT.env"
      '';
      serviceConfig = {
        Environment = "SLOT=%i";
        ExecStart = toString [
          "${pkgs.xinit}/bin/xinit ${session}"
          "-- ${pkgs.tigervnc}/bin/Xvnc :%i"
          "-auth %t/agent-desktop/%i.xauth -nolisten tcp"
          "-localhost -SecurityTypes None -AlwaysShared"
          "-geometry 1280x960 -AcceptSetDesktopSize=0 -depth 24 -s 0"
        ];
        Restart = "always";
        RestartSec = 3;
      };
    };

    "cua-driver@" = {
      description = "Cua desktop automation on :%i";
      # Stop with its desktop, but never restart with it (as PartOf= and
      # Requisite= would): only startCua starts Cua, once the new session
      # is up. Without its desktop's env file, Cua fails to start.
      unitConfig.StopPropagatedFrom = [ "agent-desktop@%i.service" ];
      after = [ "agent-desktop@%i.service" ];

      # PATH and the rest come from the desktop session (startCua above).
      environment.PATH = lib.mkForce null;

      serviceConfig = {
        EnvironmentFile = "%t/agent-desktop/%i.env";
        ExecStart = "%h/.local/bin/cua-driver serve --socket %h/.cache/cua-driver/desktop-%i.sock";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  }
  # One enabled instance per slot.
  // lib.listToAttrs (
    map (
      n:
      lib.nameValuePair "agent-desktop@${toString n}" {
        overrideStrategy = "asDropin";
        wantedBy = [ "default.target" ];
        environment = {
          PATH = lib.mkForce null;
        }
        // lib.optionalAttrs (lib.elem n agentDesktops) {
          CHROME_CONFIG_HOME = agentChromeProfile;
        };
      }
    ) desktops
  );

  # One websockify for every slot: serves the noVNC client and bridges
  # `?token=N` WebSockets to that slot's loopback VNC.
  systemd.services.novnc = {
    description = "Browser access to the agent desktops";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = toString [
        "${pkgs.python3Packages.websockify}/bin/websockify"
        "--web ${pkgs.novnc}/share/webapps/novnc"
        "--token-plugin TokenFile --token-source ${tokens}"
        "127.0.0.1:${webPort}"
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

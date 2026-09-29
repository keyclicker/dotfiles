# Agent desktops: XFCE on Xorg/Xvnc, watched through Tailnet-only
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

  # Only the agent Xorg seat admits Cua's machine-wide uinput devices.
  xorgConfig = pkgs.writeText "cua-xorg.conf" ''
    Section "ServerFlags"
      Option "AutoAddDevices" "true"
      Option "DontVTSwitch" "true"
    EndSection
    Section "Files"
      ModulePath "${pkgs.xorg-server}/lib/xorg/modules"
      ModulePath "${pkgs.xf86-video-dummy}/lib/xorg/modules"
      ModulePath "${pkgs.xf86-input-libinput}/lib/xorg/modules"
    EndSection
    Section "Device"
      Identifier "dummy"
      Driver "dummy"
      VideoRam 256000
    EndSection
    Section "Monitor"
      Identifier "monitor"
      HorizSync 5.0-1000.0
      VertRefresh 5.0-200.0
      Modeline "1280x960" 108.00 1280 1376 1488 1800 960 961 964 1000 +HSync +VSync
    EndSection
    Section "Screen"
      Identifier "screen"
      Device "dummy"
      Monitor "monitor"
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Modes "1280x960"
      EndSubSection
    EndSection
    Section "InputClass"
      Identifier "Ignore non-Cua devices"
      MatchDevicePath "/dev/input/event*"
      Option "Ignore" "true"
    EndSection
    Section "InputClass"
      Identifier "Cua virtual devices"
      MatchProduct "CUA "
      MatchDevicePath "/dev/input/event*"
      Driver "libinput"
      Option "Ignore" "false"
    EndSection
  '';

  # xinit supplies :N; SLOT comes from the instance unit, never the caller.
  xserver = pkgs.writeShellScript "agent-desktop-xserver" ''
    case " ${toString agentDesktops} " in
      *" $SLOT "*)
        exec ${pkgs.xorg-server}/bin/Xorg "$@" \
          -config ${xorgConfig} -seat cua-agent \
          -auth "$XAUTHORITY" -nolisten tcp -noreset -novtswitch -sharevts \
          -logfile "$XDG_RUNTIME_DIR/agent-desktop/$SLOT.xorg.log"
        ;;
      *)
        exec ${pkgs.tigervnc}/bin/Xvnc "$@" \
          -auth "$XAUTHORITY" -nolisten tcp -localhost \
          -SecurityTypes None -AlwaysShared -geometry 1280x960 \
          -AcceptSetDesktopSize=0 -depth 24 -s 0
        ;;
    esac
  '';

  # noVNC hides its sidebar 2s after connecting, with no setting to stop
  # it; keep it open until its handle closes it.
  novnc = pkgs.novnc.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace app/ui.js --replace-fail \
        "UI.closeControlbarTimeout = setTimeout(UI.closeControlbar, 2000);" ""
    '';
  });

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
      "PATH=${pkgs.ffmpeg-full}/bin:$PATH" \
      "CHROME_CONFIG_HOME=$CHROME_CONFIG_HOME" \
      > "$XDG_RUNTIME_DIR/agent-desktop/$SLOT.env"
    exec ${pkgs.systemd}/bin/systemctl --user start \
      "agent-vnc@$SLOT.service" "cua-driver@$SLOT.service"
  '';
in
{
  # The Cua protocol currently gives all its uinput devices one seat.
  assertions = [
    {
      assertion = builtins.length agentDesktops == 1;
      message = "Cua Xorg input supports one agent seat; keep user slots on Xvnc.";
    }
  ];

  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uinput", OWNER="keyclicker", MODE="0600"
    SUBSYSTEM=="input", ATTRS{name}=="CUA *", OWNER="keyclicker", MODE="0600", ENV{ID_SEAT}="cua-agent", TAG+="seat"
  '';

  # XFCE and the X11 bits it needs; each slot owns its X server.
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
  environment.systemPackages = [ pkgs.ghostty ];
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
    # xinit owns the X server and session: restarting the unit restarts both.
    # 1280x960 and fixed: agents click in screenshot pixels, so the frame must
    # not follow whoever's browser is open; noVNC scales it instead.
    "agent-desktop@" = {
      description = "Agent desktop :%i";
      environment = {
        XAUTHORITY = "%t/agent-desktop/%i.xauth";
        ICEAUTHORITY = "%t/agent-desktop/%i.iceauth";
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
          "-- ${xserver} :%i"
        ];
        Restart = "always";
        RestartSec = 3;
      };
    };

    # Start from XFCE autostart after the X server is ready, like Cua.
    "agent-vnc@" = {
      description = "VNC view of agent Xorg desktop :%i";
      unitConfig.StopPropagatedFrom = [ "agent-desktop@%i.service" ];
      after = [ "agent-desktop@%i.service" ];
      environment = {
        DISPLAY = ":%i";
        XAUTHORITY = "%t/agent-desktop/%i.xauth";
      };
      serviceConfig = {
        Environment = "SLOT=%i";
        ExecStart = "${pkgs.writeShellScript "agent-desktop-vnc" ''
          exec ${pkgs.tigervnc}/bin/x0vncserver \
            -display "$DISPLAY" -rfbport "$((5900 + SLOT))" \
            -localhost -SecurityTypes None -AlwaysShared \
            -AcceptSetDesktopSize=0
        ''}";
        Restart = "on-failure";
        RestartSec = 2;
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
      # PID-selected launches bypass Chromium's wrapper.
      environment.CHROME_DEVEL_SANDBOX = "${pkgs.chromium.sandbox}/bin/${pkgs.chromium.sandboxExecutableName}";

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
        "--web ${novnc}/share/webapps/novnc"
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

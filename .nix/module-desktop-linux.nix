# The NixOS desktop below the apps, what macOS plus
# module-desktop-darwin.nix are on the mac: the Wayland session (sway
# and the tools its config calls: bar, launcher, notifications, lock,
# screenshots, clipboard) started by greetd straight into the user's
# session; keyd for the key remaps, pipewire for audio, bluetooth,
# portals so GTK and flatpak apps get file pickers and screen
# sharing, fonts. The configs themselves are dotfiles:
# home-dotfiles.nix links .config/sway, waybar, fuzzel, mako.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.sway = {
    enable = true;
    # GTK apps find their settings and the portals from sway's env.
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      waybar
      fuzzel
      mako
      grim
      slurp
      wl-clipboard
      brightnessctl
      playerctl
      wdisplays
    ];
  };

  # swaylock checks the password through PAM; without this entry it
  # never unlocks.
  security.pam.services.swaylock = { };

  # Straight into sway, no greeter: single-user machine, keys only
  # over ssh, so a login prompt would guard nothing. greetd restarts
  # the session when sway exits: $mod+Shift+e logs out and right
  # back in.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = lib.getExe config.programs.sway.package;
      user = "keyclicker";
    };
  };

  # Key remaps at the evdev level, before any compositor sees them:
  # tab as esc, caps as ctrl, and the ctrl/alt/meta rotation that
  # puts $mod (meta) on the physical Alt key, where cmd sits on a mac
  # keyboard. Same idea as the karabiner profile on the mac.
  #
  # QEMU's virtual keyboards are excluded: keys arriving over SPICE
  # were already remapped by the client machine (karabiner on the
  # mac), and remapping them twice would turn caps into alt. keyd
  # takes the keyboards plugged into this machine, the client keeps
  # its own.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [
        "*"
        "-0627:0001" # QEMU virtio / usb keyboard
        "-0001:0001" # QEMU ps/2 keyboard
      ];
      settings.main = {
        tab = "esc";
        capslock = "leftcontrol";
        leftcontrol = "leftalt";
        leftalt = "leftmeta";
        rightalt = "tab";
        rightcontrol = "capslock";
      };
    };
  };

  # Audio: pipewire with the pulse API that pactl (sway bindings) and
  # pavucontrol talk to.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Portals come with programs.sway: wlr for screenshots and screen
  # sharing, gtk for file pickers and the settings (dark scheme).
  # That is all flatpak apps see of the desktop.

  # GTK settings (dark scheme, theme, cursor) live in dconf;
  # home-desktop-linux.nix writes them.
  programs.dconf.enable = true;

  hardware.graphics.enable = true;

  # Bluetooth with blueman's tray applet. Inert in a VM with no
  # adapter; here for the bare-metal desktop that composes the same
  # stack.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Electron apps (vscode, discord, obsidian) run on Wayland natively
  # instead of through Xwayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  fonts = {
    packages = with pkgs; [
      jetbrains-mono # the family the configs name
      nerd-fonts.jetbrains-mono # same glyphs plus the icons waybar uses
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrains Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}

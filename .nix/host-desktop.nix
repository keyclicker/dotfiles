# Desktop VM (#35): the mac's stack on NixOS — sway where the mac has
# yabai, flathub where it has homebrew casks — plus incus, which the
# mac cannot host. Generic like host-vm.nix: no name of its own,
# label-mounted disks, cloneable. Unlike it, home-manager links the
# dotfiles (sway, waybar, ghostty, ...), so the repo must be checked
# out at ~/.dotfiles: `install.sh iso desktop`, reboot,
# `install.sh nixos desktop`. Reached over SPICE from the Proxmox
# console; UTM on the mac builds the same leaf as desktop-utm
# (platform-utm.nix). A bare-metal desktop later composes the same
# modules on its own hardware.
{ lib, ... }:

{
  imports = [
    ./module-common.nix
    ./profile-user.nix
    ./profile-desktop.nix
    ./module-agents.nix
    ./module-incus.nix
    ./module-sway.nix
    ./module-apps.nix
    ./module-flatpak.nix
    ./module-ollama-desktop.nix
    ./module-bluetooth.nix
    ./platform-vm.nix
    ./hardware-vm.nix
    ./option-lan.nix
  ];

  # Proxmox on the x86 box; platform-utm.nix overrides for the mac.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # SPICE guest side: clipboard both ways and the display following
  # the client window. Proxmox: display=virtio (or virtio-gl), audio0
  # device=ich9-intel-hda,driver=spice. vdagentd is the system half;
  # the session half is `exec spice-vdagent` in the sway config.
  services.spice-vdagentd.enable = true;

  system.stateVersion = "26.05";
}

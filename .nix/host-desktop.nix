# Desktop VM (#35): the mac's stack on NixOS — sway where the mac has
# yabai, flathub where it has homebrew casks — plus incus, which the
# mac cannot host. A VM leaf like host-vm.nix: no name of its own,
# label-mounted disks, cloneable; Proxmox on the x86 box as
# desktop-vm, UTM on the mac as desktop-utm (platform-utm.nix on
# top). Unlike host-vm.nix, home-manager links the dotfiles (sway,
# waybar, ghostty, ...), so the repo must be checked out at
# ~/.dotfiles: `install.sh iso desktop-vm`, reboot, `install.sh nixos
# desktop-vm`. A bare-metal desktop later is its own leaf composing
# the same desktop modules on its own hardware.
{ lib, ... }:

{
  imports = [
    ./module-common.nix
    ./profile-server.nix
    ./profile-desktop.nix
    ./module-agents.nix
    ./module-incus.nix
    ./module-desktop-linux.nix
    ./module-apps-linux.nix
    ./module-ollama-desktop.nix
    ./platform-vm.nix
    ./hardware-vm.nix
    ./option-lan.nix
  ];

  # Proxmox on the x86 box; platform-utm.nix overrides for the mac.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Proxmox: display=virtio (or virtio-gl), audio0
  # device=ich9-intel-hda,driver=spice; the SPICE agent comes with
  # platform-vm.nix.

  system.stateVersion = "26.05";
}

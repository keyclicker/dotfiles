# Desktop VM (#35): the mac's stack on NixOS — sway where the mac has
# yabai, flathub where it has homebrew casks — plus incus, which the
# mac cannot host. A VM leaf like host-vm.nix: no name of its own,
# label-mounted disks, cloneable; Proxmox on the x86 box (UTM on the
# mac is host-desktop-utm.nix, the same stack on aarch64). Unlike
# host-vm.nix, home-manager links the dotfiles (sway,
# waybar, ghostty, ...), so the repo must be checked out at
# ~/.dotfiles: `install.sh iso desktop-vm`, reboot, `install.sh nixos
# desktop-vm`. A bare-metal desktop later is its own leaf composing
# the same desktop modules on its own hardware.
{ ... }:

{
  imports = [
    ./module-core.nix
    ./module-common.nix
    ./module-dev.nix
    ./profile-server.nix
    ./profile-desktop.nix
    ./module-incus.nix
    ./module-desktop-linux.nix
    ./module-apps-linux.nix
    ./module-ollama-desktop.nix
    ./platform-vm.nix
    ./hardware-vm.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Proxmox: display=virtio (or virtio-gl), audio0
  # device=ich9-intel-hda,driver=spice. SPICE guest side: clipboard
  # both ways and the display following the client window. This is
  # the system half; the session half is `exec spice-vdagent` in the
  # sway config.
  services.spice-vdagentd.enable = true;

  system.stateVersion = "26.05";
}

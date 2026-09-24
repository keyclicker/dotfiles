# Desktop on QEMU's aarch64 virt machine, accelerated by HVF on the mac.
# Use virtio-blk disks: system on vda, swap on vdb. Mounts use labels.
# Install with `install.sh iso desktop-vm`, then after reboot run
# `install.sh nixos desktop-vm` for the checkout home-manager links into.
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

  nixpkgs.hostPlatform = "aarch64-linux";

  disko.devices.disk = {
    main.device = "/dev/vda";
    swap.device = "/dev/vdb";
  };

  # Optional SPICE integration when QEMU exposes a vdagent channel.
  services.spice-vdagentd.enable = true;

  system.stateVersion = "26.05";
}

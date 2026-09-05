# Desktop VM under UTM on the mac: host-desktop-vm.nix's stack on
# Apple silicon. Same leaf shape, three things differ: the
# architecture, the disk names (virtio-blk shows vda/vdb where
# Proxmox's virtio-scsi shows sda/sdb; mounts go by label either way)
# and the serial console (pl011, not a 16550). `dots set desktop-utm;
# dots rebuild` after `install.sh iso desktop-utm`.
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

  boot.kernelParams = [ "console=ttyAMA0,115200n8" ];

  # UTM: SPICE display and clipboard sharing on. SPICE guest side:
  # clipboard both ways and the display following the client window.
  # This is the system half; the session half is `exec spice-vdagent`
  # in the sway config.
  services.spice-vdagentd.enable = true;

  system.stateVersion = "26.05";
}

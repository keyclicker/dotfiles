# UTM on the mac: platform-vm.nix's QEMU guest stack on Apple
# silicon. Composed after the host leaf in flake.nix, it flips only
# what differs there: the architecture, the disk names (virtio-blk
# shows vda/vdb where virtio-scsi shows sda/sdb; mounts go by label
# either way) and the serial console (pl011, not a 16550).
{ ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  disko.devices.disk = {
    main.device = "/dev/vda";
    swap.device = "/dev/vdb";
  };

  boot.kernelParams = [ "console=ttyAMA0,115200n8" ];
}

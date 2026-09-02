# Disk layout of every QEMU guest, declared with disko. One attrset,
# two uses: `disko` partitions and formats a blank disk from it at
# install time, and the running system renders its fileSystems from
# it. Partitions are found by GPT label, so a clone, an image or a
# nixos-anywhere reinstall all mount the same way; nothing is probed
# per machine (what nixos-generate-config used to pin as UUIDs).
{ lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    # Proxmox (virtio-scsi) and incus both show the system disk as
    # sda. Only the format step cares; mounts go by label. UTM
    # (virtio-blk) would be vda.
    device = lib.mkDefault "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [
              "-n"
              "BOOT"
            ];
            mountpoint = "/boot";
            # FAT has no Unix permissions of its own. Keep systemd-boot's
            # random seed and the rest of /boot root-only when mounted.
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          label = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "nixos"
            ];
            mountpoint = "/";
          };
        };
      };
    };
  };

  # A clone given a bigger disk grows into it on first boot: the
  # partition in the initrd, the filesystem via autoResize.
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}

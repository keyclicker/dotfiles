# Disks of every QEMU guest, declared with disko. The same attrset
# serves twice: at install time disko partitions and formats blank
# disks from it, and at runtime NixOS renders fileSystems and
# swapDevices from it. Mounts go by GPT label, not UUID, so a clone,
# an image, or a nixos-anywhere reinstall all boot from this one file.
#
# Two disks: system on the first, swap on the second (in Proxmox:
# scsi1, discard=on, backup=0). Proxmox virtio-scsi and incus both
# name them sda/sdb. UTM uses virtio-blk and would name them vda/vdb.
# Only the format step cares about device names.
{ lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
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

  # The whole second disk is swap. Cold anonymous pages leave the
  # guest through it; see the damon_reclaim and zswap parameters in
  # platform-vm.nix. A fresh random key on every boot: there is no
  # hibernation, so nothing needs to survive a reboot. `nofail` lets a
  # guest with only the system disk attached boot anyway, without swap.
  disko.devices.disk.swap = {
    type = "disk";
    device = lib.mkDefault "/dev/sdb";
    content = {
      type = "gpt";
      partitions.swap = {
        label = "swap";
        size = "100%";
        content = {
          type = "swap";
          randomEncryption = true;
          # Thin zvol underneath: hand freed blocks back at swapon.
          discardPolicy = "once";
          mountOptions = [ "nofail" ];
        };
      };
    };
  };

  # A clone given a bigger disk grows into it on first boot: the
  # partition in the initrd, the filesystem via autoResize.
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}

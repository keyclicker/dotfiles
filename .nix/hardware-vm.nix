# Disks of every QEMU guest, declared with disko. One attrset, two
# uses: `disko` partitions and formats blank disks from it at install
# time, and the running system renders its fileSystems and swapDevices
# from it. Filesystems are found by label, so a clone, an image or
# a nixos-anywhere reinstall all mount the same way; nothing is probed
# per machine (what nixos-generate-config used to pin as UUIDs).
#
# Two disks: system on the first, swap on the second (Proxmox: scsi1,
# discard=on, backup=0). Proxmox (virtio-scsi) and incus both show
# them as sda/sdb; UTM (virtio-blk) would be vda/vdb. Only the format
# step cares about the names, mounts go by label.
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
              "ESP"
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

  # All swap. Cold anonymous pages leave the guest through it (see
  # the damon_reclaim and zswap parameters in platform-vm.nix).
  # Encrypted with a fresh random key on every boot: nothing to
  # hibernate to, so nothing to keep. `nofail`: a guest booted with
  # the system disk alone (single-disk image, forgotten attach) still
  # comes up, just without swap.
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

  # Match nixpkgs' Proxmox image labels. A later `nixos-rebuild` of an
  # image-built VM and a disko-installed VM then mount the same names.
  fileSystems."/".device = lib.mkForce "/dev/disk/by-label/nixos";
  fileSystems."/boot".device = lib.mkForce "/dev/disk/by-label/ESP";

  # A clone given a bigger disk grows into it on first boot. The initrd
  # grows the partition, then the filesystem follows through autoResize.
  boot.growPartition = true;
  fileSystems."/".autoResize = true;
}

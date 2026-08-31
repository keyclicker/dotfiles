# Shared by NixOS VMs running under Proxmox/QEMU.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Clones from a generic VM image name themselves vm-<machine-id
  # prefix> (option-generic-hostname.nix, composed by the machine's
  # module list); pet hosts (agents) set networking.hostName and win.
  local.genericHostname.prefix = lib.mkDefault "vm-";

  boot = {
    # All our Proxmox VMs use OVMF/UEFI.
    loader = {
      timeout = 0;

      systemd-boot = {
        enable = true;
        editor = false;
      };

      efi.canTouchEfiVariables = true;
    };

    # Keep VGA as a fallback, but make Proxmox serial0 usable as the
    # primary terminal through xterm.js / `qm terminal`.
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];
  };

  # Proxmox guest integration: IP reporting, clean shutdown,
  # backup freeze/thaw, etc.
  services.qemuGuest.enable = true;

  # scsi disks are configured with discard=on in Proxmox, so periodically
  # return deleted guest blocks to the thin-provisioned ZFS zvol.
  services.fstrim.enable = true;

  # The ESP is FAT and has no Unix permissions of its own. Keep
  # systemd-boot's random seed and the rest of /boot root-only when mounted.
  fileSystems."/boot".options = lib.mkForce [
    "fmask=0077"
    "dmask=0077"
  ];
}

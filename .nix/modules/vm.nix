# Shared by NixOS VMs running under Proxmox/QEMU.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./lan.nix
  ];

  networking = {
    useNetworkd = true;

    # One NIC name on every guest regardless of hypervisor PCI
    # layout (Proxmox: ens18, incus: enp5s0, ...): net.ifnames=0
    # restores kernel eth0 — the same name containers get for their
    # veth. Sane for single-NIC guests only; with several NICs the
    # kernel order is nondeterministic.
    usePredictableInterfaceNames = false;
  };

  # LAN-only ports (lan.nix consumers: t3 web, mDNS) open here.
  local.lanInterface = lib.mkDefault "eth0";

  systemd.network = {
    # Interfaces networkd doesn't manage (tailscale0 today, any
    # docker/incus bridge tomorrow) sit in "pending" forever and
    # would wedge systemd-networkd-wait-online; one routable
    # interface is all "online" needs to mean here.
    wait-online.anyInterface = true;

    # eth* is the name after the rename; en* keeps the pre-reboot
    # generation working, since net.ifnames=0 applies at boot.
    networks."50-lan" = {
      matchConfig.Name = "en* eth*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
        MulticastDNS = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

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

# Shared by NixOS VMs running under Proxmox/QEMU.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking = {
    useNetworkd = true;

    # One NIC name on every guest regardless of hypervisor PCI
    # layout (Proxmox: ens18, incus: enp5s0, ...): net.ifnames=0
    # restores kernel eth0 — the same name containers get for their
    # veth, and the default lan.nix opens LAN-only ports on. Sane
    # for single-NIC guests only; with several NICs the kernel
    # order is nondeterministic.
    usePredictableInterfaceNames = false;
  };

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

      # Proactively evict page cache that hasn't been touched for 2
      # minutes so the guest's footprint shrinks back after IO bursts
      # and the freed pages can go back to the host (needs virtio
      # free-page-reporting or ballooning on the Proxmox side to
      # actually land there). Anonymous memory is skipped: with no
      # swap it is unreclaimable anyway.
      "damon_reclaim.min_age=120000000"
      "damon_reclaim.skip_anon=Y"

      # At most 512 MiB reclaimed per 1 s window. The default time
      # quota (10 ms/s) would throttle far below that, so raise it to
      # 100 ms/s; the size quota is then the binding limit.
      "damon_reclaim.quota_ms=100"
      "damon_reclaim.quota_sz=536870912"
      "damon_reclaim.quota_reset_interval_ms=1000"

      # Watermarks are permille of *free* (not available) memory:
      # start reclaiming below 80% free, stop above 90%, and back off
      # below 10% free where kswapd/direct reclaim take over.
      "damon_reclaim.wmarks_high=900"
      "damon_reclaim.wmarks_mid=800"
      "damon_reclaim.wmarks_low=100"

      "damon_reclaim.enabled=Y"
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

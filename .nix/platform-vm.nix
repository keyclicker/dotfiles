# Shared by NixOS VMs running under Proxmox/QEMU.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking = {
    useNetworkd = true;

    # One image, many instances: the VM has no name of its own, so ""
    # leaves the hostname to whoever knows it. incus sends the instance
    # name in the DHCP lease, and networkd applies it while no static
    # name exists. Proxmox, UTM and plain libvirt send nothing, so the
    # guest boots as localhost until `hostnamectl set-hostname` names
    # it. That name persists in /etc/hostname, which NixOS leaves alone
    # while this is "". Pet hosts set their name and win.
    hostName = lib.mkDefault "";

    # net.ifnames=0 gives every guest a NIC called eth0, whatever the
    # hypervisor's PCI layout (Proxmox: ens18, incus: enp5s0, ...).
    # Containers get the same name for their veth, and option-lan.nix
    # opens LAN-only ports on it by default. Sane for single-NIC
    # guests only: with several NICs the kernel order is
    # nondeterministic.
    usePredictableInterfaceNames = false;
  };

  systemd.network = {
    # Interfaces networkd does not manage (tailscale0 today, a docker
    # or incus bridge tomorrow) sit in "pending" forever and would
    # wedge systemd-networkd-wait-online. One routable interface is
    # all "online" needs to mean here.
    wait-online.anyInterface = true;

    # eth* is the name after the rename. en* keeps the first switch
    # working before the reboot, since net.ifnames=0 applies only at
    # boot.
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

      # Evict pages untouched for 2 minutes, so the guest's footprint
      # shrinks back after IO bursts and the freed pages can return to
      # the host. Landing there needs virtio free-page-reporting or
      # ballooning on the Proxmox side. Anonymous pages are included:
      # they go to zswap first, then the swap disk. Booted without
      # that disk, the kernel skips them.
      "damon_reclaim.min_age=120000000"

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

      # Compressed in-RAM cache in front of the swap disk: evicted
      # pages sit zstd-packed in up to 20% of RAM and spill to disk
      # only when that fills. Inert while there is no swap.
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=20"
    ];
  };

  # Proxmox guest integration: IP reporting, clean shutdown,
  # backup freeze/thaw, etc.
  services.qemuGuest.enable = true;

  # scsi disks are configured with discard=on in Proxmox, so periodically
  # return deleted guest blocks to the thin-provisioned ZFS zvol.
  services.fstrim.enable = true;
}

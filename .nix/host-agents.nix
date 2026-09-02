# Pet VM on the Proxmox box: the AI agent sandbox. Its own name and a
# swap disk on top of the generic VM stack.
{ lib, ... }:

{
  imports = [
    ./module-common.nix
    ./profile-server.nix
    ./module-agents.nix
    ./module-browser.nix
    ./module-slopbox.nix
    ./module-iperf.nix
    ./platform-vm.nix
    ./hardware-vm.nix
    ./option-lan.nix
  ];

  networking.hostName = "agents";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Second Proxmox disk (scsi1, backup=0), all swap. Cold anonymous
  # pages leave the guest through it (see the damon_reclaim and zswap
  # parameters in platform-vm.nix). Encrypted with a fresh random key
  # on every boot: nothing to hibernate to, so nothing to keep.
  # `nofail`: a boot without the disk attached still comes up.
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

  # Networking (networkd, DHCP on eth0) comes from platform-vm.nix,
  # LAN-only firewall ports from option-lan.nix and the modules that
  # own the services; only the name is this host's own.

  # No host-specific packages: CLI tools and dev toolchains come from
  # module-common.nix, server basics (zsh, terminfo, docker,
  # tailscale) from profile-server.nix, AI coding agents from
  # module-agents.nix, chromium and agent-browser from
  # module-browser.nix, t3 web server from module-slopbox.nix, iperf3
  # server from module-iperf.nix, Proxmox/QEMU guest bits from
  # platform-vm.nix.

  system.stateVersion = "26.05";
}

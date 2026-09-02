{ ... }:

{
  imports = [
    ./hardware-agents.nix
  ];

  networking.hostName = "agents";

  # Networking (networkd, DHCP on eth0) comes from platform-vm.nix,
  # LAN-only firewall ports from option-lan.nix and the modules
  # that own the services; only the name is this host's own.

  # No host-specific packages: CLI tools and dev toolchains come from
  # module-common.nix, server basics (zsh, terminfo,
  # docker, tailscale) from profile-server.nix, AI coding agents from
  # module-agents.nix, chromium and agent-browser from
  # module-browser.nix, t3 web server from module-slopbox.nix,
  # iperf3 server from module-iperf.nix, Proxmox/QEMU guest bits
  # from platform-vm.nix.

  system.stateVersion = "26.05";
}

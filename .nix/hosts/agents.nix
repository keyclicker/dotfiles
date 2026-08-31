{ ... }:

{
  imports = [
    ./agents-hardware.nix
  ];

  networking.hostName = "agents";

  # Networking (networkd, DHCP on eth0, LAN firewall interface)
  # comes from modules/vm.nix; only the name is this host's own.

  # No host-specific packages: CLI tools and dev toolchains come from
  # modules/common.nix, server basics (zsh, terminfo,
  # docker, tailscale) from modules/server.nix, AI coding agents from
  # modules/agents.nix, chromium and agent-browser from
  # modules/browser.nix, t3 web server from modules/slopbox.nix,
  # iperf3 server from modules/iperf.nix, Proxmox/QEMU guest bits
  # from modules/vm.nix.

  system.stateVersion = "26.05";
}

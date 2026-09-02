# Pet VM on the Proxmox box: the AI agent sandbox. Its own name on
# top of the generic VM stack.
{ ... }:

{
  imports = [
    ./module-common.nix
    ./profile-user.nix
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

  # Networking (networkd, DHCP on eth0) comes from platform-vm.nix,
  # LAN-only firewall ports from option-lan.nix and the modules that
  # own the services; only the name is this host's own.

  # No host-specific packages: CLI tools and dev toolchains come from
  # module-common.nix, the user, ssh, tailscale and zsh from
  # profile-user.nix, docker from profile-server.nix, AI coding agents from
  # module-agents.nix, chromium and agent-browser from
  # module-browser.nix, t3 web server from module-slopbox.nix, iperf3
  # server from module-iperf.nix, Proxmox/QEMU guest bits from
  # platform-vm.nix.

  system.stateVersion = "26.05";
}

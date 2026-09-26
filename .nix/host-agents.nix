# Pet VM on the Proxmox box: the AI agent sandbox. Its own name on
# top of the generic VM stack.
{ ... }:

{
  imports = [
    ./module-core.nix
    ./module-workstation.nix
    ./profile-server.nix
    ./module-browser.nix
    ./module-cua-desktop.nix
    ./module-slopbox.nix
    ./module-html-serving.nix
    ./module-projects-smb.nix
    ./module-iperf.nix
    ./platform-vm.nix
    ./hardware-vm.nix
  ];

  networking.hostName = "agents";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Networking (networkd, DHCP on eth0) comes from platform-vm.nix,
  # LAN-only firewall ports from option-lan.nix and the modules that
  # own the services; only the name is this host's own.

  # No host-specific packages: the CLI floor comes from
  # module-core.nix, interactive tools and dev toolchains from
  # module-workstation.nix, server basics (zsh, terminfo,
  # docker, tailscale) from profile-server.nix, chromium and
  # agent-browser from module-browser.nix, t3 web server from
  # module-slopbox.nix, XFCE desktop and Cua from
  # module-cua-desktop.nix, iperf3 server from module-iperf.nix,
  # HTML directory serving from module-html-serving.nix,
  # tailnet project sharing from module-projects-smb.nix,
  # Proxmox/QEMU guest bits from platform-vm.nix. The AI coding agents
  # are npm globals in the home layer (home-agents.nix, wired in
  # flake.nix).

  system.stateVersion = "26.05";
}

# Pet VM on the Proxmox box: the AI agent sandbox. Its own name on
# top of the generic VM stack.
{ ... }:

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

  # Everything else, networking and packages included, comes from the
  # imports. Only the name is this host's own.

  system.stateVersion = "26.05";
}

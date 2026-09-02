# Generic container instance, spawned as many times as needed. No
# identity of its own: incus or Proxmox names it, see
# platform-container.nix. No home-manager, same reason as host-vm.nix.
{ ... }:

{
  imports = [
    ./module-common.nix
    ./profile-server.nix
    ./platform-container.nix
    ./option-lan.nix
  ];

  # incus on the Proxmox box and Proxmox CTs are both x86_64.
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}

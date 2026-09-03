# Generic container instance: no identity of its own — the name comes
# from incus / Proxmox (platform-container.nix). Spawn it as many
# times as needed.
{ ... }:

{
  imports = [
    ./module-core.nix
    ./module-nvim-minimal.nix
    ./profile-server.nix
    ./platform-container.nix
    ./option-lan.nix
  ];

  # incus on the Proxmox box and Proxmox CTs are both x86_64.
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}

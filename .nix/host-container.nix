# Generic container instance: no identity of its own — the name comes
# from incus / Proxmox (platform-container.nix), the tooling from the
# module stack in flake.nix. Spawn it as many times as needed.
{ ... }:

{
  # incus on the Proxmox box and Proxmox CTs are both x86_64.
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}

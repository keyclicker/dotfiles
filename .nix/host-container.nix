# Generic container instance: no identity of its own — the hostname
# comes from generic-hostname (ct- prefix), the tooling from the
# module stack in flake.nix. Spawn it in incus or as a Proxmox CT.
{ ... }:

{
  # incus on the Proxmox box and Proxmox CTs are both x86_64.
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}

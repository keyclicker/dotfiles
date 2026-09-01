# Generic VM instance: no identity of its own — the name comes from
# DHCP or `hostnamectl` (modules/vm.nix), the tooling from the module
# stack in flake.nix. Spawn it on Proxmox, incus, UTM, ... as many
# times as needed.
{ lib, ... }:

{
  # Proxmox / incus on the Proxmox box; UTM on the mac wants aarch64
  # and gets its own output when it is needed.
  nixpkgs.hostPlatform = "x86_64-linux";

  # The layout nixos-install and the manual produce: ext4 root
  # labelled "nixos", FAT ESP labelled "boot". Image builders (#32)
  # bring their own layout and override these.
  fileSystems = {
    "/" = {
      device = lib.mkDefault "/dev/disk/by-label/nixos";
      fsType = lib.mkDefault "ext4";
    };

    "/boot" = {
      device = lib.mkDefault "/dev/disk/by-label/boot";
      fsType = lib.mkDefault "vfat";
    };
  };

  system.stateVersion = "26.05";
}

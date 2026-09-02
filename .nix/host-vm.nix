# Generic VM instance: no identity of its own — the name comes from
# DHCP or `hostnamectl` (platform-vm.nix). Spawn it on Proxmox, incus,
# UTM, ... as many times as needed. Prebuilt images come later (#32);
# until then install the manual way and switch like any other
# configuration. No home-manager: a fresh guest has no ~/.dotfiles
# checkout for the symlinks to point at.
{ lib, ... }:

{
  imports = [
    ./module-common.nix
    ./profile-server.nix
    ./module-incus.nix
    # module-dockge.nix exists but stays out: password-only web UI on
    # the docker socket; lazydocker over ssh does for now.
    ./platform-vm.nix
    ./option-lan.nix
  ];

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
      autoResize = true;
    };

    "/boot" = {
      device = lib.mkDefault "/dev/disk/by-label/boot";
      fsType = lib.mkDefault "vfat";
    };
  };

  # A clone given a bigger disk grows into it on first boot: the
  # partition in the initrd, the filesystem via autoResize above.
  boot.growPartition = true;

  system.stateVersion = "26.05";
}

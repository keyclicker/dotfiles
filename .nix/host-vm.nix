# Generic VM instance: no identity of its own. The name comes from
# DHCP or `hostnamectl` (platform-vm.nix). Spawn it on Proxmox, incus,
# UTM, ... as many times as needed. `.scripts/prebuild` builds the
# Proxmox template; `install.sh iso vm` remains the blank-disk path.
{ lib, ... }:

{
  imports = [
    ./module-core.nix
    ./module-nvim-minimal.nix
    ./profile-server.nix
    ./module-incus.nix
    # module-dockge.nix exists but stays out: password-only web UI on
    # the docker socket; lazydocker over ssh does for now.
    ./platform-vm.nix
    ./hardware-vm.nix
    ./option-lan.nix
  ];

  # Proxmox / incus on the Proxmox box; UTM on the mac wants aarch64
  # and gets its own output when it is needed.
  nixpkgs.hostPlatform = "x86_64-linux";

  # The Proxmox image builder otherwise defaults to SeaBIOS and cloud-init.
  # This target boots through systemd-boot and gets networking from networkd.
  image.modules.proxmox = {
    proxmox = {
      cloudInit.enable = false;
      filenameSuffix = "nixos-vm";
      qemuConf.bios = "ovmf";
    };

    # Both the disko install and the image use filesystem labels. Keeping
    # these values forced here resolves the image module's mount definitions.
    fileSystems."/".device = lib.mkForce "/dev/disk/by-label/nixos";
    fileSystems."/boot".device = lib.mkForce "/dev/disk/by-label/ESP";
  };

  system.stateVersion = "26.05";
}

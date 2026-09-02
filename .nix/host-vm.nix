# Generic VM instance, spawned on Proxmox, incus, UTM, ... as many
# times as needed. No identity of its own: the name comes from DHCP
# or `hostnamectl`, see platform-vm.nix. Until prebuilt images exist
# (#32), install with `install.sh iso vm` from the installer ISO. No
# home-manager: a fresh guest has no ~/.dotfiles checkout for the
# symlinks to point at.
{ ... }:

{
  imports = [
    ./module-common.nix
    ./profile-server.nix
    ./module-incus.nix
    # module-dockge.nix stays out: a password-only web UI on the
    # docker socket. lazydocker over ssh does for now.
    ./platform-vm.nix
    ./hardware-vm.nix
    ./option-lan.nix
  ];

  # Proxmox and incus on the Proxmox box. UTM on the mac would want
  # aarch64 and gets its own output when needed.
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";
}

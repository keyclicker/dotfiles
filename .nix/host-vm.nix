# Generic VM instance: no identity of its own — the name comes from
# DHCP or `hostnamectl` (platform-vm.nix). Spawn it on Proxmox, incus,
# UTM, ... as many times as needed. Prebuilt images come later (#32);
# until then `install.sh iso vm` from the installer ISO. No
# home-manager: a fresh guest has no ~/.dotfiles checkout for the
# symlinks to point at.
{ ... }:

{
  imports = [
    ./module-core.nix
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

  system.stateVersion = "26.05";
}

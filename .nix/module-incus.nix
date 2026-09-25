# Incus via its local Unix socket: the machine hosts containers and VMs of its
# own. Preseeded so a fresh instance works without `incus admin
# init`: dir storage pool, NAT bridge incusbr0, default profile on
# both. Remote administration goes through LAN SSH.
{ config, lib, ... }:

{
  virtualisation.incus = {
    enable = true;
    ui.enable = false;

    preseed = {
      # Explicitly clear an existing listener when reapplying the preseed.
      config."core.https_address" = "";

      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "auto";
            "ipv4.nat" = "true";
            "ipv6.address" = "auto";
          };
        }
      ];

      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config.source = "/var/lib/incus/storage-pools/default";
        }
      ];

      profiles = [
        {
          name = "default";
          # Containers run docker (profile-server.nix), which needs
          # namespaces of its own inside the CT. /dev/net/tun for
          # tailscale incus hands out by default. Proxmox CTs get the
          # same from `features: nesting=1` on the Proxmox side.
          config."security.nesting" = "true";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  # Incus requires the native nftables firewall backend.
  networking.nftables.enable = true;

  # Guests get DHCP/DNS from dnsmasq on the bridge, which the input
  # chain would otherwise drop. Forwarding is not filtered by NixOS
  # (filterForward defaults to false); incus' own nft table does NAT.
  networking.firewall.interfaces.incusbr0 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [
      53
      67
      547
    ];
  };

  # Docker flips the FORWARD policy to DROP, which cuts incus guests
  # off from the outside; docker >= 28 can keep its own rules
  # without the policy flip.
  virtualisation.docker.daemon.settings = lib.mkIf config.virtualisation.docker.enable {
    "ip-forward-no-drop" = true;
  };

  # The user from profile-server.nix drives incus without sudo.
  users.users.keyclicker.extraGroups = [ "incus-admin" ];
}

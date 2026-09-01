# incus with its web UI: the machine hosts containers and VMs of its
# own. Preseeded so a fresh instance works without `incus admin
# init`: dir storage pool, NAT bridge incusbr0, default profile on
# both, API on 8443 for the UI.
{ config, lib, ... }:

{
  virtualisation.incus = {
    enable = true;
    ui.enable = true;

    preseed = {
      config."core.https_address" = ":8443";

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

  # The NixOS incus module refuses the iptables firewall backend.
  networking.nftables.enable = true;

  # Guests get DHCP/DNS from dnsmasq on the bridge, which the input
  # chain would otherwise drop. Forwarding is not filtered by NixOS
  # (filterForward defaults to false); incus' own nft table does NAT.
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  # Docker flips the FORWARD policy to DROP, which cuts incus guests
  # off from the outside; docker >= 28 can keep its own rules
  # without the policy flip.
  virtualisation.docker.daemon.settings = lib.mkIf config.virtualisation.docker.enable {
    "ip-forward-no-drop" = true;
  };

  # The user from server.nix drives incus without sudo.
  users.users.keyclicker.extraGroups = [ "incus-admin" ];

  # Web UI, LAN only.
  local.lan.allowedTCPPorts = [ 8443 ];
}

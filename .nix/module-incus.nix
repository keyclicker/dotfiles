# incus with its web UI, for machines that host containers and VMs of
# their own. Preseeded so a fresh instance works without `incus admin
# init`: a dir storage pool, the NAT bridge incusbr0, a default
# profile using both, and the API on 8443 for the UI.
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

  # Guests get DHCP and DNS from dnsmasq on the bridge. Without this
  # the input chain would drop those packets. Forwarding needs no
  # rule: NixOS does not filter it (filterForward defaults to false),
  # and incus' own nft table does the NAT.
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  # Docker flips the FORWARD policy to DROP, which cuts incus guests
  # off from the outside. Docker 28 and later can keep its own rules
  # without the policy flip.
  virtualisation.docker.daemon.settings = lib.mkIf config.virtualisation.docker.enable {
    "ip-forward-no-drop" = true;
  };

  # The user from profile-server.nix drives incus without sudo.
  users.users.keyclicker.extraGroups = [ "incus-admin" ];

  # Web UI on the LAN and over tailscale; client certs do the auth.
  local.lan.allowedTCPPorts = [ 8443 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8443 ];
}

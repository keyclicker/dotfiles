{ ... }:

{
  imports = [
    ./agents-hardware.nix
  ];

  networking = {
    hostName = "agents";
    useNetworkd = true;

    # 22 is opened by services.openssh; t3 web + mDNS stay LAN-only.
    firewall.interfaces.ens18 = {
      allowedTCPPorts = [ 3773 ];
      allowedUDPPorts = [ 5353 ];
    };
  };

  systemd.network = {
    # Interfaces networkd doesn't manage (tailscale0 today, any
    # docker/incus bridge tomorrow) sit in "pending" forever and
    # would wedge systemd-networkd-wait-online; one routable
    # interface is all "online" needs to mean here.
    wait-online.anyInterface = true;

    # en* keeps the unit valid across VMs whose NIC name differs.
    networks."50-lan" = {
      matchConfig.Name = "en*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
        MulticastDNS = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # No host-specific packages: CLI tools come from modules/common.nix,
  # toolchains from modules/dev.nix, server basics (zsh, terminfo,
  # docker, tailscale) from modules/server.nix, AI coding agents from
  # modules/agents.nix, chromium and agent-browser from
  # modules/browser.nix, t3 web server from modules/slopbox.nix,
  # Proxmox/QEMU guest bits from modules/vm.nix.

  system.stateVersion = "26.05";
}

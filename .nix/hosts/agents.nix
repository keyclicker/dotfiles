{ ... }:

{
  imports = [
    ./agents-hardware.nix
  ];

  networking = {
    hostName = "agents";
    dhcpcd.enable = false;
    useDHCP = false;

    # 22 is opened by services.openssh; t3 web + mDNS stay LAN-only.
    firewall.interfaces.ens18 = {
      allowedTCPPorts = [ 3773 ];
      allowedUDPPorts = [ 5353 ];
    };
  };

  systemd.network = {
    enable = true;

    # tailscale0 is created by tailscaled, so networkd never finishes
    # configuring it and it sits in "pending" forever. Without this,
    # systemd-networkd-wait-online waits on it and always times out.
    wait-online.ignoredInterfaces = [ "tailscale0" ];

    networks."50-ens18" = {
      matchConfig.Name = "ens18";
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

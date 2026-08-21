{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking = {
    hostName = "agents";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;

    firewall.interfaces.eth1 = {
      allowedTCPPorts = [ 22 3773 ];
      allowedUDPPorts = [ 5353 ];
    };
  };

  systemd.network = {
    enable = true;

    # tailscale0 is created by tailscaled, so networkd never finishes
    # configuring it and it sits in "pending" forever. Without this,
    # systemd-networkd-wait-online waits on it and always times out.
    wait-online.ignoredInterfaces = [ "tailscale0" ];

    networks = {
      "50-eth0" = {
        matchConfig.Name = "eth0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        linkConfig.RequiredForOnline = "routable";
      };
      "60-eth1" = {
        matchConfig.Name = "eth1";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
          MulticastDNS = true;
        };
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  # Nix build sandbox unavailable inside the LXC container.
  nix.settings.sandbox = false;

  # No host-specific packages: CLI tools come from modules/common.nix,
  # toolchains from modules/dev.nix, server basics (zsh, terminfo,
  # docker, tailscale) from modules/server.nix, AI coding agents from
  # modules/agents.nix, chromium and agent-browser from
  # modules/browser.nix, t3 web server from modules/slopbox.nix.

  system.stateVersion = "26.11";
}

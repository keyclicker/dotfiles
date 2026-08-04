{
  lib,
  modulesPath,
  pkgs,
  ...
}:

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

  # Host-specific packages; cross-platform CLI tools come from
  # modules/common.nix, server basics (zsh, terminfo, docker, tailscale)
  # from modules/server.nix, AI coding agents from modules/agents.nix,
  # t3 web server from modules/slopbox.nix.
  environment.systemPackages = with pkgs; [
    python3
    gnumake
    pkg-config
    chromium
    playwright-test

    (writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${lib.getExe chromium}"
      export AGENT_BROWSER_ARGS="--no-sandbox"
      exec ${lib.getExe agent-browser} "$@"
    '')
  ];

  system.stateVersion = "26.11";
}

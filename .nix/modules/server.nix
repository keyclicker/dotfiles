# Shared by servers (NixOS only): user, ssh, mDNS resolution,
# tailscale, docker, terminal niceties for remote sessions.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./lan.nix ];

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;

  # mDNS (resolved below) answers on the LAN interface when the host
  # names one.
  networking.firewall.interfaces = lib.optionalAttrs (config.local.lanInterface != null) {
    ${config.local.lanInterface}.allowedUDPPorts = [ 5353 ];
  };

  # ncurses comes with NixOS; only the terminfo database needs adding.
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  users.users.keyclicker = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGovJeDnHrDiFm+8iu2ucNSBCifqQVycI93JRYeTyj0VAAAADXNzaDp5dWJpLW5hbm8= ssh:yubi-nano"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      MulticastDNS = true;
      LLMNR = false;
    };
  };
}

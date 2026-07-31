# Shared by servers (NixOS only): user, ssh, mDNS resolution,
# tailscale, docker, terminal niceties for remote sessions.
{ pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    zsh
    ncurses
    ghostty.terminfo
  ];

  users.users.keyclicker = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = import ../keys.nix;
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

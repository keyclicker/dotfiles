# Shared by servers (NixOS only): user, ssh, mDNS resolution,
# tailscale, docker, terminal niceties for remote sessions.
#
# Privilege is who a process is, never what it knows: no account has
# a password. root is locked and unreachable over ssh; keyclicker is
# the only login, by key, with sudo for free; the console (Proxmox,
# incus) logs keyclicker in without asking, because reaching the
# console already means owning the hypervisor. Services get their own
# ids (DynamicUser or a dedicated user) unless they are the agents'
# own tools and run as keyclicker on purpose (module-slopbox.nix), and
# docker containers are remapped off host root where the platform
# allows (platform-vm.nix).
{ config, pkgs, ... }:

let
  home = config.users.users.keyclicker.home;
in
{
  imports = [ ./option-lan.nix ];

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  services.tailscale.enable = true;
  virtualisation.docker.enable = true;

  # mDNS responder (resolved below)
  local.lan.allowedUDPPorts = [ 5353 ];

  # ncurses comes with NixOS; only the terminfo database needs adding.
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  # Accounts are exactly what this file says: no passwd/shadow drift,
  # and no password can appear (nothing sets one here, so every
  # account stays locked).
  users.mutableUsers = false;

  users.users.keyclicker = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGovJeDnHrDiFm+8iu2ucNSBCifqQVycI93JRYeTyj0VAAAADXNzaDp5dWJpLW5hbm8= ssh:yubi-nano"
    ];
  };

  # home-dotfiles.nix links $HOME into ~/.dotfiles, and a fresh guest
  # (iso, nixos-anywhere, an image) boots without a checkout: every
  # link dangles until one exists. The boot that finds it missing
  # clones it; the condition makes every later boot a no-op and
  # leaves a checkout put there by hand (`install.sh nixos <host>`)
  # alone. Retries while the network or GitHub is not there yet.
  systemd.services.dotfiles-clone = {
    description = "First-boot checkout of ~/.dotfiles";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!${home}/.dotfiles";
    path = [ pkgs.git ];
    script = "git clone https://github.com/keyclicker/dotfiles.git ${home}/.dotfiles";
    serviceConfig = {
      Type = "oneshot";
      User = "keyclicker";
      Group = "users";
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };

  security.sudo = {
    # Key-only login already gates the account; a sudo password would
    # protect nothing and would break --target-host rebuilds.
    wheelNeedsPassword = false;
    # sudo binary runnable by wheel only: one less setuid entry point
    # for everything else on the box.
    execWheelOnly = true;
  };

  # Console = hypervisor access; a login prompt there adds nothing
  # and, with no passwords, would lock the console out. Covers the
  # serial/VGA getty of VMs and the console getty of containers.
  services.getty.autologinUser = "keyclicker";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # root is locked; nothing needs it over ssh either (installs
      # talk to the installer's root, rebuilds go through keyclicker
      # + sudo).
      PermitRootLogin = "no";
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

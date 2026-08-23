{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking.hostName = "nas-shell";

  programs.zsh.enable = true;
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  users.users.keyclicker = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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

  system.stateVersion = "26.05";
}

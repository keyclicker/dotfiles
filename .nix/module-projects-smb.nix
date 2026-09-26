# Passwordless project access for devices allowed through the tailnet ACLs.
{ config, ... }:

{
  imports = [ ./option-tailnet.nix ];

  # Samba ignores point-to-point interfaces; Serve owns the tailnet listener.
  local.tailnet.tcp."445" = "tcp://127.0.0.1:445";

  services.samba = {
    enable = true;
    openFirewall = false;
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        interfaces = "lo";
        "bind interfaces only" = "yes";
        "smb ports" = "445";
        "map to guest" = "Bad User";
        "guest account" = "keyclicker";
        "load printers" = "no";
        "disable spoolss" = "yes";
      };

      projects = {
        path = "${config.users.users.keyclicker.home}/projects";
        "read only" = "no";
        "guest ok" = "yes";
        "guest only" = "yes";

        # Keep Finder litter out of the repos: refuse `.DS_Store`, and
        # store Mac metadata in xattrs instead of `._*` AppleDouble files.
        "veto files" = "/.DS_Store/";
        "delete veto files" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:resource" = "stream";
      };
    };
  };
}

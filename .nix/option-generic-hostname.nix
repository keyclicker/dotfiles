# Generic images (vm/container targets) must not share one hostname
# when spawned multiple times. When a prefix is set and no pet name
# is configured, a oneshot boot service names the machine
# <prefix><first 4 of /etc/machine-id>, e.g. vm-3f2a — unique per
# instance because machine-id is generated on first boot.
{
  config,
  lib,
  ...
}:

{
  options.local.genericHostname.prefix = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "vm-";
    description = ''
      Hostname prefix for machines spawned from a generic image.
      Null disables the service; an explicit networking.hostName
      (pet hosts) also wins over it.
    '';
  };

  config = lib.mkIf (config.local.genericHostname.prefix != null) {
    # NixOS defaults hostName to "nixos"; an image is nameless until
    # something names it. Pets override this with their own name.
    networking.hostName = lib.mkDefault "";

    systemd.services.generic-hostname = lib.mkIf (config.networking.hostName == "") {
      description = "Set generic hostname from machine-id";
      wantedBy = [ "multi-user.target" ];
      # Before the network comes up, so DHCP and mDNS announce the
      # generated name, not "(none)". A DHCP/cloud-init-provided name
      # arriving later still overrides the kernel hostname.
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        current=$(cat /proc/sys/kernel/hostname)
        case "$current" in
          "" | "(none)" | localhost)
            printf '%s%s' "${config.local.genericHostname.prefix}" \
              "$(cut -c1-4 /etc/machine-id)" > /proc/sys/kernel/hostname
            ;;
        esac
      '';
    };
  };
}

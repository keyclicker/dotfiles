# The local.lan options. Modules list their LAN-only ports here
# instead of touching the firewall themselves. The single firewall
# write lives below and stays inert until some module sets a port.
#
# The interface defaults to eth0 because every guest has one: VMs
# through net.ifnames=0 in platform-vm.nix, containers because their
# veth is named that way. A host with other hardware overrides it.
# null keeps the LAN ports closed.
{ config, lib, ... }:

{
  options.local.lan = {
    interface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "eth0";
      description = ''
        Interface facing the trusted LAN. LAN-only ports open on it;
        null keeps them closed.
      '';
    };

    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "TCP ports modules open on the LAN interface.";
    };

    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "UDP ports modules open on the LAN interface.";
    };
  };

  config =
    lib.mkIf
      (
        config.local.lan.interface != null
        && config.local.lan.allowedTCPPorts ++ config.local.lan.allowedUDPPorts != [ ]
      )
      {
        networking.firewall.interfaces.${config.local.lan.interface} = {
          allowedTCPPorts = config.local.lan.allowedTCPPorts;
          allowedUDPPorts = config.local.lan.allowedUDPPorts;
        };
      };
}

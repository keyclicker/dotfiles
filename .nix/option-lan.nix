# local.lan vocabulary: a module that serves on the LAN imports this
# file and lists its ports here instead of touching the firewall
# itself; the one dynamic-attr
# firewall write lives below and stays inert until a port is set.
# Every guest's NIC is eth0 (VMs via net.ifnames=0 in platform-vm.nix,
# container veths natively), so the default fits all virtual
# machines; a host with different hardware overrides it, null
# keeps the LAN ports closed.
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

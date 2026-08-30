# Declares local.lanInterface so modules can open their LAN-only
# ports on the right NIC themselves; only the host knows its name.
{ lib, ... }:

{
  options.local.lanInterface = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "ens18";
    description = ''
      Interface facing the trusted LAN. Modules that serve LAN-only
      traffic open their firewall ports on it; when null those ports
      stay closed.
    '';
  };
}

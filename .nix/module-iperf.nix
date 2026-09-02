# iperf3 throughput server (NixOS only). The port is open on all
# interfaces, not just the LAN: clients may sit on another VLAN, and
# the router decides who gets routed here. Safe enough, since the
# payload is junk bytes and the daemon runs sandboxed (DynamicUser,
# no capabilities).
{ ... }:

{
  services.iperf3.enable = true;
  networking.firewall.allowedTCPPorts = [ 5201 ];
}

# iperf3 throughput server (NixOS only). The payload is junk bytes and
# the daemon runs sandboxed (DynamicUser, no capabilities), so the port
# is open on all interfaces: clients may sit on another VLAN, and the
# router decides who gets routed here.
{ ... }:

{
  services.iperf3.enable = true;
  networking.firewall.allowedTCPPorts = [ 5201 ];
}

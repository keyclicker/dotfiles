# Throughput testing is an application service: tailnet access only.
{ ... }:

{
  services.iperf3.enable = true;
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 5201 ];
    allowedUDPPorts = [ 5201 ];
  };
}

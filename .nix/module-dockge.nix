# dockge: web UI for docker compose stacks. No nixpkgs package — it
# runs as a docker container itself, on the docker from profile-server.nix.
# Stacks live in /opt/stacks (dockge's convention), its own state in
# /var/lib/dockge.
#
# Host networking on purpose: a docker-published port is DNAT'ed
# ahead of the NixOS firewall and would be open on every interface.
# In the host namespace dockge is an ordinary listener on 5001 and
# the firewall gates it like any other service (LAN + tailscale).
#
# Not composable with platform-vm.nix as is: its docker remaps
# container root to dockremap's range, which can neither open the
# root:docker socket nor write /var/lib/dockge. Add --userns=host to
# extraOptions there (dockge holds the socket anyway, remapping it
# protects nothing), or keep it to the container platform.
{ ... }:

{
  imports = [ ./option-lan.nix ];

  virtualisation.oci-containers = {
    backend = "docker";

    containers.dockge = {
      image = "louislam/dockge:1";
      extraOptions = [ "--network=host" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/dockge:/app/data"
        "/opt/stacks:/opt/stacks"
      ];
      environment.DOCKGE_STACKS_DIR = "/opt/stacks";
    };
  };

  local.lan.allowedTCPPorts = [ 5001 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 5001 ];
}

# dockge: web UI for docker compose stacks. No nixpkgs package — it
# runs as a docker container itself, on the docker from server.nix.
# Stacks live in /opt/stacks (dockge's convention), its own state in
# /var/lib/dockge.
#
# Docker publishes the port through its own nat rules, ahead of the
# NixOS firewall, so 5001 is reachable on every interface (LAN,
# tailscale); local.lan cannot gate it.
{ ... }:

{
  virtualisation.oci-containers = {
    backend = "docker";

    containers.dockge = {
      image = "louislam/dockge:1";
      ports = [ "5001:5001" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/dockge:/app/data"
        "/opt/stacks:/opt/stacks"
      ];
      environment.DOCKGE_STACKS_DIR = "/opt/stacks";
    };
  };
}

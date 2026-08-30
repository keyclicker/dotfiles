# Shared by NixOS containers running under incus / Proxmox LXC.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  # Spawned CTs name themselves ct-<machine-id prefix>
  # (option-generic-hostname.nix, composed by the machine's module
  # list); a pet CT would set networking.hostName and win.
  local.genericHostname.prefix = lib.mkDefault "ct-";

  # The lxc-container profile inherits the host's resolv.conf by
  # default, which conflicts with the resolved (mDNS) setup in
  # server.nix — the CT does its own name resolution.
  networking.useHostResolvConf = false;

  # The nix build sandbox needs namespaces an unprivileged CT can't
  # create, so builds inside containers run unsandboxed. This is the
  # workaround dropped in #24 when agents moved to a VM — it returns
  # here scoped to the one target that needs it.
  nix.settings.sandbox = false;
}

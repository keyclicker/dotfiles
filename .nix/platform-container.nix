# Shared by NixOS containers running under incus / Proxmox LXC.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  # incus and Proxmox both name the CT through lxc (lxc.uts.name)
  # before init runs; "" keeps that name where the default "nixos"
  # would overwrite it. A pet CT sets networking.hostName and wins.
  networking.hostName = lib.mkDefault "";

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

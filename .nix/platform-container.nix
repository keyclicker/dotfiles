# Shared by NixOS containers running under incus / Proxmox LXC.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  # incus and Proxmox both set the CT's name through lxc.uts.name
  # before init runs. "" keeps that name; the default "nixos" would
  # overwrite it. A pet CT sets networking.hostName and wins.
  networking.hostName = lib.mkDefault "";

  # The lxc-container profile inherits the host's resolv.conf by
  # default. That conflicts with resolved and mDNS from
  # profile-server.nix. The CT does its own name resolution.
  networking.useHostResolvConf = false;

  # The nix build sandbox needs namespaces an unprivileged CT cannot
  # create, so builds inside containers run unsandboxed. History in #24.
  nix.settings.sandbox = false;
}

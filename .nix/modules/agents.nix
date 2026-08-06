# AI coding agent CLIs (claude, codex, opencode). Shared by every
# machine except vps; not to be confused with hosts/agents.nix (the
# sandbox host that merely imports this too).
#
# The three resolve through the nixpkgs-agents pin (flake.nix's
# agentOverlay), so their versions sit in flake.lock like everything
# else: refresh with `nix flake update nixpkgs-agents` and rebuild.
# For a release newer than the lock, `npx --yes <pkg>@latest` runs one
# without touching the profile.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode
  ];
}

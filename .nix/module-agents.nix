# AI coding agent CLIs (claude, codex, opencode), always latest via
# npx. Every NixOS/darwin machine plus the jail; not the foreign
# Linux hosts (host-standalone.nix). Not to be confused with
# host-agents.nix (the sandbox host that merely imports this too).
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "claude" ''
      exec ${nodejs}/bin/npx --yes @anthropic-ai/claude-code@latest "$@"
    '')

    (writeShellScriptBin "codex" ''
      exec ${nodejs}/bin/npx --yes @openai/codex@latest "$@"
    '')

    (writeShellScriptBin "opencode" ''
      exec ${nodejs}/bin/npx --yes opencode-ai@latest "$@"
    '')
  ];
}

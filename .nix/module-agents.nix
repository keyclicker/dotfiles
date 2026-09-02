# AI coding agent CLIs (claude, codex, opencode), always latest via
# npx. Used by every NixOS/darwin machine and the jail, not by the
# foreign Linux hosts. Not to be confused with host-agents.nix, the
# sandbox host, which merely imports this too.
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

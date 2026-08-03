# AI coding agent CLIs (claude, codex, opencode), always latest via
# npx. Shared by every machine; not to be confused with hosts/agents.nix
# (the sandbox host that merely imports this like everyone else).
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

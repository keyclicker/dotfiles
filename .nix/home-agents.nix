# AI coding agent CLIs (claude, codex, opencode) as npm globals
# (option-npm-globals.nix): always the current release, updated on
# every rebuild, the way casks and flatpaks track upstream. Every
# NixOS/darwin machine plus the jail; not the foreign Linux hosts
# (host-standalone.nix). Not to be confused with host-agents.nix (the
# sandbox host that merely gets this too).
{ ... }:

{
  imports = [ ./option-npm-globals.nix ];

  local.npmGlobals.packages = [
    "@anthropic-ai/claude-code"
    "@openai/codex"
    "opencode-ai"
  ];
}

# AI coding agent CLIs (claude, codex, opencode) and t3 code as npm
# globals (option-npm-globals.nix): normally the current release,
# updated on every rebuild, the way casks and flatpaks track upstream.
# Every NixOS/darwin machine plus the jail; not the foreign Linux
# hosts (host-standalone.nix). The t3 web server (module-slopbox.nix)
# execs the same install, so one `npm install` serves both. Not to be
# confused with host-agents.nix (the sandbox host that merely gets
# this too).
{ ... }:

{
  imports = [ ./option-npm-globals.nix ];

  local.npmGlobals.packages = [
    "@anthropic-ai/claude-code"
    "@openai/codex"
    "opencode-ai"

    # npm ignores dependency-local overrides. Keep T3 and its Effect
    # runtime aligned until upstream publishes exact transitive pins:
    # https://github.com/pingdotgg/t3code/issues/2667
    "t3@0.0.40"
    "effect@4.0.0-beta.103"
    "@effect/platform-node-shared@4.0.0-beta.103"
  ];
}

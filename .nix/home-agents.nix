# Coding CLIs track latest on every rebuild. T3 uses Bun because npm's
# peer resolver loops on its published Effect dependencies. Both installers
# put their commands in ~/.local/bin; the T3 service uses that same binary.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./option-npm-globals.nix ];

  local.npmGlobals.packages = [
    "@anthropic-ai/claude-code"
    "@openai/codex"
    "opencode-ai"
  ];

  # TODO: Temporary until T3 fixes its published dependency metadata.
  # Once a clean `npm install --global t3@latest` succeeds and the server
  # starts correctly, return "t3" to local.npmGlobals.packages and remove
  # the Bun setup and T3 activation hook below. Keep tracking latest.
  programs.bun.enable = true;

  # Bun reads this even when activation has no XDG_CONFIG_HOME.
  home.file.".bunfig.toml".text = ''
    [install]
    globalBinDir = "${config.home.homeDirectory}/.local/bin"
  '';

  home.extraActivationPath = [ pkgs.bun ];

  # Run after npm and home-file linking. Each installer has its own
  # deadline so their combined runtime stays below activation's timeout.
  home.activation.t3 = lib.hm.dag.entryAfter [ "npmGlobals" "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/timeout --kill-after=10s 2m \
      ${pkgs.bun}/bin/bun add --global t3@latest \
      || warnEcho "T3: install failed (exit $?); retry: bun add --global t3@latest"
  '';
}

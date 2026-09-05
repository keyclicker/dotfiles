# local.npmGlobals vocabulary: npm packages a host keeps installed
# globally, the way module-apps-darwin.nix keeps casks and
# module-apps-linux.nix keeps flatpaks: an "ensure installed" list,
# nothing pinned. Home layers list packages here; the one npm write
# lives below and stays inert until the list is set.
#
# How it works:
#
#   - ~/.npmrc points npm's global prefix at ~/.local, so bins land
#     in ~/.local/bin (on PATH via .zshrc) and libraries in
#     ~/.local/lib/node_modules. No PATH plumbing of its own.
#   - Every activation runs `npm install --global <list>`: missing
#     packages get installed, present ones move to the registry's
#     latest. A rebuild is an update; so is `npm update -g` by hand.
#   - State lives in $HOME, not the store. `npm install -g`,
#     `npm rm -g` and the CLIs' own self-updaters work as on any
#     machine. Dropping a package from the list does not uninstall
#     it; that is an `npm rm -g` by hand.
#   - Offline, the install is a warning, not a failed switch.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.npmGlobals;
  prefix = "${config.home.homeDirectory}/.local";
in
{
  options.local.npmGlobals.packages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "@anthropic-ai/claude-code" ];
    description = ''
      npm packages kept installed globally at the registry's latest:
      installed or updated on every activation.
    '';
  };

  config = lib.mkIf (cfg.packages != [ ]) {
    # The installed CLIs are `#!/usr/bin/env node` shims.
    home.packages = [ pkgs.nodejs ];

    home.file.".npmrc".text = ''
      prefix=${prefix}
    '';

    # .zshrc puts ~/.local/bin on PATH for shells; this covers the
    # jail, whose agents get hm-session-vars.sh instead of a shell.
    home.sessionPath = [ "${prefix}/bin" ];

    home.activation.npmGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! run ${pkgs.nodejs}/bin/npm install --global ${lib.escapeShellArgs cfg.packages}; then
        warnEcho "npm globals: install failed (offline?); retry: npm install -g ${toString cfg.packages}"
      fi
    '';
  };
}

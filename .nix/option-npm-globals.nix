# local.npmGlobals vocabulary: npm packages a host keeps installed
# globally, the way module-apps-darwin.nix keeps casks and
# module-apps-linux.nix keeps flatpaks: an "ensure installed" list,
# using npm package specs. A home layer imports this file and lists
# packages here; the one npm write stays inert until the list is set.
#
# How it works:
#
#   - ~/.npmrc (a dotfile, linked on every host) points npm's global
#     prefix at ~/.local, so bins land in ~/.local/bin (on PATH via
#     .zshrc) and libraries in ~/.local/lib/node_modules. No PATH
#     plumbing of its own.
#   - Every activation runs `npm install --global <list>`: missing
#     packages get installed, present ones move to the requested
#     version (latest when no version is specified).
#   - State lives in $HOME, not the store. `npm install -g`,
#     `npm rm -g` and the CLIs' own self-updaters work as on any
#     machine. Dropping a package from the list does not uninstall
#     it; that is an `npm rm -g` by hand.
#   - Offline or stuck installs time out with a warning instead of
#     failing the switch.
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
      npm package specs installed or updated globally on every activation.
      Unversioned names track the registry's latest release.
    '';
  };

  config = lib.mkIf (cfg.packages != [ ]) {
    # The installed CLIs are `#!/usr/bin/env node` shims.
    home.packages = [ pkgs.nodejs ];

    # Lifecycle scripts use node-gyp for native addons (e.g. node-pty).
    # Activation has its own PATH, independent of the user's packages.
    home.extraActivationPath = [
      pkgs.nodejs
      pkgs.python3
      pkgs.gnumake
      pkgs.stdenv.cc
    ];

    # .zshrc puts ~/.local/bin on PATH for shells; this covers the
    # jail, whose agents get hm-session-vars.sh instead of a shell.
    home.sessionPath = [ "${prefix}/bin" ];

    home.activation.npmGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/timeout --kill-after=10s 2m \
        ${pkgs.nodejs}/bin/npm install --global --no-audit --no-fund \
        ${lib.escapeShellArgs cfg.packages} \
        || warnEcho "npm globals: install failed (exit $?); retry: npm install -g ${toString cfg.packages}"
    '';
  };
}

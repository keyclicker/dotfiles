# AI coding agent CLIs (claude, codex, opencode). Shared by every
# machine except vps; not to be confused with hosts/agents.nix (the
# sandbox host that merely imports this too).
#
# The CLIs themselves are deliberately not nix-managed. They release
# near-daily and each ships its own updater, which a read-only store
# path cannot host — nixpkgs' claude-code has to set
# DISABLE_AUTOUPDATER for exactly that reason. So nix contributes one
# script: `agent-update` installs them into $HOME on a fresh machine
# and refreshes them afterwards. nix-rebuild runs it after every
# switch, the jail launcher whenever it provisions, and in between the
# CLIs update themselves.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "agent-update" ''
      # One CLI failing (offline, registry down) must not stop the
      # others; the exit code reports it and the caller decides.
      status=0

      # pnpm keeps global bins here and refuses `add -g` unless that
      # directory is on PATH. .zshrc exports the same default for
      # interactive use, hosts/jail.nix for the jail's agents.
      export PNPM_HOME="''${PNPM_HOME:-$HOME/.local/share/pnpm}"

      # Vendor installers and postinstall scripts reach for the usual
      # system tools — claude's for curl and id, opencode's for node —
      # so they are supplied here rather than assumed of the caller.
      export PATH="$PNPM_HOME/bin:$HOME/.local/bin:${
        lib.makeBinPath [
          bash
          coreutils
          curl
          gnugrep
          gnused
          gnutar
          gzip
          nodejs
          pnpm
          xz
        ]
      }:$PATH"

      # Claude Code's native build updates itself, in the background
      # too, so the installer is a first-run affair.
      if command -v claude >/dev/null 2>&1; then
        claude update || status=1
      else
        curl -fsSL https://claude.ai/install.sh | bash || status=1
      fi

      # minimumReleaseAge=0: pnpm 11 holds back npm releases younger
      # than a day. That is a sane default against a poisoned release,
      # but it is not what this repo asks for, and the npx wrappers
      # this replaced had no such quarantine either. Drop the flag to
      # trade a day of freshness for that buffer.
      #
      # `codex update` shells out to this very command when codex was
      # installed this way, so one line covers install and update.
      pnpm add -g --config.minimumReleaseAge=0 @openai/codex@latest || status=1

      # --allow-build: opencode's postinstall fetches its platform
      # binary, and pnpm runs no build script unless the package is
      # named. `opencode upgrade` is not a substitute — it replaces
      # the package without rerunning that postinstall, leaving a
      # binary that refuses to start.
      pnpm add -g --config.minimumReleaseAge=0 \
        --allow-build=opencode-ai opencode-ai@latest || status=1

      exit $status
    '')
  ];
}

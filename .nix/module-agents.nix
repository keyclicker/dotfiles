# AI coding agent CLIs. Nix supplies an offline-capable fallback;
# writable npm installs refresh in the background and take precedence.
# Every NixOS/darwin machine plus the jail; not the foreign Linux hosts
# (host-standalone.nix). Not to be confused with host-agents.nix (the
# sandbox host that merely imports this too).
{ pkgs, ... }:

let
  updateIntervalSeconds = 24 * 60 * 60;

  updateAgent = pkgs.writeShellScript "update-agent-cli" ''
    set -euo pipefail

    command_name="$1"
    npm_package="$2"
    mutable_prefix="$3"
    update_state="$4"
    npm_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/agent-clis/npm"

    ${pkgs.coreutils}/bin/mkdir -p "$mutable_prefix" "$update_state" "$npm_cache"

    exec 9>"$update_state/update.lock"
    ${pkgs.flock}/bin/flock -n 9 || exit 0
    ${pkgs.coreutils}/bin/date +%s > "$update_state/last-attempt"

    # Agent processes may inherit npm's own lifecycle variables when their
    # parent was launched through npx. Clear those before choosing our prefix.
    if ${pkgs.coreutils}/bin/env \
      -u npm_command \
      -u npm_config_global_prefix \
      -u npm_config_local_prefix \
      -u npm_config_prefix \
      -u npm_execpath \
      -u npm_lifecycle_event \
      -u npm_lifecycle_script \
      -u npm_node_execpath \
      -u npm_package_json \
      NPM_CONFIG_CACHE="$npm_cache" \
      NPM_CONFIG_PREFIX="$mutable_prefix" \
      npm_config_cache="$npm_cache" \
      npm_config_prefix="$mutable_prefix" \
      ${pkgs.nodejs}/bin/npm install --global --no-audit --no-fund \
        --allow-scripts="$npm_package" \
        "$npm_package@latest"
    then
      ${pkgs.coreutils}/bin/date +%s > "$update_state/last-success"
      printf '%s updated successfully\n' "$command_name"
    else
      printf '%s update failed; using installed version\n' "$command_name" >&2
      exit 1
    fi
  '';

  mkAgent =
    {
      command,
      npmPackage,
      fallback,
      runtimeEnvironment ? "",
    }:
    pkgs.writeShellScriptBin command ''
      mutable_prefix="''${XDG_DATA_HOME:-$HOME/.local/share}/agent-clis/${command}"
      update_state="''${XDG_STATE_HOME:-$HOME/.local/state}/agent-clis/${command}"
      mutable_command="$mutable_prefix/bin/${command}"
      last_attempt=0
      now="$(${pkgs.coreutils}/bin/date +%s)"

      if [ -r "$update_state/last-attempt" ]; then
        read -r last_attempt < "$update_state/last-attempt" || last_attempt=0
      fi
      case "$last_attempt" in
        "" | *[!0-9]*) last_attempt=0 ;;
      esac

      if [ "''${AGENT_CLI_DISABLE_AUTOUPDATE:-0}" != 1 ] \
        && [ "$((now - last_attempt))" -ge ${toString updateIntervalSeconds} ]
      then
        ${pkgs.coreutils}/bin/mkdir -p "$update_state"
        ${pkgs.coreutils}/bin/nohup ${updateAgent} \
          ${pkgs.lib.escapeShellArg command} \
          ${pkgs.lib.escapeShellArg npmPackage} \
          "$mutable_prefix" "$update_state" \
          > "$update_state/update.log" 2>&1 </dev/null &
      fi

      ${runtimeEnvironment}

      if [ -x "$mutable_command" ]; then
        export NPM_CONFIG_PREFIX="$mutable_prefix"
        export npm_config_global_prefix="$mutable_prefix"
        export npm_config_prefix="$mutable_prefix"
        exec "$mutable_command" "$@"
      fi

      exec ${pkgs.lib.getExe fallback} "$@"
    '';
in
{
  environment.systemPackages = [
    (mkAgent {
      command = "claude";
      npmPackage = "@anthropic-ai/claude-code";
      fallback = pkgs.claude-code;
      # One updater avoids racing Claude's updater against npm. `claude update`
      # remains available because this only disables background checks.
      runtimeEnvironment = "export DISABLE_AUTOUPDATER=1";
    })

    (mkAgent {
      command = "codex";
      npmPackage = "@openai/codex";
      fallback = pkgs.codex;
    })

    (mkAgent {
      command = "opencode";
      npmPackage = "opencode-ai";
      fallback = pkgs.opencode;
      runtimeEnvironment = "export OPENCODE_DISABLE_AUTOUPDATE=1";
    })
  ];
}

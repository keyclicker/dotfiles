# Headless browser stack for the agents VM, with Chromium's sandbox enabled.
{ pkgs, ... }:

let
  keyring = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
  unlock = ''
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$UID/bus}"
    export GNOME_KEYRING_CONTROL="''${GNOME_KEYRING_CONTROL:-/run/user/$UID/keyring}"
    test -f "''${XDG_DATA_HOME:-$HOME/.local/share}/keyrings/login.keyring" || {
      echo "Enroll the login keyring first" >&2
      exit 1
    }
    ${keyring} --unlock --control-directory="$GNOME_KEYRING_CONTROL" \
      < /run/browser-keyring/password >/dev/null || exit 1
    ${keyring} --start --components=secrets \
      --control-directory="$GNOME_KEYRING_CONTROL" >/dev/null || exit 1
  '';
  chromium = pkgs.chromium.overrideAttrs (old: {
    # agent-browser supplies --password-store=basic; the final flag wins.
    buildCommand = old.buildCommand + ''
      wrapProgram "$out/bin/chromium" \
        --run ${pkgs.lib.escapeShellArg unlock} \
        --append-flags '--password-store=gnome-libsecret'
    '';
  });
in
{
  services.gnome.gnome-keyring.enable = true;

  # Only the sealed credential persists. The unlock password lives in /run.
  systemd.services.browser-keyring = {
    description = "Release the browser keyring password from the TPM";
    wantedBy = [ "multi-user.target" ];
    before = [ "systemd-user-sessions.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "keyclicker";
      RuntimeDirectory = "browser-keyring";
      RuntimeDirectoryMode = "0700";
      LoadCredentialEncrypted = "password:/var/lib/browser-keyring/password.cred";
      ExecStart = "${pkgs.coreutils}/bin/install -m 0400 %d/password /run/browser-keyring/password";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  environment.systemPackages = [
    chromium
    pkgs.playwright-test

    # Use nixpkgs Chromium and leave its sandbox enabled.
    (pkgs.writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.lib.getExe chromium}"
      exec ${pkgs.lib.getExe pkgs.agent-browser} "$@"
    '')
  ];
}

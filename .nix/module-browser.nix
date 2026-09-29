# Headless browser stack for the agents VM, with Chromium's sandbox enabled.
{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (p: [ p.secretstorage ]);
  keyring = pkgs.writeShellScriptBin "browser-keyring" ''
    exec ${pkgs.coreutils}/bin/timeout 30 \
      ${python}/bin/python ${../packages/browser-keyring/keyring.py} \
      --daemon ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon "$@"
  '';
  chromium = pkgs.chromium.overrideAttrs (old: {
    # agent-browser supplies --password-store=basic; the final flag wins.
    buildCommand = old.buildCommand + ''
      wrapProgram "$out/bin/chromium" \
        --run 'export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$UID/bus}"' \
        --run '${keyring}/bin/browser-keyring || exit 1' \
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
    keyring
    pkgs.playwright-test

    # Use nixpkgs Chromium and leave its sandbox enabled.
    (pkgs.writeShellScriptBin "agent-browser" ''
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.lib.getExe chromium}"
      exec ${pkgs.lib.getExe pkgs.agent-browser} "$@"
    '')
  ];
}

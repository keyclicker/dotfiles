# Browser keyring

Chromium uses GNOME Libsecret, including launches through `agent-browser`.
The wrapper unlocks the default collection before launching and refuses to
launch if the credential is missing, unlock fails, or the keyring is plaintext.
The password-store flag comes last because `agent-browser` adds `basic` itself.

`browser-keyring.service` releases a TPM-sealed password into a private directory
under `/run`. Only the encrypted credential persists under `/var/lib`; neither
the password nor its encrypted credential belongs in Git or the Nix store.
Separate desktop buses get separate daemon control sockets. They use the same
user's existing default collection, preserving Chromium's Safe Storage key.

GNOME's standard Secret Service API only offers interactive unlock/password
changes. The helper uses GNOME's internal password API with an encrypted D-Bus
session to support unattended unlock and migrate the original empty password.

## Enrollment

Close Chromium and make an encrypted backup of the keyrings and cookie
databases first. Check `systemd-analyze has-tpm2`: it must report `yes`.
Generate the credential once; never overwrite one used by an enrolled keyring:

```sh
sudo install -d -m 0700 /var/lib/browser-keyring
sudo python3 - <<'PY'
import os
import secrets
import subprocess

sealed = subprocess.run(
    ["systemd-creds", "encrypt", "--with-key=tpm2", "--tpm2-pcrs=7",
     "--name=password", "-", "-"],
    input=secrets.token_hex(32).encode(), capture_output=True, check=True,
).stdout
with open("/var/lib/browser-keyring/password.cred", "xb") as file:
    os.fchmod(file.fileno(), 0o600)
    file.write(sealed)
PY
```

Apply the NixOS configuration, then run `browser-keyring --enroll` as the desktop
user on its session bus. This changes an empty default-keyring password while
preserving items, or creates an encrypted default collection on a fresh machine.
It refuses to replace an existing nonempty password it cannot unlock. Repeating
enrollment with the same credential is safe.

`migrate_cookies.py` converts existing Linux `v10` cookies to `v11` using the
preserved Chromium key. Run it with the helper's Python environment, passing
explicit paths to closed `Cookies` databases. It verifies decryption and hostname
digests before committing, preserves cookie metadata, and prints only counts.
It does not migrate saved-password databases or other browser storage formats.

## Recovery and limits

Keep the VM's TPM state. Replacing it loses automatic access to the sealed
password; changing the PCR 7 boot policy can also prevent unsealing. Arrange an
offline recovery copy before making either change. A backup containing both
the VM disk and virtual TPM state still needs backup encryption/access controls.
The setup protects copied profiles and disks, not root or processes sharing the
unlocked user's account. Old snapshots may still contain the earlier plaintext
keyring or basic-storage cookies.

Validation should include a real keyring password change, retained items,
lock/unlock, wrong-password rejection, a TPM seal/unseal round trip, and a
Chromium cookie written as `v11`. Check `chrome://sandbox` as well.

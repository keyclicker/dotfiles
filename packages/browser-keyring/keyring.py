"""Unlock GNOME's default collection with the TPM-backed boot credential."""

import argparse
import hashlib
import os
import subprocess
from pathlib import Path

import secretstorage
from jeepney import DBus, DBusErrorResponse
from secretstorage.collection import Collection
from secretstorage.util import DBusAddressWrapper, format_secret, open_session


def main():
    """Enroll an empty-password collection once, or unlock it for Chromium."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--enroll", action="store_true")
    parser.add_argument("--daemon", required=True)
    parser.add_argument(
        "--credential", type=Path, default=Path("/run/browser-keyring/password")
    )
    args = parser.parse_args()
    password = args.credential.read_bytes()
    if len(password) < 32:
        raise RuntimeError("Missing or invalid keyring credential")

    os.environ.setdefault(
        "DBUS_SESSION_BUS_ADDRESS",
        f"unix:path=/run/user/{os.getuid()}/bus",
    )
    connection = secretstorage.dbus_init()
    owned, = connection.send_and_get_reply(
        DBus().NameHasOwner("org.freedesktop.secrets"), timeout=10
    ).body
    if not owned:
        # Each desktop has its own bus. Reusing another bus's control socket
        # makes GNOME Keyring activate on the wrong bus and Chromium times out.
        bus_id = hashlib.sha256(
            os.environ["DBUS_SESSION_BUS_ADDRESS"].encode()
        ).hexdigest()[:16]
        control = Path(f"/run/user/{os.getuid()}/browser-keyring-{bus_id}")
        control.mkdir(mode=0o700, exist_ok=True)
        subprocess.run(
            [args.daemon, "--start", "--components=secrets",
             f"--control-directory={control}"],
            check=True, stdout=subprocess.DEVNULL, timeout=10,
        )
    service = DBusAddressWrapper(
        "/org/freedesktop/secrets", "org.freedesktop.Secret.Service", connection
    )
    internal = DBusAddressWrapper(
        "/org/freedesktop/secrets",
        "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface",
        connection,
    )
    session = open_session(connection)
    if not session.encrypted:
        raise RuntimeError("Secret Service did not negotiate encryption")

    secret = format_secret(session, password, "text/plain")
    path, = service.call("ReadAlias", "s", "default")
    if path == "/":
        if not args.enroll:
            raise RuntimeError("Enroll the default keyring before using Chromium")
        path, = internal.call(
            "CreateWithMasterPassword",
            "a{sv}(oayays)",
            {"org.freedesktop.Secret.Collection.Label": ("s", "Browser")},
            secret,
        )
        service.call("SetAlias", "so", "default", path)
    elif args.enroll:
        # Unlocking an unencrypted collection succeeds with any password.
        # Change its password explicitly before accepting an enrolled retry.
        try:
            internal.call(
                "ChangeWithMasterPassword",
                "o(oayays)(oayays)",
                path,
                format_secret(session, b"", "text/plain"),
                secret,
            )
        except DBusErrorResponse:
            service.call("Lock", "ao", [path])
            internal.call("UnlockWithMasterPassword", "o(oayays)", path, secret)
    else:
        internal.call("UnlockWithMasterPassword", "o(oayays)", path, secret)

    if Collection(connection, path).is_locked():
        raise RuntimeError("The default keyring is still locked")
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    keyrings = data_home / "keyrings"
    name = (keyrings / "default").read_text().strip()
    if Path(name).name != name:
        raise RuntimeError("Invalid default keyring filename")
    with (keyrings / f"{name}.keyring").open("rb") as file:
        if file.read(16) != b"GnomeKeyring\n\r\x00\n":
            raise RuntimeError("The default keyring is not encrypted; enroll it")
    connection.close()


if __name__ == "__main__":
    main()

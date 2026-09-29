"""Re-encrypt closed Chromium cookie databases from Linux v10 to v11.

Make an encrypted backup first. This retains cookie values and metadata;
it does not contact their websites or print their contents.
"""

import argparse
import hashlib
import sqlite3
import subprocess
from pathlib import Path

import secretstorage
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


def cipher(password):
    """Use Chromium's Linux OSCrypt AES-CBC key derivation."""
    key = hashlib.pbkdf2_hmac("sha1", password, b"saltysalt", 1, 16)
    return Cipher(algorithms.AES(key), modes.CBC(b" " * 16))


def decrypt(ciphertext, password):
    """Decode a v10/v11 cookie, retaining its embedded hostname digest."""
    decoder = cipher(password).decryptor()
    padded = decoder.update(ciphertext[3:]) + decoder.finalize()
    unpadder = padding.PKCS7(128).unpadder()
    return unpadder.update(padded) + unpadder.finalize()


def encrypt(plaintext, password):
    """Encode a cookie with the existing keyring-backed Chromium key."""
    padder = padding.PKCS7(128).padder()
    padded = padder.update(plaintext) + padder.finalize()
    encoder = cipher(password).encryptor()
    return b"v11" + encoder.update(padded) + encoder.finalize()


def migrate(path, password):
    """Validate every encrypted cookie before committing any replacements."""
    with sqlite3.connect(path.as_uri() + "?mode=rw", uri=True) as db:
        db.execute("PRAGMA secure_delete=ON")
        db.execute("BEGIN IMMEDIATE")
        version = int(db.execute(
            "SELECT value FROM meta WHERE key='version'"
        ).fetchone()[0])
        updates = []
        for rowid, host, value, encrypted in db.execute(
            "SELECT rowid, host_key, value, encrypted_value FROM cookies"
        ):
            if value or encrypted[:3] not in (b"v10", b"v11"):
                raise RuntimeError("Unsupported cookie format; no changes made")
            old_password = b"peanuts" if encrypted[:3] == b"v10" else password
            plaintext = decrypt(encrypted, old_password)
            if version >= 24:
                if plaintext[:32] != hashlib.sha256(host.encode()).digest():
                    raise RuntimeError("Cookie integrity check failed")
            if encrypted[:3] == b"v10":
                replacement = encrypt(plaintext, password)
                if decrypt(replacement, password) != plaintext:
                    raise RuntimeError("Cookie round-trip check failed")
                updates.append((replacement, rowid))
        db.executemany(
            "UPDATE cookies SET encrypted_value=? WHERE rowid=?", updates
        )
        db.commit()
        db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        db.execute("VACUUM")
        db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    print(f"Migrated {len(updates)} cookies in {path}")


def main():
    """Use the unlocked default keyring to migrate explicit database paths."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("databases", nargs="+", type=Path)
    args = parser.parse_args()
    running = subprocess.run(
        ["pgrep", "-x", "chromium"], stdout=subprocess.DEVNULL, check=False
    )
    if running.returncode != 1:
        raise RuntimeError("Close Chromium before migrating cookies")
    connection = secretstorage.dbus_init()
    collection = secretstorage.get_default_collection(connection)
    collection.ensure_not_locked()
    items = list(collection.search_items({"application": "chromium"}))
    if len(items) != 1:
        raise RuntimeError("Expected exactly one Chromium Safe Storage key")
    password = items[0].get_secret()
    for path in args.databases:
        migrate(path.resolve(), password)
    connection.close()


if __name__ == "__main__":
    main()

# HTML directory server

Serves `~/public/` on localhost port 8765. The gateway
(`../gateway`) exposes it privately over HTTPS at `/public/`. Links in
the listing are relative, so it works under any path prefix.

Put files directly in `~/public/`. Directory listings are generated on each
request, including when an `index.html` exists. Click that file to open it.
Symlinks outside `~/public/` stay hidden unless their resolved targets are under
an explicit `--allow-root`. The NixOS service allows `~/projects/`. Create a
symlink in `~/public/` to publish a selected directory or file; allowlisting a
root does not publish it automatically.

- `server.py` handles files and directory metadata.
- `index.html` is the Jinja template, with HTML escaping enabled.
- `style.css` is included in the rendered page.
- `../../.nix/module-html-serving.nix` supplies Python/Jinja and the systemd
  service, and creates the public directory.

The agents host imports the module. After merging, `dots rebuild` installs
it.

For local development with Python and Jinja installed:

```sh
python3 server.py --directory ~/public --port 8766
python3 -B -m unittest -v
```

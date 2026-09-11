# HTML directory server

Serves `~/public/` on localhost port 8765. Tailscale Serve exposes it
privately over HTTPS on port 8444. Run `tailscale serve status` for the URL.

Put files directly in `~/public/`. Directory listings are generated on each
request, including when an `index.html` exists. Click that file to open it.

- `server.py` handles files and directory metadata.
- `index.html` is the Jinja template, with HTML escaping enabled.
- `style.css` is included in the rendered page.
- `../../.nix/module-html-serving.nix` supplies Python/Jinja and the systemd
  services, creates the public directory, and configures the Tailscale route.

The agents host imports the module. After merging, `dots rebuild` installs
it. The machine must already be signed into Tailscale with Serve enabled.
The setup only changes port 8444; existing routes remain in place.

For local development with Python and Jinja installed:

```sh
python3 server.py --directory ~/public --port 8766
python3 -B -m unittest -v
```

On the current VM, remove the old manually installed user service before
starting the NixOS service, since both use port 8765:

```sh
systemctl --user disable --now html-serving.service
```

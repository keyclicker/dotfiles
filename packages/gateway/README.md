# Gateway

One tailnet entry point for the agents box: open it, click through.

```text
https://agents.<tailnet>.ts.net/          services index
                               /public/   ~/public listing (../html-serving)
                               /desktop/  XFCE desktop over noVNC
                               /t3        → :3773, T3 Code
                               /udex      → :8443, Udex preview
```

Tailscale terminates HTTPS on 443 and forwards it to nginx on
`127.0.0.1:8080`; the path picks the app.

- `nginx.conf` holds every route. It is included into nginx's `http`
  block, and `@site@` is replaced with this directory.
- `index.html` is the static services list served at `/`.
- `../../.nix/module-gateway.nix` enables nginx, runs the
  html-serving directory server and declares the 443 route via
  `option-tailnet.nix`.

Apps that load assets from `/` (T3, Udex) can't live under a path, so
they keep their own tailnet ports; the index links to them through
short redirects.

## Adding a service

Path-friendly app (relative asset URLs): add a `location` to
`nginx.conf` and a line to `index.html`. Root-only app: give it a
`local.tailnet.https` port in its module, add a redirect `location`
and an index line.

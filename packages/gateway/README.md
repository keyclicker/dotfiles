# Gateway

One tailnet entry point for the agents box, no ports to remember.

```text
https://agents.<tailnet>.ts.net/          services index
                               /public/   ~/public listing (../html-serving)
                               /desktop/  XFCE desktop over noVNC
                               /t3        → t3.<tailnet>.ts.net
                               /udex      → :8443 (Udex owns that route)
https://t3.<tailnet>.ts.net/              T3 Code
```

Tailscale terminates HTTPS for the node name and for the `svc:t3`
Tailscale Service, then forwards both to nginx on `127.0.0.1:8080`.
nginx picks the site by `Host`, the app by path.

- `nginx.conf` holds every route. It is included into nginx's `http`
  block, and `@site@` is replaced with this directory.
- `index.html` is the static services list served at `/`.
- `../../.nix/module-gateway.nix` enables nginx and declares the
  Tailscale routes via `option-tailnet.nix`.

Apps that load assets from `/` (T3, Udex) need an origin of their own.
They get a Tailscale Service name; everything else lives under a path.

## One-time setup

A Service host must be a tagged node; agents already is. In the admin
console:

1. **Services → Define a Service**: name `t3`, port `tcp:443`.
2. Approve agents under the service's hosts, or auto-approve its tag in
   the policy file:

   ```json
   "autoApprovers": { "services": { "svc:t3": ["tag:<agents tag>"] } }
   ```

3. Make sure a grant lets your devices reach `svc:t3` on 443.

Then `dots rebuild`. Until the service is approved, `t3.<tailnet>` does
not resolve, and T3 is reachable only on loopback.

## Adding a service

Path-friendly app (relative asset URLs): add a `location` to the agents
server block and a line to `index.html`. Root-only app: define
`svc:<name>`, add `local.tailnet.services.<name>` in
`module-gateway.nix` and a `server_name <name>.*;` block here.

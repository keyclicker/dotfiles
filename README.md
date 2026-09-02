# dotfiles

One repo for every machine: shell, editors, agents, and the nix
configurations that install them (`.nix/`, see its README).

First switch on a fresh machine, one line per platform:

```sh
# MacBook (nix-darwin)
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- mac

# fresh NixOS guest, from the installer ISO (wipes the disk)
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- iso vm

# NixOS already running (agents, desktop, vm, container)
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- nixos agents

# Ubuntu and friends (standalone home-manager)
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- standalone
```

Installs nix if missing, clones the repo to `~/.dotfiles`, switches.
Later: `dots rebuild`.

# Nix configurations

One flake for every machine. Each machine is a stack of role modules
plus a host leaf; every module owns its packages next to its config.

## Layout

```
.nix/
├── flake.nix           # inputs + one output per machine:
│                       # mac       = common + desktop + hosts/mac
│                       # agents    = common + server + slopbox
│                       #             + hosts/agents
│                       # raspberry = home-manager, hosts/raspberry
│                       #             (reuses common's package list)
├── modules/
│   ├── common.nix      # every machine: nix settings (flakes, gc,
│   │                   # optimise) + cross-platform CLI tools
│   ├── desktop.nix     # desktops: shared desktop packages
│   ├── server.nix      # servers: user + ssh keys, sshd hardening,
│   │                   # mDNS resolution, tailscale, docker, terminfo
│   └── slopbox.nix     # AI coding agents: claude, codex, t3 CLI
│                       # wrappers + t3 web server (port 3773)
└── hosts/              # leaves: machine-specific config + packages
    ├── mac.nix         # nix-darwin: homebrew casks, macOS defaults
    ├── agents.nix      # NixOS LXC guest: networking, toolchains
    └── raspberry.nix   # Ubuntu pi: home-manager user env, apt system
```

## Design

- **Modules own their packages**: a machine's package set is the merge
  of its modules' `environment.systemPackages` — read the module list
  in `flake.nix`, then each module is self-contained. No separate
  package data file to cross-reference.
- **Layers**: `common` = cross-platform CLI tools the dotfiles depend
  on, installed everywhere. `desktop` = shared by mac + future NixOS
  desktop. Role modules (`server`, `slopbox`) add only packages coupled
  to the services they configure. Host-only packages stay in the host
  leaf.
- **Reuse on non-NixOS hosts**: the raspberry home-manager config feeds
  `common`'s `environment.systemPackages` into `home.packages` by
  importing the module directly. This works while `modules/common.nix`
  stays a plain `{ pkgs, ... }` function; the moment it needs
  config/lib, extract the package list into shared data instead.
- **Pins**: Linux hosts follow `nixos-unstable` (`nixpkgs`); mac follows
  `nixpkgs-unstable` (`nixpkgs-darwin`), matching the original
  standalone darwin flake.

## Planned hosts

- `desktop` — NixOS desktop (`common` + `desktop` + leaf)

## Usage

```sh
# mac
sudo darwin-rebuild switch --flake ~/.nix#mac

# agents container
sudo nixos-rebuild switch --flake ~/.nix#agents

# raspberry (Ubuntu, user environment only; see hosts/raspberry.nix
# for first-time bootstrap)
home-manager switch --flake ~/.nix#keyclicker@raspberry
```

`~/.nix` is a symlink to `~/.dotfiles/.nix`.

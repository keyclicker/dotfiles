# Nix configurations

One flake for every machine. Package lists are shared data; each host
composes layers on top.

## Layout

```
.nix/
├── flake.nix           # inputs + one output per machine
├── packages.nix        # pure package lists: common / desktop
├── keys.nix            # ssh public keys, single source of truth
├── modules/
│   ├── common.nix      # every machine: nix settings (flakes, gc,
│   │                   # optimise) + common packages
│   ├── desktop.nix     # desktops: shared desktop packages
│   ├── server.nix      # servers: user + ssh keys, sshd hardening,
│   │                   # mDNS resolution, tailscale, docker, terminfo
│   └── slopbox.nix     # AI coding agents: claude, codex, t3 CLI
│                       # wrappers + t3 web server (port 3773)
└── hosts/              # leaves: machine-specific config only
    ├── mac.nix         # nix-darwin: homebrew casks, macOS defaults
    └── agents.nix      # NixOS LXC guest: networking, toolchains
```

## Design

- **Layers**: `hosts/*` import nothing shared; `flake.nix` composes
  `common` + (`desktop` | `server`) + host leaf per machine.
- **Packages as data**: `packages.nix` holds plain lists so darwin and
  NixOS modules (and later home-manager on non-NixOS hosts) can reuse
  them. `common` = cross-platform CLI tools the dotfiles depend on,
  installed everywhere. `desktop` = shared by mac + future NixOS
  desktop. Host-only packages stay in the host leaf.
- **Pins**: Linux hosts follow `nixos-unstable` (`nixpkgs`); mac follows
  `nixpkgs-unstable` (`nixpkgs-darwin`), matching the original
  standalone darwin flake.

## Planned hosts

- `desktop` — NixOS desktop (`common` + `desktop` + leaf)
- `server` — Ubuntu host running nix; gets `common` packages via
  home-manager, system stays apt

## Usage

```sh
# mac
sudo darwin-rebuild switch --flake ~/.nix#mac

# agents container
sudo nixos-rebuild switch --flake ~/.nix#agents
```

`~/.nix` is a symlink to `~/.dotfiles/.nix`.

# Nix configurations

One flake for every machine. Each machine is a stack of role modules
plus a host leaf; every module owns its packages next to its config.
Home-manager symlinks the dotfiles from the repo root into `$HOME`.

## Layout

```
.nix/
├── flake.nix           # inputs + one output per machine:
│                       # mac       = common + desktop + agents
│                       #             + hosts/mac + home/common
│                       #             + home/desktop
│                       # agents    = common + server + agents +
│                       #             slopbox + hosts/agents
│                       #             + home/common
│                       # raspberry = standalone home-manager,
│                       #             home/standalone + hosts/raspberry
├── modules/            # system modules (nix-darwin / NixOS)
│   ├── common.nix      # every machine: nix settings (flakes, gc,
│   │                   # optimise) + cross-platform CLI tools
│   ├── desktop.nix     # desktops: shared desktop packages
│   ├── server.nix      # servers: user + ssh keys, sshd hardening,
│   │                   # mDNS resolution, tailscale, docker, terminfo
│   ├── agents.nix      # AI coding agent CLIs (claude, codex,
│   │                   # opencode), every machine
│   └── slopbox.nix     # t3 code: CLI wrapper + web server
│                       # (port 3773)
├── home/               # home-manager modules, mirror modules/ layers
│   ├── common.nix      # core dotfile symlinks (shell, git, tmux,
│   │                   # vim, nvim, scripts, ai)
│   ├── desktop.nix     # GUI/desktop dotfile symlinks
│   │                   # (.doom.d, ghostty, karabiner, sway, ...)
│   └── standalone.nix  # foreign (non-NixOS) Linux: emulates the
│                       # system layer at user level — common's
│                       # packages as home.packages, user gc
└── hosts/              # leaves: machine-specific config + packages
    ├── mac.nix         # nix-darwin: homebrew casks, macOS defaults
    ├── agents.nix      # NixOS LXC guest: networking, toolchains
    └── raspberry.nix   # Ubuntu pi: home-manager user env, apt system
```

## Design

- **Home-manager owns the dotfile symlinks**: `home/common.nix` (plus
  `home/desktop.nix` for GUI hosts) maps each repo file (`~/.dotfiles/.zshrc`,
  `.config/nvim`, ...) to its `$HOME` target with `mkOutOfStoreSymlink`,
  pointing at the live checkout — edits apply immediately, no rebuild.
  stow and link.sh are retired. The repo must be checked out at
  `~/.dotfiles` on every host.
- **`modules/` vs `home/`**: same layer names, different module systems.
  `modules/*` evaluate in the system module system (nix-darwin/NixOS),
  `home/*` in home-manager's — they cannot share files, so each layer
  gets a pair: `modules/common.nix` ↔ `home/common.nix`,
  `modules/desktop.nix` ↔ `home/desktop.nix`.
- **Per-entry links for shared dirs**: `~/.config`, `~/.claude`,
  `~/.codex`, `~/.gnupg` are never owned wholesale — machine-local
  state (claude settings/transcripts, gpg keys, other apps' config)
  lives next to the linked entries.
- **Modules own their packages**: a machine's package set is the merge
  of its modules' `environment.systemPackages` — read the module list
  in `flake.nix`, then each module is self-contained. No separate
  package data file to cross-reference.
- **Reuse on non-NixOS hosts**: `home/standalone.nix` is the role
  module for machines where the distro owns the system layer — it
  feeds `common`'s `environment.systemPackages` into `home.packages`
  by importing the module directly and re-declares user-level gc.
  This works while `modules/common.nix` stays a plain `{ pkgs, ... }`
  function; the moment it needs config/lib, extract the package list
  into shared data instead. Host leaves (raspberry) stay identity-only:
  username, home directory.
- **Layers**: `common` = everywhere. `desktop` = mac + future NixOS
  desktop. Role modules (`server`, `slopbox`) add only packages coupled
  to the services they configure. Host-only packages stay in the host
  leaf.
- **Pins**: Linux hosts follow `nixos-unstable` (`nixpkgs`); mac follows
  `nixpkgs-unstable` (`nixpkgs-darwin`), matching the original
  standalone darwin flake.

## Planned hosts

- `desktop` — NixOS desktop (`common` + `desktop` + `home/*` + leaf)

## Usage

```sh
# any machine (wraps the right rebuild command)
nix-rebuild

# mac
sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac

# agents container
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents

# raspberry (Ubuntu, user environment only; see hosts/raspberry.nix
# for first-time bootstrap)
home-manager switch --flake ~/.dotfiles/.nix#keyclicker@raspberry
```

The flake is addressed as `~/.dotfiles/.nix` directly; the old `~/.nix`
symlink is no longer needed (but harmless if kept).

## First switch on an existing machine

Old stow/manual symlinks collide with home-manager's links; the flake
sets `backupFileExtension = "hm-bak"`, so they are renamed aside
instead of failing the activation. After the first successful switch:

```sh
# leftover backups are dangling symlinks, not data — inspect, then rm
find ~ ~/.config ~/.claude ~/.codex ~/.gnupg -maxdepth 1 -name '*.hm-bak'
```

Verify with `readlink -f ~/.zshrc` — it should resolve to
`~/.dotfiles/.zshrc` (via one store-path indirection, which is how
`mkOutOfStoreSymlink` works).

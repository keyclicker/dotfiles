# Nix configurations

One flake for every machine. A machine is a `host-*.nix` leaf that
imports its stack: a platform, profiles, modules, options and (for
pets) generated hardware. `flake.nix` is wiring only: one output per
leaf plus the home-manager plumbing. Home-manager symlinks the
dotfiles from the repo root into `$HOME`.

## Layout

Flat files; the prefix is the layer. Prefixes match the directory
names a later split would use (`option-` ↔ `options/`), so splitting
a layer when it grows past ~5 files is a pure `git mv`.

```
.nix/
├── flake.nix                # inputs + one output per host leaf
│
├── option-lan.nix           # local.lan.* vocabulary: modules list LAN-only
│                            # ports here; the one firewall write lives
│                            # inside and stays inert until a port is set
│
├── module-common.nix        # every machine: nix settings (flakes, gc,
│                            # optimise), core CLI tools, dev toolchains
├── module-agents.nix        # AI coding agent CLIs (claude, codex, opencode)
├── module-browser.nix       # headless chromium + agent-browser for agents
├── module-slopbox.nix       # t3 code: CLI wrapper + web server (3773, LAN)
├── module-iperf.nix         # iperf3 server (5201, all interfaces)
├── module-incus.nix         # incus + web UI (8443, LAN + tailscale),
│                            # nftables, docker/incus forwarding truce
├── module-dockge.nix        # dockge on the docker socket; written, not
│                            # composed anywhere (password-only web UI)
├── module-ollama-darwin.nix # ollama as a launchd user agent (mac)
│
├── profile-server.nix       # servers: user + ssh keys, sshd hardening,
│                            # mDNS, tailscale, docker, terminfo
├── profile-desktop.nix      # desktops: shared desktop packages
│
├── platform-vm.nix          # QEMU guests (Proxmox, incus, UTM): networkd
│                            # DHCP on eth0, systemd-boot, serial console,
│                            # hostname from DHCP / hostnamectl
├── platform-container.nix   # LXC guests (incus, Proxmox CT): hostname
│                            # from lxc, no build sandbox
│
├── hardware-agents.nix      # nixos-generate-config output for agents
│
├── home-common.nix          # core dotfile symlinks (shell, git, tmux,
│                            # vim, nvim, scripts, ai)
├── home-desktop.nix         # GUI dotfile symlinks (.doom.d, ghostty,
│                            # karabiner, sway, ...)
├── home-standalone.nix      # foreign (non-NixOS) Linux: the shell user
│                            # environment, nothing system-level
│
├── host-mac.nix             # MacBook: nix-darwin, homebrew casks
├── host-agents.nix          # pet VM on Proxmox: the agent sandbox
├── host-vm.nix              # generic VM, spawned N times, no identity
├── host-container.nix       # generic container, same idea
├── host-standalone.nix      # any foreign Linux (Ubuntu pi, VPS): user
│                            # environment only, one output per arch
└── host-jail.nix            # Docker jail (.scripts/agent-jail), same
```

## Layers

Imports point downward only. Hosts compose; everything below them is
a self-contained piece that imports nothing from the repo.

| prefix      | role                                                          |
|-------------|---------------------------------------------------------------|
| `option-`   | `local.*` vocabulary and the central write it gates. Modules **set** the options, never import the file; the host pulls it in. |
| `module-`   | one software area each, finest slice, imports nothing         |
| `profile-`  | machine role: what every server / desktop gets                |
| `platform-` | substrate glue (VM, container); imports only nixpkgs profiles |
| `hardware-` | generated pet hardware config                                 |
| `home-`     | home-manager mirror of the layers above                       |
| `host-`     | identity leaf, the only place repo files compose               |

Outputs by leaf:

| output                           | leaf                 | stack                                                                 |
|----------------------------------|----------------------|-----------------------------------------------------------------------|
| `mac`                            | `host-mac.nix`       | common + desktop + agents + ollama-darwin; home common + desktop      |
| `agents`                         | `host-agents.nix`    | common + server + agents + browser + slopbox + iperf + vm + lan + hardware; home common |
| `vm`                             | `host-vm.nix`        | common + server + incus + vm + lan                                    |
| `container`                      | `host-container.nix` | common + server + container + lan                                     |
| `keyclicker@standalone-<system>` | `host-standalone.nix`| home standalone                                                       |
| `keyclicker@jail-<system>`       | `host-jail.nix`      | home standalone + agents + browser                                    |

`<system>` is `x86_64-linux` or `aarch64-linux`: standalone
home-manager needs `pkgs` for a fixed system, so identity-less home
leaves are instantiated per architecture and the caller (`dots`,
`agent-jail`) picks its own.

## Design

- **Home-manager owns the dotfile symlinks**: `home-common.nix` (plus
  `home-desktop.nix` for GUI hosts) maps each repo file
  (`~/.dotfiles/.zshrc`, `.config/nvim`, ...) to its `$HOME` target
  with `mkOutOfStoreSymlink`, pointing at the live checkout — edits
  apply immediately, no rebuild. The repo must be checked out at
  `~/.dotfiles` on every host. Generic guests (`vm`, `container`) skip
  home-manager: a fresh guest has no checkout to point at.
- **System vs home**: same layer names, different module systems.
  `module-*`/`profile-*` evaluate in nix-darwin/NixOS, `home-*` in
  home-manager's — they cannot share files, so a layer that needs both
  gets a pair: `module-common.nix` ↔ `home-common.nix`,
  `profile-desktop.nix` ↔ `home-desktop.nix`.
- **Home-manager stays in `flake.nix`**: the leaf owns the system
  stack, but the hm NixOS/darwin module and the `home-*` list need
  the `home-manager` flake input, so that block lives next to the
  output.
- **Per-entry links for shared dirs**: `~/.config`, `~/.claude`,
  `~/.codex`, `~/.gnupg` are never owned wholesale — machine-local
  state (claude settings/transcripts, gpg keys, other apps' config)
  lives next to the linked entries.
- **Modules own their packages**: a machine's package set is the merge
  of its modules' `environment.systemPackages` — read the imports in
  the host leaf, then each module is self-contained. No separate
  package data file to cross-reference.
- **Options over firewall pokes**: modules that serve on the LAN set
  `local.lan.allowed*Ports`; `option-lan.nix` turns the list into the
  one `networking.firewall.interfaces.<lan>` write. Every guest's NIC
  is `eth0` (`platform-vm.nix` disables predictable names; container
  veths are `eth0` natively), so the default fits all guests.
- **Generic guests have no name**: `platform-vm.nix` and
  `platform-container.nix` set `networking.hostName = ""`, so the
  spawner's name sticks (incus via DHCP or lxc, Proxmox CT via lxc) or
  `hostnamectl set-hostname` persists in `/etc/hostname`. Pet hosts
  set their name and win.
- **Foreign Linux gets the shell environment, 1:1**:
  `home-standalone.nix` feeds `module-common.nix`'s
  `environment.systemPackages` into `home.packages` by importing the
  module as a plain function, so an Ubuntu shell has exactly the tools
  a NixOS one has. Nothing system-level is emulated: hostname, nix
  daemon, gc, services stay with the distro. This works while the
  imported modules stay plain `{ pkgs, ... }` functions; the moment
  one needs config/lib, extract the package list into shared data
  instead. The jail adds agents + browser the same way.
- **Pins**: Linux hosts follow `nixos-unstable` (`nixpkgs`); mac follows
  `nixpkgs-unstable` (`nixpkgs-darwin`), matching the original
  standalone darwin flake.

## Planned

- `desktop` — NixOS desktop (#35): `host-desktop.nix` on
  `platform-vm.nix` + `profile-desktop.nix` + `home-desktop.nix`
- prebuilt images for `vm` / `container` (#32), disko + nixos-anywhere
  (#33)

## Usage

```sh
# fresh machine: install nix if missing, enable flakes, first switch;
# optional second arg sets the login shell from the nix profile
~/.dotfiles/install.sh standalone zsh

# any machine (wraps the right rebuild command; `dots help` for more)
dots rebuild

# mac
sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac

# agents VM
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents

# generic guests (install the manual way first, then switch)
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container

# foreign Linux (Ubuntu pi, VPS; user environment only). `dots rebuild`
# appends this machine's architecture; by hand:
home-manager switch --flake ~/.dotfiles/.nix#keyclicker@standalone-x86_64-linux
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

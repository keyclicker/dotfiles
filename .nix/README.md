# Nix configurations

One flake for every machine. A machine is a `host-*.nix` leaf that
imports its stack: a platform, profiles, modules, options and a
declared disk layout. `flake.nix` is wiring only: one output per
leaf plus the home-manager and disko plumbing. Home-manager symlinks the
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
├── module-ollama-desktop.nix # ollama on loopback: launchd user agent on
│                             # the mac, services.ollama on NixOS, one tuning
├── module-desktop-darwin.nix # the mac desktop below the apps: system
│                             # defaults, Touch ID for sudo
├── module-desktop-linux.nix # the NixOS desktop below the apps: sway +
│                            # bar/launcher/notifications/lock/screenshots,
│                            # greetd autologin, keyd remaps, pipewire,
│                            # bluetooth, portals, fonts (configs are
│                            # dotfiles, see home-desktop)
├── module-apps-darwin.nix   # GUI apps on the mac: homebrew casks, mac-only
│                            # packages
├── module-apps-linux.nix    # GUI apps on the NixOS desktop: nixpkgs for
│                            # what must see the host (terminal, editors,
│                            # media), flathub for the self-updating rest
│
├── profile-server.nix       # servers: user + ssh keys, sshd hardening,
│                            # mDNS, tailscale, docker, terminfo
├── profile-desktop.nix      # desktops (mac + NixOS): shared packages
│
├── platform-vm.nix          # QEMU guests (Proxmox, incus, UTM): networkd
│                            # DHCP on eth0, systemd-boot, serial console,
│                            # hostname from DHCP / hostnamectl
├── platform-container.nix   # LXC guests (incus, Proxmox CT): hostname
│                            # from lxc, no build sandbox
├── platform-utm.nix         # UTM on the mac: aarch64, virtio-blk disk
│                            # names, pl011 console; on top of a host leaf
│
├── hardware-vm.nix          # disko layout of every QEMU guest: ESP + ext4
│                            # root on sda, encrypted swap on sdb, by GPT
│                            # label; installs and mounts from one attrset
│
├── home-common.nix          # core dotfile symlinks (shell, git, tmux,
│                            # vim, nvim, scripts, ai)
├── home-desktop.nix         # GUI dotfile symlinks (.doom.d, ghostty,
│                            # karabiner, sway, waybar, mako, ...) and,
│                            # on Linux, the GTK look (dconf, settings.ini)
├── home-standalone.nix      # foreign (non-NixOS) Linux: the shell user
│                            # environment, nothing system-level
│
├── host-mac.nix             # MacBook: nix-darwin, homebrew casks
├── host-agents.nix          # pet VM on Proxmox: the agent sandbox
├── host-desktop.nix         # desktop VM (#35): the mac's stack on sway,
│                            # generic identity, SPICE; UTM via platform-utm
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
| `hardware-` | declared disks (disko): one attrset formats at install and mounts at runtime |
| `home-`     | home-manager mirror of the layers above                       |
| `host-`     | identity leaf, the only place repo files compose               |

Outputs by leaf:

| output                           | leaf                 | stack                                                                 |
|----------------------------------|----------------------|-----------------------------------------------------------------------|
| `mac`                            | `host-mac.nix`       | common + desktop + agents + desktop-darwin + ollama-desktop + apps-darwin; home common + desktop |
| `agents`                         | `host-agents.nix`    | common + server + agents + browser + slopbox + iperf + vm + hardware + lan; home common |
| `desktop`                        | `host-desktop.nix`   | common + server + desktop + agents + incus + desktop-linux + apps-linux + ollama-desktop + vm + hardware + lan; home common + desktop |
| `desktop-utm`                    | `host-desktop.nix`   | the same + `platform-utm.nix` (aarch64, UTM on the mac)              |
| `vm`                             | `host-vm.nix`        | common + server + incus + vm + hardware + lan                         |
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
- **Home-manager and disko stay in `flake.nix`**: the leaf owns the
  system stack, but the hm NixOS/darwin module, the `home-*` list and
  the disko module need their flake inputs, so those lines live next
  to the output; the leaves only set the options.
- **Disks are declared, not probed**: `hardware-vm.nix` states the
  layout (GPT, `ESP` + `root` partitions found by label) and disko
  renders both the install script and the runtime `fileSystems` from
  it. No `nixos-generate-config`, no per-machine UUIDs, so a clone,
  an image or a `nixos-anywhere` reinstall all boot the same file.
  Every guest gets two disks: system and an encrypted swap disk
  (`nofail`, so a single-disk boot still comes up).
- **The desktop mirrors the mac**: `host-desktop.nix` composes what
  `host-mac.nix` does (common, desktop, agents, ollama) plus incus,
  with `module-desktop-linux.nix` standing in for yabai/skhd/karabiner and
  `module-apps-linux.nix` for the casks of `module-apps-darwin.nix`:
  self-updating consumer apps (browser, chat, music, notes) come from
  flathub via nix-flatpak so they track upstream between rebuilds,
  like casks do; anything that must see the host's PATH and dotfiles
  (terminal, editors, media tools) comes from nixpkgs. The session is dotfiles (`.config/sway`,
  `waybar`, `fuzzel`, `mako`), linked by `home-desktop.nix`; nix only
  installs what they call. keyd remaps the keyboards plugged into
  the machine and skips QEMU's virtual ones: keys arriving over
  SPICE were remapped by the client already (karabiner on the mac).
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
  daemon, services stay with the distro; only the nix store gc is
  ours, as a user timer. This works while the
  imported modules stay plain `{ pkgs, ... }` functions; the moment
  one needs config/lib, extract the package list into shared data
  instead. The jail adds agents + browser the same way.
- **Pins**: Linux hosts follow `nixos-unstable` (`nixpkgs`); mac follows
  `nixpkgs-unstable` (`nixpkgs-darwin`), matching the original
  standalone darwin flake.

## Planned

- a bare-metal NixOS desktop: `host-<name>.nix` composing the
  desktop modules on its own `hardware-<name>.nix`
- prebuilt images for `vm` / `container` (#32)

## Usage

```sh
# fresh machine: install nix if missing, clone, first switch (mac | iso <host>
# | nixos <host> | standalone); reads top to bottom as the per-platform manual
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- standalone

# fresh NixOS guest from the installer ISO: disko wipes and formats the
# disk as hardware-vm.nix says, nixos-install, reboot
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- iso vm

# the same from another machine, onto whatever the target booted (ISO,
# cloud image, old NixOS)
nix run github:nix-community/nixos-anywhere -- --flake ~/.dotfiles/.nix#agents --target-host root@<ip>

# any machine (wraps the right rebuild command; `dots help` for more)
dots rebuild

# mac
sudo darwin-rebuild switch --flake ~/.dotfiles/.nix#mac

# agents VM
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#agents

# desktop VM (`iso desktop` first, then `install.sh nixos desktop` for the
# checkout home-manager links into); UTM on the mac: desktop-utm
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#desktop

# generic guests (`iso vm` above first, then switch)
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

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
├── flake.nix                # inputs, one output per host leaf, the
│                            # guest image packages
│
├── option-lan.nix           # local.lan.* vocabulary: modules list LAN-only
│                            # ports here; the one firewall write lives
│                            # inside and stays inert until a port is set
│
├── module-core.nix          # every machine: nix settings (flakes, gc,
│                            # optimise), the CLI floor a box is administered
│                            # with; generic guests stop here
├── module-common.nix        # every machine somebody works in: the
│                            # interactive tool set (yazi, ffmpeg, gh, ...)
├── module-dev.nix           # dev toolchains: build tools, languages,
│                            # C compilers; stacked wherever common is
├── module-nvim-minimal.nix  # generic guests: nvim flagged minimal (no LSP,
│                            # formatters, latex), tree-sitter parsers
│                            # prebuilt by nixpkgs instead of compiled
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
│                            # dotfiles, see home-dotfiles)
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
│                            # hostname from DHCP / hostnamectl, SPICE agent
│                            # (graphical.target only)
├── platform-container.nix   # LXC guests (incus, Proxmox CT): hostname
│                            # from lxc, no build sandbox
│
├── hardware-vm.nix          # disko layout of every QEMU guest: ESP + ext4
│                            # root on sda, encrypted swap on sdb, by GPT
│                            # label; installs and mounts from one attrset
│
├── home-dotfiles.nix        # every dotfile symlink (shell, git, tmux, vim,
│                            # nvim, scripts, ai, ghostty, sway, karabiner,
│                            # ...); OS-bound entries check the platform
├── home-desktop-linux.nix   # the NixOS desktop's GTK look (dconf,
│                            # settings.ini, cursor), xdg user dirs
├── home-standalone.nix      # foreign (non-NixOS) Linux: the shell user
│                            # environment, nothing system-level
│
├── host-mac.nix             # MacBook: nix-darwin, homebrew casks
├── host-agents.nix          # pet VM on Proxmox: the agent sandbox
├── host-desktop-vm.nix      # desktop VM (#35): the mac's stack on sway, no
│                            # identity; Proxmox on the x86 box
├── host-desktop-utm.nix     # the same under UTM on the mac: aarch64,
│                            # virtio-blk disk names, pl011 console
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
| `mac`                            | `host-mac.nix`       | core + common + dev + desktop + agents + desktop-darwin + ollama-desktop + apps-darwin; home dotfiles |
| `agents`                         | `host-agents.nix`    | core + common + dev + server + agents + browser + slopbox + iperf + vm + hardware + lan; home dotfiles |
| `desktop-vm`                     | `host-desktop-vm.nix`| core + common + dev + server + desktop + agents + incus + desktop-linux + apps-linux + ollama-desktop + vm + hardware + lan; home dotfiles + desktop-linux |
| `desktop-utm`                    | `host-desktop-utm.nix`| the same on aarch64 (UTM on the mac)                                |
| `vm`                             | `host-vm.nix`        | core + nvim-minimal + server + incus + vm + hardware + lan; home dotfiles |
| `container`                      | `host-container.nix` | core + nvim-minimal + server + container + lan; home dotfiles       |
| `keyclicker@standalone-<system>` | `host-standalone.nix`| home standalone                                                       |
| `keyclicker@jail-<system>`       | `host-jail.nix`      | home standalone + agents + browser                                    |

`<system>` is `x86_64-linux` or `aarch64-linux`: standalone
home-manager needs `pkgs` for a fixed system, so identity-less home
leaves are instantiated per architecture and the caller (`dots`,
`agent-jail`) picks its own.

Images (`packages.x86_64-linux`, built by `dots image <target>`):

| package           | from        | files                                             |
|-------------------|-------------|---------------------------------------------------|
| `vm-image`        | `vm`        | `main.qcow2` + `swap.qcow2`, disko's build of `hardware-vm.nix` |
| `container-image` | `container` | `rootfs.tar.xz` + `metadata.tar.xz` (incus), from `lxc-container.nix` |

## Design

- **Home-manager owns the dotfile symlinks**: `home-dotfiles.nix`
  maps each repo file (`~/.dotfiles/.zshrc`, `.config/nvim`, ...) to
  its `$HOME` target with `mkOutOfStoreSymlink`, pointing at the live
  checkout — edits apply immediately, no rebuild. Every host links
  everything; only entries bound to one OS (macOS preferences, the
  sway session) check the platform. The repo must be checked out at
  `~/.dotfiles` on every host; `install.sh nixos <host>` clones it,
  which is why an `iso` install is followed by that step.
- **System vs home**: same layer names, different module systems.
  `module-*`/`profile-*` evaluate in nix-darwin/NixOS, `home-*` in
  home-manager's — they cannot share files, so a layer that needs both
  gets a pair: `module-desktop-linux.nix` ↔ `home-desktop-linux.nix`.
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
- **Generic guests spawn from images**: the same disko attrset that
  installs `vm` from the ISO formats two blank qcow2 files in a build
  VM (`system.build.diskoImages`), so the image and an `iso vm`
  install are the same system on the same partitions; `container`'s
  rootfs tarball comes from the `lxc-container.nix` already in its
  stack. `flake.nix` exposes them as packages, `dots image` builds and
  ships them, the hypervisor imports once and clones. The image is a
  starting point: instances keep taking changes with `dots rebuild`.
- **The desktop mirrors the mac**: `host-desktop-vm.nix` composes what
  `host-mac.nix` does (common, desktop, agents, ollama) plus incus,
  with `module-desktop-linux.nix` standing in for yabai/skhd/karabiner and
  `module-apps-linux.nix` for the casks of `module-apps-darwin.nix`:
  self-updating consumer apps (browser, chat, music, notes) come from
  flathub via nix-flatpak so they track upstream between rebuilds,
  like casks do; anything that must see the host's PATH and dotfiles
  (terminal, editors, media tools) comes from nixpkgs. The session is dotfiles (`.config/sway`,
  `waybar`, `fuzzel`, `mako`), linked by `home-dotfiles.nix`; nix only
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
- **Generic guests stay small**: `vm` and `container` compose
  `module-core.nix` alone, the floor a box is administered with over
  ssh (git, tmux, neovim, mc, htop, compose). Every host somebody works
  in stacks `module-common.nix` (interactive tools) and
  `module-dev.nix` (toolchains) on top; those two are most of a
  machine's store, and a guest spawned N times would pay for them N
  times.
- **One nvim config, a minimal profile for guests**: the same linked
  `.config/nvim` runs everywhere; `module-nvim-minimal.nix` exports
  `NVIM_MINIMAL`, which turns off every spec that pulls a toolchain
  (LSP servers via mason, formatters, linters, latex, refactoring,
  neogit, codediff) before lazy clones it, and `NVIM_TREESITTER`, a
  store directory shaped like nvim-treesitter's install dir with
  parsers and queries prebuilt by nixpkgs, so a guest never compiles a
  grammar. What remains is git-clone only: a first start is seconds,
  not the minutes a slow VM spends in gcc.
- **Foreign Linux gets the shell environment, 1:1**:
  `home-standalone.nix` feeds the `environment.systemPackages` of
  `module-core.nix`, `module-common.nix` and `module-dev.nix` into
  `home.packages` by importing each module as a plain function, so an
  Ubuntu shell has exactly the tools a NixOS one has. Nothing
  system-level is emulated: hostname, nix daemon, services stay with
  the distro; only the nix store gc is ours, as a user timer. This
  works while the imported modules stay plain `{ pkgs, ... }`
  functions; the moment one needs config/lib, extract the package
  list into shared data instead. The jail adds agents + browser the
  same way.
- **Pins**: one `nixpkgs` (`nixos-unstable`) for every host, mac
  included; nix-darwin, home-manager and disko follow it.

## Planned

- a bare-metal NixOS desktop: `host-<name>.nix` composing the
  desktop modules on its own `hardware-<name>.nix`

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

# desktop VM (`iso desktop-vm` first, then `install.sh nixos desktop-vm` for
# the checkout home-manager links into); UTM on the mac: desktop-utm
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#desktop-vm

# generic guests (from the image, see below, or `iso vm` above; then switch)
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container

# foreign Linux (Ubuntu pi, VPS; user environment only). `dots rebuild`
# appends this machine's architecture; by hand:
home-manager switch --flake ~/.dotfiles/.nix#keyclicker@standalone-x86_64-linux
```

The flake is addressed as `~/.dotfiles/.nix` directly; the old `~/.nix`
symlink is no longer needed (but harmless if kept).

## Guest images

`vm` and `container` spawn from prebuilt images: import once, clone
per instance, boot. No installer. Built on any x86_64 nix machine
(the agents VM does), shipped with rsync:

```sh
dots image vm pve:/root/images/          # main.qcow2 + swap.qcow2
dots image container pve:/root/images/   # rootfs.tar.xz + metadata.tar.xz
```

Proxmox VM: a template from the two disks, clones from the template.
UEFI without pre-enrolled Secure Boot keys (systemd-boot is unsigned),
virtio-scsi so the disks come up as sda/sdb (`hardware-vm.nix`),
serial console and guest agent as `platform-vm.nix` expects:

```sh
qm create 9000 --name nixos-vm --ostype l26 --machine q35 --bios ovmf \
  --efidisk0 local-zfs:1,efitype=4m,pre-enrolled-keys=0 \
  --scsihw virtio-scsi-single --agent 1 --serial0 socket \
  --net0 virtio,bridge=vmbr0 --cores 2 --memory 4096
qm set 9000 --scsi0 local-zfs:0,import-from=/root/images/main.qcow2,discard=on
qm set 9000 --scsi1 local-zfs:0,import-from=/root/images/swap.qcow2,discard=on,backup=0
qm set 9000 --boot order=scsi0
qm template 9000

qm clone 9000 101 --name box
qm disk resize 101 scsi0 32G   # optional; the root grows into it on boot
qm start 101
```

Proxmox sends no hostname, so the clone boots as `localhost`:
`hostnamectl set-hostname box` once, it persists (`platform-vm.nix`).
Then `install.sh nixos vm` for the checkout home-manager links into.

Proxmox CT: the rootfs tarball is the template. `--ostype nixos` has
Proxmox write hostname and network the NixOS way; `nesting=1` is what
docker inside needs (`module-incus.nix` sets the same for incus CTs):

```sh
cp /root/images/rootfs.tar.xz /var/lib/vz/template/cache/nixos-container.tar.xz
pct create 201 local:vztmpl/nixos-container.tar.xz --ostype nixos \
  --hostname box --unprivileged 1 --features nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp --rootfs local-zfs:8 \
  --cores 2 --memory 2048
pct start 201
```

incus (on a `vm` instance or anywhere): both tarballs make one image,
the instance name becomes the hostname (`platform-container.nix`):

```sh
incus image import metadata.tar.xz rootfs.tar.xz --alias nixos-container
incus launch nixos-container box
```

After a flake change: `dots image` again, import again; running
instances take the change with `dots rebuild`, the image is only where
they start.

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

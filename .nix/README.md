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
├── option-lan.nix           # local.lan.* vocabulary: modules that serve on
│                            # the LAN import it and list their ports; the
│                            # one firewall write lives inside and stays
│                            # inert until a port is set
├── option-npm-globals.nix   # local.npmGlobals.* vocabulary (home-manager):
│                            # npm packages kept at latest, casks/flatpaks
│                            # style; one install per activation
│
├── module-core.nix          # every machine: nix settings (flakes, gc,
│                            # optimise), the CLI floor a box is administered
│                            # with; generic guests stop here
├── module-workstation.nix   # every machine somebody works in: interactive
│                            # tools, build tools, languages, C compilers
├── module-nvim-minimal.nix  # generic guests: nvim flagged minimal (no LSP,
│                            # formatters, latex), tree-sitter parsers
│                            # prebuilt by nixpkgs instead of compiled
├── module-browser.nix       # headless chromium + agent-browser for agents
├── module-cua-desktop.nix   # XFCE/X11 + Cua + noVNC on loopback
├── module-slopbox.nix       # t3 code web server (HTTPS 3773, tailnet),
│                            # exec'ing the npm global of home-agents.nix
├── module-html-serving.nix  # ~/public directory index on loopback,
│                            # Python server in packages/html-serving
├── module-gateway.nix       # tailnet front door on 443: services index,
│                            # nginx routes paths to the loopback services
│                            # above (config in packages/gateway)
├── module-iperf.nix         # iperf3 server (TCP/UDP 5201, tailnet)
├── module-incus.nix         # incus via local Unix socket (no web listener),
│                            # nftables, docker/incus forwarding truce
├── module-ollama-desktop.nix # ollama on loopback only;
│                            # launchd on mac, services.ollama on NixOS
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
│                            # hostname from DHCP / local.nix
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
├── home-agents.nix          # AI coding agent CLIs (claude, codex, opencode)
│                            # and t3 code as npm globals
├── home-standalone.nix      # foreign (non-NixOS) Linux: the shell user
│                            # environment, nothing system-level
│
├── host-mac.nix             # MacBook: nix-darwin, homebrew casks
├── host-agents.nix          # pet VM on Proxmox: the agent sandbox
├── host-desktop-vm.nix      # aarch64 desktop on handwritten QEMU/HVF
│                            # on the mac: virtio-blk disks, PL011 console
├── host-vm.nix              # generic VM, spawned N times, no identity
├── host-container.nix       # generic container, same idea
└── host-standalone.nix      # any foreign Linux (Ubuntu pi, VPS): user
                             # environment only, one output per arch
```

## Layers

Imports point downward only. Hosts compose; everything below them is
a self-contained piece that imports nothing from the repo but the
`option-` file it sets.

| prefix      | role                                                          |
|-------------|---------------------------------------------------------------|
| `option-`   | `local.*` vocabulary and the central write it gates. The consumers that set an option import the file; the module system dedups imports by path, so N importers evaluate it once. |
| `module-`   | one software area each, finest slice, imports nothing but the `option-` it sets |
| `profile-`  | machine role: what every server / desktop gets                |
| `platform-` | substrate glue (VM, container); imports only nixpkgs profiles |
| `hardware-` | declared disks (disko): one attrset formats at install and mounts at runtime |
| `home-`     | home-manager mirror of the layers above                       |
| `host-`     | identity leaf, the only place repo files compose               |

Outputs by leaf:

| output                           | leaf                 | stack                                                                 |
|----------------------------------|----------------------|-----------------------------------------------------------------------|
| `mac`                            | `host-mac.nix`       | core + common + dev + desktop + desktop-darwin + ollama-desktop + apps-darwin; home dotfiles + agents |
| `agents`                         | `host-agents.nix`    | core + common + dev + server + browser + slopbox + html-serving + gateway + iperf + vm + hardware; home dotfiles + agents |
| `desktop-vm`                     | `host-desktop-vm.nix`| core + common + dev + server + desktop + incus + desktop-linux + apps-linux + ollama-desktop + vm + hardware; home dotfiles + desktop-linux + agents |
| `vm`                             | `host-vm.nix`        | core + nvim-minimal + server + incus + vm + hardware; home dotfiles |
| `container`                      | `host-container.nix` | core + nvim-minimal + server + container; home dotfiles       |
| `keyclicker@standalone-<system>` | `host-standalone.nix`| home standalone                                                       |

`<system>` is `x86_64-linux` or `aarch64-linux`: standalone
home-manager needs `pkgs` for a fixed system, so identity-less home
leaves are instantiated per architecture and the caller (`dots`)
picks its own.

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
- **Options over firewall pokes**: modules that serve on the LAN import
  `option-lan.nix` and set `local.lan.allowed*Ports`; it turns the list
  into the one `networking.firewall.interfaces.<lan>` write. Every
  guest's NIC is `eth0` (`platform-vm.nix` disables predictable names;
  container veths are `eth0` natively), so the default fits all guests.
- **npm globals like casks**: the agent CLIs (claude, codex, opencode)
  and t3 are not packaged, they are kept at the registry's latest.
  `home-agents.nix` lists them in `local.npmGlobals.packages`;
  `option-npm-globals.nix` runs one `npm install --global` per
  activation, so a rebuild is an update and nothing is pinned, like
  casks and flatpaks. `~/.npmrc` is a dotfile on every host and points
  the global prefix at `~/.local`, so `npm install -g` by hand, with
  whatever node a box has, lands on the same PATH. State stays in
  `$HOME`: `npm update -g` by hand works the same.
- **Generic guests have no name**: `platform-vm.nix` and
  `platform-container.nix` set `networking.hostName = ""`, so the
  spawner's name sticks (incus via DHCP or lxc, Proxmox CT via lxc);
  a guest nobody names boots as `localhost` until `/etc/nixos/local.nix`
  sets `networking.hostName` (next bullet). `hostnamectl` is not a way:
  NixOS points hostnamed at the store copy of the option, which a
  nameless guest does not have. Pet hosts set their name and win.
- **Generic guests take a local patch**: a guest that needs one thing
  the shared image must not carry (a port, a service, a name) puts it in
  `/etc/nixos/local.nix`; `vm` and `container` import that file when it
  exists (`localModules` in `flake.nix`). It is outside the flake, so
  only an impure evaluation sees it: `dots rebuild` passes `--impure`
  when the file is there, a bare `nixos-rebuild` needs the flag by hand
  or the patch silently drops out. Pets do not import it: their config
  is the repo.
- **Generic guests stay small**: `vm` and `container` compose
  `module-core.nix` alone, the floor a box is administered with over
  ssh (git, tmux, neovim, mc, htop, compose). Every host somebody works
  in stacks `module-workstation.nix` (interactive tools and toolchains)
  on top; this is most of a machine's store, and a guest spawned N
  times would pay for it N times.
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
  `module-core.nix` and `module-workstation.nix` into
  `home.packages` by importing each module as a plain function, so an
  Ubuntu shell has exactly the tools a NixOS one has. Nothing
  system-level is emulated: hostname, nix daemon, services stay with
  the distro; only the nix store gc is ours, as a user timer. This
  works while the imported modules stay plain `{ pkgs, ... }`
  functions; the moment one needs config/lib, extract the package
  list into shared data instead.
- **Pins**: one `nixpkgs` (`nixos-unstable`) for every host, mac
  included; nix-darwin, home-manager and disko follow it.

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

# desktop VM (`iso desktop-vm` first, then `install.sh nixos desktop-vm` for
# the checkout home-manager links into); aarch64 QEMU on Apple silicon
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#desktop-vm

# generic guests (`iso vm` above first, then switch)
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#vm
sudo nixos-rebuild switch --flake ~/.dotfiles/.nix#container
# with a local patch in /etc/nixos/local.nix (or `dots rebuild`, which adds the flag)
sudo nixos-rebuild switch --impure --flake ~/.dotfiles/.nix#vm

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

## Desktop QEMU on Apple silicon

`desktop-vm` is the single ARM desktop target; the former `desktop-utm`
output is removed. Existing ARM guests can run `dots set desktop-vm`
before rebuilding. The former x86 desktop needs a fresh ARM installation;
its system disk cannot be reused as an ARM installation.

Use QEMU's `virt` machine with HVF, UEFI firmware with writable variables,
virtio-blk system and swap disks (`vda` / `vdb`), a `virtio-gpu-pci` display,
a USB keyboard/tablet, and a virtio network adapter. The serial console is
`ttyAMA0`; the headless x86 `vm` target still uses `ttyS0`.

Boot an aarch64 NixOS installer ISO and run `install.sh iso desktop-vm`.
This formats both attached disks. After rebooting without the ISO, run
`install.sh nixos desktop-vm` to clone the dotfiles and pin the target.
The SPICE guest agent remains available if a QEMU client supplies its
channel; a basic Cocoa window does not provide SPICE integration.

## Agents desktop

`agents` runs a persistent XFCE/X11 desktop for computer use. TigerVNC
supplies the virtual display; the `vnc-desktop` user service starts it at
boot through lingering, and viewer disconnects leave it running.

Open it in a browser while on the tailnet:

```text
https://<tailnet-hostname>/desktop/vnc.html?autoconnect=true&resize=remote
```

Websockify serves noVNC and bridges it to loopback VNC. Tailnet access
rules are the only login gate: VNC has no password and never leaves
loopback, X11 uses a private cookie and no TCP listener.

Cua Driver is the one manual step. Nix has no prebuilt package, and Cua's
own flake compiles from source, so install the official binary once as
the desktop user:

```sh
curl -fsSL https://cua.ai/driver/install.sh -o /tmp/cua-install.sh
bash /tmp/cua-install.sh --no-modify-path
```

Nix supplies its libraries through `nix-ld` and starts
`~/.local/bin/cua-driver` with the graphical session. After an update:
`systemctl --user restart cua-driver`. To debug, from a desktop terminal:

```sh
cua-driver doctor
systemctl --user status vnc-desktop cua-driver
```

## Service exposure

The NixOS firewall uses native nftables. Its input chain still applies
when Tailscale accepts a packet in its own base chain; do not switch back
to the iptables backend or trust `tailscale0` wholesale.

| Service | LAN | Tailscale | Local backend |
| --- | --- | --- | --- |
| SSH | TCP 22 | Closed | Wildcard listener, interface firewall |
| mDNS | UDP 5353 | Closed | systemd-resolved |
| DNS resolver | Closed | Closed | Loopback TCP/UDP 53 |
| Gateway (agents) | Closed | HTTPS 443 via Serve | nginx 127.0.0.1:8080 |
| T3 (agents) | Closed | HTTPS 3773 via Serve | 127.0.0.1:3773 |
| Desktop (agents) | Closed | `/desktop/` via gateway | Web 127.0.0.1:6080; VNC 127.0.0.1:5901 |
| HTML (agents) | Closed | `/public/` via gateway | 127.0.0.1:8765 |
| iperf3 (agents) | Closed | TCP/UDP 5201 | Wildcard listener, interface firewall |
| Ollama (desktops) | Closed | Closed | 127.0.0.1:11434 |
| Incus (VM hosts) | Closed | Closed | Unix socket only |

Tailscale's encrypted transport uses UDP 41641 on all interfaces. DHCP
and ICMP retain the system firewall defaults. Incus guests get DNS and
DHCP on `incusbr0`; the bridge does not bypass the host firewall.

LAN means the configured `local.lan.interface` (normally `eth0`), not a
source-subnet restriction. Localhost remains available for local clients.
New host services should allow ports on `tailscale0` or bind loopback and
use Tailscale Serve. Docker port publishing bypasses the host input chain:
explicitly publish on a Tailscale address, never an unspecified address.

Service modules import `option-tailnet.nix` and declare their routes:

```nix
local.tailnet.https."3773" = "http://127.0.0.1:3773";
local.tailnet.tcp."445" = "tcp://127.0.0.1:445";
```

Serve listens on the tailnet address only, so a backend on loopback can
share the port number. On agents, web apps that work under a path skip
their own route: they bind loopback and `packages/gateway/nginx.conf`
serves them on 443.

The thin wrapper generates one oneshot unit per port. Tailscaled handles
traffic; stopping a unit removes only its listener. Removing a declaration
and rebuilding therefore removes the route. Manual routes on other ports
remain intact. Manual changes to managed ports are overwritten when their
units restart, not continuously reconciled. Each port must appear in only
one map; Tailscale validates the port and target when applying the route.

The pinned upstream `services.tailscale.serve` module targets named
Tailscale Services and couples the frontend and backend web protocols.
Keep this wrapper for HTTPS-to-HTTP routes on the existing machine address.

Mac and desktop Ollama stay loopback-only. Apple-managed SSH, mDNS and the
macOS firewall are not configured by this repo; their LAN restrictions
need verification on the Mac. Standalone home-manager likewise does not
own the distro firewall.

Rebuild each managed host to apply these changes. Existing Incus preseed
state has its HTTPS address explicitly cleared. The Serve route on 443 is
updated in place (now the gateway, T3 moves to 3773), the old
8444/8445 routes are removed; unrelated Serve routes and Docker
stacks are preserved. Apply the SSH restriction from the LAN or console.

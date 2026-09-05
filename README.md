# dotfiles

Shell, editors, window managers, AI agent configs, and one nix flake that
installs all of it on every machine I use: MacBook, NixOS desktop, agent
sandbox VM, throwaway guests, Ubuntu boxes.

Home-manager symlinks the files here into `$HOME`. The links point at the
checkout, not the nix store, so editing `.zshrc` takes effect in the next
shell without a rebuild. Rebuild only for packages and system settings.

## Install

Installs nix if missing, clones to `~/.dotfiles` (the links depend on that
path), runs the first switch.

MacBook, nix-darwin:

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- mac
```

Fresh NixOS from the installer ISO:

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- iso <host>
```

NixOS already running:

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- nixos <host>
```

Ubuntu and friends, home-manager only:

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- standalone
```

Hosts: `agents`, `desktop-vm`, `vm`, and `container` (nixos only). `iso`
wipes two disks after a typed `yes`; the first boot clones the checkout.
`nixos <host>` moves a NixOS that is already running onto this
configuration. `standalone` leaves the distro in charge of the system
and gives the user the same tools a NixOS host has.

Same install from another machine over ssh:

```sh
nix run github:nix-community/nixos-anywhere -- --flake ~/.dotfiles/.nix#agents --target-host root@<ip>
```

## Daily use

`dots` wraps `darwin-rebuild`, `nixos-rebuild`, and `home-manager`, picking
the one that fits the machine.

```sh
dots rebuild         # build this machine's target, switch
dots upgrade         # git pull, bump flake.lock, rebuild
dots status          # host, drift from origin, nixpkgs pin age
dots list            # flake targets, * marks this machine
dots set desktop-vm  # pin host when autodetect is wrong; `unset` reverts
```

`.zshrc` runs `dots warn` at startup: one line if the checkout is behind
origin or the nixpkgs pin is older than two weeks.

## Layout

```
.nix/          the flake, one output per host. Has its own README
install.sh     first switch, one function per platform
.zshrc         zsh: history, keybinds, aliases, prompt, plugin hooks
.zshenv        env for non-interactive shells
.zprofile      homebrew on PATH (mac)
.tmux.conf     tmux, plugins from nixpkgs, no tpm
.vimrc         plain vim for machines that only have vim
.gitconfig     identity, gpg signing, machine-local include
.gnupg/        gpg and gpg-agent config
Brewfile       mac packages homebrew owns instead of nix
.config/       nvim (kickstart-based), ghostty, yazi, mc, mpv, qalculate,
               sway + waybar + fuzzel + mako (linux),
               yabai + skhd + karabiner + linearmouse (mac)
.claude/       Claude Code: CLAUDE.md, skills
.codex/        Codex: AGENTS.md, skills
.agents/       shared agent instructions and skills; .claude and .codex link here
.doom.d/       doom emacs
.scripts/      dots, agent-jail, small utilities
```

## Agent jail

`agent-jail` runs Claude Code or Codex in a Docker container. Only the
current project directory is mounted, as `/work`. The agent installs and
logs in inside the container, so the host's `~/.claude`, `~/.codex`, and
Keychain never appear in it.

```sh
aj          # Claude Code
aj --codex  # Codex
```

Both run with their own permission prompts off. The container is the
sandbox, so `/work` is writable and network is open. Use it on repos under
version control. Details in `.scripts/agent-jail/README.md`.

## Migrating from old dotfiles

Existing symlinks (hand-made, stow) collide with home-manager's. The flake
sets `backupFileExtension = "hm-bak"`, so activation renames them instead of
failing. Leftovers are dangling links, not data. Check, then delete:

```sh
find ~ ~/.config ~/.claude ~/.codex ~/.gnupg -maxdepth 1 -name '*.hm-bak'
```

A link is correct when it resolves to the checkout through one store path:

```sh
readlink -f ~/.zshrc   # ~/.dotfiles/.zshrc
```

## License

GPL-2.0, see [LICENSE](LICENSE).

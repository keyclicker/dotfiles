# dotfiles

Shell, editors, window management, agent configs, and the nix flake
that puts them on every machine I use: a MacBook, a NixOS desktop, an
agent sandbox VM, throwaway guests, and whatever Ubuntu box I am
logged into.

Home-manager symlinks the files in this repo into `$HOME`, pointing at
the live checkout. Editing `.zshrc` here changes the shell in the next
prompt, no rebuild. A rebuild is only for packages and system
settings.

## Install

One line per platform. It installs nix if missing, clones the repo to
`~/.dotfiles` (home-manager's links point there, so the path is not
optional) and does the first switch.

MacBook, via nix-darwin:

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- mac
```

Fresh NixOS guest booted from the installer ISO. disko prints the
disks it is about to wipe and waits for a typed `yes`. Hosts: `vm`,
`agents`, `desktop-vm`.

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- iso vm
```

NixOS that already boots, moved onto this repo's configuration. Hosts:
`agents`, `desktop-vm`, `vm`, `container`.

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- nixos agents
```

Ubuntu and friends. The distro keeps the system, nix gets the user
environment and the same tools a NixOS host has.

```sh
curl -L https://raw.githubusercontent.com/keyclicker/dotfiles/master/install.sh | sh -s -- standalone
```

The same install driven from another machine over ssh, onto whatever
the target booted (ISO, cloud image, an old NixOS):

```sh
nix run github:nix-community/nixos-anywhere -- --flake ~/.dotfiles/.nix#agents --target-host root@<ip>
```

After an `iso` install, the host has no checkout yet. Boot it and run
the `nixos <host>` line above to clone one.

## Day to day

`dots` picks the right rebuild command for the machine it runs on,
`darwin-rebuild`, `nixos-rebuild` or `home-manager`, so I never have
to remember which.

Build this machine's target and switch onto it:

```sh
dots rebuild
```

Pull the repo, bump `flake.lock`, then rebuild:

```sh
dots upgrade
```

Where the machine stands: resolved host, how far the checkout drifted
from origin, how old the nixpkgs pin is.

```sh
dots status
```

Every buildable target in the flake, with `*` on this machine's:

```sh
dots list
```

Pin the host when autodetect guesses wrong (`dots unset` returns to
autodetect):

```sh
dots set desktop-vm
```

`.zshrc` runs `dots warn` at shell start, so a checkout that fell
behind or a pin older than two weeks says so on its own instead of
waiting to be asked. Rest of the commands: `dots help`.

## What is here

```
.nix/          the flake: one output per machine (see .nix/README.md)
install.sh     first switch, one section per platform, readable as the manual
.zshrc         zsh: history, keybinds, aliases, prompt, plugin hooks
.zshenv        environment for non-interactive shells
.tmux.conf     tmux; plugins come from nixpkgs, no tpm
.vimrc         plain vim, for machines that only have vim
.gitconfig     git identity, gpg signing, machine-local include
Brewfile       mac packages homebrew owns rather than nix
.config/       nvim (kickstart-based), ghostty, sway + waybar + fuzzel + mako,
               yabai + skhd + karabiner on the mac, yazi, mc, mpv, qalculate
.claude/       Claude Code: CLAUDE.md, commands, agents, skills
.codex/        Codex: AGENTS.md, skills
.agents/       shared agent instructions and skills both of the above link to
.doom.d/       doom emacs
.scripts/      dots, the agent jails, small utilities
```

The nix side has its own README: layers, what every host composes, and
the reasoning behind each choice.

## Agent jails

`agent-jail` runs Claude Code or Codex in a Docker container that
mounts the project directory and nothing else of the host. The agent
installs and authenticates inside the container, so the real
`~/.claude`, `~/.codex` and the macOS Keychain never appear in it.

Claude Code, from any project directory:

```sh
aj
```

Codex instead:

```sh
aj --codex
```

Both run with their own permission prompts off. The container is the
sandbox, which also means `/work` is read-write and network egress is
open, so point it at repos under version control.
`.scripts/agent-jail/README.md` has the rest.

## First switch on a machine with older dotfiles

Hand-made or stow symlinks collide with home-manager's. The flake sets
`backupFileExtension = "hm-bak"`, so they get renamed aside instead of
failing the activation. What is left over is dangling symlinks rather
than data, worth a look before deleting:

```sh
find ~ ~/.config ~/.claude ~/.codex ~/.gnupg -maxdepth 1 -name '*.hm-bak'
```

To confirm a link landed:

```sh
readlink -f ~/.zshrc
```

It should resolve to `~/.dotfiles/.zshrc` through one store path. That
indirection is how `mkOutOfStoreSymlink` works.

## License

GPL-2.0, see [LICENSE](LICENSE).

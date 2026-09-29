# dotfiles

Shell, editors, window managers, AI agent configs, and one nix flake that
installs all of it on every machine I use: MacBook, NixOS desktop, agent
sandbox VM, throwaway guests, Ubuntu boxes.

Home-manager symlinks the files here into `$HOME`. The links point at the
checkout, not the nix store, so editing `.config/zsh/.zshrc` takes effect in the next
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
wipes two disks after a typed `yes` and leaves no checkout, so run
`nixos <host>` after first boot. `standalone` leaves the distro in charge
of the system and gives the user the same tools a NixOS host has.

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

`.config/zsh/.zshrc` runs `dots warn` at startup: one line if the checkout is behind
origin or the nixpkgs pin is older than two weeks.

## Layout

```
.nix/          the flake, one output per host. Has its own README
install.sh     first switch, one function per platform
.zshenv        bootstrap XDG paths and non-interactive shell environment
.gnupg/        gpg and gpg-agent config
Brewfile       mac packages homebrew owns instead of nix
.config/       zsh, tmux, git, npm, vim, doom, nvim (kickstart-based), ghostty, yazi, mc, mpv, qalculate,
               sway + waybar + fuzzel + mako (linux),
               yabai + skhd + karabiner + linearmouse (mac)
.claude/       Claude Code: CLAUDE.md, skills
.codex/        Codex: AGENTS.md, skills
.agents/       shared agent instructions and skills; .claude and .codex link here
.scripts/      dots and utilities; linked into ~/.local/bin
packages/      subprojects: agents gateway, html-serving,
               InputSourceSelector (source of .scripts/input)
```

## Home layout

`home-xdg.nix` sets the application paths. Configuration lives in
`~/.config`, disposable caches in `~/.cache`, installed toolchains and
package data in `~/.local/share`, and history/session saves in
`~/.local/state`. Shells load Home Manager's environment from `.zshenv`;
npm and Bun activation hooks receive their paths explicitly.

Git's machine-local overrides belong in `~/.config/git/local`.
Agent homes remain unchanged. Bun's global packages live in
`~/.local/share/bun/install/global`, with executables in `~/.local/bin`.

When deploying an unmerged worktree, set the Home Manager option
`local.dotfilesDirectory` to that checkout so live links resolve there.
The default remains `~/.dotfiles`.

Existing data needs a one-time move before using the new environment:

| Old path | New path |
| --- | --- |
| `.cargo` | `.local/share/cargo` |
| `.rustup` | `.local/share/rustup` |
| `go` | `.local/share/go` |
| `go/pkg/mod` | `.cache/go/mod` |
| `.docker` | `.config/docker` |
| `.npm` | `.cache/npm` |
| `.bun/install/cache` | `.cache/bun` |
| `.bun/install/global` | `.local/share/bun/install/global` |
| `.zsh_history` | `.local/state/zsh/history` |
| `.zcompdump` | `.cache/zsh/zcompdump` |
| `.tmux/resurrect` | `.local/state/tmux/resurrect` |
| `.gitconfig.local` | `.config/git/local` |

Stop writers first, preserve existing destination contents, and start new
shells after switching. Home Manager relocates the managed config links;
it does not move these mutable directories automatically.

## Migrating from old dotfiles

Existing symlinks (hand-made, stow) collide with home-manager's. The flake
sets `backupFileExtension = "hm-bak"`, so activation renames them instead of
failing. Leftovers are dangling links, not data. Check, then delete:

```sh
find ~ ~/.config ~/.claude ~/.codex ~/.gnupg -maxdepth 1 -name '*.hm-bak'
```

A link is correct when it resolves to the checkout through one store path:

```sh
readlink -f ~/.config/zsh/.zshrc   # ~/.dotfiles/.config/zsh/.zshrc
```

## License

GPL-2.0, see [LICENSE](LICENSE).

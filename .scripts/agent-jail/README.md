# agent-jail

Run **Claude Code or Codex inside a Docker container** so it has full tool access
(bash, network, package installs) but **cannot reach your host filesystem**
beyond the project directory you launch it from.

```
cd ~/some-project
agent-jail --claude # Claude Code (also the default)
agent-jail --codex  # Codex
agent-jail paste    # clipboard image -> jail (macOS; see "Pasting images")
```

Each agent authenticates independently on first use. Its login is saved in the
private jail home and reused on later runs.

On macOS each launch starts or reuses a dedicated Colima profile named
`agent-jail`; it does not change the host's active Docker context. Concurrent
jail sessions share that profile, which remains running between sessions. New
profiles use 4 CPUs, 4 GiB RAM, a 30 GiB sparse disk, Apple's Virtualization
framework, and VirtioFS. On Linux the host's own Docker daemon is used directly.

The image builds automatically on first use, and the jail environment is
provisioned whenever `~/.dotfiles/.nix` changes (see below). Rebuild the image
after changing the `Dockerfile` or your UID:GID with `agent-jail --rebuild`.
Everything after the launcher flags is passed to the selected agent.
The launcher exits without making changes unless the current directory is inside
a Git repository.

## Why

Host binaries and credentials are not usable inside the Linux container. The
jail therefore uses independent Linux installations and logins. Your real
Claude and Codex state and the Keychain are never mounted.

## Permissions

Both agents run with their internal permissions and sandboxes bypassed. The
**container is the sandbox** (non-root, `--cap-drop ALL`, `--security-opt
no-new-privileges`), so in-container gating is redundant. The trade-off: `/work`
is read-write and maps to your real project, and egress is open, so only point
`agent-jail` at projects you'd trust an autonomous agent with — ideally under
version control.

## What it does

- Mounts the current dir **read-write** at `/work/<name>-<hash>` — a
  deterministic per-project path, so each project's sessions, memory, and
  transcripts stay separate inside the shared jail home. Edits land on your
  host.
- Mounts `~/.dotfiles` **read-only** at `/home/keyclicker/.dotfiles`. It is both
  the source of the jail's environment and the source of the instructions,
  editor config, and shell config the agent works with.
- Mounts `~/.agent-jail` as the container's complete `/home/keyclicker`, so its
  login, config, transcripts, memory, package state, caches, and scratch files
  persist together and are shared across projects. Its credentials are plaintext
  here; your host credentials are untouched.
- Copies its own Claude `settings.json` and Codex `config.toml` templates into
  the jail home on first run only. Host settings are never read, and later
  launches preserve jail-local changes.

## The jail environment

The image bakes no packages. The toolchain is a home-manager leaf in the
dotfiles flake — `.nix/hosts/jail.nix`, exposed as
`homeConfigurations."keyclicker@jail-<system>"` — built and activated **inside
the container** from the read-only mount:

```
nix build "path:~/.dotfiles/.nix#homeConfigurations.\"keyclicker@jail-aarch64-linux\".activationPackage"
~/.jail-activation/activate
```

The launcher does this whenever the contents of `~/.dotfiles/.nix` change,
tracked by a hash in `~/.agent-jail/.jail-generation`. The first provision after
a `--rebuild` downloads the whole closure and takes a while; later launches
compare the hash and start immediately.

Consequences worth knowing:

- The jail and the real machines share one package definition. `hosts/jail.nix`
  stacks the same modules the other hosts do (`common`, `dev`, `agents`,
  `browser`) and adds what a bare container lacks — libc tooling, locales,
  certificates — plus everyday project tooling (eslint, prettier, ruff, pytest,
  tsx, typescript, yarn, nginx).
- `claude`, `codex`, and `opencode` come from `modules/agents.nix` as
  `npx ...@latest` wrappers, so the jail always runs the current release and
  nothing needs updating by hand.
- `home/common.nix` links your dotfiles into `$HOME`, so the agent gets your
  nvim, zsh, git, and tmux config, `CLAUDE.md`, commands, agents, and skills.
  It deliberately does **not** manage `.claude/settings.json`, which is why the
  jail's own settings survive the mount.
- Those links point into a read-only mount: the agent can read your config and
  cannot edit it. Adding a tool to the jail is a host-side edit of
  `hosts/jail.nix`.

Anything else is added **at runtime** (it can't `apt` — non-root — but these
persist under `~/.agent-jail` and the Nix volume):

- `nix profile install nixpkgs#<pkg>` — anything in nixpkgs
- `pnpm add -g <pkg>` — Node CLIs
- `uv tool install <tool>` — Python CLIs (or `uvx <tool>` ad-hoc); plus
  `uv venv` / `uv pip` / `uv python install` — all persistent

Agents can manage their own persistent tools in **`~/agent-flake/`** inside the
jail (seeded once from `agent-flake/`, and writable unlike the dotfiles).
Install it with
`nix profile install --profile ~/.agent-tools-profile ~/agent-flake`; after
editing it, update with
`nix profile upgrade --profile ~/.agent-tools-profile --all`. This profile is on
`PATH` and survives normal launches. `--rebuild` clears installed agent tools,
but keeps the flake so they can be installed again.
Per-project deps install normally via `uv sync` / `pnpm install` into the
mounted project.

## Pasting images

Terminals paste text only, and the jail cannot see the host clipboard, so
native image paste (Ctrl+V) inside either agent cannot work. Instead, copy any
image (screenshot hotkey, browser "Copy Image") and run on the host:

```
agent-jail paste
```

It saves the image to `~/.agent-jail/clipboard/` — which the jail sees as
`~/clipboard/` — and copies that in-jail path. Paste the path (Cmd+V) into the
agent's prompt; the agent reads the image from there. macOS built-ins only
(`osascript`, `sips`), so this subcommand is macOS-only.

## Files

| File                | Purpose                                                   |
|---------------------|-----------------------------------------------------------|
| `agent-jail`        | Launcher: picks the daemon, builds, provisions, runs.      |
| `Dockerfile`        | System layer only: nix, a host-UID account, loader path.   |
| `jail-prompt.md`    | Session-only jail instructions passed to either agent.     |
| `config-templates/` | Initial Claude and Codex configuration templates.          |
| `agent-flake/`      | Initial agent-owned flake for persistent tools.            |

The package set lives in `~/.dotfiles/.nix/hosts/jail.nix`, not here.

## Install

```
./install.sh
```

This installs the runtime files under `~/.local/libexec/agent-jail` and links
`~/.local/bin/agent-jail`, with `~/.local/bin/aj` as a short alias. If
`~/.local/bin` is not on `PATH`, the installer prints the shell configuration
line to add it.

## Threat model

**Isolated:** the host filesystem (only the project, the agent home, and the
read-only dotfiles are mounted), host processes, the Keychain, your real Claude
and Codex config. Runs as a non-root user with `--cap-drop ALL` and
`--security-opt no-new-privileges`.

**Readable, not isolated:** `~/.dotfiles` in full. It is a config repo, not a
secret store — but it is your whole config tree, and the agent can read it.

**NOT isolated:** the network — full egress is on (needed for the API, WebFetch,
WebSearch, and package downloads). A compromised tool could exfiltrate the
mounted project, which is read-write by design, or the dotfiles.

The container gets exactly these from the host (see `agent-jail`):

```
-v "$PROJECT:/work/<name>-<hash>"                    # project, rw, deterministic path
-v "$HOME/.agent-jail:/home/keyclicker"              # complete agent home
-v "$HOME/.dotfiles:/home/keyclicker/.dotfiles:ro"   # environment + instructions
-v agent-jail-nix:/nix                               # nix store (named volume)
--cap-drop ALL  --security-opt no-new-privileges  --pids-limit 512
```

The Nix store remains a Docker named volume because the macOS host filesystem is
case-insensitive while the store is not. It auto-seeds from the image on first
mount. `agent-jail --rebuild` recreates it from the rebuilt image, which also
forces the jail environment to be provisioned again.

The jail links your `~/.gitconfig`, so it commits as you — but it has no GPG key
and no push credentials, so signing and pushing fail there by construction.

No Docker socket, host home, `~/.ssh`, or host credentials are mounted.

## Reset / uninstall

```
rm ~/.local/bin/agent-jail
rm ~/.local/bin/aj
rm -rf ~/.local/libexec/agent-jail
rm -rf ~/.agent-jail            # forget login, jail config, package stores
docker volume rm agent-jail-nix # drop the Nix store
docker image rm agent-jail      # drop the image
```

On macOS the two `docker` commands need the jail's context
(`docker --context colima-agent-jail ...`, after `colima start agent-jail
--activate=false`), and the VM itself goes with `colima delete agent-jail`.

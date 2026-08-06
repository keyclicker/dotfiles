# agent-jail

Run **Claude Code or Codex inside a Docker container** so it has full tool access
(bash, network, package installs) but **cannot reach your host filesystem**
beyond the project directory you launch it from.

```
cd ~/some-project
agent-jail --claude # Claude Code (also the default)
agent-jail --codex  # Codex
agent-jail paste    # clipboard image -> jail (see "Pasting images")
```

Each agent authenticates independently on first use. Its login is saved in the
private jail home and reused on later runs.

Each launch starts or reuses a dedicated Colima profile named `agent-jail`; it
does not change the host's active Docker context. Concurrent jail sessions share
that profile, which remains running between sessions. New profiles use 4 CPUs,
4 GiB RAM, a 30 GiB sparse disk, Apple's Virtualization framework, and VirtioFS.

The image builds automatically on first use. Claude Code and Codex install
separately on first use; update both with `agent-jail --update`. Rebuild the image
after changing the
`Dockerfile`, flake, or your UID:GID with `agent-jail --rebuild`.
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
- Copies its own Claude `settings.json` template into the jail state on first
  run only. Host
  `~/.claude/settings.json` is never read, and later launches preserve jail-local
  settings changes.
- Mounts only host `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, read-only.
  Nothing else from host `~/.claude` or `~/.codex` is shared or written.
- Mounts `~/.agent-jail` as the container's complete `/home/agent`, so its login,
  config, transcripts, memory, package state, caches, and scratch files persist
  together and are shared across projects. Its credentials are plaintext here;
  your host credentials are untouched.

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
(`osascript`, `sips`).

## Bundled tooling

A deliberately small **general** base — what an agent needs on almost any project:

- **CLI:** git, gh, ripgrep, fd, jq, git-delta, curl, wget, less, openssh-client.
- **Node:** node, npm, pnpm, yarn, and TypeScript.
- **Python:** python3, Poetry, uv (full toolkit — all state persistent),
  plus GCC, make, binutils, and pkg-config for native deps.
- **Browser:** Playwright + Chromium (e2e / debugging).

Claude Code and Codex are intentionally not built into the image. The launcher
installs their latest releases with pnpm into the persistent jail home on first
use. Run `agent-jail --update` to resolve current registry versions and update
both without rebuilding the image.

Anything else is added **at runtime** (it can't `apt` — non-root — but these
persist under `~/.agent-jail` and the Nix volume):

- `nix profile install nixpkgs#<pkg>` — anything in nixpkgs
- `pnpm add -g <pkg>` — Node CLIs
- `uv tool install <tool>` — Python CLIs (or `uvx <tool>` ad-hoc); plus
  `uv venv` / `uv pip` / `uv python install` — all persistent

Recurring extras go in **`user-flake/`**. The launcher installs that flake on
first use and reinstalls it with `agent-jail --rebuild`.

Agents can manage their own persistent tools in **`~/agent-flake/`** inside the
jail. Install it with
`nix profile install --profile ~/.agent-tools-profile ~/agent-flake`; after
editing it, update with
`nix profile upgrade --profile ~/.agent-tools-profile --all`. This profile is on
`PATH` and survives normal launches. `--rebuild` clears installed agent tools,
but keeps the flake so they can be installed again.
Per-project deps install normally via `poetry install` / `pnpm install` into the
mounted project.

## Files

| File             | Purpose                                                       |
|------------------|---------------------------------------------------------------|
| `Dockerfile`     | Assembles the Nix base and host-matched non-root user.         |
| `flake.nix`      | Declares the complete base package set for Linux architectures.|
| `flake.lock`     | Pins nixpkgs for reproducible base builds.                    |
| `agent-jail`     | Launcher: manages Colima, builds the image, and runs the jail. |
| `jail-prompt.md` | Session-only jail instructions passed to either agent.         |
| `config-templates/` | Initial Claude and Codex configuration templates.         |
| `user-flake/`    | User-defined runtime tools in the persistent Nix profile.      |
| `agent-flake/`   | Initial agent-owned flake for persistent tools.                 |

## Install

```
./install.sh
```

This installs the runtime files under `~/.local/libexec/agent-jail` and links
`~/.local/bin/agent-jail`, with `~/.local/bin/aj` as a short alias. If
`~/.local/bin` is not on `PATH`, the installer prints the shell configuration
line to add it.

## Threat model

**Isolated:** host filesystem (only the project + agent home are mounted), host
processes, Keychain, your real Claude and Codex config. Runs as a non-root user with
`--cap-drop ALL` and `--security-opt no-new-privileges`.

**NOT isolated:** the network — full egress is on (needed for the API, WebFetch,
WebSearch, and package downloads). A compromised tool could exfiltrate the mounted
project, which is read-write by design.

The container gets exactly these from the host (see `agent-jail`):

```
-v "$PROJECT:/work/<name>-<hash>"                             # project, rw, deterministic path
-v "$HOME/.agent-jail:/home/agent"                            # complete agent home
-v "$HOME/.claude/CLAUDE.md:/home/agent/.claude/CLAUDE.md:ro" # instructions, if present
-v "$HOME/.codex/AGENTS.md:/home/agent/.codex/AGENTS.md:ro"   # instructions, if present
-v agent-jail-nix:/nix                                        # nix store (named volume)
--cap-drop ALL  --security-opt no-new-privileges  --pids-limit 512
```

The Nix store remains a Docker named volume because the macOS host filesystem is
case-insensitive while the store is not. It auto-seeds from the image on first
mount. `agent-jail --rebuild` recreates it from the rebuilt image and reinstalls
`user-flake/`.

No Docker socket, host home, `~/.ssh`, or host credentials are mounted.

## Reset / uninstall

```
rm ~/.local/bin/agent-jail
rm ~/.local/bin/aj
rm -rf ~/.local/libexec/agent-jail
rm -rf ~/.agent-jail            # forget login, jail config, package stores
colima start agent-jail --activate=false
docker --context colima-agent-jail volume rm agent-jail-nix # drop the Nix store
docker --context colima-agent-jail image rm agent-jail      # drop the image
colima delete agent-jail
```

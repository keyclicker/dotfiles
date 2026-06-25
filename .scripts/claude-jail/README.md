# claude-jail

Run **Claude Code inside a Docker container** so it has full tool access (bash,
network, package installs) but **cannot reach your host filesystem** beyond the
project directory you launch it from.

```
$ cd ~/some-project
$ claude-jail          # builds the image on first run, then drops into a jailed session
```

On the very first run, type `/login` inside Claude to authenticate (browser
OAuth). The token is saved in a private state dir and reused on later runs.

The image rebuilds automatically when the `Dockerfile` (or your UID:GID) changes.
Force a fresh build (e.g. to pull a newer base image) with `claude-jail --rebuild`.
Everything after the flag is passed straight through to `claude`.

## Why

The host `claude` binary is a macOS native and its credentials live in the
Keychain — neither is usable from a Linux container. So the container installs
its **own** Claude Code and authenticates **independently**. Your real
`~/.claude`, `~/.claude.json`, and Keychain are never mounted.

## Permissions

The jail always runs with `--dangerously-skip-permissions` — no prompts. The
**container is the sandbox** (non-root, `--cap-drop ALL`, `--security-opt
no-new-privileges`), so in-container gating is redundant. The trade-off: `/work`
is read-write and maps to your real project, and egress is open, so only point
`claude-jail` at projects you'd trust an autonomous agent with — ideally under
version control.

## What it does

- Mounts the current dir **read-write** at `/work`; edits land on your host.
- Ships its **own** `settings.json` (in this dir) — the host `~/.claude/settings.json`
  is **never** read, so its `sandbox` and `permissions` blocks can't bleed in. The
  bundled file disables the in-Claude sandbox (the container already is one), wires
  the in-container `statusLine` + `SessionStart` hook, and declares the **plugins**
  to enable (see below).
- **Plugins** mirror the host set — `context7`, `playwright`, `github`,
  `clangd-lsp` / `typescript-lsp` / `pyright-lsp`, `caveman`. They're *enabled* via
  the bundled `settings.json` and *installed* by `requirements.sh` into the mounted
  state dir (`~/.claude/plugins`), so they persist across `--rm`. The LSP plugins'
  servers (`clangd`, `typescript-language-server`, `pyright`) are installed by the
  same `requirements.sh`. (The Google Drive connector is skipped — interactive OAuth,
  no good headless.) `--dangerously-skip-permissions` auto-approves their tools.
- **Copies** a minimal set of host *content* into the container's state dir:
  `CLAUDE.md`, `statusline.sh`, `agents/`, `skills/` (`~/.dotfiles` symlinks
  dereferenced). Nothing else, no credentials. The host `~/.claude` is never written.
- Binds **project memory** `./.claude/memory` to `~/.claude/projects/-work/memory`
  and **session transcripts** to `./.claude/transcripts`, so both persist next to
  the project.
- Persists the container's **own** login under `~/.claude-jail/state` (its
  `.credentials.json` lives here in plaintext; your host credentials are untouched).
- The bundled `settings.json` installs a `SessionStart` hook that prints the package
  inventory and points `statusLine` at the copied in-container script — no host paths.

## Bundled tooling

A deliberately small **general** base — what an agent needs on almost any project:

- **CLI:** git, gh, ripgrep, fd, jq, git-delta, curl, wget, less, openssh-client.
- **Node:** node, npm, pnpm + yarn (corepack).
- **Python:** python3, Poetry, uv (full toolkit — all state persistent),
  `build-essential` + `python3-dev` for native deps.
- **Browser:** Playwright + Chromium (e2e / debugging; browsers at `/ms-playwright`).
- **Claude Code** itself.

Anything else is added **at runtime** (it can't `apt` — non-root — but these
persist under `~/.claude-jail/pack`):

- `nix profile install nixpkgs#<pkg>` — anything in nixpkgs
- `pnpm add -g <pkg>` — Node CLIs
- `uv tool install <tool>` — Python CLIs (or `uvx <tool>` ad-hoc); plus
  `uv venv` / `uv pip` / `uv python install` — all persistent

Recurring extras go in **`requirements.sh`** (an idempotent "ensure installed"
list the launcher re-runs when it changes) — extra packages, the LSP servers, and
the **Claude plugins** (`claude plugin install`, into persistent state). Per-project
deps install normally via `poetry install` / `pnpm install` into the mounted project.

## Files

| File             | Purpose                                                       |
|------------------|---------------------------------------------------------------|
| `Dockerfile`     | Minimal general base image, non-root user.                    |
| `claude-jail`    | Launcher: builds image, seeds config/memory, `docker run`.    |
| `settings.json`  | Jail's own Claude settings (sandbox off, hooks/statusLine).    |
| `requirements.sh`| Optional extra tooling, installed into the persistent stores. |
| `pkglist.sh`     | `SessionStart` hook printing the live package inventory.      |

## Install

```
chmod +x claude-jail
ln -s "$PWD/claude-jail" ~/.local/bin/claude-jail   # or anywhere on PATH
```

## Threat model

**Isolated:** host filesystem (only the project + state dirs are mounted), host
processes, Keychain, your real Claude config. Runs as a non-root user with
`--cap-drop ALL` and `--security-opt no-new-privileges`.

**NOT isolated:** the network — full egress is on (needed for the API, WebFetch,
WebSearch, MCP, npm). A compromised tool could exfiltrate the mounted project,
which is read-write by design.

The container gets exactly these from the host (see `claude-jail`):

```
-v "$PROJECT:/work"                                           # project, rw
-v "$STATE:/home/agent/.claude"                               # login + copied config
-v "$PROJECT/.claude/transcripts:~/.claude/projects/-work"    # session .jsonl
-v "$PROJECT/.claude/memory:~/.claude/projects/-work/memory"  # project memory
-v "$PACK/nix:/nix"                                           # persistent nix store
-v "$PACK/npm:/home/agent/.npm"                              # npm cache
-v "$PACK/pnpm:/home/agent/.local/share/pnpm"                 # pnpm store + bins
-v "$PACK/pip:/home/agent/.cache/pip"                         # pip cache
-v "$PACK/uv-cache:/home/agent/.cache/uv"                     # uv cache
-v "$PACK/uv-data:/home/agent/.local/share/uv"                # uv tools + pythons
--cap-drop ALL  --security-opt no-new-privileges  --pids-limit 512
```

`$PACK` = `~/.claude-jail/pack`. The `pack/nix` store is **seeded** from the image
on first run (the bind mount would otherwise hide the baked install); after a
Dockerfile nix change, `rm -rf ~/.claude-jail/pack/nix` to force a reseed.

No Docker socket, no host home, no `~/.ssh`, no credentials mount.

## Reset / uninstall

```
rm -rf ~/.claude-jail            # forget login, copied config, package stores
docker image rm claude-jail      # drop the image
```

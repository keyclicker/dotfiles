# claude-jail

Run **Claude Code inside a Docker container** so it has full tool access (bash,
network, package installs) but **cannot reach your host filesystem** beyond the
project directory you launch it from.

```
$ cd ~/some-project
$ claude-jail          # builds image on first run, then drops you into a jailed session
```

On the very first run, type `/login` inside Claude to authenticate (browser
OAuth). The token is saved in a private state dir and reused on later runs.

The image rebuilds automatically when the `Dockerfile` changes. Force a rebuild
(e.g. to pull a newer base image) with `claude-jail --rebuild`.

## Why

The host `claude` binary is a macOS native and its credentials live in the macOS
Keychain — neither is usable from a Linux container. So the container installs
its **own** Claude Code and authenticates **independently**. Your real
`~/.claude`, `~/.claude.json`, and Keychain are never mounted.

## What it does

- Mounts the current dir **read-write** at `/work` — edits the agent makes land
  on your host (default permission mode still prompts you first).
- **Copies** a minimal set of your config into the container's state dir:
  `settings.json`, `CLAUDE.md`, `statusline.sh`, `agents/`, `skills/`
  (`~/.dotfiles` symlinks dereferenced). The host `~/.claude` is never written.
  Nothing else from `~/.claude`, no `~/.claude.json`, no credentials.
- **Project memory** `./.claude/memory` is bound to the container's
  `~/.claude/projects/-work/memory`, so memory persists next to the project.
- **Session transcripts** are written to `./.claude/transcripts` (bound to
  `~/.claude/projects/-work`); the memory mount overlays it, so transcripts hold
  only the session `.jsonl`.
- Persists the container's **own** login in `~/.claude-jail/state` (the jail's
  `.credentials.json` lives here in plaintext — your host's credentials and
  Keychain are never touched).
- Creates `./.claude/{memory,transcripts}` in the launch dir (the mount targets).
- Overrides host-only paths via `--settings` (the copied config's `statusLine` is
  repointed at the in-container script and host `hooks` are cleared, since both
  reference host-absolute paths that don't exist in the jail).

## Permission mode

By default the jail runs in **normal permission mode** — edits/writes prompt you,
and any `permissions` rules from your copied `settings.json` apply (note: Claude
*unions* permission rules across sources, so a copied override can add grants but
cannot remove host ones).

Two flags loosen this:

- `claude-jail --auto` — auto-runs commands but **still prompts before edits**
  (allows `Bash`, sets `ask` on `Edit`/`Write`/`MultiEdit`/`NotebookEdit`). Since
  `ask` outranks `allow`, edit prompts hold even if your copied config allows those
  tools. Middle ground.
- `claude-jail --yolo` — skips **all** prompts, edits included
  (`--dangerously-skip-permissions`). The **container is the sandbox**, so prompts
  are largely redundant inside it — but `/work` is read-write and maps to your real
  project, so `--yolo` lets the agent modify it without asking. Use it on projects
  you'd trust an autonomous agent with (ideally under version control).

(`--yolo` bypasses gating outright, so it takes precedence over `--auto`.)

## Threat model — what is and isn't isolated

**Isolated:** host filesystem (only the project dir + the state dir are mounted),
host processes, Keychain, your real Claude config. Runs as a non-root user with
`--cap-drop ALL` and `--security-opt no-new-privileges`.

**NOT isolated:** the network — full egress is on (needed for the API and for
WebFetch / WebSearch / MCP / npm). A compromised tool could exfiltrate the
contents of the mounted project dir. The project dir is read-write by design.

## Bundled toolchains

So the agent can test/debug without runtime installs:

- **Next.js / Node:** node 22, npm, pnpm, yarn (corepack), Playwright + Chromium
  (e2e + browser debugging; browsers at `/ms-playwright`).
- **Python / FastAPI:** python 3.11, Poetry, ruff, mypy, `build-essential` +
  `python3-dev` for native deps.
- **General:** git, ripgrep, curl, jq.

Per-project deps (`fastapi`, `uvicorn`, `pytest`, npm/pnpm packages) install
normally via `poetry install` / `pnpm install` into the mounted project.

## Files

| File         | Purpose                                                      |
|--------------|--------------------------------------------------------------|
| `Dockerfile` | Debian + Node + Claude Code + dev toolchains, non-root user. |
| `claude-jail`| Launcher: builds image, seeds config/memory, `docker run`.   |

## Install

```
chmod +x claude-jail
ln -s "$PWD/claude-jail" ~/.local/bin/claude-jail   # or anywhere on PATH
```

## Audit checklist

The container gets exactly these from the host (see `claude-jail`):

```
-v "$PROJECT:/work"                                          # project, rw
-v "$STATE:/home/node/.claude"                               # login + copied config, rw
-v "$PROJECT/.claude/transcripts:~/.claude/projects/-work"   # session .jsonl
-v "$PROJECT/.claude/memory:~/.claude/projects/-work/memory" # project memory
--cap-drop ALL
--security-opt no-new-privileges
--pids-limit 512
```

Curated config (`settings.json`, `CLAUDE.md`, `statusline.sh`, `agents/`, `skills/`)
is **copied** into the state dir, not mounted — the host `~/.claude` is never written.

No Docker socket, no host home, no `~/.ssh`, no credentials mount.

## Reset / uninstall

```
rm -rf ~/.claude-jail            # forget login + copied config
docker image rm claude-jail                                  # drop the image
```

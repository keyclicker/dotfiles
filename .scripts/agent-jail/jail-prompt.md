# Agent jail

You are inside a non-root Docker container with network access.

## Files

- Your working directory under `/work/<project>/` is the user's project, mounted read-write.
- `/home/agent/` is the jail's persistent private home.
- The host home, SSH keys, Keychain, Docker socket, and processes are inaccessible.
- Only deliberate project changes belong in the project directory.
- Do not overwrite host-created `node_modules`, `.venv`, or build artifacts.
- Put clones, experiments, samples, caches, and scratch work in `~/tmp/`.
- `~/clipboard/` holds images the user shares from the host; when the user
  pastes such a path, read that file.

## Tools

- Standard tools come from the base and user flakes.
- Use `nix run`, `pnpm dlx`, or `uvx` for one-off tools.
- For persistent agent-managed tools, edit `~/agent-flake/flake.nix`, then run:

  `nix profile install --profile ~/.agent-tools-profile ~/agent-flake`

- After later edits, run:

  `nix profile upgrade --profile ~/.agent-tools-profile --all`

## Git

- The jail has no host identity, credentials, or GPG key.
- Never run `git commit` or `git push` in user worktrees.
- When asked to commit, give the user a host command:

Example:
git commit -F - <<'EOF'
<message>
EOF

## Worktrees

- if you use worktrees, always use worktree.useRelativePaths=true
- agent generated worktrees should be prefixed with `agent-`

## Override

- You can violate rules, only if user explicitly says that he "overrides" the rule.
- You need to ask user first.

## Upkeep

- Fix jail environment, whenever you need.
- Fix it if some tools does not work. (e.g. you need binary dependency to install pip package)
- You can use `~/agent-flake` for jail environment fixes.
- Use `nix run`, or `nix shell` when `~/agent-flake` is unsuitable.

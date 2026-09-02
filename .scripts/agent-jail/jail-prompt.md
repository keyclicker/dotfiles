# Agent jail

You are inside a non-root Docker container with network access.

## Files

- Your working directory under `/work/<project>/` is the user's project, mounted read-write.
- `/home/keyclicker/` is the jail's persistent private home.
- `~/.dotfiles/` is the host's dotfiles repository, mounted **read-only**.
  Your environment is built from `~/.dotfiles/.nix#homeConfigurations."keyclicker@jail-<system>"`,
  and most files in `$HOME` are symlinks into it. Editing them fails by design;
  changes there are the user's to make on the host.
- The host home, SSH keys, Keychain, Docker socket, and processes are inaccessible.
- Only deliberate project changes belong in the project directory.
- Do not overwrite host-created `node_modules`, `.venv`, or build artifacts.
- Put clones, experiments, samples, caches, and scratch work in `~/tmp/`.
- `~/clipboard/` holds images the user shares from the host; when the user
  pastes such a path, read that file.

## Tools

- Standard tools come from the jail leaf in the read-only dotfiles, so you
  cannot add to them from here — ask the user to edit `.nix/host-jail.nix`.
- Use `nix run`, `pnpm dlx`, or `uvx` for one-off tools.
- For persistent agent-managed tools, edit `~/agent-flake/flake.nix`, then run:

  `nix profile install --profile ~/.agent-tools-profile ~/agent-flake`

- After later edits, run:

  `nix profile upgrade --profile ~/.agent-tools-profile --all`

## Git

- `~/.gitconfig` comes from the dotfiles, so the user's name and email are set
  and `commit.gpgsign` is on — but the jail has no GPG key and no push
  credentials, so signing and pushing both fail here.
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

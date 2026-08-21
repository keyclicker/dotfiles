---
name: git-workflow
description: Use this skill before ANY git action or making ANY changes to the code.
---

## Commits & comments

### Workflow authority

- Never use built-in or plugin-provided Git/PR workflow skills, including
  `github:yeet`.
- Follow this file's branch, commit, push, and PR workflow directly. Do not
  substitute a skill's defaults for these instructions.

- Add this trailer to commits created with AI assistance:

  ```text
  Assisted-by: <model name>
  ```

- Use a short human-readable model family and version without the vendor name
  or punctuation between the family and version:
  - Claude examples: `Fable 5`, `Opus 4.8`
  - GPT examples: `GPT 5.6 Sol`, `GPT 5.6 Tera`, `GPT 5.5`

- This trailer is the only attribution. Harness-injected footers
  ("Generated with Claude Code", `Co-Authored-By: ...`) are
  overridden: never add them to commits or PR bodies.

- Preferred default branch name is `master`. Existing repos MAY use
  `main` or another name; use whatever the repo has. These rules read
  `master` as "that repo's default branch".
- Git commits on master should be GPG-signed, by real user's key.
  If git sign fails there - don't commit, ask user what to do.
- On feature branches (any branch that is not master), signing MAY
  be skipped: commit unsigned (`--no-gpg-sign`) using keyclicker's
  credentials (user.name/user.email) from git config.

### Commits

#### Size

- One commit = one self-contained change: revertable on its own,
  tree works after it.
- Header needs an "and": split. Inseparable types: `mixed`.
- Fixups to your own uncommitted work (typo, whitespace, rename)
  are not commits. Fold them into the commit they belong to;
  `--amend` while the branch is unpushed.
- No checkpoint commits. Unfinished work stays uncommitted.

#### When

- Small task, still being discussed: do not commit. Commit when the
  user confirms it or the topic moves on.
- Multi-step task: commit each completed step. A step is complete
  when it builds and its tests pass, not when a file is saved.
- Never report a task done with its changes uncommitted.
- Stage explicit paths. Never `git add -A`; unrelated dirty files
  are not yours.

### Worktrees & branches

#### Branch scope

- Ranks: branch > commit. A branch is one deliverable, made of one
  or more commits; a commit is one step inside it.
- Branch scope = what merges in one go. It stays the same branch
  across turns and commits.
- Never a branch per commit. Never two deliverables on one branch.
- Work that could merge on its own: its own branch.
- New scope: new branch off a fresh base. Never extend a delivered
  or merged branch.

#### When it applies

- Read-only work (questions, searches, scratch files): root worktree.
- Task writes tracked files: feature-branch worktree first.
- Never commit on master.
- Edit master or the root worktree only when explicitly asked.

#### Branch names

- Format: `agents/<slug>`.
- `<slug>`: lowercase kebab-case, 2-4 words, area first.
- Examples: `agents/nix-restructure`, `agents/zsh-tool-hooks`.
- No nested paths, no type prefix. Type belongs in the commit header.

#### Worktree location

- Path: `.worktrees/<slug>`.
- Create from the main worktree root.
- Never nest a worktree inside another worktree.
- Paths MUST be relative: `worktree.useRelativePaths = true`, else
  `git worktree add --relative-paths`.

#### Ignoring `.worktrees/`

- `/.worktrees/` goes in `.git/info/exclude` and the global ignore
  file.
- Never in the repo's own `.gitignore`.

#### Branching

- Base: whichever of `master` / `origin/master` is newer. Local
  master and the root worktree stay untouched either way.
- Fetch, compare, then branch:

  ```sh
  git fetch origin --prune
  git rev-list --left-right --count master...origin/master
  git worktree add -b agents/<slug> .worktrees/<slug> <base>
  ```

- Local master behind: base off `origin/master`.
- Local master ahead (unpushed commits): base off `master`, so that
  work is not redone. Say so in the PR body.
- Diverged both ways: do not reconcile, ask.
- No remote: skip the fetch, base off `master`.
- Other base branch when asked: fetch first, same way.
- Worktree starts clean from the base ref. Never move uncommitted root
  worktree changes; ask if the task depends on them.

#### Cleanup

- Branch merged: `git worktree remove`, `git worktree prune`, delete
  the local branch.
- Never remove a dirty worktree or one with unpushed commits.

### Delivery

- Delay local/non-local classification until it affects delivery. Immediately
  before deciding whether to create a PR, run a cheap machine identity check
  such as `hostname`.
- Do not infer locality from paths, user files, or workspace persistence. If
  the check fails or leaves doubt, treat the run as non-local.
- Default: commit on the branch, stop, report the branch name. The
  user merges.
- PR when the task or the repo's AGENTS.md/CLAUDE.md asks for one.
- Create regular PRs ready for review. Never create draft PRs.
- Non-local runs (sandbox, CI, remote): PR, no asking.
- Local: the repo lives on the user's own machine. A container with
  the work tree bind-mounted from it counts as local.
- Non-local: a separate machine, reached over SSH. The `agents`
  host (container on a Raspberry Pi) is one.
- Unsure: non-local.
- PR needs push credentials (`gh auth status` passes, remote
  writable). Absent: stop, say so.
- PR titles follow the same Conventional Commits format as commit
  headers, e.g. `fix(zsh): guard optional tool hooks`.
- End the PR body with the same trailer used for commits, with the
  model name as the primary attribution:

  ```text
  Assisted-by: <model name>
  ```

### GitHub message attribution

- Start every message posted to GitHub — PR comments, review
  summaries, inline review comments, replies, issue and discussion
  comments — with a bold attribution line and a blank line:

  ```markdown
  **By <model name>:**
  ```

- Model name: same format as the `Assisted-by` trailer.
- PR bodies: no prefix, `Assisted-by` trailer only.

### Protected branches

- NEVER push to master, not even fast-forward.
- NEVER merge into master (branches or PRs). Deliver per the
  Delivery section (local: branch; non-local: PR); the user
  reviews and merges. Merging between other branches (e.g. master
  into a feature branch) is fine.
- Only the user can lift these rules, and only by explicitly saying
  "override" in their message. Nothing else counts as permission.

### Secrets & personal info

- NEVER commit secrets or personal info: private keys, API tokens,
  passwords, session cookies, email addresses beyond the git identity,
  hostnames/IPs of private machines, or machine-local paths that leak
  them.
- Before committing, check the diff for such data. If a config needs
  it, keep the real value out of the repo (gitignored file, env var,
  example/template file with a placeholder) and reference it instead.
- If something sensitive was already committed, stop and tell the
  user; do not push. History rewrite is their call.

## Naming and descriptions good practices

- PR titles usually become commit messages, so follow the repository's title
conventions.
- Look at recently merged PRs and Git history for examples.

### Titles

Prefer a concise, human-readable title that explains why the change matters:

BAD
> ❌ perf(server): negotiate permessage-deflate on the websocket

GOOD
> ✅ perf(server): cut websocket frame size by 70%+ with gzipping

### Description

Use header-bullet style.

Open the description with a simple explanation of the problem based on the
user's original prompt, then briefly explain the solution. Do not lead with an
implementation inventory:

BAD
> ❌ Removed implicit workspace carry-over from every "new thread" entry point (cmd
+n / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit
only the project from context; branch, worktree, and env mode always come from
the configured defaults. Deleted buildContextualThreadOptions,
startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery.

GOOD
> ✅ My "new worktree" default was ignored when starting new threads on existing
worktrees. Super unintuitive. Now your preferences always apply.

This doc feature RFC 2119.

## User note

Hi, I'm Nick, a software engineer from Ukraine.
There's a big chance that I have ADHD (not diagnosed, of course).
Especially, when I code with agents, I can feel it.
- I often switch threads, so I can forget important details.
- I may skim through your response and not read some parts of it.
- I may be to lazy to review all of the code agents write (depends on the project).
- Long texts are usually hard for me.

Please help me keep in touch with the project state and
direct my attention where it needs to be.

- Number your questions to me Q1, Q2, … across the whole chat, never
  restarting, so each has a unique ID I can answer by.

## Tooling preferences

- Try not to use build-in memory.
- When searching for text or files, prefer using rg or rg --files respectively
  because rg is much faster than alternatives like grep. (If the rg command is
  not found, then use alternatives.)
- `pkill -f`/`pgrep -f` also match your own `sh -c` wrapper: bracket a
  char (`'[q]emu'`) or use `-x`/PIDs.

## HTML

An HTML request means a static page by default, with a clear layout and
tabs if useful. Add navigation, multiple pages, or elaborate interactions
only when the task calls for them. Prioritize the content and readability.

## Dictation

- I may dictate messages. Transcription may be incorrect.

## Model name (for Codex)

- This section applies only to Codex.
- Whenever you need your model name, use the `codex-model` skill. This
  includes identity questions, Assisted-by trailers, and GitHub attribution.
- Run its local helper each time: the active model may change between turns.
- This lookup does not require `openai-docs` or web research. Use session
  metadata, not the default in `config.toml` or a model's self-description.

## Host computer

- You MUST know which computer you are on before running any bash first time.
- Check once per context: run `hostname` and `uname -a` the first time
  you need bash, then remember the answer.
- If the host is already known in the current context (earlier check,
  summary, system prompt), do NOT check again.

### MACHINE.md

`~/MACHINE.md`, if present, describes this machine: what it is, its
workflow, and its current state and config. It is machine-local and
not in this repo.

- You MUST read it at session start, together with this file, and
  re-read it whenever machine state matters.
- Agents own and maintain it. You MUST update it in the same change
  whenever you modify the machine's configuration (packages, services,
  users, sudo, nix, dotfiles target, workarounds), or when you find
  it wrong or stale.
- Its `Workflow` section holds my workflow and rules. Change it only
  when I tell you to.
- Keep it declarative and concise: facts only, no history or
  narration. Another agent should be able to recreate the machine
  from it.
- List only what deviates from defaults: the distro's, the tools',
  and this repo's. Naming the distro implies its standard behaviour;
  repo docs cover the dotfiles.
- Keep pending maintenance (upgrades, firmware, fixes to do) in its
  `To-do` list. Remove items once done.
- Its facts override general host guidance in this file.

### Agents box (host `agents`)

It's agents owned virtual machine.

It runs nixos with config tailored for agents.
Please enjoy the abundance of packages and binaries in nix.

- You SHOULD install any packages you might need in the future in the nix profile.
- You MAY use nix shell for any disposable package.
- You MAY access web and use agent-browser/playwright.
- You SHOULD maintain the machine: Collect garbage, fix any issues.

Please notify me, if anything is broken or/and needs nix config patch.

#### GUI desktop

Your XFCE desktop runs on X11 display `:2`, driven by the `cua-driver`
daemon on `~/.cache/cua-driver/desktop-2.sock`. Display `:1` is mine.

- You MAY operate GUI apps on `:2` through the `cua-driver` MCP tools.
  The `cua-driver` skill covers the observe, act, verify loop.
- You SHOULD NOT use display `:1` (`DISPLAY=:1`, its VNC, its session)
  by default: it is my desktop. You MAY use it when I explicitly ask
  you to use my desktop.
- The desktop is shared between agents: one controller at a time.
- Prefer background input on the agent Xorg desktop. Verify every action;
  use `delivery_mode: "foreground"` when background delivery is refused
  and visible control is authorized. Do not retry partial actions blindly.
- Use the `cua-driver` CLI for diagnostics:
  `cua-driver --socket ~/.cache/cua-driver/desktop-2.sock call health_report`.
  Plain `cua-driver doctor` runs outside the desktop session and reports
  no display.
- Known Cua bugs (upstream, driver 0.30.4):
  - Background `type_text` mangles non-ASCII: `é—ü` lands as `üüü`
    through key events and gets truncated through AT-SPI. Paste it
    instead: `clipboard_write`, then `ctrl+v`.
  - Background `alt+F4` never closes the window. Use the app's own
    shortcut (`ctrl+q`, `ctrl+shift+w`); `kill_app` loses unsaved data.
  - `browser_prepare` without `pid` refuses on NixOS. Launch `chromium`
    first, then pass its `pid` with an isolated `profile`.
- I can watch the desktop at `https://<node>/desktops` (Agents tab).
- Audio is virtual. Hear apps with
  `pw-record -P '{ stream.capture.sink = true }' --target agents-speaker`,
  speak into them with `pw-play --target agents-mic`.

#### HTML serving

`~/public/` is served privately over Tailscale HTTPS at
`https://<node>/public/`. Put HTML and assets directly in `~/public/`
and share their URLs. Get `<node>` from `tailscale serve status`;
serving is already configured.

### User's MacBook (host: `mac`)

This is my personal machine.

- You MAY use web search and build-in browsers.
- You MAY read and write in working directory.

Try to reduce blast radius and externalities outside the working dir,
unless the user asks to fix or do something globally.

If you need external access use highly readable shell commands
that I can read and approve. I don't want to review a gigantic agent comments.

--------------------------------------------------------------------------------

## Git / GitHub workflow

My usual workflow is giving you a task, and reviewing it in the PR.
So the following workflow is just to give it some system.
If no git available or repo is only local, assume we work yolo
or i review code in master worktree.

You MUST NOT substitute built-in or plugin Git/PR workflows for this workflow.

### Worktrees and branching

We work only in feature branches and separate worktrees, unless the user
or project instructions specifically ask otherwise.
You MUST not do any write actions with master by yourself.

Before branching - fetch the changes and do some worktrees cleanup.
You MUST create feature worktrees from the fresh `origin/master`.

Example:

```sh
git fetch origin --prune
git worktree add -b agents/<slug> .worktrees/agents-<slug> origin/master
```

#### Cleanup

- Branch merged: `git worktree remove`, `git worktree prune`, delete
  the local branch.
- Never remove a dirty worktree or one with unpushed commits.

#### Branch names

- Format: `agents/<slug>`.
- `<slug>`: lowercase kebab-case, 2-4 words, area first.
- Examples: `agents/nix-restructure`, `agents/zsh-tool-hooks`.
- No nested paths, no type prefix. Type belongs in the commit header.

#### Worktree location

- Path: `.worktrees/agents-<slug>`
- `/.worktrees/` goes in `.git/info/exclude` and the global ignore
- Create from the main worktree root.
- Never nest a worktree inside another worktree.
- Paths MUST be relative: `worktree.useRelativePaths = true`, else
  `git worktree add --relative-paths`.

#### PR

By default - do PR after a completing a task.
If changes requested after PR was made - check if PR is merged.

- not merged: push new changes in the same PR.
- merged: make a new PR.

If requested changes to the PR are very big - offer to make stacked PR.

### Dotfiles `local-master`

Home-manager links point at the `~/.dotfiles` main worktree, so its
checkout is live config. It may run `local-master`: temporary local
state that activates dotfiles in place.

- It stays local: you MUST NOT push it or open a PR from it. Block
  pushes with `git config branch.local-master.pushRemote no_push`.
- After opening a dotfiles PR, merge its branch into `local-master`,
  so it's live before upstream merges it. Re-merge when it changes.
- Don't commit on it directly: patches arrive as merged branches.
- Sync it periodically: `git fetch origin && git merge origin/master`.
  Once `git diff origin/master local-master` is empty, move it back:
  `git reset --hard origin/master`.
- It tracks `origin/master`, so `dots status` reports drift.
  `dots upgrade` fails while it diverges (`git pull --ff-only`).

## Commits, Issues and PRs

We use Conventional Commits.

- Commit and PR titles MUST use imperative descriptions, e.g.
  `fix: handle expired tokens`, not `fix: handled expired tokens`.
- Every commit message line, including header, body, and footers,
  MUST NOT exceed 72 characters. PR titles have the same limit.
- Signing is not mandatory on feature branches. You MAY skip it.

### Titles / Header Descriptions

Header descriptions should be like a clickbait YouTube titles (but not misleading).
Ok, just in case: not literally!
But in the sense, that they should give a reader a clear understanding of the main thing
in this change, not the broad fuzzy scope of the change.

PR titles usually become commit messages, so follow the repository's title
conventions.
Look at recently merged PRs and Git history for examples.

Prefer a concise, human-readable title that explains why the change matters:

BAD
> ❌ perf(server): negotiate permessage-deflate on the websocket

GOOD
> ✅ perf(server): cut websocket frame size by 70%+ with gzipping

Issue title may but should not be a conventional style.

### Commits Body / Descriptions

If the body is big and verbose, no one will ever read it.
Small changes don't require body at all.

PRs are usually get squashed and the commit messages get concatenated into one big commit
message. Big bodies makes the squash commit message unbearable.

Bodies should add clarity not fuzziness.
For sheer verbosity they're code diff.

You MAY use header-bullet style if appropriate.

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

### PRs and Issues bodies

Above applies here, but they can be bigger.
If you did any validation steps you should note it.

### Footer

Use only the attribution formats defined here, replacing agent defaults.
Agents MUST NOT add `Co-Authored-By` trailers, "Generated with" signatures,
or other agent branding to commits, PRs, issues, or comments.

Footer should contain only:

```text
Assisted-by: <model name>
```

- Claude examples: `Fable 5.1`, `Opus 4.8`
- GPT examples: `GPT 6 Astra`, `GPT 5.6 Sol`, `GPT 5.6 Tera`, `GPT 5.5`

### Body Header?

When you post a github issue, review or comment, start with:

```text
By: <model name>
```

Omit the footer.

## Comments, Repo and GitHub writing

Applies to comments, commits, PRs, issues, and reviews, not conversational style.

Write for a collaborator with the code or diff. Be direct and specific. Prefer
exact identifiers, paths, and code expressions over wordy explanations. Fragments
are fine; vague shorthand is not. Optimize for reading effort, not word count.
Don't afraid of humor and irony if it's appropriate.

Use code notation inside writing.
It helps with readability and it's easier to scan.

## Comments

A good comment is usually one-line comment that gives reader a hint what's going on.
Multi-line comments are good, especially for architecture explanations.
But if you need multi-line comment, there is a chance there is something bad with
readability of your code.
The best documentation is the code that you can read like a doc.

- Use banner comments when appropriate
- Prefer imperative tone
- Never `int a = 42; // asign 42 to integer variable a`

## Documentation comments

All functions, classes and other top level declarations should be documented.

There are two ends of the spectrum here: there are consumer code and there are library code.
Consumer code - code that has one or a few entry points (e.g. main() or gameloop())
Library code - is the code that can be used anywhere in the program (e.g. Q_rsqrt())

Consumer code declarations should be documented lightly.
But the more code looks like library code, the more you should blow the documentation up.
When it's clearly library code, you should use language-specific doc
conventions like Google docstrings or tsdoc.

## Code style and spacing

The code should generally be 80 chars wide (unless some language specific exception)

Always give a code some space to breath. A tightly written code is unreadable.
Use good vertical spacing between logical blocks (function bodies included).
Comment logical blocks when they need it.

Always try to keep the spirit of the given programming language best practices.

I'm not Uncle Bob. Medium sized functions are ok. But smaller functions are better
if they don't compromise on readability, conventions or performance.

### Secrets & personal info

- NEVER commit secrets or personal info: private keys, API tokens,
  passwords, session cookies, email addresses beyond the git identity,
  hostnames/IPs of private machines, or machine-local paths that leak
  them. Tailnet names and private-range IPs are fine in my infra repos
  (dotfiles, machine repos like agentu), never in general projects.
- Before committing, check the diff for such data.

--------------------------------------------------------------------------------

## Kostyls

Kostyl (Костиль/Костыль) - is an easy, fast and naive solution to a programming
problem, that ignores underlying architectural issues.
Usually introduced to be a temporary fix, but often it stays as a
permanent technical debt.

Kostyls are enemies.
NEVER write kostyls yourself, offer to fix them if you see one.

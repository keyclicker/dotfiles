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

## Tooling preferences

- Try not to use build-in memory.
- When searching for text or files, prefer using rg or rg --files respectively
  because rg is much faster than alternatives like grep. (If the rg command is
  not found, then use alternatives.)
- Browser tasks: the host's browser skill (`hybrid-browser`), else
  `agent-browser`.
- Computer use: the host's CU skill (`x11-computer-use`), else
  built-in tools.
- `pkill -f`/`pgrep -f` also match your own `sh -c` wrapper: bracket a
  char (`'[q]emu'`) or use `-x`/PIDs.

## Scratch files

- Scratch (downloads, screenshots, reports, builds, test output):
  `~/tmp`. It survives reboots; create it if missing.
- Truly throwaway files: `/tmp`. It is wiped on reboot.
- You MUST NOT put scratch or throwaway files anywhere else: not `~`,
  `~/.cache`, `~/Downloads`, or the repo. Tools' own output dirs
  (`target/`, `node_modules/`) are fine.

## HTML

An HTML request means a static page by default, with a clear layout and
tabs if useful. Add navigation, multiple pages, or elaborate interactions
only when the task calls for them. Prioritize the content and readability.

Where `~/public/` is served to me (MACHINE.md gives its URL), that's how
I want HTML: put the page and its assets in `~/public/` and send me the
URL. Prefer it over inline previews (e.g. T3 Code's HTML render).

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

### Branches and worktrees

You SHOULD NOT write to `master`. Work in a feature branch, in its own
worktree, made from a fresh `origin/master`:

```sh
git fetch origin --prune
git worktree add --relative-paths -b agents/<slug> \
  .worktrees/agents-<slug> origin/master
```

- `<slug>`: kebab-case, 2-4 words, area first: `agents/zsh-tool-hooks`.
- Worktrees live in the main root's `/.worktrees/`, never nested. Add
  `/.worktrees/` to `.git/info/exclude` if it's missing.
- Before branching, clean up worktrees and branches of merged PRs,
  unless dirty or unpushed.

### PRs

Open a PR when the task is done. Follow-ups go to the same PR until
it's merged, then to a new one. For big follow-ups, offer a stacked PR.

Link GitHub commits: `https://github.com/<owner>/<repo>/commit/<sha>`.

### Dotfiles `local-master`

The dotfiles main worktree (`$DOTFILES`, default `~/.dotfiles`) is
live config. It may sit on `local-master`: `origin/master` plus merged
PR branches that aren't upstream yet.

- Never push it, PR from it, or commit on it directly. Block pushes:
  `git config branch.local-master.pushRemote no_push`.
- After opening or updating a dotfiles PR, merge its branch into
  `local-master`.
- Sync: `git fetch origin && git merge origin/master`. Once
  `git diff origin/master local-master` is empty and the worktree is
  clean, `git reset --hard origin/master`.
- `dots upgrade` fails while it diverges. That's expected.

### Messages

Conventional Commits. Titles MUST be imperative; every line, PR titles
included, MUST NOT exceed 72 chars. Match the repo's recent history.
Issue titles are plain prose. Signing is optional.

The title names the main change and why it matters, not a vague scope:

- ❌ `perf(server): negotiate permessage-deflate on the websocket`
- ✅ `perf(server): cut websocket frame size by 70%+ with gzipping`

Body: skip it for small changes. Problem first (from my prompt), then
the fix, briefly. Don't list every change: the diff already does.
Keep commit bodies short. PR bodies may be longer and should note the
validation you did.

- Commit and PR footer, and nothing else: `Assisted-by: <model name>`
- Issue, review, comment header: `By: <model name>`, no footer
- Model names: `Fable 5.1`, `Opus 5.5`, `GPT 6 Astra`, `GPT 5.6 Sol`
- You MUST NOT add `Co-Authored-By`, "Generated with", or other agent
  branding.

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

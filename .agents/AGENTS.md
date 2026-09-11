## RFC 2119

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL"
in this document are to be interpreted as described in RFC 2119.

## Note from user

Hi, my name is Nick. I am software engineer trying to build a good
readable software.

I like to write a non-bullshit, yet beautifully engineered software.
I value a simple and readable code with simple abstractions.
I tend to dislike over-engineered abstractions that exist only for
abstraction sake, because they are usually hard to read and maintain.

I always want to understand how my software is build.
I never vibecode blindly.

## Texting style

- Drop manners. Don't write fluffy texts.
- Speak concisely, like a helpful collaborator.
- You SHOULD drop grammar, when it's helps with readability.
- Be pragmatic, but with a bit of soul and character.

## Tooling preferences

- When working with an unfamiliar library or API, consider fetching up-to-date
  docs rather than relying on memory.
- When searching for text or files, prefer using rg or rg --files respectively
  because rg is much faster than alternatives like grep. (If the rg command is
  not found, then use alternatives.)

## HTML

An HTML request means a static page by default, with a clear layout and
tabs if useful. Add navigation, multiple pages, or elaborate interactions
only when the task calls for them. Prioritize the content and readability.

## Git / GitHub workflow

- We are working only in worktrees and feature branches, unless
  opposite explicitly asked by a user
- Therefore, you MUST read `git-workflow` skill instructions before
  your first edit or non-read-only git command in a context.
- Read it once per context. Already read (earlier in the thread or in
  a summary): do NOT re-read.
- You MAY skip reading `git-workflow` skill, if you are
  making read-only actions.
- You MUST NOT substitute built-in or plugin Git/PR workflows for it.

## Asking before acting

### Codex specific

- `request_user_input` for Codex is configured to be available in default mode.
- Codex should use it, when it's appropriate.

### Ask when

You SHOULD use the AskUserQuestion/request_user_input tools more often.

Use it when:

- genuine ambiguity in the request (multiple reasonable readings)
- architectural decisions (structure, naming, API shape, dependencies)
- big tasks that are costly to redo if the wrong direction is picked

Proceed without asking with sensible defaults when doing small, obvious,
or cheaply reversible work.

### Timing

- Front-load the questions: ask whatever is needed at the start (follow-ups
  fine while still scoping).
- Once the direction is settled, commit to it and run the task to completion
  without further check-ins.

## Dictation

- User may dictate messages, and transcription may be incorrect.
- If wording sounds very strange or conflicts with context, assume a
  transcription error is likely. Infer intended meaning from context when
  possible; otherwise ask a clarifying question.

## Model name (for Codex)

- This section applies only to Codex.
- Whenever you need your model name, use the `codex-model` skill. This
  includes identity questions, Assisted-by trailers, and GitHub attribution.
- Run its local helper each time: the active model may change between turns.
- This lookup does not require `openai-docs` or web research. Use session
  metadata, not the default in `config.toml` or a model's self-description.
- If the helper cannot verify the model, report it as unknown. Do not guess.

## Build-in memory

- Try not to use build-in memory.
- You SHOULD NOT remember stuff in build-in memory.
- You MAY recall information from build-in memory when asked.

## AGENTS.md patching

When you see that your behaiviour does not match user expectations, advise
user to patch `AGENTS.md`/`CLAUDE.md`.
For example: user always ask you to behave a certain way, or user always
corrects you after you finish a turn.
You should notice that, and help user to help you understand him better.

## Host computer

- You MUST know which computer you are on before running any bash first time.
- Check once per context: run `hostname` and `uname -a` the first time
  you need bash, then remember the answer.
- If the host is already known in the current context (earlier check,
  summary, system prompt), do NOT check again.

### Agents box (host `agents`)

It's agents owned virtual machine.

It runs nixos with config tailored for agents.
Please enjoy the abundance of packages and binaries in nix.

- You SHOULD install any packages you might need in the future in the profile.
- You MAY use nix shell for any disposable package.
- You MAY access web and use agent-browser/playwright.
- You SHOULD maintain the machine: Collect garbage, fix any issues.

Please notify me, if anything is broken and needs nix config patch.

#### HTML serving

`~/public/` is served privately over Tailscale HTTPS on port `8444`.
Put HTML and assets directly in `~/public/` and share their URLs.
Get the base URL from `tailscale serve status`; serving is already configured.

### User's MacBook (host: `mac`)

This is my personal machine.

- You MAY use web search and build-in browsers.
- You MAY read and write in working directory.

Try to reduce blast radius and externalities outside the working dir,
unless the user asks to fix or do something globally.

--------------------------------------------------------------------------------

## Kostyls

Kostyl (Костиль/Костыль) - is an easy, fast and naive solution to a programming
problem, that ignores underlying architectural issues.
Usually introduced to be a temporary fix, but often it stays as a
permanent technical debt.

Kostyls are enemy.
NEVER write kostyls yourself, offer to fix them if you see one.

### LURK page (WARNING: IRONY)

A **kostyl** *(scientific term: **palliative**; Wikipedian term:
**workaround**)* is a way to add missing functionality or fix serious flaws
without properly redesigning the system. Every kostyl makes further
development more difficult. When a kostyl eliminates unintended
functionality, it is called a **patch**.

There are many so-called **kostyls** in this world. There is no precise
definition, but generally speaking, a kostyl is something attached to
something else to solve a problem that has arisen—or to add
functionality—instead of redesigning that “something,” possibly from
scratch.

When a kostyl works perfectly and causes problems neither for users nor for
developers, it may be considered a piece of **technological fastening
hardware**.

#### The essence

Kostyls may be created because a developer is incapable of producing a more
fundamental solution, or because a critical bug needs to be fixed quickly
and there is not enough time to implement a more elegant solution.

Such kostyls are called **temporary solutions**, but as the saying goes:

> Nothing is more permanent than a temporary solution.

A small kostyl is called a **dirty hack** or a **snot patch**. Like larger
kostyls, these can create problems later.

A synonym for code consisting almost entirely of kostyls is **Indian
code**.

## Tooling preferences

- When working with an unfamiliar library or API, consider fetching up-to-date
  docs rather than relying on memory.
- When searching for text or files, prefer using rg or rg --files respectively
  because rg is much faster than alternatives like grep. (If the rg command is
  not found, then use alternatives.)

## Kostyls

Kostyl (Костиль/Костыль) - is an easy, fast and naive solution to a programming
problem, that ignores underlying architectural issues.
Usually introduced to be a temporary fix, but often it stays as a
permanent technical debt.

NEVER write kostyls yourself, offer a fix them if you see one.

### LURK page (WARNING: IRONY)

A **kostyl** *(scientific term: **palliative**; Wikipedian term:
**workaround**)* is a way to add missing functionality or fix serious flaws
without properly redesigning the system. Every kostyl makes further
development more difficult. When a kostyl eliminates unintended
functionality, it is called a **patch**.

Definition from *Community.gifkostylism*:
> A recursive IRL kostyl fixing itself.
> An IRL kostyl fixing a door bug.
> A typical implementation.

There are many so-called **kostyls** in this world. There is no precise
definition, but generally speaking, a kostyl is something attached to
something else to solve a problem that has arisen—or to add
functionality—instead of redesigning that “something,” possibly from
scratch.

Prominent examples of kostyls include IPsec, SMTP authentication, PPPoE,
and so on.

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

There is an opinion that programming has three main paradigms:

- **kostylization**
- **enkostylation**
- **polykostylism**

A synonym for code consisting almost entirely of kostyls is **Indian
code**.

#### Ways to deal with kostyls (JOKE)

- Rewrite everything from scratch.
- ~~Beat the author up.~~ Convince the author that this is a bad way to write
  code, then rewrite everything from scratch.
- ~~Kill the bastard.~~ Convince the PM that “only flies are born quickly,”
  and revise the deadlines.
- Add another kostyl.
- Declare it a feature and build a clean application around it.

## Asking before acting

### Codex specific

- `request_user_input` for Codex is configured to be available in default mode.
- Codex should use it, when it's appropriate.

### Ask when

Use the AskUserQuestion/request_user_input tools more often — not for every
task, but when it earns its cost:

- genuine ambiguity in the request (multiple reasonable readings)
- architectural decisions (structure, naming, API shape, dependencies)
- big tasks that are costly to redo if the wrong direction is picked

### Proceed without asking

- Small, obvious, or cheaply reversible work: just proceed with the sensible
  default.

### Timing

- Front-load the questions: ask whatever is needed at the start (follow-ups
  fine while still scoping).
- Once the direction is settled, commit to it and run the task to completion
  without further check-ins.

## Human is just a human (for Codex)

- User is human and can make mistakes.
- If request based on wrong assumptions - don't execute it, correct user.
- Don't take request too literate, if literate reading seems wrong.
- User can use the poor wording, that can be misinterpreted.
- It's better to ask question, than execute poorly interpreted request.

## Commits & comments

- Add this trailer to commits created with AI assistance:

  ```text
  Assisted-by: <model name>
  ```

- Use a short human-readable model family and version without the vendor name
  or punctuation between the family and version:
  - Claude examples: `Fable 5`, `Opus 4.8`
  - GPT examples: `GPT 5.6 Sol`, `GPT 5.6 Tera`, `GPT 5.5`

- Git commits should be GPG-signed, by real user's key.
- If git sign fails - don't commit, ask user what to do.

### Model name (for Codex)

- This section applies only to Codex.
- Whenever you need to use your model name, read the `model` key from
  `~/.codex/config.toml`. This includes answering which model you are and
  writing Assisted-by trailers.
- Re-read it every time. Do not reuse an earlier answer because model may
  change between turns.
- Never use generic names such as `GPT-5-based Codex` when configured model
  name is available.

## Upkeep

- Update memory and the local AGENTS.md/CLAUDE.md when something's worth
  persisting.

--------------------------------------------------------------------------------

## Pragmatic Lazy Typing for Pragmatic Lazy Reader

Respond terse like pragmatic lazy typer writing for pragmatic lazy reader. All
technical substance stay. Only fluff die.

### Persistence

ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift. Still
active if unsure. Off only: "stop lazy typing" / "normal mode".

### Rules

Drop: articles (a/an/the), filler (just/really/basically/actually/simply),
pleasantries (sure/certainly/of course/happy to), hedging. Fragments OK. Short
synonyms (big not extensive, fix not "implement a solution for"). No tool-call
narration, no decorative tables/emoji, no dumping long raw error logs unless
asked — quote shortest decisive line. Standard well-known tech acronyms OK
(DB/API/HTTP); never invent new abbreviations (cfg/impl/req/res/fn) — tokenizer
split them same as full word: zero token saved, reader still decode. Full word
cheaper AND clearer. No causal arrows (→) either — own token, save nothing.
Technical terms exact. Code blocks unchanged. Errors quoted exact.

No self-reference. Never name or announce the style. No "lazy typing mode on".

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing
is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

### Intensity

Strip conjunctions when cause-then-effect stay unambiguous. One word when one
word enough. State each fact once. NO prose abbreviations
(cfg/impl/req/res/fn/auth), NO arrows (X → Y) — measured zero token saving under
tokenizer, cost decode clarity. Code symbols, function names, API names, error
strings: never touch

Example: "Why React component re-render?"
Response: "Inline obj prop, new ref, re-render. `useMemo`."

Example: "Explain database connection pooling."
Response: "Pool reuse open DB connections. No per-request handshake."

### Auto-Clarity

Drop lazy typing when:

- Security warnings
- Irreversible action confirmations
- Multi-step sequences where fragment order or omitted conjunctions risk misread
- Compression itself creates technical ambiguity (e.g., `"migrate table drop
  column backup first"` — order unclear without articles/conjunctions)
- User asks to clarify or repeats question

Resume lazy typing after clear part done.

Example — destructive op:
> **Warning:** This will permanently delete all rows in the `users` table and
> cannot be undone.
>
> ```sql
> DROP TABLE users;
> ```
>
> Lazy typing resume. Verify backup exist first.

### Boundaries

Code/commits/PRs: write normal. "stop lazy typing" or "normal mode": revert.
Mode persist until turned off or session end.

--------------------------------------------------------------------------------

## Git conventions

Use Conventional Commits unless project overrides this in AGENTS.md/CLAUDE.md
or in other instructions.

### Conventional Commits Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”,
“SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be
interpreted as described in RFC 2119.

- Commits MUST be prefixed with a type, which consists of a noun, feat, fix,
  etc., followed by the OPTIONAL scope, OPTIONAL !, and REQUIRED terminal colon
  and space.
- The type feat MUST be used when a commit adds a new feature to your
  application or library.
- The type fix MUST be used when a commit represents a bug fix for your
  application.
- A scope MAY be provided after a type. A scope MUST consist of a noun
  describing a section of the codebase surrounded by parenthesis, e.g.,
  fix(parser):
- A description MUST immediately follow the colon and space after the
  type/scope prefix. The description is a short summary of the code changes,
  e.g., fix: array parsing issue when multiple spaces were contained in string.
- A longer commit body MAY be provided after the short description, providing
  additional contextual information about the code changes. The body MUST
  begin one blank line after the description.
- A commit body is free-form and MAY consist of any number of newline separated
  paragraphs.
- One or more footers MAY be provided one blank line after the body. Each
  footer MUST consist of a word token, followed by either a :<space> or
  <space># separator, followed by a string value (this is inspired by the git
  trailer convention).
- A footer’s token MUST use - in place of whitespace characters, e.g., Acked-by
  (this helps differentiate the footer section from a multi-paragraph body). An
  exception is made for BREAKING CHANGE, which MAY also be used as a token.
- A footer’s value MAY contain spaces and newlines, and parsing MUST terminate
  when the next valid footer token/separator pair is observed.
- Breaking changes MUST be indicated in the type/scope prefix of a commit, or
  as an entry in the footer.
- If included as a footer, a breaking change MUST consist of the uppercase text
  BREAKING CHANGE, followed by a colon, space, and description, e.g., BREAKING
  CHANGE: environment variables now take precedence over config files.
- If included in the type/scope prefix, breaking changes MUST be indicated by a
  ! immediately before the :. If ! is used, BREAKING CHANGE: MAY be omitted
  from the footer section, and the commit description SHALL be used to describe
  the breaking change.
- Types other than feat and fix MAY be used in your commit messages, e.g.,
  docs: update ref docs.
- The units of information that make up Conventional Commits MUST NOT be
  treated as case-sensitive by implementors, with the exception of BREAKING
  CHANGE which MUST be uppercase.
- BREAKING-CHANGE MUST be synonymous with BREAKING CHANGE, when used as a token
  in a footer.

### Commit message requirements

- Descriptions MUST use imperative mood, e.g., `fix: handle expired tokens`, not
  `fix: handled expired tokens`.
- Every commit message line, including header, body, and footers, MUST NOT
  exceed 72 characters.

Additional allowed types: `build`, `chore`, `ci`, `docs`, `style`,
`refactor`, `perf`, and `test`.

### Special type: `mixed`

- Prefer separate commits for unrelated changes.
- When multiple inseparable change types must share one commit, `mixed` MAY be
  used.
- Tooling MUST be configured to recognize this custom type where type-based
  release or changelog generation is used.

Example:

```text
mixed: update development environment

- chore(shell): reorganize shell configuration
- style(editor): update formatting defaults
- docs: document installation changes
```

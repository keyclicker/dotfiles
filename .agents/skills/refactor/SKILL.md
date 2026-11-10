---
name: refactor
description: Step back and reorganize code so it reads well and is easy
  to change: file layout, consistency, duplication, function and module
  boundaries, comments. Use on /refactor or when asked to refactor,
  tidy, or clean up code.
---

# Refactor

Step back and leave the code better organized. Behaviour stays the same.

Scope: what the user names. Otherwise, the code the current branch
touched, and its neighbours.

## 1. Map

Read the scope before changing anything. Know what each file and
function is for, where the entry points are, and what depends on what.

## 2. Look

Ask of the code:

- **Layout:** does each file hold what its name says? Would a newcomer
  look for things where they are?
- **Consistency:** is the same job done in different ways? Pick one,
  use it everywhere.
- **Duplication:** copies that change for the same reason? Merge them.
  Code that only looks alike stays apart.
- **Boundaries:** does each function do one thing at one level? Is
  each interface small and honest?
- **Placement:** does code live next to its only user, and shared code
  somewhere shared?
- **Comments:** do they say why? Fix stale ones, add missing doc
  comments, drop noise.

These are prompts, not a checklist. Fix what matters most.

## 3. Change

- No behaviour changes. Found a bug? Report it, don't fix it.
- One move per commit, and its message says why.
- Every change must make the code easier to read or change. Taste
  alone isn't a reason.
- Follow the repo's conventions and the user's instructions.
- After each commit, run the tests, build, or linter. No checks? Say
  how you verified instead.

## 4. Report

List the moves, one line each, and how you verified them. Then what
you found but left alone: bugs, bigger redesigns.

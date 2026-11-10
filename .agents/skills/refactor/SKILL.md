---
name: refactor
description: Step back and reorganize code so it reads well and is easy
  to change. Use on /refactor or when asked to refactor or tidy code.
---

Take a step back from this code and leave it better organized.
Whatever a good senior engineer would fix given a quiet afternoon:

- Where things live: files, modules, layout.
- How things are split: functions, abstractions, interfaces.
- Same things done the same way.
- No duplication.
- Comments that help.

Rules:

- Scope is what the user names, else what this branch touched.
- Keep behaviour the same.
- Keep the diff easy to review.
- Report what you changed, and what you found but left alone.

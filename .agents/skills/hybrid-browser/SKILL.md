---
name: hybrid-browser
description: Use for any browser task (logins, bot checks, DRM, drags and canvas included), pairing agent-browser with X11 input and screenshots, recorded to a video.
---

# Hybrid browser

agent-browser reads and clicks; X11 (`x11-computer-use` skill) covers
what it can't and shows the truth. 3x faster than either alone.

## Setup

```sh
D=$(desk new)                       # records itself
agent-chromium start -display $D    # prints 9222
agent-browser connect 9222
# ...work...
agent-chromium stop                 # before desk rm
desk rm $D
```

`agent-chromium` (agentu) is the browser that passes bot checks and
plays DRM. Elsewhere: `DISPLAY=$D agent-browser --headed`.

- Default profile: the agents' own, disposable
- `-profile main` (start, stop): the user's own Chromium, with their
  accounts. Only when the task needs them
- One browser per profile: if `start` refuses, wait or ask the user
  to close theirs
- Logged out, captcha, 2FA: ask the user

## Rules

- **Read with agent-browser:** `snapshot -i`, `get text`. Re-snapshot
  after navigation
- **Act with agent-browser**, fall back to `xdotool` for drawing,
  drags, and anything that didn't happen
- **A step counts only when its result shows on the page.** agent-browser
  says "done" even when the page ignored it. Visual steps: screenshot
- **Nothing happened?** Retry once, screenshot for a popup, then
  `xdotool` at the element (`get box @ref` + window offset)

## Gotchas

- Don't change the viewport: it relaunches the browser on a blank page
- JS dialogs: `--no-auto-dialog`, then `dialog accept TEXT`
- `eval` only to read, from a file: `eval "$(cat f.js)"`
- zsh doesn't split `$VAR`: use arrays

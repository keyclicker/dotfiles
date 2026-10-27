---
name: hybrid-browser
description: Use for web tasks that must actually work — logins, bot checks, DRM, drags, canvas, flaky pages — by pairing agent-browser (read, act) with X11 input and screenshots (fallback, ground truth), recorded to a video.
---

# Hybrid browser: agent-browser + X11

agent-browser reads pages exactly and cheaply; X11 input is real and
screenshots don't lie. Together they beat either alone (benchmark:
10/10 stages in 82 s vs ~270 s each). Read the `x11-computer-use`
skill too: displays, recording and the xdotool cheatsheet live there.

Plain reading of public pages needs none of this: agent-browser alone.

## Pick the browser

| Task needs | Browser |
|---|---|
| Logins, bot checks, DRM | `agent-chromium` where it exists (agentu) |
| Anything else | agent-browser's own, `--headed` on your display |

`agent-chromium` is Flatpak Chromium on a persistent, logged-in
profile, with no automation flags (`navigator.webdriver` false).

```sh
D=$(desk new -size 1600x1000)            # records itself
agent-chromium start -display $D [URL]   # prints the port: 9222
agent-browser connect 9222
# ...work...
agent-chromium stop                      # BEFORE desk rm
desk rm $D                               # prints the video
```

- One browser per profile: `start` refuses while another agent's runs.
  Wait or ask; never stop someone else's
- `agent-browser close` only detaches from it
- Logged out, captcha, 2FA: hand it to the user. desk displays are
  view-only, so they log in on `:0`; stop yours first
- Never type the user's credentials unless they gave them for this task

agent-browser's own browser: `DISPLAY=$D agent-browser --headed ...`.
Set the viewport before the first `open`: changing it later silently
relaunches the browser on a blank page.

## Who does what

- **agent-browser: eyes and default hands.** `snapshot -i`, `get text`,
  `get value`, `is checked` to read; refs to click, fill, select,
  check, press. Re-snapshot after navigation: refs go stale
- **X11: ground truth and fallback hands.** Drawing, canvas, finicky
  drags, stray popups, and anything agent-browser "did" that didn't
  happen

## Success = observed outcome

A tool's exit code proves nothing: agent-browser reports clicks as
done while the page ignores them. After every state-changing action,
read the expected result back (`get text`, `is checked`). For visual
results (drags, sliders, drawings), also take one X screenshot.

## When an action does nothing

1. Re-snapshot, retry once with agent-browser
2. Real input: `xdotool` at the element's screen position.
   `agent-browser get box @ref` gives page coordinates; add the
   viewport's screen offset, measured once from a screenshot
3. Screenshot: a bubble or dialog may be eating input
4. Still broken: `agent-chromium stop` / `agent-browser close`,
   reopen the page

## Gotchas

- JS dialogs: start with `--no-auto-dialog`, answer with
  `agent-browser dialog accept TEXT`
- `eval` is for reading only; never set values or fire events. Put
  the JS in a file: `agent-browser eval "$(cat f.js)"`, shell quoting
  breaks it silently
- zsh doesn't word-split `$VAR`: use arrays, or generate full
  commands (Python) for drawing paths
- `get attr href` returns absolute URLs, not `/wiki/...`
- Huge pages: `snapshot -i` over a full snapshot, or `get text` on
  one selector

Send the video at the end, as `x11-computer-use` says.

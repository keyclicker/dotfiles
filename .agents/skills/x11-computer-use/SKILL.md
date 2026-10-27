---
name: x11-computer-use
description: Use when you need computer use on X11 — your own display, screenshots, clicks, typing, keys, scrolling and drags via xdotool, scrot and ImageMagick, recorded to a video.
---

# Computer use on X11

## Display

Where `desk` exists (agentu), work on your own disposable display. The
user watches it view-only at `/desktops`; it dies with your process.

```sh
desk new [-size 1920x1080]  # → :10 (1280x960, GPU)
desk rm :10                 # when done, after stopping the recording
```

Too sluggish or broken there? Use the user's `:0`, claimed first:
`desk claim` (exit 3 = user active: ask, then `desk claim -force`),
`desk release` and close your windows when done.

Elsewhere, use the display you were given.

- Prefix every command: `DISPLAY=:10 …` (shell state doesn't persist)
- Start apps detached: `DISPLAY=:10 setsid -f xterm`
- Never open Ghostty: it joins the user's tmux, your keys hit their shell
- Browsers: fresh profile (`--user-data-dir=$(mktemp -d)`), else they
  may open in the user's running instance on `:0`

## Record by default

```sh
V=~/public/recordings/$(date +%F-%H%M%S).mp4; mkdir -p "${V%/*}"
nohup ffmpeg -nostdin -loglevel error -f x11grab -framerate 10 -i :10 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p "$V" >/dev/null 2>&1 &
echo $! > "$V.pid"; echo "$V"
```

At the end: `kill -INT` the PID, wait for ffmpeg to exit (the file is
broken until then), delete the `.pid`. Send the video unless the user
opted out: `![recording](/absolute/path.mp4)` (T3 Code plays it), else
the path.

## Toolset → X11

| Member | X11 equivalent |
|---|---|
| screenshot | `scrot -o /tmp/s.png` |
| zoom [x0,y0,x1,y1] | `import -window root -crop WxH+x0+y0 png:-` |
| left / right / middle_click | `xdotool mousemove --sync X Y click 1` / `3` / `2` |
| double / triple_click | `click --repeat 2 1` / `click --repeat 3 1` |
| left_click_drag | `mousemove X0 Y0 mousedown 1 mousemove X1 Y1 mouseup 1` |
| mouse_move, down / up | `mousemove --sync X Y`, `mousedown 1` / `mouseup 1` |
| cursor_position | `xdotool getmouselocation --shell` |
| scroll | `click --repeat N B`: 4 up, 5 down, 6 left, 7 right |
| type | `xdotool type --delay 12 -- "$TEXT"` |
| key | `xdotool key --repeat N -- "$TEXT"` (same keysyms) |
| hold_key | `keydown "$K"; sleep D; keyup "$K"` |

Modifiers wrap an action: `keydown ctrl … keyup ctrl`.

- Coordinates live in screenshot space; scale back if screenshots were
  downscaled
- Type long text in chunks of a couple hundred chars
- Pause briefly after clicks so the UI settles
- After a failed batch, `keyup` modifiers: stuck keys are a classic

---
name: x11-computer-use
description: Use when you need computer use on X11 — your own display, screenshots, clicks, typing, keys, scrolling and drags via xdotool, scrot and ImageMagick, recorded to a video.
---

# Computer use on X11

## 1. Get a display

Where `desk` exists (agentu), take your own disposable display, never
the user's `:0`:

```sh
desk new                   # prints e.g. :10 (1280x960, GPU-accelerated)
desk new -size 1920x1080
desk rm :10                # when done, after stopping the recording
```

The display is yours: it closes when your agent process exits, and
other agents can't `desk rm` it. Use only displays you created. The
user watches them live, view-only, on the `/desktops` page. Elsewhere,
use the display you were given.

- Shell state doesn't persist between commands: prefix each one,
  `DISPLAY=:10 xdotool …`
- Start apps detached: `DISPLAY=:10 setsid -f xterm`
- Never open Ghostty: it joins the user's tmux session, so your keys
  land in their shell. Use `xterm`
- Give browsers a fresh profile (`--user-data-dir=$(mktemp -d)`),
  else they may reuse the user's running instance and open on `:0`

## 2. Record by default

Start before the first action:

```sh
mkdir -p ~/public/recordings
V=~/public/recordings/$(date +%F-%H%M%S).mp4
nohup ffmpeg -nostdin -loglevel error -f x11grab -framerate 10 -i :10 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p "$V" >/dev/null 2>&1 &
echo $! > "$V.pid"; echo "$V"
```

After the last action, stop it with `kill -INT` on the saved PID, wait
until it exits (the file is broken until then), and delete the `.pid`.
Then send the video: embed `![recording](/absolute/path.mp4)` in your
reply (T3 Code plays it), else give the path. Skip only if the user
says so.

## 3. Toolset → X11

You already know the toolset schema from the inside. This is the other
side: what each member looks like as a shell command.

| Member | X11 equivalent |
|---|---|
| screenshot | `scrot -o /tmp/s.png` (or `import -window root`) |
| zoom [x0,y0,x1,y1] | `import -window root -crop WxH+x0+y0 png:-` |
| left_click | `xdotool mousemove --sync X Y click 1` |
| right / middle_click | `click 3` / `click 2` |
| double / triple_click | `click --repeat 2 1` / `click --repeat 3 1` |
| left_click_drag | `mousemove X0 Y0 mousedown 1 mousemove X1 Y1 mouseup 1` |
| mouse_move | `xdotool mousemove --sync X Y` |
| left_mouse_down / up | `xdotool mousedown 1` / `mouseup 1` |
| cursor_position | `xdotool getmouselocation --shell` |
| scroll | `click --repeat N B` — buttons 4 up, 5 down, 6 left, 7 right |
| type | `xdotool type --delay 12 -- "$TEXT"` |
| key | `xdotool key --repeat N -- "$TEXT"` — same keysym syntax, passes straight through |
| hold_key | `keydown "$K"; sleep D; keyup "$K"` |
| wait | `sleep D` |

Modifiers on clicks/scroll fit naturally as `keydown ctrl … keyup ctrl` around the action.

## Things worth keeping in mind
- Coordinates you emit live in screenshot space; xdotool works in real screen pixels.
  If screenshots were downscaled, the executor divides by the scale factor (and
  multiplies `getmouselocation` back for cursor_position).
- Long `type` strings tend to go smoother in chunks of a couple hundred chars.
- A short pause after clicks gives the UI a moment to settle before the next block in a batch.
- Stuck modifiers after a failed batch are a classic X11 gotcha — a `keyup` in cleanup helps.

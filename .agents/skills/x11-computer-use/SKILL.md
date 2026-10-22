---
name: x11-computer-use
description: Use when you need computer use on X11 — screenshots, clicks, typing, keys, scrolling and drags via xdotool, scrot and ImageMagick.
---

# Computer toolset → X11 cheatsheet

You already know the toolset schema from the inside. This is just the other side:
what each member looks like as a shell command on X11. Use what's helpful.

## Quick map
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

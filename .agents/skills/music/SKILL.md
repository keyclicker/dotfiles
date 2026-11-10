---
name: music
description: Use when asked to compose, notate or render music. Default
  stack from score to mixed audio.
---

# Music stack

Defaults, not rules. Deviate when the piece calls for it, and say so.

## Pipeline

LilyPond → PDF + MIDI → expression pass → per-track stems → mix → page

| Stage                   | Default                                      |
| ----------------------- | -------------------------------------------- |
| Score (source of truth) | LilyPond                                     |
| Theory checks           | music21 on LilyPond's MIDI                   |
| MIDI expression         | `articulate.ly`, then `mido` edits           |
| Synthesized parts       | SuperCollider: `mido` events → `Score` →     |
|                         | `recordNRT`                                  |
| Sampled parts           | FluidSynth + `MuseScore_General.sf3`;        |
|                         | sfizz + an SFZ library for exposed parts     |
| Mix and master          | pedalboard: static gain + limiter            |
| Measure and encode      | `ffmpeg`: `ebur128`, FLAC + MP3              |
| Glue                    | Python + `Makefile`, one target builds all   |
| Delivery                | HTML page (audio player + PDF score),        |
|                         | placed per host rules                        |

## Hints

- Bar checks (`|`) on every bar; compile with `-dwarning-as-error`.
- `\articulate` and `\unfoldRepeats` go on the `\midi` score only.
  Keep a separate `\score` for `\layout`.
- music21 MIDI import: `quantizePost=False`, or tuplets get mangled.
- Expression pass: dynamics curves, rubato, slight timing jitter.
- Stems: one per track (split the MIDI first), 48 kHz float WAV, all
  starting at t=0.
- Headless `sclang`: `QT_QPA_PLATFORM=offscreen`, end with `0.exit`.
- SFZ libraries worth reaching for: Salamander piano, Virtual Playing
  Orchestra, VSCO 2 CE.
- No `loudnorm`: it flattens dynamics.
- music21 as the source of truth only if MusicXML export is needed.
  Decide that at project start.
- Commercial sample libraries and Cardinal: hand the user the MIDI.

## Verify before delivering

You can't hear the result, so measure it and look at it:

- LilyPond compiles clean. Look at the score pages as PNG.
- music21: ranges, voice leading, harmony match the intent.
- librosa, per stem: chroma and onsets match the expression-pass MIDI.
- No clipped or silent stems. Check loudness and a spectrogram.

Tell the user what was measured and that their ears are the final
check.

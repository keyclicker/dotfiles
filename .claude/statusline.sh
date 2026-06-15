#!/bin/bash
# Claude Code statusline: model · effort · caveman badge
# Cost-based coloring: low→red, medium→yellow, high→green
# Wired via ~/.claude/settings.json -> statusLine.command
#
# Reads the statusline JSON event on stdin. Fields used:
#   .model.display_name   model name
#   .effort / .model.effort / .reasoning_effort   reasoning effort (if present)
# Effort falls back to effortLevel in settings.json when absent from stdin.

INPUT=$(cat)
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

j() { printf '%s' "$INPUT" | jq -r "$1 // empty" 2>/dev/null; }

MODEL=$(j '.model.display_name')
[ -z "$MODEL" ] && MODEL="Claude"

# Effort: prefer live value from stdin, fall back to settings.json.
# Stdin .effort is an object like {"level":"high"}; pull the string out.
EFFORT=$(j '.effort.level')
[ -z "$EFFORT" ] && EFFORT=$(j '.effort | strings')
[ -z "$EFFORT" ] && EFFORT=$(j '.model.effort')
[ -z "$EFFORT" ] && EFFORT=$(j '.reasoning_effort')
[ -z "$EFFORT" ] && EFFORT=$(jq -r '.effortLevel // empty' "$CONFIG_DIR/settings.json" 2>/dev/null)
EFFORT=$(printf '%s' "$EFFORT" | tr -d '\n\r' | tr -cd 'a-zA-Z0-9 _-')

# Cost-based colors, muted ramp: red (cheap) → green (pricey)
# Model: haiku=red, sonnet=gold, opus/fable=green
model_lower=$(printf '%s' "$MODEL" | tr '[:upper:]' '[:lower:]')
case "$model_lower" in
  haiku*) C_MODEL='\033[38;5;167m' ;;     # soft red — cheap
  sonnet*) C_MODEL='\033[38;5;179m' ;;    # soft gold — mid
  opus*|fable*|claude*4*) C_MODEL='\033[38;5;108m' ;;  # sage green — pricey
  *) C_MODEL='\033[38;5;245m' ;;          # grey — unknown
esac

# Haiku has no reasoning effort — drop it.
case "$model_lower" in haiku*) EFFORT='' ;; esac

# Effort ramp: low → max, red → green
effort_lower=$(printf '%s' "$EFFORT" | tr '[:upper:]' '[:lower:]')
case "$effort_lower" in
  low) C_EFF='\033[38;5;167m' ;;          # soft red
  medium|balanced) C_EFF='\033[38;5;173m' ;;  # soft orange
  high) C_EFF='\033[38;5;179m' ;;         # soft gold
  xhigh) C_EFF='\033[38;5;143m' ;;        # olive
  max) C_EFF='\033[38;5;108m' ;;          # sage green
  *) C_EFF='\033[38;5;245m' ;;            # grey — unknown
esac

C_DIM='\033[38;5;240m'    # grey separator
RESET='\033[0m'

OUT=$(printf "${C_MODEL}%s${RESET}" "$MODEL")
[ -n "$EFFORT" ] && OUT="$OUT$(printf " ${C_DIM}·${RESET} ${C_EFF}%s${RESET}" "$EFFORT")"

# Caveman badge, appended if the plugin script is present.
# Glob the version-hash dir so it survives plugin updates.
CAVE=$(ls "$CONFIG_DIR"/plugins/cache/caveman/caveman/*/hooks/caveman-statusline.sh 2>/dev/null | head -n1)
if [ -n "$CAVE" ] && [ -f "$CAVE" ]; then
  BADGE=$(bash "$CAVE" 2>/dev/null)
  [ -n "$BADGE" ] && OUT="$OUT $BADGE"
fi

printf '%b' "$OUT"

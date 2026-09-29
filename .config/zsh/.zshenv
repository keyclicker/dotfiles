# Load Home Manager variables for non-interactive shells too.
[ -r "$HOME/.config/zsh/session.zsh" ] &&
  . "$HOME/.config/zsh/session.zsh"

[ -f "$CARGO_HOME/env" ] && . "$CARGO_HOME/env"

# Terminfo from the nix profile (ghostty on non-NixOS hosts); trailing
# colon keeps ncurses' built-in default search path.
[ -d "$HOME/.nix-profile/share/terminfo" ] &&
  export TERMINFO_DIRS="$HOME/.nix-profile/share/terminfo:$TERMINFO_DIRS"

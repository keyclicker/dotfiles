[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Terminfo from the nix profile (ghostty on non-NixOS hosts); trailing
# colon keeps ncurses' built-in default search path.
[ -d "$HOME/.nix-profile/share/terminfo" ] &&
  export TERMINFO_DIRS="$HOME/.nix-profile/share/terminfo:$TERMINFO_DIRS"
